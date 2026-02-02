use crate::font::Font;
use std::collections::{HashMap};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum FontsError {
    #[error("Failed to parse JSON: {0}")]
    JsonError(#[from] serde_json::Error),
}

pub struct Fonts {
    fonts: HashMap<String, Font>,
}

impl Fonts {
    pub fn new() -> Result<Self, FontsError> {

        let fonts = include_str!(concat!(env!("OUT_DIR"), "/fonts.json"));

        let fonts_list: Vec<Font> = serde_json::from_str(fonts)?;

        let mut fonts_map = HashMap::new();

        for font in fonts_list {
            fonts_map.insert(font.id.clone(), font);
        }

        Ok(Self { fonts: fonts_map })
    }

    pub fn font(&self, id: &str) -> Option<&Font> {
        self.fonts.get(id)
    }

    pub fn collection(&self) -> impl Iterator<Item = &Font> {
        self.fonts.values()
    }
}
