// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import SwiftUI

struct Attribute: View {
    let title: String
    let detail: String?

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(detail ?? LocalString.attribute_detail_unknown).foregroundColor(.secondary)
        }
    }
}

struct AttributeBool: View {
    let title: String
    let detail: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            #if os(macOS)
            Text(detail ? LocalString.common_button_yes : LocalString.common_button_no).foregroundColor(.secondary)
            #elseif os(iOS)
            if detail {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            } else {
                Image(systemName: "multiply.circle.fill").foregroundColor(.orange)
            }
            #endif
        }
    }
}

struct ZimValidationAttributeOptional: View {
    let title: String
    let isValid: Bool?
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            #if os(macOS)
            let textValue: String = {
                switch isValid {
                case .some(true): LocalString.common_button_yes
                case .some(false): LocalString.common_button_no
                case .none: ""
                }
            }()
            Text(textValue).foregroundColor(isValid == false ? .red : .secondary)
            #elseif os(iOS)
            switch isValid {
            case .some(true):
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            case .some(false):
                Image(systemName: "xmark.circle.fill").foregroundColor(.red)
            case .none:
                Image(systemName: "circle").foregroundStyle(.orange)
            }
            #endif
        }
    }
}
