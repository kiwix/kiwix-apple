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
        guard let action = viewModel.action else { return }
        defer { viewModel.action = nil }
        switch action {
        case .back:
            nsView.goBack()
        case .forward:
            nsView.goForward()
        case .url(let url):
            nsView.load(URLRequest(url: url))
        case .main(let zimFileID):
            let zimFileID = zimFileID ?? nsView.url?.host ?? ""
            guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
            nsView.load(URLRequest(url: url))
        }
    }
}

enum WebViewAction {
    case back, forward, url(URL), main(String? = nil)
}
