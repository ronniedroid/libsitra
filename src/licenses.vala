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

[CCode (gir_namespace = "Libsitra", gir_version = "0.1")]
namespace Libsitra {

public class Licenses : BaseInfo {
    public Licenses () {}

    protected override void initialize_data () {
        data_map["mit"] = "Permissive licence allowing almost unrestricted use, modification, and distribution.";
        data_map["OFL-1.1"] = "Free to use, modify, and distribute, with conditions: no selling and original licence must be included.";
        data_map["Apache-2.0"] = "Permissive, requires attribution, notice of changes, and inclusion of NOTICE file. Modified code can use a different licence.";
        data_map["UFL-1.0"] = "Permissive, requires attribution and licence file.";
        data_map["CC.0-1.0"] = "Permissive license allowing unrestricted use, modification, and distribution.";
        data_map["Unlicense"] = "Permissive license allowing unrestricted use, modification, and distribution.";
    }

    public override string get_id (Libsitra.Font font) {
        return font.license;
    }
}

}
