//
//  WebView.swift
//  macOS_SwiftUI
//
//  Created by Chris Li on 11/5/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit
import RealmSwift

struct WebView: NSViewRepresentable {
    @EnvironmentObject var viewModel: SceneViewModel
    
    func makeNSView(context: Context) -> WKWebView { viewModel.webView }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        guard let url = viewModel.url, nsView.url != url else { return }
        nsView.load(URLRequest(url: url))
    }
}
