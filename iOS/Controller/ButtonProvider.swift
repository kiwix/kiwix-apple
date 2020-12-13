//
//  ButtonProvider.swift
//  Kiwix
//
//  Created by Chris Li on 12/13/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import WebKit

class ButtonProvider {
    unowned var webView: WKWebView
    
    let chevronLeftButton = BarButton(imageName: "chevron.left")
    let chevronRightButton = BarButton(imageName: "chevron.right")
    let outlineButton = BarButton(imageName: "list.bullet")
    let bookmarkButton = BookmarkButton(imageName: "star", bookmarkedImageName: "star.fill")
    
    var navigationLeftButtons: [BarButton] {
        [chevronLeftButton, chevronRightButton, outlineButton, bookmarkButton]
    }
    
    private var chevronLeftButtonObserver: NSKeyValueObservation?
    private var chevronRightButtonObserver: NSKeyValueObservation?
    
    init(webView: WKWebView) {
        self.webView = webView
        
        chevronLeftButtonObserver = webView.observe(\.canGoBack, options: [.initial, .new], changeHandler: { (webView, _) in
            self.chevronLeftButton.isEnabled = webView.canGoBack
        })
        chevronRightButtonObserver = webView.observe(\.canGoForward, options: [.initial, .new], changeHandler: { (webView, _) in
            self.chevronRightButton.isEnabled = webView.canGoForward
        })
    }
}
