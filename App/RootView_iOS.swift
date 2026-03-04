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
    @EnvironmentObject var navigation: NavigationViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var allSections: [MenuSection] = MenuSection.allMenuSections
    @State private var menuDict: [MenuSection: [MenuItem]] = MenuSection.staticDictionary
    @State private var selection: MenuItem? = .opened
    @FetchRequest(
        sortDescriptors: [],
        predicate: Tab.Predicate.notMissing(),
        animation: .easeInOut
    ) private var tabs: FetchedResults<Tab>
    
    var body: some View {
        if horizontalSizeClass == .compact {
            CompactViewWrapper()
        } else {
            ipadSplitView()
        }
    }

    @ViewBuilder
    func ipadSplitView() -> some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(allSections) { (section: MenuSection) in
                    if section == .tabs {
                        Section {
                            ForEach(tabs) { (tab: Tab) in
                                NavigationLink(value: MenuItem.tab(objectID: tab.objectID)) {
                                    labelFor(tab: tab)
                                }
                            }
                            .onDelete(perform: deleteTab)
                        }
                    } else {
                        let sectionItems: [MenuItem] = menuDict[section]!
                        Section {
                            ForEach(sectionItems, id: \.id) { (item: MenuItem) -> NavigationLink in
                                NavigationLink(value: item) {
                                    labelFor(item: item)
                                }
                            }
                        } header: {
                            if let headerText = section.header {
                                Text(headerText)
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle(Brand.appName)
        } detail: {
            let navSelection = selection?.navigationItem
            switch navSelection {
            case .loading:
                LoadingDataView()
            case .bookmarks:
                Bookmarks()
            case .tab(let tabID):
                BrowserTab(tabID: tabID).id(tabID)
            case .opened:
                ZimFilesOpened()
            case .categories:
                ZimFilesCategories(dismiss: nil)
            case .new:
                ZimFilesNew(dismiss: nil)
            case .downloads:
                ZimFilesDownloads(dismiss: nil)
            case .hotspot:
                HotspotZimFilesSelection()
            case .settings(let scrollToHotspot):
                Settings(scrollToHotspot: scrollToHotspot)
            case .map, nil:
                EmptyView()
            }
        }
        .task {
            await loadDonations()
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
            // we use labelFor(zimFile:) instead
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
            return [.bookmarks, .opened, .categories, .downloads, .new, .hotspot, .settings]
        } else {
            return [.bookmarks, .hotspot, .settings]
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
                return [.hotspot, .settings]
            } else {
                return [.settings]
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
