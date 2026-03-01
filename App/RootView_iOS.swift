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
//    @State private var allSections: [MenuSection] = MenuSection.allMenuSections
//    @State private var staticMenus: [MenuSection: [MenuItem]] = MenuSection.staticDictionary
    @State private var selectedItem: MenuItem?
    @State private var items: [MenuItem] = allItems()
    
    var body: some View {
        NavigationSplitView {
            List(items, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.name, systemImage: item.icon)
                }
            }
        } detail: {
            Text("Selected: \(String(describing: selectedItem?.name))")
        }
        .task {
            selectedItem = .opened
        }
        
        
//        NavigationSplitView {
//            List {
//                ForEach(allSections) { (section: MenuSection) in
//                    let sectionItems: [MenuItem] = staticMenus[section]!
//                    if let headerText = section.header {
//                        Section(header: Text(headerText)) {
//                            ForEach(sectionItems, id: \.id) { item in
//                                NavigationLink(value: item) {
//                                    Label(item.name, systemImage: item.icon)
//                                }
//                            }
//                        }
//                    } else {
//                        Section {
//                            ForEach(sectionItems, id: \.id) { item in
//                                NavigationLink(value: item) {
//                                    Label(item.name, systemImage: item.icon)
//                                }
//                            }
//                        }
//                    }
//                }
//            }.listStyle(.sidebar)
//        } detail: {
//            Text("detail")
//        }.task {
//            // load tabs
//            // load donations
//        }
        
    }
    
    private static func allItems() -> [MenuItem] {
        if FeatureFlags.hasLibrary {
            return [.bookmarks, .opened, .categories, .downloads, .new, .hotspot, .settings]
        } else {
            return [.bookmarks, .hotspot, .settings]
        }
    }
}


enum MenuSection: String, CaseIterable, Identifiable {
    var id: String { rawValue }
//    case tabs
    case primary
    case library
    case settings
//    case donation

    static var allMenuSections: [MenuSection] {
        if !FeatureFlags.hasLibrary {
            return allCases.filter { $0 != .library }
        } else {
            return allCases
        }
//        switch (FeatureFlags.hasLibrary, Brand.hideDonation) {
//        case (true, true):
//            allCases.filter { ![.donation].contains($0) }
//        case (false, true):
//            allCases.filter { ![.donation, .library].contains($0) }
//        case (true, false):
//            allCases
//        case (false, false):
//            allCases.filter { ![.library].contains($0) }
//        }
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
//        case .tabs: return []
        case .primary: return [.bookmarks]
        case .library: return [.opened, .categories, .downloads, .new, .hotspot]
        case .settings:
            if !FeatureFlags.hasLibrary {
                return [.hotspot, .settings]
            } else {
                return [.settings]
            }
//        case .donation: return []
//            if await Payment.paymentButtonTypeAsync() != nil {
//                return [.donation]
//            } else {
//                return []
//            }
        }
    }
}

/*
 // apply initial snapshot
 var snapshot = NSDiffableDataSourceSnapshot<Section, MenuItem>()
 snapshot.appendSections(Section.allSections)
 if snapshot.sectionIdentifiers.contains(.primary) {
     snapshot.appendItems([.bookmarks], toSection: .primary)
 }
 if snapshot.sectionIdentifiers.contains(.library) {
     snapshot.appendItems([.opened, .categories, .downloads, .new, .hotspot], toSection: .library)
 }
 if snapshot.sectionIdentifiers.contains(.settings) {
     if !FeatureFlags.hasLibrary {
         snapshot.appendItems([.hotspot], toSection: .settings)
     }
     snapshot.appendItems([.settings], toSection: .settings)
 }
 
 // show the donation async
 Task { @MainActor in
     if snapshot.sectionIdentifiers.contains(.donation),
        await Payment.paymentButtonTypeAsync() != nil {
         snapshot.appendItems([.donation], toSection: .donation)
     }
     await dataSource.applySnapshotUsingReloadData(snapshot)
     try? fetchedResultController.performFetch()
 }
 */



#Preview {
    RootView_iOS()
}
#endif
