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

struct KiwixLogo: View {
    
    let maxHeight: CGFloat
    
    init(maxHeight: CGFloat = 25) {
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: maxHeight / 4)
                .fill(Color.white)
                .frame(width: maxHeight, height: maxHeight)
            Image("KiwixLogo")
                .resizable()
                .scaledToFit()
                .frame(width: maxHeight / 1.6182, height: maxHeight / 1.6182)
        }
    }
}
