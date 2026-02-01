use libsitra::{Fonts, Library};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🔤 Libsitra Demo\n");

    // 1. Load Fonts (Synchronous logic embedded via include_str!)
    println!("Loading fonts...");
    let fonts = Fonts::new()?;

    // collection() returns an Iterator now
    let count = fonts.collection().count();
    println!("✓ Loaded {} fonts\n", count);

    // 2. Show first 5 fonts
    println!("First 5 fonts:");
    // We can use the iterator directly
    for font in fonts.collection().take(5) {
        println!("  • {} ({})", font.family, font.id);
        println!(
            "    Category: {}, Variable: {}",
            font.category, font.variable
        );
    }

    // 3. Initialize the Library (Async logic)
    println!("\n🔧 Initializing Library...");
    let mut library = Library::new().await?;

    // 4. Try Installing a Font (e.g., "Abel")
    if let Some(font) = fonts.font("open-sans") {
        println!("\n📥 Checking font: {}", font.family);

        if library.is_installed(&font.id) {
            println!("  ! {} is already installed.", font.family);
        } else {
            println!("  → Installing {}...", font.family);

            // Define a simple callback to print progress to the console
            let progress_cb = |p: f32| {
                print!(
                    "\r    Progress: [{:<20}] {:.0}%",
                    "=".repeat((p * 20.0) as usize),
                    p * 100.0
                );
                use std::io::{self, Write};
                let _ = io::stdout().flush();
            };

            library.install(font, Some(progress_cb)).await?;
            println!("\n  ✓ Installation complete!");
        }
    }

    // 5. List all tracked fonts
    println!("\n🗄️  Current Library Status:");
    let installed = library.list_installed();
    if installed.is_empty() {
        println!("  No fonts installed yet.");
    } else {
        for id in installed {
            println!("  [Installed] {}", id);
        }
    }

    println!("\n✅ Demo complete!");
    Ok(())
}
