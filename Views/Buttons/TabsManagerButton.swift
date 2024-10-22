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

#if os(iOS)
struct TabsManagerButton: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @EnvironmentObject private var navigation: NavigationViewModel
    @State private var presentedSheet: PresentedSheet?

    private enum PresentedSheet: String, Identifiable {
        var id: String { rawValue }
        case tabsManager
    }

    var body: some View {
        Menu {
            Section {
                Button {
                    navigation.createTab()
                } label: {
                    Label("common.tab.menu.new_tab".localized, systemImage: "plus.square")
                }
                Button(role: .destructive) {
                    guard case .tab(let tabID) = navigation.currentItem else { return }
                    navigation.deleteTab(tabID: tabID)
                } label: {
                    Label("common.tab.menu.close_this".localized, systemImage: "xmark.square")
                }
                Button(role: .destructive) {
                    navigation.deleteAllTabs()
                } label: {
                    Label("common.tab.menu.close_all".localized, systemImage: "xmark.square.fill")
                }
            }
        } label: {
            Label("common.tab.manager.title".localized, systemImage: "square.stack")
        } primaryAction: {
            presentedSheet = .tabsManager
        }
        .sheet(item: $presentedSheet) { presentedSheet in
            switch presentedSheet {
            case .tabsManager:
                NavigationStack {
                    TabManager().toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                self.presentedSheet = nil
                            } label: {
                                Text("common.button.done".localized).fontWeight(.semibold)
                            }
                        }
                    }
                }.modifier(MarkAsHalfSheet())
            }
        }
    }
}

struct TabManager: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @EnvironmentObject private var navigation: NavigationViewModel
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Tab.created, order: .reverse)],
        animation: .easeInOut
    ) private var tabs: FetchedResults<Tab>

    var body: some View {
        List(tabs, id: \.self) { tab in
            Button {
                navigation.currentItem = NavigationItem.tab(objectID: tab.objectID)
            } label: {
                TabLabel(tab: tab)
            }
            .listRowBackground(
                navigation.currentItem == NavigationItem.tab(objectID: tab.objectID) ? Color.blue.opacity(0.2) : nil
            )
            .swipeActions {
                Button(role: .destructive) {
                    navigation.deleteTab(tabID: tab.objectID)
                } label: {
                    Label("common.tab.list.close".localized, systemImage: "xmark")
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("common.tab.navigation.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                Button(role: .destructive) {
                    guard case let .tab(tabID) = navigation.currentItem else { return }
                    navigation.deleteTab(tabID: tabID)
                } label: {
                    Label("common.tab.menu.close_this".localized, systemImage: "xmark.square")
                }
                Button(role: .destructive) {
                    navigation.deleteAllTabs()
                } label: {
                    Label("common.tab.menu.close_all".localized, systemImage: "xmark.square.fill")
                }
            } label: {
                Label("common.tab.menu.new_tab".localized, systemImage: "plus.square")
            } primaryAction: {
                navigation.createTab()
            }
        }
    }
}
#endif
