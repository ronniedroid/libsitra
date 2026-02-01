use crate::font::Font;
use directories::ProjectDirs;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use thiserror::Error;
use tokio::fs;

#[derive(Error, Debug)]
pub enum LibraryError {
    #[error("IO Error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Network Error: {0}")]
    Network(#[from] reqwest::Error),
    #[error("JSON Error: {0}")]
    Json(#[from] serde_json::Error),
    #[error("Font already installed: {0}")]
    AlreadyInstalled(String),
    #[error("Font not installed: {0}")]
    NotInstalled(String),
    #[error("Could not determine project directories")]
    ProjectDirsNotFound,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct InstalledFontEntry {
    id: String,
    family: String,
    install_path: PathBuf,
}

pub struct Library {
    fonts_dir: PathBuf,
    tracking_file_path: PathBuf,
    installed_fonts_db: HashMap<String, InstalledFontEntry>,
    client: reqwest::Client,
}

impl Library {
    pub async fn new() -> Result<Self, LibraryError> {
        let proj_dirs =
            ProjectDirs::from("com", "sitra", "sitra").ok_or(LibraryError::ProjectDirsNotFound)?;
        let data_dir = proj_dirs.data_dir();

        // Uses the 'dirs' crate to find standard font path (~/.local/share/fonts)
        let fonts_dir = dirs::font_dir().unwrap_or_else(|| data_dir.join("fonts"));
        let tracking_file_path = data_dir.join("installed_fonts.json");

        fs::create_dir_all(&fonts_dir).await?;
        fs::create_dir_all(data_dir).await?;

        let mut installed_fonts_db = HashMap::new();
        if tracking_file_path.exists() {
            let content = fs::read_to_string(&tracking_file_path).await?;
            if !content.is_empty() {
                installed_fonts_db = serde_json::from_str(&content)?;
            }
        }

        Ok(Self {
            fonts_dir,
            tracking_file_path,
            installed_fonts_db,
            client: reqwest::Client::new(),
        })
    }

    pub async fn install<F>(
        &mut self,
        font: &Font,
        progress_cb: Option<F>,
    ) -> Result<(), LibraryError>
    where
        F: Fn(f32) + Send + 'static,
    {
        if self.is_installed(&font.id) {
            return Err(LibraryError::AlreadyInstalled(font.id.clone()));
        }

        if let Some(ref cb) = progress_cb {
            cb(0.0);
        }

        let temp_dir = std::env::temp_dir().join(format!("sitra-{}", font.id));
        if temp_dir.exists() {
            fs::remove_dir_all(&temp_dir).await?;
        }
        fs::create_dir_all(&temp_dir).await?;

        let total = font.files.len() as f32;
        for (i, (variant, url)) in font.files.iter().enumerate() {
            let filename = self.normalize_filename(&font.id, variant);
            let file_path = temp_dir.join(filename);
            let response = self.client.get(url).send().await?;
            let content = response.bytes().await?;
            fs::write(file_path, content).await?;

            if let Some(ref cb) = progress_cb {
                cb(((i + 1) as f32 / total) * 0.85);
            }
        }

        let dest_dir = self.fonts_dir.join(&font.id);
        if dest_dir.exists() {
            fs::remove_dir_all(&dest_dir).await?;
        }

        // Try moving (fast). If cross-device, copy then delete (slow).
        if fs::rename(&temp_dir, &dest_dir).await.is_err() {
            fs::create_dir_all(&dest_dir).await?;
            self.copy_dir_all(&temp_dir, &dest_dir).await?;
            let _ = fs::remove_dir_all(&temp_dir).await;
        }

        self.track_installation(font).await?;

        if let Some(ref cb) = progress_cb {
            cb(1.0);
        }

        Ok(())
    }

    pub async fn uninstall(&mut self, font_id: &str) -> Result<(), LibraryError> {
        // 1. Check if it exists
        if !self.is_installed(font_id) {
            return Err(LibraryError::NotInstalled(font_id.to_string()));
        }

        // 2. Remove physical files
        let dest_dir = self.fonts_dir.join(font_id);
        if dest_dir.exists() {
            fs::remove_dir_all(&dest_dir).await?;
        }

        // 3. Update internal DB and save file
        self.installed_fonts_db.remove(font_id);
        self.save_tracking_db().await?;

        Ok(())
    }

    /// Added the missing async directory copy helper
    async fn copy_dir_all(
        &self,
        src: impl AsRef<Path>,
        dst: impl AsRef<Path>,
    ) -> std::io::Result<()> {
        fs::create_dir_all(&dst).await?;
        let mut entries = fs::read_dir(src).await?;

        while let Some(entry) = entries.next_entry().await? {
            let file_type = entry.file_type().await?;
            if file_type.is_dir() {
                // Manual recursion for folders
                Box::pin(self.copy_dir_all(entry.path(), dst.as_ref().join(entry.file_name())))
                    .await?;
            } else {
                fs::copy(entry.path(), dst.as_ref().join(entry.file_name())).await?;
            }
        }

        Ok(())
    }

    pub fn is_installed(&self, font_id: &str) -> bool {
        self.installed_fonts_db.contains_key(font_id)
    }

    async fn track_installation(&mut self, font: &Font) -> Result<(), LibraryError> {
        let entry = InstalledFontEntry {
            id: font.id.clone(),
            family: font.family.clone(),
            install_path: self.fonts_dir.join(&font.id),
        };

        self.installed_fonts_db.insert(font.id.clone(), entry);
        self.save_tracking_db().await
    }

    async fn save_tracking_db(&self) -> Result<(), LibraryError> {
        let json = serde_json::to_string_pretty(&self.installed_fonts_db)?;
        let temp_path = self.tracking_file_path.with_extension("tmp");
        fs::write(&temp_path, &json).await?;
        fs::rename(temp_path, &self.tracking_file_path).await?;

        Ok(())
    }

    pub fn list_installed(&self) -> Vec<String> {
        self.installed_fonts_db.keys().cloned().collect()
    }

    fn normalize_filename(&self, font_id: &str, variant: &str) -> String {
        let suffix = match variant {
            "regular" => String::new(),
            v if v.ends_with("italic") => {
                let weight = v.replace("italic", "");
                if weight.is_empty() {
                    "-italic".to_string()
                } else {
                    format!("-{}-italic", weight)
                }
            }
            v => format!("-{}", v),
        };

        format!("{}{}.ttf", font_id, suffix)
    }
}
