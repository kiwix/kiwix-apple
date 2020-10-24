//
//  WebView.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit

@available(iOS 14.0, *)
struct WebView: UIViewRepresentable {
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        return sceneViewModel.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
}
