//
//  SettingWebController.swift
//  iOS
//
//  Created by Chris Li on 1/29/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import WebKit

class SettingWebController: UIViewController {
    let fileURL: URL
    let webView = WKWebView()
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: webView.leftAnchor),
            view.rightAnchor.constraint(equalTo: webView.rightAnchor),
            view.topAnchor.constraint(equalTo: webView.topAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor)])
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
    }
}
