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

#if os(iOS)
import Foundation
import SwiftUI

@MainActor
struct SplitViewForiPad: View {
    @EnvironmentObject var navigation: NavigationViewModel
    // start with side menu collapsed state by default
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var allSections: [MenuSection] = MenuSection.allMenuSections
    @State private var menuDict: [MenuSection: [MenuItem]] = MenuSection.staticDictionary
    @State private var selection: MenuItem?
    @State private var navPath = NavigationPath()
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "created", ascending: true)],
        predicate: Tab.Predicate.notMissing(),
        animation: .easeInOut
    ) private var tabs: FetchedResults<Tab>
    private let selectFileById = NotificationCenter.default.publisher(for: .selectFile)
    @State private var hasZimFiles: Bool?
    @State private var openingFilesTask: Task<Void, Never>?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selection) {
                ForEach(allSections) { (section: MenuSection) in
                    sectionFor(section)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle(Brand.appName)
            .toolbar {
                Menu {
                    Button(role: .destructive) {
                        guard case let .tab(tabID) = navigation.currentItem else { return }
                        Task { [weak navigation] in
                            await navigation?.deleteTab(tabID: tabID)
                        }
                    } label: {
                        Label(LocalString.common_tab_menu_close_this, systemImage: "xmark.square")
                    }
                    Button(role: .destructive) {
                        Task { [weak navigation] in
                            await navigation?.deleteAllTabs()
                        }
                    } label: {
                        Label(LocalString.common_tab_menu_close_all, systemImage: "xmark.square.fill")
                    }
                } label: {
                    Label(LocalString.common_tab_menu_new_tab, systemImage: "plus.square")
                } primaryAction: {
                    navigation.createTab()
                }
            }
        } detail: {
            NavigationStack(path: $navPath) {
                switch selection {
                case .tab(let tabID):
                    BrowserTab(tabID: tabID).id(tabID)
                case .bookmarks:
                    Bookmarks()
                case .opened:
                    ZimFilesOpened()
                case .categories:
                    ZimFilesCategories(dismiss: nil)
                case .new:
                    ZimFilesNew(dismiss: nil)
                case .downloads:
                    ZimFilesDownloads(dismiss: nil)
                case let .settings(scrollToHotspot):
                    Settings(scrollToHotspot: scrollToHotspot)
                case .donation:
                    // this won't be triggered
                    EmptyView()
                case .hotspot:
                    HotspotZimFilesSelection()
                case nil:
                    LoadingDataView()
                }
            }
        }
        .task {
            await loadDonations()
            await observeHasZimFiles()
            observeOpeningFiles()
            // set up the default selection
            // as direct opening a file (when the app is not launched)
            // won't trigger .onChange(of: navigation.currentItem)
            if let currentItem = navigation.currentItem {
                selection = MenuItem(from: currentItem)
            }
        }
        .onChange(of: navigation.currentItem) { oldValue, newValue in
            if newValue != oldValue {
                if hasZimFiles == true, newValue != .loading {
                    // allow the side menu to be displayed
                    columnVisibility = .automatic
                } else if hasZimFiles == false {
                    columnVisibility = .detailOnly
                }
            }
            updateSelection(newValue)
        }
        // open file details, after importing file
        .onReceive(selectFileById, perform: { notification in
            guard let fileId = notification.userInfo?["fileId"] as? UUID else {
                return
            }
            navPath.append(fileId)
        })
    }
    
    @ViewBuilder
    private func sectionFor(_ section: MenuSection) -> some View {
        if section == .tabs {
            Section {
                ForEach(tabs) { (tab: Tab) in
                    NavigationLink(value: MenuItem.tab(objectID: tab.objectID)) {
                        labelFor(tab: tab)
                    }
                    .id(tab.id)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { [weak navigation] in
                                await navigation?.deleteTab(tabID: tab.objectID)
                            }
                        } label: {
                            Label(LocalString.sidebar_view_navigation_button_close, systemImage: "xmark")
                        }
                    }
                }
            }
        } else {
            if let sectionItems: [MenuItem] = menuDict[section] {
                Section {
                    ForEach(sectionItems, id: \.id) { (item: MenuItem) in
                        navigationLinkFor(item: item)
                            .id(item.id)
                    }
                } header: {
                    if let headerText = section.header {
                        Text(headerText)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func navigationLinkFor(item: MenuItem) -> some View {
        if case .donation = item {
            Button {
                // trigger the donation pop-up, but do not select the menu item itself
                NotificationCenter.openDonations()
            } label: {
                labelFor(item: .donation)
            }
        } else {
            NavigationLink(value: item) {
                labelFor(item: item)
            }
            .id(item.id)
        }
    }
    
    @ViewBuilder
    private func labelFor(tab: Tab) -> some View {
        let text = tab.title ?? LocalString.common_tab_menu_new_tab

        Label {
            Text(text)
                .lineLimit(1)
                .truncationMode(.tail)
        } icon: {
            iconImageFor(tab: tab)
                .resizable()
                .frame(maxWidth: 22, maxHeight: 22)
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 3, height: 3)))
        }
    }

    private func iconImageFor(tab: Tab) -> Image {
        let categoryImage: UIImage?
        if let zimFile = tab.zimFile, let category = Category(rawValue: zimFile.category) {
            if let imgData = zimFile.faviconData,
               let image = UIImage(data: imgData) {
                categoryImage = image
            } else {
                categoryImage = UIImage(named: category.icon)
            }
        } else {
            categoryImage = nil
        }
        
        if let categoryImage {
            return Image(uiImage: categoryImage)
        } else {
            return Image(systemName: "square")
        }
    }
    
    @ViewBuilder
    private func labelFor(item: MenuItem) -> some View {
        let isSelected: Bool = item == selection
        switch item {
        case .tab:
            // we use labelFor(tab:) instead
            EmptyView()
        case .donation:
            Label {
                Text(item.name)
            } icon: {
                Image(systemName: item.icon)
                    .foregroundStyle(Color.red)
                    .symbolVariant(isSelected ? .fill : .none)
                    .modifier(Symbol26Vairant())
            }
        default:
            Label(item.name, systemImage: item.icon)
                .symbolVariant(isSelected ? .fill : .none)
                .modifier(Symbol26Vairant())
        }
    }
    
    private static func allItems() -> [MenuItem] {
        if FeatureFlags.hasLibrary {
            return [.bookmarks, .opened, .categories, .downloads, .new, .hotspot, .settings(scrollToHotspot: false)]
        } else {
            return [.bookmarks, .hotspot, .settings(scrollToHotspot: false)]
        }
    }
    
    private func loadDonations() async {
        guard allSections.contains(.donation) else { return }
        if await Payment.paymentButtonTypeAsync() != nil {
            menuDict[.donation] = [.donation]
        }
    }
    
    private func updateSelection(_ newNavItem: NavigationItem?) {
        if let newNavItem, let newSelection = MenuItem(from: newNavItem) {
            if selection != newSelection {
                selection = newSelection
                while !navPath.isEmpty {
                    navPath.removeLast()
                }
                navPath.append(newSelection)
            }
        }
    }
    
    private func observeOpeningFiles() {
        openingFilesTask = Task {
            // open main page or open in new tab via long tap
            for await notification in NotificationCenter.default.notifications(named: .openURL) {
                guard let url = notification.userInfo?["url"] as? URL else { return }
                let inNewTab = notification.userInfo?["inNewTab"] as? Bool ?? false
                let deepLinkId: UUID?
                if case .deepLink(.some(let linkID)) = notification.userInfo?["context"] as? OpenURLContext {
                    deepLinkId = linkID
                } else {
                    deepLinkId = nil
                }
                Task { @MainActor in
                    if !inNewTab, case let .tab(tabID) = navigation.currentItem {
                        BrowserViewModel.getCached(tabID: tabID).load(url: url)
                    } else {
                        let tabID = navigation.createTab()
                        BrowserViewModel.getCached(tabID: tabID).load(url: url)
                    }
                    if let deepLinkId {
                        DeepLinkService.shared.stopFor(uuid: deepLinkId)
                    }
                }
            }
        }
    }
    
    private func observeHasZimFiles() async {
         let newValue = await Database.shared.viewContext.perform {
            let request = ZimFile.fetchRequest(predicate: ZimFile.openedPredicate())
            let context = Database.shared.viewContext
            if let count = try? context.count(for: request) {
                return count > 0
            }
            return false
        }
        hasZimFiles = newValue
    }
}

private struct Symbol26Vairant: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.symbolColorRenderingMode(.gradient)
        } else {
            content
        }
    }
}

#endif
