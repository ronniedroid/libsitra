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
namespace Libsitra {
    public class Fonts : Object {
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
            // Try multiple possible locations for the data files
            string[] possible_prefixes = {
                "/usr/local/share/libsitra",  // Default --prefix=/usr/local
                "/usr/share/libsitra",         // System installation
                Path.build_filename (Environment.get_current_dir (), "src", "assets")  // Development fallback
            };

            string? fonts_json_path = null;
            string? google_fonts_json_path = null;

            // Find the first location where both files exist
            foreach (var prefix in possible_prefixes) {
                var fonts_path = Path.build_filename (prefix, "fonts.json");
                var google_path = Path.build_filename (prefix, "google-fonts.json");

                if (FileUtils.test (fonts_path, FileTest.EXISTS) &&
                    FileUtils.test (google_path, FileTest.EXISTS)) {
                    fonts_json_path = fonts_path;
                    google_fonts_json_path = google_path;
                    break;
                }
            }

            if (fonts_json_path == null || google_fonts_json_path == null) {
                throw new FileError.NOENT ("Could not find fonts.json and google_fonts.json in any expected location");
            }

            // Read fonts.json
            string fonts_json;
            FileUtils.get_contents (fonts_json_path, out fonts_json);

            // Read google_fonts.json
            string google_fonts_json;
            FileUtils.get_contents (google_fonts_json_path, out google_fonts_json);

            // Parse the JSON data
            load_from_json (fonts_json, google_fonts_json);
        }

        public void load_from_json (string fonts_json, string google_fonts_json) throws Error {
            var google_files_map = new Gee.HashMap<string, Gee.Map<string, string>> ();
            var google_parser = new Json.Parser ();
            google_parser.load_from_data (google_fonts_json);

            var root = google_parser.get_root ().get_object ();
            var items = root.get_array_member ("items");

            foreach (var node in items.get_elements ()) {
                var obj = node.get_object ();
                string family = obj.get_string_member ("family");
                google_fonts.add (family);

                var files_obj = obj.get_object_member ("files");
                var variant_files = new Gee.HashMap<string, string> ();

                foreach (var member_name in files_obj.get_members ()) {
                    variant_files.set (member_name, files_obj.get_string_member (member_name));
                }
                google_files_map.set (family, variant_files);
            }

            var parser = new Json.Parser ();
            parser.load_from_data (fonts_json);
            var array = parser.get_root ().get_array ();

            foreach (var node in array.get_elements ()) {
                var font_info = Font.from_json (node.get_object ());
                if (google_fonts.contains (font_info.family)) {
                    if (google_files_map.has_key (font_info.family)) {
                        font_info.files.set_all (google_files_map.get (font_info.family));
                    }
                    fonts.set (font_info.id, font_info);
                }
            }
        }

        public Font? get_font (string id) {
            return fonts.get (id);
        }

        public Gee.Map<string, Font> get_all_fonts () {
            return fonts;
        }

        public Gee.List<string> get_font_names () {
            var font_list = new Gee.ArrayList<Font> ();
            font_list.add_all (fonts.values);

            font_list.sort ((font_a, font_b) => {
                // Calculate combined score (subsets + weights)
                int score_a = font_a.subsets.size + font_a.weights.size;
                int score_b = font_b.subsets.size + font_b.weights.size;
                int score_diff = score_b - score_a;
                if (score_diff != 0) {
                    return score_diff;
                }
                // If scores are equal, fall back to alphabetical
                return font_a.family.collate (font_b.family);
            });

            var names = new Gee.ArrayList<string> ();
            foreach (var font in font_list) {
                names.add (font.family);
            }
            return names;
        }

        public string?[] get_font_names_array () {
            var names = (string[]) get_font_names ().to_array ();
            var result = new string?[names.length + 1];
            for (int i = 0; i < names.length; i++) {
                result[i] = names[i];
            }
            result[names.length] = null;
            return result;
        }

        public string get_font_cdn_link (Font font, string subset, int? weight = null, bool italic = false) {
            if (font.variable) {
                string style = italic ? "italic" : "normal";
                return "https://cdn.jsdelivr.net/fontsource/fonts/%s:vf@latest/%s-wght-%s.woff2".printf(font.id, subset, style);
            } else {
                int w = weight != null ? weight : 400;
                string style = italic ? "italic" : "normal";
                return "https://cdn.jsdelivr.net/fontsource/fonts/%s@latest/%s-%d-%s.woff2".printf(font.id, subset, w, style);
            }
        }
    }
}
