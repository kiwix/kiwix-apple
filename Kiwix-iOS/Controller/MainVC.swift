//
//  MainVC.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import PSOperations

class MainVC: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var tocVisiualEffectView: UIVisualEffectView!
    @IBOutlet weak var tocTopToSuperViewBottomSpacing: NSLayoutConstraint!
    @IBOutlet weak var tocHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tocLeadSpacing: NSLayoutConstraint!
    
    var tableOfContentsController: TableOfContentsController?
    var bookmarkController: UIViewController?
    var libraryController: UIViewController?
    var settingController: UIViewController?
    var searchController: SearchController?
    var welcomeController: UIViewController?
    let searchBar = SearchBar()
    
    var context: UnsafeMutablePointer<Void> = nil
    var article: Article?
    
    var navBarOriginalHeight: CGFloat = 0.0
    let navBarMinHeight: CGFloat = 10.0
    var previousScrollViewYOffset: CGFloat = 0.0
    
    var isShowingTableOfContents = false
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        webView.scrollView.delegate = nil
        
        navigationItem.titleView = searchBar
        searchBar.delegate = self
        ZimMultiReader.sharedInstance.delegate = self
        
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "webViewNotInjectJavascriptToAdjustPageLayout", options: .New, context: context)
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "webViewZoomScale", options: .New, context: context)
        configureButtonColor()
        showGetStartedAlert()
        showWelcome()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
