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

struct BadgeModifier: ViewModifier {
    let count: Int
    
    private static let formatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        numberFormatter.usesGroupingSeparator = false
        return numberFormatter
    }()
    
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            HStack {
                if FeatureFlags.hasLibrary, count > 0 {
                    Text(Self.formatter.string(for: count) ?? "")
                        .font(.subheadline)
                        .fontDesign(.monospaced)
                        .frame(minWidth: 18, minHeight: 18)
                        .padding(.horizontal, count > 9 ? 12 : 8)
                        .foregroundColor(.background)
                        .background(Color.accentColor.opacity(0.5))
                        .clipShape(Capsule())
                        .bold()
                }
                content
            }
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0))
        }
    }
}
