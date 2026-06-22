#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use tauri::menu::{AboutMetadata, Menu, PredefinedMenuItem, Submenu};

fn main() {
    let builder = tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_process::init())
        .setup(|app| {
            // Updater needs to be registered inside setup, gated to desktop
            // only (it isn't supported on mobile targets).
            #[cfg(desktop)]
            app.handle().plugin(tauri_plugin_updater::Builder::new().build())?;
            Ok(())
        });

    // Only macOS gets a menu - see earlier notes on why Windows skips this.
    let builder = if cfg!(target_os = "macos") {
        builder.menu(|handle| {
            let about_metadata = AboutMetadata {
                version: Some("1.0.0".into()),
                short_version: Some("Build 1".into()),
                copyright: Some("© 2026 Marin Golub".into()),
                credits: Some("A game about sliding through graveyards.".into()),
                ..Default::default()
            };

            let app_menu = Submenu::with_items(
                handle,
                "Graveyard Slide",
                true,
                &[
                    &PredefinedMenuItem::about(handle, Some("About This Madness"), Some(about_metadata))?,
                    &PredefinedMenuItem::separator(handle)?,
                    &PredefinedMenuItem::quit(handle, Some("Get Me Out"))?,
                ],
            )?;
            Menu::with_items(handle, &[&app_menu])
        })
    } else {
        builder
    };

    builder
        .run(tauri::generate_context!())
        .expect("error while running Graveyard Slide");
}
