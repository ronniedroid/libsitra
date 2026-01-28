/* licenses_manager.vala
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
public class Libsitra.Licenses : Object {
    private KeyFile key_file;

    public Licenses () {
        key_file = new KeyFile ();
        try {
            var data = resources_lookup_data ("/io/github/ronniedroid/libsitra/licenses", ResourceLookupFlags.NONE);
            key_file.load_from_data ((string)data.get_data (), data.get_size (), KeyFileFlags.NONE);
        } catch (Error e) {
            critical ("Could not load categories: %s", e.message);
        }
    }

    public string describe (Font font) {
        try {
            return key_file.get_string (font.license, "description");
        } catch {
            return "No description available";
        }
    }

    public string[] titles () {
        return key_file.get_groups ();
    }
}
