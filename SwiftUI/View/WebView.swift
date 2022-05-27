//
//  WebView.swift
//  Kiwix
//
//  Created by Chris Li on 11/5/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

#if os(macOS)
struct WebView: NSViewRepresentable {
    @EnvironmentObject var viewModel: ReaderViewModel
    
    func makeNSView(context: Context) -> WKWebView { viewModel.webView }
    func updateNSView(_ uiView: WKWebView, context: Context) { }
}
#elseif os(iOS)
struct WebView: UIViewRepresentable {
    @EnvironmentObject var viewModel: ReaderViewModel
    
    func makeUIView(context: Context) -> WKWebView { viewModel.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) { }
}
#endif
