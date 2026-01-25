/* base_info_manager.vala
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

using GLib;
using Gee;

[CCode (gir_namespace = "Libsitra", gir_version = "0.1")]
namespace Libsitra {

public abstract class BaseInfo : Object {
    protected HashMap<string, string> data_map;

    construct {
        data_map = new HashMap<string, string> ();
        initialize_data ();
    }

    protected abstract void initialize_data ();
    public abstract string get_id (Font font);

    public string get_description (string key) {
        if (data_map.has_key (key)) {
            return data_map[key];
        }
        return "No description available";
    }

    public string[] get_all_keys () {
        var keys = new string[data_map.size];
        int i = 0;
        foreach (var key in data_map.keys) {
            keys[i++] = key;
        }
        return keys;
    }
}

}
