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
import SwiftUI
import CoreData

@MainActor
struct RootViewiOS: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var body: some View {
        if horizontalSizeClass == .compact {
            CompactViewWrapper()
        } else {
            SplitViewForiPad()
        }
    }
}

@MainActor
struct SplitViewForiPad: View {
    @EnvironmentObject var navigation: NavigationViewModel
    @State private var allSections: [MenuSection] = MenuSection.allMenuSections
    @State private var menuDict: [MenuSection: [MenuItem]] = MenuSection.staticDictionary
    @State private var selection: MenuItem? = .opened
    @State private var navPath = NavigationPath()
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "created", ascending: true)],
        predicate: Tab.Predicate.notMissing(),
        animation: .easeInOut
    ) private var tabs: FetchedResults<Tab>

    var body: some View {
        let _ = Self._logChanges()
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(allSections) { (section: MenuSection) in
                    sectionFor(section)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle(Brand.appName)
            .toolbar {
                ToolbarItem(id: "add_tab") {
                    Button {
                        navigation.createTab()
                    } label: {
                        Image(systemName: "plus.square")
                    }
                    .onLongPressGesture {
                        // TODO: impement menu
                    }
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
                    // this should not be triggered
                    let _ = assertionFailure("donation selection should not be triggerred")
                    EmptyView()
                case .hotspot:
                    HotspotZimFilesSelection()
                case nil:
                    EmptyView()
                }
            }
        }
        .task {
            await loadDonations()
            await observeOpeningFiles()
        }
        .onChange(of: navigation.currentItem) { _, newValue in
            updateSelection(newValue)
        }
    }
    
    @ViewBuilder
    private func sectionFor(_ section: MenuSection) -> some View {
        if section == .tabs {
            Section {
                ForEach(tabs) { (tab: Tab) in
                    NavigationLink(value: MenuItem.tab(objectID: tab.objectID)) {
                        labelFor(tab: tab)
                    }.id(tab.id)
                }
                .onDelete(perform: deleteTab)
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
        let image: UIImage = {
            if let zimFile = tab.zimFile, let category = Category(rawValue: zimFile.category) {
                if let imgData = zimFile.faviconData {
                    UIImage(data: imgData) ?? UIImage(systemName: "square")!
                } else {
                    UIImage(named: category.icon) ?? UIImage(systemName: "square")!
                }
            } else {
                UIImage(systemName: "square")!
            }
        }()
        
        Label {
            Text(text)
                .lineLimit(1)
                .truncationMode(.tail)
        } icon: {
            Image(uiImage: image)
                .resizable()
                .frame(maxWidth: 22, maxHeight: 22)
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 3, height: 3)))
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
    
    private func deleteTab(at offsets: IndexSet) {
        for offset in offsets {
            if 0 <= offset && offset < tabs.count {
                let tab = tabs[offset]
                Task {
                    await navigation.deleteTab(tabID: tab.objectID)
                }
            }
        }
    }
    
    private func updateSelection(_ newNavItem: NavigationItem?) {
        if let newNavItem, let newSelection = MenuItem(from: newNavItem) {
            if selection != newSelection {
                selection = newSelection
            }
        }
    }
    
    @MainActor
    private func observeOpeningFiles() async {
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
                    navPath.append(ZimFileService.shared.get)
                }
                if let deepLinkId {
                    DeepLinkService.shared.stopFor(uuid: deepLinkId)
                }
            }
        }
    }
}

struct Symbol26Vairant: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.symbolColorRenderingMode(.gradient)
        } else {
            content
        }
    }
}

enum MenuSection: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case tabs
    case primary
    case library
    case settings
    case donation
    
    static var allMenuSections: [MenuSection] {
        switch (FeatureFlags.hasLibrary, Brand.hideDonation) {
        case (true, true):
            allCases.filter { ![.donation].contains($0) }
        case (false, true):
            allCases.filter { ![.donation, .library].contains($0) }
        case (true, false):
            allCases
        case (false, false):
            allCases.filter { ![.library].contains($0) }
        }
    }
    
    var header: String? {
        switch self {
        case .library: return LocalString.common_tab_menu_library
        default: return nil
        }
    }
    
    static var staticDictionary: [MenuSection: [MenuItem]] {
        var dict: [MenuSection: [MenuItem]] = [:]
        for section in allMenuSections {
            dict[section] = itemsFor(section)
        }
        return dict
    }
    
    static func itemsFor(_ section: MenuSection) -> [MenuItem] {
        switch section {
        case .primary: return [.bookmarks]
        case .library: return [.opened, .categories, .downloads, .new, .hotspot]
        case .settings:
            if !FeatureFlags.hasLibrary {
                return [.hotspot, .settings(scrollToHotspot: false)]
            } else {
                return [.settings(scrollToHotspot: false)]
            }
            // initially empty, we load them async
        case .tabs: return []
        case .donation: return []
        }
    }
}

#Preview {
    RootViewiOS()
}
#endif
