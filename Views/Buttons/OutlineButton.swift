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

struct OutlineButton: View {
    @Environment(\.dismissSearch) private var dismissSearch
    @EnvironmentObject private var browser: BrowserViewModel
    @State private var isShowingOutline = false

    var body: some View {
        #if os(macOS)
        Menu {
            ForEach(browser.outlineItems) { item in
                Button(String(repeating: "    ", count: item.level) + item.text) {
                    browser.scrollTo(outlineItemID: item.id)
                    dismissSearch()
                }
            }
        } label: {
            Label("outline_button.outline.title".localized, systemImage: "list.bullet")
        }
        .disabled(browser.outlineItems.isEmpty)
        .help("outline_button.outline.help".localized)
        #elseif os(iOS)
        Button {
            isShowingOutline = true
        } label: {
            Image(systemName: "list.bullet")
        }
        .disabled(browser.outlineItems.isEmpty)
        .help("outline_button.outline.help".localized)
        .popover(isPresented: $isShowingOutline) {
            NavigationStack {
                Group {
                    if browser.outlineItemTree.isEmpty {
                        Message(text: "outline_button.outline.empty.message".localized)
                    } else {
                        List(browser.outlineItemTree) { item in
                            OutlineNode(item: item) { item in
                                browser.scrollTo(outlineItemID: item.id)
                                isShowingOutline = false
                                dismissSearch()
                            }
                        }.listStyle(.plain)
                    }
                }
                .navigationTitle(browser.articleTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            isShowingOutline = false
                        } label: {
                            Text("common.button.done".localized).fontWeight(.semibold)
                        }
                    }
                }
            }
            .frame(idealWidth: 360, idealHeight: 600)
            .modifier(MarkAsHalfSheet())
        }
        #endif
    }

    struct OutlineNode: View {
        @ObservedObject var item: OutlineItem

        let action: ((OutlineItem) -> Void)?

        var body: some View {
            if let children = item.children {
                DisclosureGroup(isExpanded: $item.isExpanded) {
                    ForEach(children) { child in
                        OutlineNode(item: child, action: action)
                    }
                } label: {
                    Button(item.text) { action?(item) }
                }
            } else {
                Button(item.text) { action?(item) }
            }
        }
    }
}
