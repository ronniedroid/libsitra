/* fonts_manager.vala
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

[CCode (gir_namespace = "Libsitra", gir_version = "0.1")]
public class Libsitra.Fonts : Object {
    private Gee.Map<string, Font> fonts;
    private Gee.Set<string> google_fonts;

    public Fonts () {
        fonts = new Gee.HashMap<string, Font> ();
        google_fonts = new Gee.HashSet<string> ();

        try {
            load_fonts_from_files ();
        } catch (Error e) {
            warning (@"Failed to load fonts: $(e.message)");
        }
    }

    private void load_fonts_from_files () throws Error {
        try {
            var fonts_file = File.new_for_uri ("resource:///io/github/ronniedroid/libsitra/fonts.json");
            var google_file = File.new_for_uri ("resource:///io/github/ronniedroid/libsitra/google-fonts.json");

            uint8[] fonts_data;
            uint8[] google_data;

            fonts_file.load_contents (null, out fonts_data, null);
            google_file.load_contents (null, out google_data, null);

            var google_files_map = parse_google_fonts ((string) google_data);
            load_fonts ((string) fonts_data, google_files_map);
        } catch (Error e) {
            throw new FileError.NOENT ("Failed to load embedded resources: " + e.message);
        }
    }

    private Gee.HashMap<string, Gee.Map<string, string>> parse_google_fonts (string json) throws Error {
        var files_map = new Gee.HashMap<string, Gee.Map<string, string>> ();
        var parser = new Json.Parser ();
        parser.load_from_data (json);

        var items = parser.get_root ().get_object ().get_array_member ("items");
        foreach (var node in items.get_elements ()) {
            var obj = node.get_object ();
            string family = obj.get_string_member ("family");
            google_fonts.add (family);
            files_map.set (family, extract_variant_files (obj));
        }

        return files_map;
    }

    private Gee.Map<string, string> extract_variant_files (Json.Object obj) {
        var variant_files = new Gee.HashMap<string, string> ();
        var files_obj = obj.get_object_member ("files");

        foreach (var member_name in files_obj.get_members ()) {
            variant_files.set (member_name, files_obj.get_string_member (member_name));
        }

        return variant_files;
    }

    private void load_fonts (string json, Gee.HashMap<string, Gee.Map<string, string>> google_files_map) throws Error {
        var parser = new Json.Parser ();
        parser.load_from_data (json);

        foreach (var node in parser.get_root ().get_array ().get_elements ()) {
            var font_info = Font.from_json (node.get_object ());

            if (google_fonts.contains (font_info.family)) {
                if (google_files_map.has_key (font_info.family)) {
                    font_info.files.set_all (google_files_map.get (font_info.family));
                }
                fonts.set (font_info.id, font_info);
            }
        }
    }

    public Font? font (string id) {
        return fonts.get (id);
    }

    public Gee.Collection<Font> collection () {
        return fonts.values;
    }
}
