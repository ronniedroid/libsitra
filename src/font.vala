/* font.vala
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
using Json;

[CCode (gir_namespace = "Libsitra", gir_version = "0.1")]
public class Libsitra.Font : GLib.Object {
    public string id { get; set; }
    public string family { get; set; }
    public string category { get; set; }
    public bool variable { get; set; }
    public string license { get; set; }
    public Gee.List<int> weights { get; set; default = new Gee.ArrayList<int> (); }
    public Gee.List<string> subsets { get; set; default = new Gee.ArrayList<string> (); }
    public Gee.Map<string, string> files { get; set; default = new Gee.HashMap<string, string> (); }
    public Gee.List<string> styles { get; set; default = new Gee.ArrayList<string> (); }

    public Font (string id, string family, string category, bool variable, string license,
        Gee.List<int> weights, Gee.List<string> subsets, Gee.List<string> styles, Gee.Map<string, string>? files = null, Gee.Map<string, string>? links = null) {
        this.id = id;
        this.family = family;
        this.category = category;
        this.variable = variable;
        this.license = license;
        this.weights = weights;
        this.subsets = subsets;
        this.styles = styles;
        if (files != null) {
            this.files.set_all (files);
        }
    }

    public static Font from_json (Json.Object obj) {
        string id = obj.get_string_member ("id");
        string family = obj.get_string_member ("family");
        string category = obj.get_string_member ("category");
        bool variable = obj.get_boolean_member ("variable");
        string license = obj.get_string_member ("license");

        var weights_array = obj.get_array_member ("weights");
        var weights = new Gee.ArrayList<int> ();
        foreach (var node in weights_array.get_elements ()) {
            weights.add ((int) node.get_int ());
        }

        var subsets_array = obj.get_array_member ("subsets");
        var subsets = new Gee.ArrayList<string> ();
        foreach (var node in subsets_array.get_elements ()) {
            subsets.add ((string) node.get_string ());
        }

        var styles_array = obj.get_array_member ("styles");
        var styles = new Gee.ArrayList<string> ();
        foreach (var node in styles_array.get_elements ()) {
            styles.add ((string) node.get_string ());
        }

        var font = new Font (id, family, category, variable, license, weights, subsets, styles, null);
        return font;
    }
}

