//
//  Welcome.swift
//  Kiwix
//
//  Created by Chris Li on 6/4/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

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
            .onChange(of: library.isInProgress) { isInProgress in
                guard !isInProgress else { return }
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
                Library(tabItem: .categories)
            }
            #endif
        } else {
            LazyVGrid(
                columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
                alignment: .leading,
                spacing: 12
            ) {
                GridSection(title: "library-main-page".localized) {
                    ForEach(zimFiles) { zimFile in
                        Button {
                            guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID) else { return }
                            browser.load(url: url)
                        } label: {
                            ZimFileCell(zimFile, prominent: .name)
                        }.buttonStyle(.plain)
                    }
                }
                if !bookmarks.isEmpty {
                    GridSection(title: "title-bookmarks".localized) {
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
                    Text("title-open-file".localized)
                    Spacer()
                }.padding(6)
            }
            Button {
                library.start(isUserInitiated: true)
            } label: {
                HStack {
                    Spacer()
                    if library.isInProgress {
                        #if os(macOS)
                        Text("title-fetching".localized)
                        #elseif os(iOS)
                        HStack(spacing: 6) {
                            ProgressView().frame(maxHeight: 10)
                            Text("title-fetching".localized)
                        }
                        #endif
                    } else {
                        Text("title-fetch-catalog".localized)
                    }
                    Spacer()
                }.padding(6)
            }.disabled(library.isInProgress)
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
