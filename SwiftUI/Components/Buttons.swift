//
//  Buttons.swift
//  Kiwix
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

import Defaults

struct BookmarkToggleButton: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    @FetchRequest private var bookmarks: FetchedResults<Bookmark>
    
    private let url: URL?
    private var isBookmarked: Bool { !bookmarks.isEmpty }
    
    init(url: URL?) {
        self._bookmarks = FetchRequest<Bookmark>(sortDescriptors: [], predicate: {
            if let url = url {
                return NSPredicate(format: "articleURL == %@", url as CVarArg)
            } else {
                return NSPredicate(format: "articleURL == nil")
            }
        }())
        self.url = url
    }
    
    var body: some View {
        Button {
            if isBookmarked {
                viewModel.deleteBookmark(url)
            } else {
                viewModel.createBookmark(url)
            }
        } label: {
            Label {
                Text(isBookmarked ? "Remove Bookmark" : "Add Bookmark")
            } icon: {
                Image(systemName: isBookmarked ? "star.fill" : "star")
                    .renderingMode(isBookmarked ? .original : .template)
            }
        }
        .disabled(url == nil)
        .help(isBookmarked ? "Remove bookmark" : "Bookmark the current article")
    }
}

struct BookmarkMultiButton: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    @FetchRequest private var bookmarks: FetchedResults<Bookmark>
    
    private let url: URL?
    private var isBookmarked: Bool { !bookmarks.isEmpty }
    
    init(url: URL?) {
        self._bookmarks = FetchRequest<Bookmark>(sortDescriptors: [], predicate: {
            if let url = url {
                return NSPredicate(format: "articleURL == %@", url as CVarArg)
            } else {
                return NSPredicate(format: "articleURL == nil")
            }
        }())
        self.url = url
    }
    
    var body: some View {
        Button { } label: {
            Image(systemName: isBookmarked ? "star.fill" : "star")
                .renderingMode(isBookmarked ? .original : .template)
        }
        .simultaneousGesture(TapGesture().onEnded {
            viewModel.activeSheet = .bookmarks
        })
        .simultaneousGesture(LongPressGesture().onEnded { _ in
            if isBookmarked {
                viewModel.deleteBookmark(url)
            } else {
                viewModel.createBookmark(url)
            }
        })
        .help("Show bookmarks. Long press to bookmark or unbookmark the current article.")
    }
}

struct FileImportButton: View {
    @State private var isPresented: Bool = false
    
    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label("Open...", systemImage: "plus")
        }
        .fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [UTType(exportedAs: "org.openzim.zim")],
            allowsMultipleSelection: true
        ) { result in
            guard case let .success(urls) = result else { return }
            for url in urls {
                LibraryViewModel.open(url: url)
            }
        }
        .help("Open a zim file")
        .keyboardShortcut("o")
    }
}

struct LibraryButton: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        Button {
            viewModel.activeSheet = .library
        } label: {
            Label("Library", systemImage: "folder")
        }
    }
}

struct MainArticleButton: View {
    @Binding var url: URL?
    
    var body: some View {
        Button {
            let zimFileID = UUID(uuidString: url?.host ?? "")
            url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID)
        } label: {
            Label("Main Article", systemImage: "house")
        }.help("Show main article")
    }
}

@available(iOS 15.0, *)
struct MainArticleMenu: View {
    @Binding var url: URL?
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        Menu {
            ForEach(zimFiles) { zimFile in
                Button(zimFile.name) {
                    url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.id)
                }
            }
        } label: {
            Label("Main Page", systemImage: "house")
        } primaryAction: {
            let zimFileID = UUID(uuidString: url?.host ?? "")
            url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID)
        }.help("Show main article")
    }
}

struct MoreActionMenu: View {
    @Binding var url: URL?
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        Menu {
            Section {
                ForEach(zimFiles) { zimFile in
                    Button {
                        url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.id)
                    } label: {
                        Label(zimFile.name, systemImage: "house")
                    }
                }
            }
            LibraryButton()
            SettingsButton()
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

struct NavigateBackButton: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        Button {
            viewModel.goBack()
        } label: {
            Label("Go Back", systemImage: "chevron.backward")
        }
        .disabled(!viewModel.canGoBack)
        .help("Show the previous page")
    }
}

