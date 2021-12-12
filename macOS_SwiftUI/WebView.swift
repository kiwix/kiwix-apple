//
//  WebView.swift
//  Kiwix
//
//  Created by Chris Li on 11/5/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit
import RealmSwift

struct WebView: NSViewRepresentable {
    @Binding var url: URL?
    let webView: WKWebView
    
    func makeNSView(context: Context) -> WKWebView { }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        guard let url = url, nsView.url != url else { return }
        nsView.load(URLRequest(url: url))
    }
}
