//
//  MainController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit
import WebKit

class MainController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var tocVisiualEffectView: UIVisualEffectView!
    @IBOutlet weak var tocTopToSuperViewBottomSpacing: NSLayoutConstraint!
    @IBOutlet weak var tocHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tocLeadSpacing: NSLayoutConstraint!
    
    
    let searchBar = SearchBar()
    lazy var controllers = Controllers()
    lazy var buttons = Buttons()
    
    var isShowingTableOfContents = false
    private(set) var tableOfContentsController: TableOfContentsController?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = searchBar
        searchBar.delegate = self
        buttons.delegate = self
        webView.delegate = self
        
        showWelcome()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass ||
            traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass else {return}
        // buttons
        switch traitCollection.horizontalSizeClass {
        case .compact:
            navigationController?.setToolbarHidden(false, animated: false)
            navigationItem.leftBarButtonItems = nil
            navigationItem.rightBarButtonItems = nil
            if searchBar.isFirstResponder {
                navigationItem.rightBarButtonItem = buttons.cancel
            }
            toolbarItems = buttons.toolbar
        case .regular:
            navigationController?.setToolbarHidden(true, animated: false)
            toolbarItems = nil
            navigationItem.leftBarButtonItems = buttons.navLeft
            navigationItem.rightBarButtonItems = buttons.navRight
        default:
            return
        }
        configureTOCConstraints()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbeddedTOCController" {
            guard let controller = segue.destination as? TableOfContentsController else {return}
            tableOfContentsController = controller
            tableOfContentsController?.delegate = self
        }
    }
    
    
}
