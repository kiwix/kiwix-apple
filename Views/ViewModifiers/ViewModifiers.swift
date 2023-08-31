//
//  ToolbarRoleBrowser.swift
//  Kiwix
//
//  Created by Chris Li on 9/1/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

struct MarkAsHalfSheet: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            content.presentationDetents([.medium, .large])
        } else {
            /*
             HACK: Use medium as selection so that half sized sheets are consistently shown
             when tab manager button is pressed, user can still freely adjust sheet size.
            */
            content.backport.presentationDetents([.medium, .large], selection: .constant(.medium))
        }
    }
}

struct ToolbarRoleBrowser: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content
        #elseif os(iOS)
        if #available(iOS 16.0, *) {
            content.toolbarRole(.browser)
        } else {
            content
        }
        #endif
    }
}
