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

                load ((string)fonts_data, (string)google_data);
            } catch (Error e) {
                throw new FileError.NOENT ("Failed to load embedded resources: " + e.message);
            }
        }

        public void load (string fonts_json, string google_fonts_json) throws Error {
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

        public Font? font (string id) {
            return fonts.get (id);
        }

        public Gee.Collection<Font> collection () {
            return fonts.values;
        }
    }
