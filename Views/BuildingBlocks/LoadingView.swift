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

struct LogoView: View {
    var body: some View {
        GeometryReader { geometry in
            Image(Brand.loadingLogoImage)
                .frame(height: 140)
                .aspectRatio(contentMode: .fit)
                .position(
                    x: geometry.size.width * 0.5,
                    y: geometry.size.height * 0.5
                )
            }.ignoresSafeArea()
    }
}

struct LoadingMessageView: View {
    let message: String
    var body: some View {
        GeometryReader { geometry in
            Text(message)
                .position(
                    x: geometry.size.width * 0.5,
                    y: geometry.size.height * 0.5 + 138
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
