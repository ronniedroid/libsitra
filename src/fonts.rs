use crate::font::Font;
use serde::Deserialize;
use std::collections::{HashMap, HashSet};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum FontsError {
    #[error("Failed to parse JSON: {0}")]
    JsonError(#[from] serde_json::Error),
}

#[derive(Deserialize)]
struct GoogleFontsResponse {
    items: Vec<GoogleFontItem>,
}

#[derive(Deserialize)]
struct GoogleFontItem {
    family: String,
    files: HashMap<String, String>,
}

pub struct Fonts {
    fonts: HashMap<String, Font>,
}

impl Fonts {
    pub fn new() -> Result<Self, FontsError> {
        let fonts_json = include_str!("assets/fonts.json");
        let google_json = include_str!("assets/google-fonts.json");

        let google_resp: GoogleFontsResponse = serde_json::from_str(google_json)?;

        let google_files_map: HashMap<String, HashMap<String, String>> = google_resp
            .items
            .into_iter()
            .map(|item| (item.family, item.files))
            .collect();

        let google_names: HashSet<String> = google_files_map.keys().cloned().collect();

        let fonts_list: Vec<Font> = serde_json::from_str(fonts_json)?;

        let fonts = fonts_list
            .into_iter()
            .filter(|font| google_names.contains(&font.family))
            .map(|mut font| {
                if let Some(files) = google_files_map.get(&font.family) {
                    font.files.extend(files.clone());
                }
                let font_item = (font.id.clone(), font);
                font_item
            })
            .collect();

        Ok(Self { fonts })
    }

    pub fn font(&self, id: &str) -> Option<&Font> {
        self.fonts.get(id)
    }

    pub fn collection(&self) -> impl Iterator<Item = &Font> {
        self.fonts.values()
    }
}
