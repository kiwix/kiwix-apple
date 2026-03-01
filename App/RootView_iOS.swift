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

@MainActor
struct RootView_iOS: View {
    @State private var allSections: [MenuSection] = MenuSection.allMenuSections
    @State private var menuDict: [MenuSection: [MenuItem]] = MenuSection.staticDictionary
    @State private var selection: MenuItem? = .opened
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(allSections) { (section: MenuSection) -> Section in
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
            }.listStyle(.sidebar)
        } detail: {
            Text("detail: \(String(describing: selection?.name))")
        }.task {
//            await loadTabs()
            await loadDonations()
        }
    }
    
    @ViewBuilder
    private func labelFor(item: MenuItem) -> some View {
        let isSelected: Bool = item == selection
        switch item {
        case .tab:
            Label {
                Text(item.name)
            } icon: {
                Image(systemName: "square")
                    .symbolVariant(isSelected ? .fill : .none)
                    .modifier(Symbol26Vairant())
            }
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
        var dict = Dictionary<MenuSection, Array<MenuItem>>()
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
    RootView_iOS()
}
#endif
