//
//  MainVC2.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class MainVC: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    var bookmarkVC: UIViewController?
    var libraryVC: UIViewController?
    var settingVC: UIViewController?
    var searchVC: SearchVC?
    let searchBar = SearchBar()
    
    var context: UnsafeMutablePointer<Void> = nil
    var article: Article?
    
    var navBarOriginalHeight: CGFloat = 0.0
    let navBarMinHeight: CGFloat = 10.0
    var previousScrollViewYOffset: CGFloat = 0.0
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        webView.scrollView.delegate = self
        
        navigationItem.titleView = searchBar
        searchBar.delegate = self
        
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "webViewNotInjectJavascriptToAdjustPageLayout", options: .New, context: context)
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "webViewZoomScale", options: .New, context: context)
        configureButtonColor()
        
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
        bookmarkVC = nil
        libraryVC = nil
        settingVC = nil
        searchVC = nil
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureUIElements(self.traitCollection)
    }
    
<<<<<<< HEAD
    // MARK: - Configure
=======
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        guard traitCollection.horizontalSizeClass == .Regular else {return}
        if searchController.active {
            let searchText = searchController.searchBar.text
            coordinator.animateAlongsideTransition({ (context) -> Void in
                self.searchController.active = false
                }, completion: { (completed) -> Void in
                    self.searchController.active = true
                    self.searchController.searchBar.text = searchText
            })
        }
    }
    
    lazy var searchController: UISearchController = {
        let searchResultsTBVC = UIStoryboard.main.instantiateViewControllerWithIdentifier("SearchResultTBVC") as! SearchResultTBVC
        let searchController = UISearchController(searchResultsController: searchResultsTBVC)
        searchController.searchResultsUpdater = searchResultsTBVC
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.delegate = self
        searchController.searchBar.autocapitalizationType = .None
        searchController.searchBar.searchBarStyle = .Minimal
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = true
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {searchController.modalPresentationStyle = .Popover}
        self.definesPresentationContext = true
        self.searchBarOriginalPlaceHolder = searchController.searchBar.placeholder
        return searchController
    }()
    
    func showGetStartedAlertIfNeeded() {
        guard !Preference.hasShowGetStartedAlert else {return}
        
        let showLibraryAction = UIAlertAction(title: NSLocalizedString("Open Book Library", comment: "Welcome Message"), style: .Default, handler: { (action) -> Void in
            self.showLibraryButtonTapped()
            Preference.hasShowGetStartedAlert = true
        })
        let importFromiTunesAction = UIAlertAction(title: NSLocalizedString("Import Book from iTunes", comment: "Welcome Message"), style: .Default, handler: { (action) -> Void in
            let action = UIAlertAction(title: NSLocalizedString("OK", comment: "Welcome Message"), style: .Default, handler: { (action) -> Void in
                Preference.hasShowGetStartedAlert = true
            })
            let importTitle = NSLocalizedString("Import from iTunes", comment: "Welcome Message")
            let importMessage = NSLocalizedString("Add zim files using iTunes File Sharing, kiwix will scan and recognize the files automatically.", comment: "Welcome Message")
            let alertController = UIAlertController(title: importTitle, message: importMessage, style: .Alert, actions: [action])
            self.navigationController?.presentViewController(alertController, animated: true, completion: nil)
        })
        
        let welcomeTitle = NSLocalizedString("Welcome to Kiwix", comment: "Welcome Message")
        let welcomeMessage = NSLocalizedString("Download or import a book to get started.", comment: "Welcome Message")
        let alertController = UIAlertController(title: welcomeTitle, message: welcomeMessage, style: .Alert, actions: [showLibraryAction, importFromiTunesAction])
        self.navigationController?.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Loading
    
    func load(url: NSURL?) {
        self.url = url
        if isShowingWelcome {configureChildViewController()}
        webViewVC?.load(url)
    }
    
    // MARK: - View Configuration
    var welcomeVC: UIViewController?
    var webViewVC: WebViewVC?
    var bookmarkVC: UIViewController?
    var libraryVC: UIViewController?
    var settingVC: UIViewController?
    
    var isShowingWelcome: Bool {
        guard let welcomeVC = welcomeVC else {return false}
        return childViewControllers.contains(welcomeVC)
    }
    
    func configureSearchBar() {
        navigationItem.titleView = searchController.searchBar
    }
>>>>>>> origin/master
    
    func configureUIElements(traitCollection: UITraitCollection) {
        switch traitCollection.horizontalSizeClass {
        case .Regular:
            navigationController?.toolbarHidden = true
            toolbarItems?.removeAll()
            navigationItem.leftBarButtonItems = [navigateLeftButton, navigateRightButton, blankButton]
            navigationItem.rightBarButtonItems = [settingButton, libraryButton, bookmarkButton]
        case .Compact:
            if !searchBar.isFirstResponder() {navigationController?.toolbarHidden = false}
            navigationItem.leftBarButtonItems?.removeAll()
            navigationItem.rightBarButtonItems?.removeAll()
            let spaceButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            toolbarItems = [navigateLeftButton, spaceButton, navigateRightButton, spaceButton, bookmarkButton, spaceButton, libraryButton, spaceButton, settingButton]
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad && searchBar.isFirstResponder() {
                navigationItem.setRightBarButtonItem(cancelButton, animated: true)
            }
        case .Unspecified:
            break
        }
        configureWebViewInsets()
        
    }
    
    func configureButtonColor() {
        configureNavigationButtonTint()
        libraryButton.tintColor = UIColor.grayColor()
        settingButton.tintColor = UIColor.grayColor()
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
    
    func configureSearchBarCancelButton() {
        
    }
    
    // MARK: - UIViewAnimations
    
    func animateInSearchResultController() {
        guard let searchVC = self.searchVC ?? UIStoryboard.main.initViewController(SearchVC.self) else {return}
        self.searchVC = searchVC
        guard !childViewControllers.contains(searchVC) else {return}
        addChildViewController(searchVC)
        searchVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchVC.view)
        searchVC.didMoveToParentViewController(self)
        searchVC.view.alpha = 0.5
        searchVC.view.transform = CGAffineTransformMakeScale(0.94, 0.94)
        
        let views = ["searchVC": searchVC.view]
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[searchVC]|", options: .AlignAllCenterY, metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[searchVC]|", options: .AlignAllCenterX, metrics: nil, views: views))
        
        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
            searchVC.view.alpha = 1.0
            searchVC.view.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
    
    func animateOutSearchResultController() {
        guard let searchResultVC = searchVC else {return}
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
    
    // MARK: - Show/hide Search
    
    func showSearch() {
        navigationController?.toolbarHidden = true
        animateInSearchResultController()
        searchBar.setShowsCancelButton(true, animated: true)
        searchBar.placeholder = LocalizedStrings.search
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad && traitCollection.horizontalSizeClass == .Compact {
            navigationItem.setRightBarButtonItem(cancelButton, animated: true)
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

    // MARK: - Buttons

    lazy var navigateLeftButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "LeftArrow", target: self, action: "navigateLeftButtonTapped")
    lazy var navigateRightButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "RightArrow", target: self, action: "navigateRightButtonTapped")
    lazy var bookmarkButton: LPTBarButtonItem = LPTBarButtonItem(imageName: "Star", highlightedImageName: "StarHighlighted", delegate: self)
    lazy var libraryButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Library", target: self, action: "showLibraryButtonTapped")
    lazy var settingButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Setting", target: self, action: "showSettingButtonTapped")
    lazy var blankButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "BlankImage", target: nil, action: nil)
    lazy var cancelButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelButtonTapped")
    
    // MARK: - Actions
    
    func navigateLeftButtonTapped() {
        webView.goBack()
    }
    
    func navigateRightButtonTapped() {
        webView.goForward()
    }
    
    func showLibraryButtonTapped() {
        guard let viewController = libraryVC ?? UIStoryboard.library.instantiateInitialViewController() else {return}
        //let viewController = UITabBarController()
        //viewController.viewControllers = [UITableViewController(), UITableViewController(), UITableViewController()]
        viewController.modalPresentationStyle = .FormSheet
        libraryVC = viewController
        presentViewController(viewController, animated: true, completion: nil)
    }
    
    func showSettingButtonTapped() {
        guard let viewController = settingVC ?? UIStoryboard.setting.instantiateInitialViewController() else {return}
        viewController.modalPresentationStyle = .FormSheet
        settingVC = viewController
        presentViewController(viewController, animated: true, completion: nil)
    }
    
    func cancelButtonTapped() {
        hideSearch()
        navigationItem.setRightBarButtonItem(nil, animated: true)
    }
    
}
