//
//  TabLabel.swift
//  Kiwix
//
//  Created by Chris Li on 7/29/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

#if os(iOS)
struct TabLabel: View {
    @ObservedObject var tab: Tab
    
    var body: some View {
        if let zimFile = tab.zimFile, let category = Category(rawValue: zimFile.category) {
            Label {
                Text(tab.title ?? "New Tab").lineLimit(1)
            } icon: {
                Favicon(category: category, imageData: zimFile.faviconData).frame(width: 22, height: 22)
            }
        } else {
            Label(tab.title ?? "New Tab", systemImage: "square")
        }
    }
}
#endif

struct TabLabelForMacOS: View {
    @ObservedObject var tab: Tab
    
    var body: some View {
        
        if let zimFile = tab.zimFile, let category = Category(rawValue: zimFile.category) {
            Label {
                Text(tab.title ?? "New Tab").lineLimit(1)
            } icon: {
                Favicon(category: category, imageData: zimFile.faviconData).frame(width: 22, height: 22)
            }
        } else {
            Label(tab.title ?? "New Tab", systemImage: "square")
        }
    }
}
