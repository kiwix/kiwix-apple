//
//  Buttons.swift
//  Kiwix
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

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
            viewModel.webView?.goBack()
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
            viewModel.webView?.goForward()
        } label: {
            Label("Go Forward", systemImage: "chevron.forward")
        }
        .disabled(!viewModel.canGoForward)
        .help("Show the next page")
    }
}

struct NavigationItemButtons: View {
    @FocusedBinding(\.navigationItem) var navigationItem: NavigationItem??
    
    var body: some View {
        buildButtons([.reading, .bookmarks, .map], keyboardShortcutOffset: 1)
        Divider()
        buildButtons([.opened, .categories, .downloads, .new], keyboardShortcutOffset: 4)
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
