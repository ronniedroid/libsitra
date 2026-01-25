/* categories_manager.vala
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

public class Categories : BaseInfo {
    public Categories () {}

    protected override void initialize_data () {
        data_map["sans-serif"] = "Fonts without decorative strokes; clean and modern, commonly used for UI and body text.";
        data_map["display"] = "Decorative fonts designed for headlines and large sizes, not suitable for long text.";
        data_map["serif"] = "Fonts with decorative strokes at the ends of letters; traditional and often used in print.";
        data_map["handwriting"] = "Fonts that mimic handwritten or cursive styles; informal and expressive.";
        data_map["monospace"] = "Fonts where all characters have equal width; commonly used for code and terminals.";
        data_map["icons"] = "Symbol-based fonts containing pictograms or UI icons instead of letters.";
    }

    public override string get_id (Libsitra.Font font) {
        return font.category;
    }

    public string[] get_category_labels () {
        return get_all_keys ();
    }
}

}
