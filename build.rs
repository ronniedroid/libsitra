// build.rs
use std::collections::HashMap;
use std::env;
use std::fs;
use std::path::Path;
use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize)]
struct GoogleFontItem {
    family: String,
    files: HashMap<String, String>,
}

#[derive(Deserialize)]
struct GoogleResponse {
    items: Vec<GoogleFontItem>,
}

#[derive(Deserialize, Serialize)]
struct RawFont {
    id: String,
    family: String,
    category: String,
    variable: bool,
    license: String,
    #[serde(default)]
    weights: Vec<u32>,
    #[serde(default)]
    subsets: Vec<String>,
    #[serde(default)]
    styles: Vec<String>,
    #[serde(default)]
    files: HashMap<String, String>,
}

fn main() {
    println!("cargo:rerun-if-changed=src/assets/fontsource-fonts.json");
    println!("cargo:rerun-if-changed=src/assets/google-fonts.json");

    let out_dir = env::var("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("fonts.json");

    // 1. Load Google Fonts
    let google_raw = fs::read_to_string("src/assets/google-fonts.json")
        .expect("Could not read google-fonts.json");
    let google_data: GoogleResponse = serde_json::from_str(&google_raw).unwrap();
    let google_map: HashMap<String, HashMap<String, String>> = google_data.items
        .into_iter()
        .map(|item| (item.family, item.files))
        .collect();

    // 2. Load Local Fonts
    let local_raw = fs::read_to_string("src/assets/fontsource-fonts.json")
        .expect("Could not read fontsource-fonts.json");
    let local_fonts: Vec<RawFont> = serde_json::from_str(&local_raw).unwrap();

    // 3. Merge and Filter
    let processed: Vec<RawFont> = local_fonts
        .into_iter()
        .filter(|f| google_map.contains_key(&f.family))
        .map(|mut f| {
            if let Some(google_files) = google_map.get(&f.family) {
                f.files.extend(google_files.clone());
            }
            f
        })
        .collect();

    // 4. Generate Rust source code with embedded JSON
    let final_json = serde_json::to_string(&processed).unwrap();

    if !processed.is_empty() {
        fs::write(&dest_path, final_json).unwrap();
    }
}
