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

struct CircularProgressGaugeStyle: ProgressViewStyle {
    
    private let lineWidth: CGFloat
    
    init(lineWidth: CGFloat = 2.35) {
        self.lineWidth = lineWidth
    }
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(Color.secondary, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(configuration.fractionCompleted ?? 0))
                .stroke(Color.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, miterLimit: 0))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: configuration.fractionCompleted)
        }
    }
}
