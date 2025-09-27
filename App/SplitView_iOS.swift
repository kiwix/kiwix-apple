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

struct SplitViewiOS: View {
    @State private var currentNavItem: MenuItem?
    @State private var preferredColumn = NavigationSplitViewColumn.detail
    @EnvironmentObject private var navigation: NavigationViewModel
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Tab.created, order: .reverse)],
        predicate: Tab.Predicate.notMissing,
        animation: .easeInOut
    ) private var tabs: FetchedResults<Tab>
    
    private enum Section: String, CaseIterable {
        case tabs
        case primary
        case library
        case settings
        case donation

        static var allSections: [Section] {
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
    }
    
    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredColumn) {
            // sidebar
            List(selection: $currentNavItem) {
//                Section {
                    ForEach(tabs) { tab in
                        menuLabel(for: tab)
                    }
//                }
            }
            .navigationTitle(Brand.appName)
            .navigationBarTitleDisplayMode(.inline)
//            .toolbarVisibility(.automatic, for: .navigationBar)
//            .toolbar {
//                ToolbarItem {
//                    Button {
//                        Label(title: Text(LocalString.sidebar_view_navigation_button_close)
//                    }
//                }
//            }
        } content: {
            EmptyView()
        } detail: {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func menuLabel(for tab: Tab) -> some View {
        let text: String = tab.title ?? LocalString.common_tab_menu_new_tab
        let image: Image = imageFor(tab: tab)
        
        Label {
            Text(text)
        } icon: {
            image.frame(width: 22, height: 22)
                .cornerRadius(3)
        }
    }
    
    private func imageFor(tab: Tab) -> Image {
        if let zimFile = tab.zimFile,
           let category = Category(rawValue: zimFile.category) {
            if let imageData = zimFile.faviconData,
               let img = imageFrom(data: imageData) {
                return img
            } else {
                return Image(systemName: category.icon)
            }
        }
        return Image(systemName: "square")
    }
        
    /*
     if let zimFile = tab.zimFile, let category = Category(rawValue: zimFile.category) {
         config.textProperties.numberOfLines = 1
         if let imgData = zimFile.faviconData {
             config.image = UIImage(data: imgData)
         } else {
             config.image = UIImage(named: category.icon)
         }
         config.imageProperties.maximumSize = CGSize(width: 22, height: 22)
         config.imageProperties.cornerRadius = 3
     } else {
         config.image = UIImage(systemName: "square")
     }
     */
    
    @ViewBuilder
    private func defaultMenuLabel(for item: MenuItem) -> some View {
        let image = Image(systemName: item.icon)
        Label {
            Text(item.name)
                .lineLimit(1)
        } icon: {
            if let iconColor = item.iconForegroundColor {
                image.tint(Color(uiColor: iconColor))
            } else {
                image
            }
        }.accessibilityIdentifier(item.accessibilityIdentifier)
    }
}

private func imageFrom(data: Data) -> Image? {
    guard let uiImage = UIImage(data: data) else {
        return nil
    }
    return Image(uiImage: uiImage)
}
#endif
