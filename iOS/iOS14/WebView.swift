//
//  WebView.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct WebView: UIViewControllerRepresentable {
    private let webViewController = WebViewController()
    
    func makeUIViewController(context: Context) -> WebViewController {
        return webViewController
    }
    
    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        
    }
}

@available(iOS 14.0, *)
class WebViewStates: ObservableObject {
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
}
