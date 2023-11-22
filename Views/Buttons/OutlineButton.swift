//
//  OutlineButton.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

import SwiftUIBackports

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
            Label("Outline".localized, systemImage: "list.bullet")
        }
        .disabled(browser.outlineItems.isEmpty)
        .help("Show article outline".localized)
        #elseif os(iOS)
        Button {
            isShowingOutline = true
        } label: {
            Image(systemName: "list.bullet")
        }
        .disabled(browser.outlineItems.isEmpty)
        .help("Show article outline".localized)
        .popover(isPresented: $isShowingOutline) {
            NavigationView {
                Group {
                    if browser.outlineItemTree.isEmpty {
                        Message(text: "No outline available".localized)
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
                            Text("Done".localized).fontWeight(.semibold)
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
