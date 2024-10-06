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

enum LogoCalc {

    ///   44 height for the row of buttons,
    /// + 20 spacing above and below (x2)
    /// + 32 for bottom bar
    private static let minButtonSpace: CGFloat = oneRowOfButtonsHeight + spacing * 2 + 32 // 116
    private static let oneRowOfButtonsHeight: CGFloat = 44
    private static let twoRowsOfButtonsHeight: CGFloat = 96
    private static let spacing: CGFloat = 20
    private static let errorMsgHeight: CGFloat = 22

    static func sizeWithin(_ geometry: CGSize) -> CGSize {

        let height = min(geometry.height * 0.5,
                         // 2 * 116 = 232 this is used on the splash screen as well
                         geometry.height - 2 * minButtonSpace)
        let width = max(geometry.width * 0.5, 0)
        let size = CGSize(width: width, height: height)
        debugPrint("Size Within : \(geometry) is: \(size)")
        return size
    }

    static func errorTextCenterYIn(_ geometry: CGSize, isCompact: Bool) -> CGFloat {
        let logoSize = sizeWithin(geometry)
        if isCompact { // put the error to the top of the screen
            return (geometry.height - logoSize.height - errorMsgHeight) * 0.5 - spacing
        } else {
            return (geometry.height + logoSize.height + errorMsgHeight) * 0.5 + spacing + twoRowsOfButtonsHeight + spacing
        }
    }

    static func buttonCenterYIn(_ geometry: CGSize, isCompact: Bool) -> CGFloat {
        let logoSize = sizeWithin(geometry)
        if isCompact { // one row of buttons (HStack)
            return (geometry.height + logoSize.height + oneRowOfButtonsHeight) * 0.5 + spacing
        } else { // two row of buttons (VStack)
            return (geometry.height + logoSize.height + twoRowsOfButtonsHeight) * 0.5 + spacing
        }
    }

    static func buttonsWidthIn(_ geometry: CGSize, isCompact: Bool) -> CGFloat {
        if isCompact {
            return geometry.width - 2 * spacing
        } else {
            return sizeWithin(geometry).width // 2 column buttons, match the logo width
        }
    }
}

struct LogoView: View {
    var body: some View {
        GeometryReader { geometry in
            let logoSize = LogoCalc.sizeWithin(geometry.size)
            Image(Brand.loadingLogoImage)
                .resizable()
                .scaledToFit()
                .frame(width: logoSize.width, height: logoSize.height)
                .position(
                    x: geometry.size.width * 0.5,
                    y: geometry.size.height * 0.5
                )
            }.ignoresSafeArea()
    }
}

struct LoadingMessageView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let message: String
    var body: some View {
        GeometryReader { geometry in
            let isCompact = horizontalSizeClass == .compact
            let buttonCenterY = LogoCalc.buttonCenterYIn(geometry.size, isCompact: isCompact)
            Text(message)
                .position(
                    x: geometry.size.width * 0.5,
                    y: buttonCenterY
                )
        }
    }
}

struct LoadingProgressView: View {
    var body: some View {
        GeometryReader { geometry in
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.primary)
                .frame(
                    width: geometry.size.width * 0.618,
                    height: geometry.size.height * 0.191
                )
                .position(
                    x: geometry.size.width * 0.5,
                    y: geometry.size.height * 0.809
                )
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            LogoView()
            LoadingMessageView(message: "welcome.loading.data.text".localized)
        }.ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
}