struct NavigateForwardButton: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        Button {
            viewModel.goForward()
        } label: {
            Label("Go Forward", systemImage: "chevron.forward")
        }
        .disabled(!viewModel.canGoForward)
        .help("Show the next page")
    }
}

struct NavigationButtons: View {
    @FocusedValue(\.canGoBack) var canGoBack: Bool?
    @FocusedValue(\.canGoForward) var canGoForward: Bool?
    @FocusedValue(\.readingViewModel) var viewModel: ReadingViewModel?
    
    var body: some View {
        Button("Go Back") { viewModel?.goBack() }
            .keyboardShortcut("[")
            .disabled(!(canGoBack ?? false))
        Button("Go Forward") { viewModel?.goForward() }
            .keyboardShortcut("]")
            .disabled(!(canGoForward ?? false))
    }
}

struct OutlineButton: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        Button {
            viewModel.activeSheet = .outline
        } label: {
            Image(systemName: "list.bullet")
        }
        .disabled(viewModel.outlineItems.isEmpty)
        .help("Show article outline")
    }
}

struct OutlineMenu: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        Menu {
            ForEach(viewModel.outlineItems) { item in
                Button(String(repeating: "    ", count: item.level) + item.text) {
                    viewModel.scrollTo(outlineItemID: item.id)
                }
            }
        } label: {
            Label("Outline", systemImage: "list.bullet")
        }
        .disabled(viewModel.outlineItems.isEmpty)
        .help("Show article outline")
    }
}

struct PageZoomButtons: View {
    @Default(.webViewPageZoom) var webViewPageZoom
    @FocusedBinding(\.navigationItem) var navigationItem: NavigationItem??
    @FocusedValue(\.url) var url: URL??
    
    var body: some View {
        Button("Actual Size") { webViewPageZoom = 1 }
            .keyboardShortcut("0")
            .disabled(webViewPageZoom == 1)
        Button("Zoom In") { webViewPageZoom += 0.1 }
            .keyboardShortcut("+")
            .disabled(navigationItem != .reading || (url ?? nil) == nil)
        Button("Zoom Out") { webViewPageZoom -= 0.1 }
            .keyboardShortcut("-")
            .disabled(navigationItem != .reading || (url ?? nil) == nil)
    }
}

struct RandomArticleButton: View {
    @Binding var url: URL?
    
    var body: some View {
        Button {
            let zimFileID = UUID(uuidString: url?.host ?? "")
            url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFileID)
        } label: {
            Label("Random Article", systemImage: "die.face.5")
        }.help("Show random article")
    }
}

@available(iOS 15.0, *)
struct RandomArticleMenu: View {
    @Binding var url: URL?
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        Menu {
            ForEach(zimFiles) { zimFile in
                Button(zimFile.name) {
                    url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFile.id)
                }
            }
        } label: {
            Label("Random Page", systemImage: "die.face.5")
        } primaryAction: {
            let zimFileID = UUID(uuidString: url?.host ?? "")
            url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFileID)
        }.help("Show random article")
    }
}

struct SettingsButton: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        Button {
            viewModel.activeSheet = .settings
        } label: {
            Label("Settings", systemImage: "gear")
        }
    }
}

#if os(macOS)
struct SidebarButton: View {
    var body: some View {
        Button {
            guard let responder = NSApp.keyWindow?.firstResponder else { return }
            responder.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        } label: {
            Image(systemName: "sidebar.leading")
        }
        .help("Show sidebar")
    }
}
#endif

struct SidebarNavigationItemButtons: View {
    @FocusedBinding(\.navigationItem) var navigationItem: NavigationItem??
    
    var body: some View {
        buildButtons([.reading, .bookmarks], keyboardShortcutOffset: 1)
        Divider()
        buildButtons([.opened, .categories, .downloads, .new], keyboardShortcutOffset: 3)
    }
    
    private func buildButtons(_ navigationItems: [NavigationItem], keyboardShortcutOffset: Int) -> some View {
        ForEach(Array(navigationItems.enumerated()), id: \.element) { index, item in
            Button(item.name) {
                navigationItem = item
            }
            .keyboardShortcut(KeyEquivalent(Character("\(index + keyboardShortcutOffset)")))
            .disabled(navigationItem == nil)
        }
    }
}