//        showGetStarted()
    }
    
    deinit {
        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: "webViewNotInjectJavascriptToAdjustPageLayout")
        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: "webViewZoomScale")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == self.context else {return}
        webView.reload()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        tableOfContentsController = nil
        bookmarkController = nil
        libraryController = nil
        settingController = nil
        searchController = nil
        welcomeController = nil
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            configureUIElements(traitCollection.horizontalSizeClass)
        }
        configureTOCViewConstraints()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbeddedTOCController" {
            guard let destinationViewController = segue.destinationViewController as? TableOfContentsController else {return}
            tableOfContentsController = destinationViewController
            tableOfContentsController?.delegate = self
        }
    }
    
    // MARK: - First Time Launch Alert
    
    func showGetStartedAlert() {
        guard !Preference.hasShowGetStartedAlert else {return}
        let operation = GetStartedAlert(mainController: self)
        GlobalOperationQueue.sharedInstance.addOperation(operation)
        Preference.hasShowGetStartedAlert = true
    }
    
    // MARK: - Configure
    
    func configureUIElements(horizontalSizeClass: UIUserInterfaceSizeClass) {
        switch horizontalSizeClass {
        case .Regular:
            navigationController?.toolbarHidden = true
            toolbarItems?.removeAll()
            navigationItem.leftBarButtonItems = [navigateLeftButton, navigateRightButton, tableOfContentButton]
            navigationItem.rightBarButtonItems = [settingButton, libraryButton, bookmarkButton]
            searchBar.setShowsCancelButton(false, animated: true)
        case .Compact:
            if !searchBar.isFirstResponder() {navigationController?.toolbarHidden = false}
            if searchBar.isFirstResponder() {searchBar.setShowsCancelButton(true, animated: true)}
            navigationItem.leftBarButtonItems?.removeAll()
            navigationItem.rightBarButtonItems?.removeAll()
            let spaceButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            toolbarItems = [navigateLeftButton, spaceButton, navigateRightButton, spaceButton, tableOfContentButton, spaceButton, bookmarkButton, spaceButton, libraryButton, spaceButton, settingButton]            
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad && searchBar.isFirstResponder() {
                navigationItem.setRightBarButtonItem(cancelButton, animated: true)
            }
        case .Unspecified:
            break
        }
    }
    
    func configureButtonColor() {
        configureNavigationButtonTint()
        tableOfContentButton.tintColor = UIColor.grayColor()
        libraryButton.tintColor = UIColor.grayColor()
        settingButton.tintColor = UIColor.grayColor()
        UIBarButtonItem.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).tintColor = UIColor.themeColor
    }
    
    func configureNavigationButtonTint() {
        navigateLeftButton.tintColor = webView.canGoBack ? nil : UIColor.grayColor()
        navigateRightButton.tintColor = webView.canGoForward ? nil : UIColor.grayColor()
    }
    
    func configureBookmarkButton() {
        bookmarkButton.customImageView?.highlighted = article?.isBookmarked ?? false
    }
    
    func configureWebViewInsets() {
        let topInset: CGFloat = {
            guard let navigationBar = navigationController?.navigationBar else {return 44.0}
            return navigationBar.hidden ? 0.0 : navigationBar.frame.origin.y + navigationBar.frame.height
        }()
        let bottomInset: CGFloat = {
            guard let toolbar = navigationController?.toolbar else {return 0.0}
            return traitCollection.horizontalSizeClass == .Compact ? view.frame.height - toolbar.frame.origin.y : 0.0
        }()
        webView.scrollView.contentInset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0)
        webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, bottomInset, 0)
    }
    
    func configureSearchBarPlaceHolder() {
        if let title = article?.title {
            let placeHolder =  Utilities.truncatedPlaceHolderString(title, searchBar: searchBar)
            searchBar.placeholder = placeHolder
        } else {
            searchBar.placeholder = LocalizedStrings.search
        }
    }
    
    // MARK: - UIViewAnimations
    
    func animateInSearchResultController() {
        guard let searchController = searchController ?? UIStoryboard.search.instantiateInitialViewController() as? SearchController else {return}
        self.searchController = searchController
        guard !childViewControllers.contains(searchController) else {return}
        addChildViewController(searchController)
        searchController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchController.view)
        searchController.didMoveToParentViewController(self)
        searchController.view.alpha = 0.5
        searchController.view.transform = CGAffineTransformMakeScale(0.94, 0.94)
        
        let views = ["SearchController": searchController.view]
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[SearchController]|", options: .AlignAllCenterY, metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[SearchController]|", options: .AlignAllCenterX, metrics: nil, views: views))
        
        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
            searchController.view.alpha = 1.0
            searchController.view.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
    
    func animateOutSearchResultController() {
        guard let searchResultVC = searchController else {return}
        UIView.animateWithDuration(0.15, delay: 0.0, options: .BeginFromCurrentState, animations: { () -> Void in
            searchResultVC.view.alpha = 0.0
            searchResultVC.view.transform = CGAffineTransformMakeScale(0.96, 0.96)
            }) { (completed) -> Void in
                searchResultVC.view.removeFromSuperview()
                searchResultVC.removeFromParentViewController()
                if self.traitCollection.horizontalSizeClass == .Compact {
                    self.navigationController?.setToolbarHidden(false, animated: true)
                }
        }
    }
    
    // MARK: - Show/Hide Search
    
    func showSearch() {
        navigationController?.toolbarHidden = true
        animateInSearchResultController()
        searchBar.placeholder = LocalizedStrings.search
        if traitCollection.horizontalSizeClass == .Compact {
            searchBar.setShowsCancelButton(true, animated: true)
        }
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad && traitCollection.horizontalSizeClass == .Compact {
            navigationItem.setRightBarButtonItem(cancelButton, animated: true)
        }
        if isShowingTableOfContents && traitCollection.horizontalSizeClass == .Compact {
            animateOutTableOfContentsController()
        }
    }
    
    func hideSearch() {
        animateOutSearchResultController()
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = nil
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad && traitCollection.horizontalSizeClass == .Compact {
            navigationItem.setRightBarButtonItem(nil, animated: true)
        }
    }
    
    // MARK: - Show/Hide TOC
    
    func animateInTableOfContentsController() {
        isShowingTableOfContents = true
        tocVisiualEffectView.hidden = false
        dimView.hidden = false
        dimView.alpha = 0.0
        view.layoutIfNeeded()
        tableOfContentsController?.headings = getTableOfContents(webView)
        configureTOCViewConstraints()
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: .CurveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 0.5
        }) { (completed) in
            
        }
    }
    
    func animateOutTableOfContentsController() {
        isShowingTableOfContents = false
        view.layoutIfNeeded()
        configureTOCViewConstraints()
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseIn, animations: {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 0.0
        }) { (completed) in
            self.dimView.hidden = true
            self.tocVisiualEffectView.hidden = true
        }
    }
    
    func configureTOCViewConstraints() {
        switch traitCollection.horizontalSizeClass {
        case .Compact:
            let tocHeight: CGFloat = {
                guard let controller = tableOfContentsController else {return floor(view.frame.height * 0.4)}
                let tocContentHeight = controller.tableView.contentSize.height
                guard controller.headings.count != 0 else {return floor(view.frame.height * 0.4)}
                let toolBarHeight: CGFloat = traitCollection.horizontalSizeClass == .Regular ? 0.0 : (traitCollection.verticalSizeClass == .Compact ? 32.0 : 44.0)
                return min(tocContentHeight + toolBarHeight, floor(view.frame.height * 0.65))
            }()
            tocHeightConstraint.constant = tocHeight
            tocTopToSuperViewBottomSpacing.constant = isShowingTableOfContents ? tocHeight : 0.0
        case .Regular:
            tocLeadSpacing.constant = isShowingTableOfContents ? 0.0 : 270
            break
        default:
            break
        }
    }
    
    // MARK: - Show/Hide Welcome
    
    func showWelcome() {
        guard let controller = welcomeController ?? UIStoryboard.welcome.instantiateInitialViewController() else {return}
        welcomeController = controller
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller)
        view.addSubview(controller.view)
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: NSLayoutFormatOptions.AlignAllTop, metrics: nil, views: ["view": controller.view]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: NSLayoutFormatOptions.AlignAllLeft, metrics: nil, views: ["view": controller.view]))
        
        controller.didMoveToParentViewController(self)
    }
    
    func hideWelcome() {
        guard let controller = welcomeController else {return}
        controller.removeFromParentViewController()
        controller.view.removeFromSuperview()
    }
    
    // MARK: - Show/Hide Get Started
    
    func showGetStarted() {
        guard let controller = UIStoryboard.welcome.initViewController(GetStartedController.self) else {return}
        controller.modalPresentationStyle = .FormSheet
        presentViewController(controller, animated: true, completion: nil)
    }

    // MARK: - Buttons

    lazy var navigateLeftButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "LeftArrow", target: self, action: #selector(MainVC.navigateLeftButtonTapped))
    lazy var navigateRightButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "RightArrow", target: self, action: #selector(MainVC.navigateRightButtonTapped))
    lazy var tableOfContentButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "TableOfContent", target: self, action: #selector(MainVC.showTableOfContentButtonTapped))
    lazy var bookmarkButton: LPTBarButtonItem = LPTBarButtonItem(imageName: "Star", highlightedImageName: "StarHighlighted", delegate: self)
    lazy var libraryButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Library", target: self, action: #selector(MainVC.showLibraryButtonTapped))
    lazy var settingButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Setting", target: self, action: #selector(MainVC.showSettingButtonTapped))
    lazy var cancelButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(MainVC.cancelButtonTapped))
    
    // MARK: - Actions
    
    func navigateLeftButtonTapped() {
        webView.goBack()
    }
    
    func navigateRightButtonTapped() {
        webView.goForward()
    }
    
    func showTableOfContentButtonTapped(sender: UIBarButtonItem) {
        guard let _ = article else {return}
        if isShowingTableOfContents {
            animateOutTableOfContentsController()
        } else {
            animateInTableOfContentsController()
        }
    }
    
    func showLibraryButtonTapped() {
        guard let viewController = libraryController ?? UIStoryboard.library.instantiateInitialViewController() else {return}
        viewController.modalPresentationStyle = .FormSheet
        libraryController = viewController
        presentViewController(viewController, animated: true, completion: nil)
    }
    
    func showSettingButtonTapped() {
        guard let viewController = settingController ?? UIStoryboard.setting.instantiateInitialViewController() else {return}
        viewController.modalPresentationStyle = .FormSheet
        settingController = viewController
        presentViewController(viewController, animated: true, completion: nil)
    }
    
    func cancelButtonTapped() {
        hideSearch()
        navigationItem.setRightBarButtonItem(nil, animated: true)
    }
    
    @IBAction func dimViewTapGestureRecognizer(sender: UITapGestureRecognizer) {
        animateOutTableOfContentsController()
    }
}
