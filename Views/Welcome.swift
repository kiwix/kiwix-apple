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

struct Welcome: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var browser: BrowserViewModel
    @EnvironmentObject private var library: LibraryViewModel
    @EnvironmentObject private var navigation: NavigationViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.created, ascending: false)],
        animation: .easeInOut
    ) private var bookmarks: FetchedResults<Bookmark>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isLibraryPresented = false

    var body: some View {
        if zimFiles.isEmpty {
            HStack {
                Spacer()
                VStack(spacing: 20) {
                    Spacer()
                    logo
                    Divider()
                    actions
                    Spacer()
                }
                #if os(macOS)
                .frame(maxWidth: 300)
                #elseif os(iOS)
                .frame(maxWidth: 600)
                #endif
                Spacer()
            }
            .padding()
            .ignoresSafeArea()
            .onChange(of: library.state) { state in
                guard state != .inProgress else { return }
                #if os(macOS)
                navigation.currentItem = .categories
                #elseif os(iOS)
                if horizontalSizeClass == .regular {
                    navigation.currentItem = .categories
                } else {
                    isLibraryPresented = true
                }
                #endif
            }
            #if os(iOS)
            .sheet(isPresented: $isLibraryPresented) {
                Library(dismiss: { isLibraryPresented = false }, tabItem: .categories)
            }
            #endif
        } else {
            LazyVGrid(
                columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
                alignment: .leading,
                spacing: 12
            ) {
                GridSection(title: "welcome.main_page.title".localized) {
                    ForEach(zimFiles) { zimFile in
                        Button {
                            guard let url = ZimFileService.shared
                                .getMainPageURL(zimFileID: zimFile.fileID) else { return }
                            browser.load(url: url)
                        } label: {
                            ZimFileCell(zimFile, prominent: .name)
                        }.buttonStyle(.plain)
                    }
                }
                if !bookmarks.isEmpty {
                    GridSection(title: "welcome.grid.bookmarks.title".localized) {
                        ForEach(bookmarks.prefix(6)) { bookmark in
                            Button {
                                browser.load(url: bookmark.articleURL)
                            } label: {
                                ArticleCell(bookmark: bookmark)
                            }
                            .buttonStyle(.plain)
                            .modifier(BookmarkContextMenu(bookmark: bookmark))
                        }
                    }
                }
            }.modifier(GridCommon(edges: .all))
        }
    }

    /// App logo shown in onboarding view
    private var logo: some View {
        VStack(spacing: 6) {
            Image(Brand.welcomeLogoImageName)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 60, height: 60)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).foregroundColor(.white))
            Text(Brand.appName.uppercased()).font(.largeTitle).fontWeight(.bold)
        }
    }

    /// Onboarding actions, open a zim file or refresh catalog
    private var actions: some View {
        HStack {
            OpenFileButton(context: .onBoarding) {
                HStack {
                    Spacer()
                    Text("welcome.actions.open_file".localized)
                    Spacer()
                }.padding(6)
            }
            Button {
                library.start(isUserInitiated: true)
            } label: {
                HStack {
                    Spacer()
                    if library.state == .inProgress {
                        #if os(macOS)
                        Text("welcome.button.status.fetching.text".localized)
                        #elseif os(iOS)
                        HStack(spacing: 6) {
                            ProgressView().frame(maxHeight: 10)
                            Text("welcome.button.status.fetching.text".localized)
                        }
                        #endif
                    } else {
                        Text("welcome.button.status.fetch_catalog.text".localized)
                    }
                    Spacer()
                }.padding(6)
            }.disabled(library.state == .inProgress)
        }
        .font(.subheadline)
        .buttonStyle(.bordered)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Welcome().environmentObject(LibraryViewModel()).preferredColorScheme(.light).padding()
        Welcome().environmentObject(LibraryViewModel()).preferredColorScheme(.dark).padding()
    }
}
