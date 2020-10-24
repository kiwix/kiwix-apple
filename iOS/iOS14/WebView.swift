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
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    func makeUIViewController(context: Context) -> WebViewController {
        return sceneViewModel.webViewController
    }
    
    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        
    }
}
