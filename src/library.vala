/* font_manager.vala
 *
 * Copyright 2025 Ronnie Nissan Yousif
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Gee;
using Soup;
using GLib;

[CCode (gir_namespace = "Libsitra", gir_version = "0.1")]
namespace Libsitra {

public class Library : GLib.Object {

    private const string FONTS_DIR_PATH = ".local/share/fonts";
    private const string TRACKING_DIR_PATH = ".local/share/sitra";
    private const string TRACKING_FILE = "installed_fonts.ini";

    private Soup.Session session;
    private string fonts_dir;
    private string tracking_file_path;
    private KeyFile installed_fonts_db;
    private Cancellable? cancellable;

    public signal void installation_started (string font_family);
    public signal void installation_progress (string font_family, double progress);
    public signal void installation_completed (string font_family, bool success, string? error_message);
    public signal void uninstallation_completed (string font_family, bool success, string? error_message);

    public Library () {
        session = new Soup.Session ();

        fonts_dir = Path.build_filename (Environment.get_home_dir (), ".local", "share", "fonts");

        var tracking_dir = Path.build_filename (Environment.get_user_data_dir (), "sitra");
        tracking_file_path = Path.build_filename (tracking_dir, TRACKING_FILE);

        try {
            var fonts_file = File.new_for_path (fonts_dir);
            if (!fonts_file.query_exists ()) {
                fonts_file.make_directory_with_parents ();
            }

            var tracking_dir_file = File.new_for_path (tracking_dir);
            if (!tracking_dir_file.query_exists ()) {
                tracking_dir_file.make_directory_with_parents ();
            }
        } catch (Error e) {
            warning ("FontManager: Failed to create directories: %s", e.message);
        }

        installed_fonts_db = new KeyFile ();
        try {
            installed_fonts_db.load_from_file (tracking_file_path, KeyFileFlags.NONE);
        } catch (Error e) {
            debug ("Installed fonts database not found, will be created on first install");
        }
    }

    public bool is_installed (Font font) {
        return installed_fonts_db.has_group (font.id);
    }

    public Gee.List<string> list_installed () {
        var fonts = new ArrayList<string> ();
        foreach (var group in installed_fonts_db.get_groups ()) {
            fonts.add (group);
        }
        return fonts;
    }

    public async void install (Font font) throws Error {
        if (cancellable != null) {
            throw new IOError.BUSY ("An installation is already in progress");
        }

        cancellable = new Cancellable ();
        installation_started (font.family);
        installation_progress (font.family, 0.0);

        string? error_msg = null;
        bool success = false;

        try {
            if (is_installed (font)) {
                throw new IOError.EXISTS ("Font '%s' is already installed".printf (font.family));
            }

            // Step 1: Create a temporary directory for the font
            var temp_dir = Environment.get_tmp_dir ();
            var font_temp_path = Path.build_filename (temp_dir, "sitra-%s".printf (font.id));
            var font_temp_dir = File.new_for_path (font_temp_path);

            if (font_temp_dir.query_exists ()) {
                yield delete_directory_recursive (font_temp_dir);
            }
            font_temp_dir.make_directory_with_parents ();

            // Step 2: Download each variant (0% - 90%)
            yield download_font_files (font, font_temp_dir);

            installation_progress (font.family, 0.9);

            // Step 3: Move to final destination (90% - 95%)
            var dest_path = Path.build_filename (fonts_dir, font.id);
            var dest_dir = File.new_for_path (dest_path);

            if (dest_dir.query_exists ()) {
                yield delete_directory_recursive (dest_dir);
            }
            dest_dir.make_directory_with_parents ();

            yield copy_directory_recursive (font_temp_dir, dest_dir);
            yield delete_directory_recursive (font_temp_dir);

            installation_progress (font.family, 0.95);

            // Step 4: Update font cache and track installation (95% - 100%)
            yield update_font_cache ();

            track_installation (font);
            installation_progress (font.family, 1.0);

            cancellable = null;
            success = true;
        } catch (Error e) {
            error_msg = e.message;
            if (e is IOError.CANCELLED) {
                error_msg = "Installation cancelled";
            }
            warning ("Font installation failed for %s: %s", font.family, e.message);
            cancellable = null;
        }
        installation_completed (font.family, success, error_msg);
    }

    public void cancel () {
        if (cancellable != null && !cancellable.is_cancelled ()) {
            cancellable.cancel ();
        }
    }

    public async void uninstall (Font font) throws Error {
        string? error_msg = null;
        bool success = false;

        try {
            if (!is_installed (font)) {
                throw new IOError.NOT_FOUND ("Font '%s' is not installed".printf (font.family));
            }

            var dest_path = Path.build_filename (fonts_dir, font.id);
            var dest_dir = File.new_for_path (dest_path);
            if (dest_dir.query_exists ()) {
                yield delete_directory_recursive (dest_dir);
            }

            installed_fonts_db.remove_group (font.id);
            try {
                installed_fonts_db.save_to_file (tracking_file_path);
            } catch (Error e) {
                warning ("Failed to save installed fonts database after uninstallation: %s".printf (e.message));
            }

            yield update_font_cache ();

            success = true;
        } catch (Error e) {
            error_msg = e.message;
            warning ("Font uninstallation failed for %s: %s", font.family, e.message);
        }

        uninstallation_completed (font.family, success, error_msg);
    }

    private async void download_font_files (Font font, File temp_dir) throws Error {
        string[] variants = (string[]) font.files.keys.to_array ();
        double count = 0;
        double total = variants.length;

        foreach (var variant in variants) {
            if (cancellable != null && cancellable.is_cancelled ()) {
                throw new IOError.CANCELLED ("Installation cancelled");
            }

            string url = font.files.get (variant);
            string filename = normalize_filename (font.id, variant);
            var file = temp_dir.get_child (filename);

            yield download_single_file (url, file);

            count++;
            installation_progress (font.family, (count / total) * 0.9);
        }
    }

    private string normalize_filename (string font_id, string variant) {
        if (variant == "regular") {
            return "%s.ttf".printf (font_id);
        }

        string normalized = variant;
        if (variant.has_suffix ("italic")) {
            string weight = variant.replace ("italic", "");
            if (weight == "") {
                normalized = "italic";
            } else {
                normalized = weight + "-italic";
            }
        }

        return "%s-%s.ttf".printf (font_id, normalized);
    }

    private async void download_single_file (string url, File destination) throws Error {
        var message = new Soup.Message ("GET", url);
        message.request_headers.append ("Accept", "font/ttf, application/octet-stream, */*");

        try {
            var input_stream = yield session.send_async (message, Priority.DEFAULT, cancellable);

            if (message.status_code != 200) {
                throw new IOError.FAILED ("Failed to download font file: HTTP %u".printf (message.status_code));
            }

            var output_stream = yield destination.replace_async (null, false, FileCreateFlags.NONE, Priority.DEFAULT, cancellable);

            yield output_stream.splice_async (input_stream, OutputStreamSpliceFlags.CLOSE_SOURCE | OutputStreamSpliceFlags.CLOSE_TARGET, Priority.DEFAULT, cancellable);
        } catch (Error e) {
            throw new IOError.FAILED ("Failed to download font file: %s".printf (e.message));
        }
    }

    private async void copy_directory_recursive (File source, File dest) throws Error {
        var enumerator = yield source.enumerate_children_async (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
            FileQueryInfoFlags.NONE,
            Priority.DEFAULT,
            cancellable);

        FileInfo? info;
        while ((info = enumerator.next_file (cancellable)) != null) {
            if (cancellable != null && cancellable.is_cancelled ()) {
                throw new IOError.CANCELLED ("Installation cancelled");
            }
            var source_child = source.get_child (info.get_name ());
            var dest_child = dest.get_child (info.get_name ());

            if (info.get_file_type () == FileType.DIRECTORY) {
                dest_child.make_directory_with_parents ();
                yield copy_directory_recursive (source_child, dest_child);
            } else {
                yield source_child.copy_async (dest_child, FileCopyFlags.OVERWRITE, Priority.DEFAULT, cancellable);
            }
        }
    }

    private async void delete_directory_recursive (File dir) throws Error {
        var enumerator = yield dir.enumerate_children_async (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
            FileQueryInfoFlags.NONE,
            Priority.DEFAULT,
            null);

        FileInfo? info;
        while ((info = enumerator.next_file (null)) != null) {
            var child = dir.get_child (info.get_name ());
            if (info.get_file_type () == FileType.DIRECTORY) {
                yield delete_directory_recursive (child);
            } else {
                child.delete ();
            }
        }

        dir.delete ();
    }

    private async void update_font_cache () throws Error {
        try {
            var subprocess = new Subprocess (
                                             SubprocessFlags.STDERR_SILENCE,
                                             "fc-cache", "-f"
            );
            yield subprocess.wait_async (null);
        } catch (Error e) {
            debug ("Font cache update failed: %s", e.message);
        }
    }

    private void track_installation (Font font) {
        var now = new DateTime.now_local ();
        var date_string = now.format ("%Y-%m-%d %H:%M:%S");
        var install_path = Path.build_filename (fonts_dir, font.id);

        installed_fonts_db.set_string (font.id, "id", font.id);
        installed_fonts_db.set_string (font.id, "family", font.family);
        installed_fonts_db.set_string (font.id, "install_date", date_string);
        installed_fonts_db.set_string (font.id, "install_path", install_path);

        try {
            installed_fonts_db.save_to_file (tracking_file_path);
        } catch (Error e) {
            warning ("Failed to save installed fonts database: %s".printf (e.message));
        }
    }
}

}
