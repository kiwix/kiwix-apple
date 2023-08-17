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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var browser: BrowserViewModel
    @State private var isShowingOutline = false

    var body: some View {
        if horizontalSizeClass == .regular {
            Menu {
                ForEach(browser.outlineItems) { item in
                    Button(String(repeating: "    ", count: item.level) + item.text) {
                        browser.scrollTo(outlineItemID: item.id)
                    }
                }
            } label: {
                Label("Outline", systemImage: "list.bullet")
            }
            .disabled(browser.outlineItems.isEmpty)
            .help("Show article outline")
        } else {
            Button {
                isShowingOutline = true
            } label: {
                Image(systemName: "list.bullet")
            }
            .disabled(browser.outlineItems.isEmpty)
            .help("Show article outline")
            .sheet(isPresented: $isShowingOutline) {
                NavigationView {
                    Group {
                        if browser.outlineItemTree.isEmpty {
                            Message(text: "No outline available")
                        } else {
                            List(browser.outlineItemTree) { item in
                                OutlineNode(item: item) { item in
                                    browser.scrollTo(outlineItemID: item.id)
                                    isShowingOutline = false
                                }
                            }.listStyle(.plain)
                        }
                    }
                    .navigationTitle(browser.articleTitle)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                isShowingOutline = false
                            } label: {
                                Text("Done").fontWeight(.semibold)
                            }
                        }
                    }
                }.modify { view in
                    #if os(macOS)
                    view
                    #elseif os(iOS)
                    if #available(iOS 16.0, *) {
                        view.presentationDetents([.medium, .large])
                    } else {
                        /*
                         HACK: Use medium as selection so that half sized sheets are consistently shown
                         when tab manager button is pressed, user can still freely adjust sheet size.
                        */
                        view.backport.presentationDetents([.medium, .large], selection: .constant(.medium))
                    }
                    #endif
                }
            }
        }
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
