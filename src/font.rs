use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Font {
    pub id: String,
    pub family: String,
    pub category: String,
    pub variable: bool,
    pub license: String,
    #[serde(default)]
    pub weights: Vec<u32>,
    #[serde(default)]
    pub subsets: Vec<String>,
    #[serde(default)]
    pub styles: Vec<String>,
    #[serde(default)]
    pub files: HashMap<String, String>,
}

impl Font {
    pub fn new(
        id: String,
        family: String,
        category: String,
        variable: bool,
        license: String,
        weights: Vec<u32>,
        subsets: Vec<String>,
        styles: Vec<String>,
        files: HashMap<String, String>,
    ) -> Self {
        Self {
            id,
            family,
            category,
            variable,
            license,
            weights,
            subsets,
            styles,
            files,
        }
    }
}
