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
import Combine
import Defaults

/// Displays the Logo and 2 buttons open file | fetch catalog.
/// Used on new tab, when no ZIM files are available
struct WelcomeCatalog: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @EnvironmentObject private var library: LibraryViewModel
    let viewState: WelcomeViewState

    var body: some View {
        ZStack {
            LogoView()
            welcomeContent
        }.ignoresSafeArea()
    }

    private var welcomeContent: some View {
        GeometryReader { geometry in
            let logoCalc = LogoCalc(
                geometry: geometry.size,
                originalImageSize: Brand.loadingLogoSize,
                horizontal: horizontalSizeClass,
                vertical: verticalSizeClass
            )
            actions
                .position(
                    x: geometry.size.width * 0.5,
                    y: logoCalc.buttonCenterY)
                .frame(maxWidth: logoCalc.buttonsWidth)
            if viewState == .error {
                Text("library_refresh_error.retrieve.description".localized)
                    .foregroundColor(.red)
                    .position(
                        x: geometry.size.width * 0.5,
                        y: logoCalc.errorTextCenterY
                    )
            }
        }
    }

    /// Onboarding actions, open a zim file or refetch catalog
    private var actions: some View {
        if verticalSizeClass == .compact { // iPhone landscape
            AnyView(HStack {
                openFileButton
                fetchCatalogButton
            })
        } else {
            AnyView(VStack {
                openFileButton
                fetchCatalogButton
            })
        }
    }

    private var openFileButton: some View {
        OpenFileButton(context: .welcomeScreen) {
            HStack {
                Spacer()
                Text("welcome.actions.open_file".localized)
                Spacer()
            }.padding(6)
        }
        .font(.subheadline)
        .buttonStyle(.bordered)
    }

    private var fetchCatalogButton: some View {
        Button {
            library.start(isUserInitiated: true)
        } label: {
            HStack {
                Spacer()
                if viewState == .loading {
                    Text("welcome.button.status.fetching_catalog.text".localized)
                } else {
                    Text("welcome.button.status.fetch_catalog.text".localized)
                }
                Spacer()
            }.padding(6)
        }
        .disabled(viewState == .loading)
        .font(.subheadline)
        .buttonStyle(.bordered)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeCatalog(viewState: .loading).environmentObject(LibraryViewModel()).preferredColorScheme(.light).padding()
        WelcomeCatalog(viewState: .error).environmentObject(LibraryViewModel()).preferredColorScheme(.dark).padding()
    }
}
