//
//  Commands.swift
//  Kiwix
//
//  Created by Chris Li on 8/17/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

struct NavigationCommands: View {
    @FocusedValue(\.canGoBack) var canGoBack: Bool?
    @FocusedValue(\.canGoForward) var canGoForward: Bool?
    @FocusedValue(\.browserViewModel) var browser: BrowserViewModel?
    
    var body: some View {
        Button("Go Back") { browser?.webView.goBack() }
            .keyboardShortcut("[")
            .disabled(canGoBack != true)
        Button("Go Forward") { browser?.webView.goForward() }
            .keyboardShortcut("]")
            .disabled(canGoForward != true)
    }
}

struct PageZoomCommands: View {
    @Default(.webViewPageZoom) var webViewPageZoom
    @FocusedValue(\.browserViewModel) var browser: BrowserViewModel?
    
    var body: some View {
        Button("Actual Size") { webViewPageZoom = 1 }
            .keyboardShortcut("0")
            .disabled(webViewPageZoom == 1 || browser?.url == nil)
        Button("Zoom In") { webViewPageZoom += 0.1 }
            .keyboardShortcut("+")
            .disabled(webViewPageZoom >= 2 || browser?.url == nil)
        Button("Zoom Out") { webViewPageZoom -= 0.1 }
            .keyboardShortcut("-")
            .disabled(webViewPageZoom <= 0.5 || browser?.url == nil)
    }
}
