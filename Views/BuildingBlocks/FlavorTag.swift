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

struct FlavorTag: View {
    let flavor: Flavor

    init(_ flavor: Flavor) {
        self.flavor = flavor
    }

    var body: some View {
        Text(flavor.description)
            .fontWeight(.medium)
            .font(.caption)
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
            .background(backgroundColor)
            .clipShape(Capsule(style: .continuous))
            .overlay(Capsule(style: .continuous).stroke(Color.gray, lineWidth: 0.5))
            .help(help)
    }

    var backgroundColor: Color {
        switch flavor {
        case .max:
            return .green
        case .noPic:
            return .blue
        case .mini:
            return .orange
        }
    }

    var help: String {
        switch flavor {
        case .max:
            return LocalString.flavor_tag_help_max
        case .noPic:
            return LocalString.flavor_tag_help_no_pic
        case .mini:
            return LocalString.flavor_tag_help_mini
        }
    }
}

struct Tag_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            FlavorTag(Flavor(rawValue: "maxi")!)
            FlavorTag(Flavor(rawValue: "nopic")!)
            FlavorTag(Flavor(rawValue: "mini")!)
        }
        .preferredColorScheme(.light)
        .padding()
        .previewLayout(.sizeThatFits)
        HStack(spacing: 20) {
            FlavorTag(Flavor(rawValue: "maxi")!)
            FlavorTag(Flavor(rawValue: "nopic")!)
            FlavorTag(Flavor(rawValue: "mini")!)
        }
        .preferredColorScheme(.dark)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
