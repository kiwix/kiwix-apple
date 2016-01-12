//
//  MainVC.swift
//  Kiwix
//
//  Created by Chris on 12/28/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit
import WebKit

class MainVC: UIViewController {

    var searchBarOriginalPlaceHolder: String? {
        didSet {
            guard let string = searchBarOriginalPlaceHolder else {return}
            searchBarOriginalPlaceHolder = string + " "
        }
    }
    var article: Article?
    var url: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchBar()
        configureChildViewController()
        configureButtonColor()
        showGetStartedAlertIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        bookmarkVC = nil
        libraryVC = nil
        settingVC = nil
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureUIElements(self.traitCollection)
    }
    
    lazy var searchController: UISearchController = {
        let searchResultsTBVC = UIStoryboard.main.instantiateViewControllerWithIdentifier("SearchResultTBVC") as! SearchResultTBVC
        let searchController = UISearchController(searchResultsController: searchResultsTBVC)
        searchController.searchResultsUpdater = searchResultsTBVC
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.delegate = self
        searchController.searchBar.autocapitalizationType = .None
        searchController.searchBar.searchBarStyle = .Minimal
        //searchController.searchBar.delegate = self
        searchController.modalPresentationStyle = .Popover
        searchController.dimsBackgroundDuringPresentation = true
        self.definesPresentationContext = true
        self.searchBarOriginalPlaceHolder = searchController.searchBar.placeholder
        return searchController
    }()
    
    func showGetStartedAlertIfNeeded() {
        guard !Preference.hasShowGetStartedAlert else {return}
        
        let showLibraryAction = UIAlertAction(title: NSLocalizedString("Open Book Library", comment: "Welcome Message"), style: .Default, handler: { (action) -> Void in
            self.showLibraryButtonTapped()
        })
        let importFromiTunesAction = UIAlertAction(title: NSLocalizedString("Import Book from iTunes", comment: "Welcome Message"), style: .Default, handler: { (action) -> Void in
            let action = UIAlertAction(title: NSLocalizedString("OK", comment: "Welcome Message"), style: .Default, handler: nil)
            let importTitle = NSLocalizedString("Import from iTunes", comment: "Welcome Message")
            let importMessage = NSLocalizedString("Import Message", comment: "Welcome Message")
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
    
    func configureUIElements(traitCollection: UITraitCollection) {
        switch traitCollection.horizontalSizeClass {
        case .Regular:
            navigationController?.toolbarHidden = true
            toolbarItems?.removeAll()
            navigationItem.leftBarButtonItems = [navigateLeftButton, navigateRightButton, blankButton]
            navigationItem.rightBarButtonItems = [settingButton, libraryButton, bookmarkButton]
        case .Compact:
            navigationController?.toolbarHidden = false
            navigationItem.leftBarButtonItems?.removeAll()
            navigationItem.rightBarButtonItems?.removeAll()
            let spaceButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            toolbarItems = [navigateLeftButton, spaceButton, navigateRightButton, spaceButton, bookmarkButton, spaceButton, libraryButton, spaceButton, settingButton]
        case .Unspecified:
            break
        }
    }
    
    func configureButtonColor() {
        navigateLeftButton.tintColor = UIColor.grayColor()
        navigateRightButton.tintColor = UIColor.grayColor()
        libraryButton.tintColor = UIColor.grayColor()
        settingButton.tintColor = UIColor.grayColor()
    }
    
    func configureChildViewController() {
        if let _ = url {
            guard let webViewVC = self.webViewVC ?? UIStoryboard.main.instantiateViewControllerWithIdentifier("WebViewVC") as? WebViewVC else {return}
            self.webViewVC = webViewVC
            replaceChildViewController(welcomeVC, withChildViewController: webViewVC)
            webViewVC.delegate = self
        } else {
            let welcomeVC = self.welcomeVC ?? UIStoryboard.main.instantiateViewControllerWithIdentifier("Welcome")
            self.welcomeVC = welcomeVC
            replaceChildViewController(webViewVC, withChildViewController: welcomeVC)
        }
    }
    
    func replaceChildViewController(oldVC: UIViewController?, withChildViewController newVC: UIViewController) {
        if let oldVC = oldVC {
            oldVC.view.removeFromSuperview()
            oldVC.removeFromParentViewController()
        }
        
        if !childViewControllers.contains(newVC) {
            addChildViewController(newVC)
            view.addSubview(newVC.view)
            newVC.didMoveToParentViewController(self)
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
        webViewVC?.goBack()
    }
    
    func navigateRightButtonTapped() {
        webViewVC?.goForward()
    }
    
    func showLibraryButtonTapped() {
        guard let viewController = libraryVC ?? UIStoryboard.library.instantiateInitialViewController() else {return}
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
        searchController.active = false
    }
}
