//
//  ButtonProvider.swift
//  Kiwix
//
//  Created by Chris Li on 12/13/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import WebKit
import RealmSwift

class ButtonProvider {
    unowned var webView: WKWebView
    weak var rootViewController: RootViewController? { didSet { setupTargetActions() } }
    
    let chevronLeftButton = BarButton(imageName: "chevron.left")
    let chevronRightButton = BarButton(imageName: "chevron.right")
    let outlineButton = BarButton(imageName: "list.bullet")
    let bookmarkButton = BookmarkButton(imageName: "star", bookmarkedImageName: "star.fill")
    private let bookmarkLongPressGestureRecognizer = UILongPressGestureRecognizer()
    
    var navigationLeftButtons: [BarButton] {
        [chevronLeftButton, chevronRightButton, outlineButton, bookmarkButton]
    }
    
    private var webViewURLObserver: NSKeyValueObservation?
    private var webViewCanGoBackObserver: NSKeyValueObservation?
    private var webViewCanGoForwardObserver: NSKeyValueObservation?
    private var bookmarksObserver: NotificationToken?
    
    init(webView: WKWebView) {
        self.webView = webView
        
        bookmarkButton.addGestureRecognizer(bookmarkLongPressGestureRecognizer)
        
        webViewURLObserver = webView.observe(\.url, changeHandler: { webView, _ in
            guard let url = webView.url else { return }
            self.bookmarkButton.isBookmarked = BookmarkService().get(url: url) != nil
        })
        webViewCanGoBackObserver = webView.observe(\.canGoBack, options: [.initial, .new], changeHandler: { (webView, _) in
            self.chevronLeftButton.isEnabled = webView.canGoBack
        })
        webViewCanGoForwardObserver = webView.observe(\.canGoForward, options: [.initial, .new], changeHandler: { (webView, _) in
            self.chevronRightButton.isEnabled = webView.canGoForward
        })
        bookmarksObserver = BookmarkService.list()?.observe { change in
            guard case .update = change, let url = webView.url else { return }
            self.bookmarkButton.isBookmarked = BookmarkService().get(url: url) != nil
        }
    }
    
    private func setupTargetActions() {
        guard let controller = rootViewController else { return }
        chevronLeftButton.addTarget(controller, action: #selector(controller.goBack), for: .touchUpInside)
        chevronRightButton.addTarget(controller, action: #selector(controller.goForward), for: .touchUpInside)
        outlineButton.addTarget(controller, action: #selector(controller.toggleOutline), for: .touchUpInside)
        bookmarkButton.addTarget(controller, action: #selector(controller.bookmarkButtonPressed), for: .touchUpInside)
        
        bookmarkLongPressGestureRecognizer.addTarget(controller, action: #selector(controller.bookmarkButtonLongPressed))
    }
}
