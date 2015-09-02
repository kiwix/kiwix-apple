//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 8/11/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UISearchBarDelegate, UISearchControllerDelegate, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    var currentArticle: Article?
    var placeHolderArticleTitle: String?
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    lazy var searchController: UISearchController = {
        let searchResultsTBVC = UIStoryboard(name: "Other", bundle: nil).instantiateViewControllerWithIdentifier("SearchResultTBVC") as! SearchResultTBVC
        let searchController = UISearchController(searchResultsController: searchResultsTBVC)
        searchController.searchResultsUpdater = searchResultsTBVC
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.delegate = self
        searchController.searchBar.autocapitalizationType = .None
        searchController.searchBar.delegate = self
        searchController.modalPresentationStyle = .Popover
        searchController.dimsBackgroundDuringPresentation = true
        self.definesPresentationContext = true
        return searchController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        configureToolBar()
        showOpenLibraryAlertIfNeeded()
        loadHomePage()
        
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "webViewScalePageToFitWidth", options: NSKeyValueObservingOptions.New, context: nil)
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "webViewZoomScale", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    deinit {
        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: "webViewScalePageToFitWidth")
        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: "webViewZoomScale")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "webViewScalePageToFitWidth" {
            webView.scalesPageToFit = Preference.webViewScalePageToFitWidth
            webView.reload()
        } else if keyPath == "webViewZoomScale" {
            configureWebViewFont()
        }
    }
    
    // MARK: - Configure views and buttons

    func configureView() {
        self.navigationItem.titleView = searchController.searchBar
        self.view.backgroundColor = UIColor.whiteColor()
        self.webView.scalesPageToFit = Preference.webViewScalePageToFitWidth
        self.webView.delegate = self
        configureWebViewFont()
    }
    
    func configureWebViewFont() {
        if !Preference.webViewScalePageToFitWidth {
            let zoomScale = Preference.webViewZoomScale
            let jString = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", zoomScale)
            webView.stringByEvaluatingJavaScriptFromString(jString)
        }
    }
    
    var goBackButton: LongPressAndTapBarButtonItem?
    var goForwardkButton: LongPressAndTapBarButtonItem?
    var bookmarkButton: LongPressAndTapBarButtonItem?
    
    func configureToolBar() {
        goBackButton = LongPressAndTapBarButtonItem(image: UIImage(named: "LeftArrow"), highlightedImage: nil, target: self, longPressAction: nil, tapAction: "goBackTap:")
        goForwardkButton = LongPressAndTapBarButtonItem(image: UIImage(named: "RightArrow"), highlightedImage: nil, target: self, longPressAction: nil, tapAction: "goForwardTap:")
        bookmarkButton = LongPressAndTapBarButtonItem(image: UIImage(named: "Bookmark"), highlightedImage: UIImage(named: "BookmarkHighlighted"), target: self, longPressAction: "handleBookmarkLongPress:", tapAction: "handleBookmarkTap:")
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            self.toolbarItems![0] = goBackButton!
            self.toolbarItems![1] = goForwardkButton!
            self.toolbarItems![3] = bookmarkButton!
            for item in self.toolbarItems! {
                item.tintColor = UIColor.grayColor()
                item.customView?.tintColor = UIColor.grayColor()
            }
        } else {
            self.navigationItem.leftBarButtonItems![0] = goBackButton!
            self.navigationItem.leftBarButtonItems![1] = goForwardkButton!
            self.navigationItem.rightBarButtonItems![2] = bookmarkButton!
            for item in self.navigationItem.leftBarButtonItems! + self.navigationItem.rightBarButtonItems! {
                item.tintColor = UIColor.grayColor()
                item.customView?.tintColor = UIColor.grayColor()
            }
        }
        self.navigationController?.navigationBar.setNeedsLayout()
    }
    
    func showOpenLibraryAlertIfNeeded() {
        if Preference.libraryLastRefreshTime == nil {
            let showLibraryAction = UIAlertAction(title: "Open Book Library", style: .Default, handler: { (action) -> Void in
                if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
                    self.performSegueWithIdentifier("ShowLibrary", sender: self)
                } else {
                    self.showLibrary(self.showLibraryButton)
                }
            })
            let importFromiTunesAction = UIAlertAction(title: "Import Book from iTunes", style: .Default, handler: { (action) -> Void in
                let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
                let alertController = Utilities.alertWith("Import from iTunes", message: "Add files to Kiwix using iTunes file sharing, Kiwix will detect and open all zim files automatically.", actions: [action])
                self.navigationController?.presentViewController(alertController, animated: true, completion: nil)
            })
            
            let alertController = Utilities.alertWith("Welcome to Kiwix", message: "Download or import a book to get started.", actions: [showLibraryAction, importFromiTunesAction])
            self.navigationController?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Loading System
    
    func loadBlankPage() {
        let request = NSURLRequest(URL: NSURL(string: "about:blank")!)
        webView.loadRequest(request)
    }
    
    func load(articlePath path: String) {
        let pathComponents = Utilities.articlePathComponents(path)
        let idString = pathComponents.idString
        let articleTitle = pathComponents.articleTitle
        load(articleTitled: articleTitle, inBookWithID: idString)
    }
    
    func load(articleTitled articleTitle: String, inBookWithID idString: String) {
        if let contentURLString = ZimMultiReader.sharedInstance.pageURLString(fromArticleTitle: articleTitle, bookIdString: idString) {
            self.load(articleContentURLString: contentURLString, inBookWithID: idString)
            currentArticle?.title = articleTitle
        } else {
            print("ZimMultiReader cannot get pageURLString from \(articleTitle) in book \(idString)")
        }
    }
    
    func load(mainPageOfBookWithID idString: String) {
        if let mainPageURLString = ZimMultiReader.sharedInstance.mainPageURLString(bookIdString: idString) {
            load(articleContentURLString: mainPageURLString, inBookWithID: idString)
        }
    }
    
    func loadRandomPage() {
        if let randomPage = ZimMultiReader.sharedInstance.randomPageURLString() {
            load(articleContentURLString: randomPage.contentURLString, inBookWithID: randomPage.idString)
        } else {
            loadBlankPage()
        }
    }
    
    func load(articleContentURLString contentURLString: String, inBookWithID idString: String) {
        let url = NSURL.kiwixURLWithZimFileIDString(idString, contentURLString: contentURLString)
        let request = NSURLRequest(URL: url)
        self.webView.loadRequest(request)
        if let book = ZimMultiReader.sharedInstance.allLocalBooksInDataBase[idString] {
            currentArticle = Article.article(withUrlString: contentURLString, book: book, context: managedObjectContext)
        }
    }
    
    func loadHomePage() {
        if let webViewHomePage = Preference.webViewHomePage {
            switch webViewHomePage {
            case WebViewHomePage.Blank:
                loadBlankPage()
            case WebViewHomePage.Random:
                loadRandomPage()
                break
            case WebViewHomePage.MainPage:
                if let idString = Preference.webViewHomePageBookID {
                    load(mainPageOfBookWithID: idString)
                }
                break
            }
        } else {
            loadBlankPage()
        }
    }
    
    // MARK: - UIWebViewDelegate 
    
    func webViewDidFinishLoad(webView: UIWebView) {
        updateToolbarButtonTintColor()
        if webView.request?.URL?.absoluteString == "about:blank" {currentArticle = nil}
        if webView.request?.URL?.scheme != "kiwix" {currentArticle = nil}
        if var path = webView.request?.URL?.path, let idString = webView.request?.URL?.host {
            if path[path.startIndex] == "/" {
                path = path.substringFromIndex(path.startIndex.advancedBy(1))
            }
            if let book = ZimMultiReader.sharedInstance.allLocalBooksInDataBase[idString] {
                currentArticle = Article.article(withUrlString: path, book: book, context: self.managedObjectContext)
                // If article dont already get a title from load methods (mainly main page), set the HTML doc title as article title
                if currentArticle?.title == nil {
                    currentArticle?.title = webView.stringByEvaluatingJavaScriptFromString("document.title")
                }
            }
        }
        
        if Preference.webViewZoomScale != 100.0 {
            configureWebViewFont()
        }
        updateToolbarButtonTintColor()
        if webView.request?.URL?.absoluteString != "about:blank" {
            searchController.searchBar.placeholder = Utilities.truncatedPlaceHolderString(webView.stringByEvaluatingJavaScriptFromString("document.title"), searchBar: searchController.searchBar)
        }
    }
    
    // MARK: - UISearchBarDelegate
    
    func willPresentSearchController(searchController: UISearchController) {
        self.dismissViewControllerAnimated(true, completion: nil)
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            self.navigationController?.setToolbarHidden(true, animated: false)
        } else if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            searchController.preferredContentSize = CGSizeMake(searchController.searchBar.frame.width, self.view.frame.size.height * 0.75)
            searchController.dimsBackgroundDuringPresentation = false
        }
        placeHolderArticleTitle = searchController.searchBar.placeholder
        searchController.searchBar.placeholder = "Search"
    }
    
    func willDismissSearchController(searchController: UISearchController) {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            self.navigationController?.setToolbarHidden(false, animated: false)
        }
        searchController.searchBar.placeholder = placeHolderArticleTitle
    }
    
    // MARK: - Actions
    func handleBookmarkLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            if let currentArticle = currentArticle {
                if currentArticle.isBookmarked == true {
                    currentArticle.isBookmarked = false
                    bookmarkButton?.customView?.tintColor = UIColor.grayColor()
                    let hud = HUDView(superView: self.view, message: "Removed")
                    hud.add()
                } else {
                    currentArticle.isBookmarked = true
                    bookmarkButton?.customView?.tintColor = UIColor.redColor().colorWithAlphaComponent(0.75)
                    let hud = HUDView(superView: self.view, message: "Added")
                    hud.add()
                }
            }
        }
    }
    
    func handleBookmarkTap(gestureRecognizer: UITapGestureRecognizer) {
        self.dismissViewControllerAnimated(true, completion: nil)
        let controller = UIStoryboard(name: "Other", bundle: nil).instantiateViewControllerWithIdentifier("BookmarkNavController")
        controller.modalPresentationStyle = .Popover
        controller.preferredContentSize = CGSizeMake(400, 500)
        let popoverPresentationController = controller.popoverPresentationController
        popoverPresentationController?.barButtonItem = bookmarkButton
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    func goBackTap(gestureRecognizer: UITapGestureRecognizer) {
        webView.goBack()
    }
    
    func goForwardTap(gestureRecognizer: UITapGestureRecognizer) {
        webView.goForward()
    }
    
    func updateToolbarButtonTintColor() {
        goBackButton?.customView?.tintColor = webView.canGoBack ? nil : UIColor.grayColor()
        goForwardkButton?.customView?.tintColor = webView.canGoForward ? nil : UIColor.grayColor()
        if let currentAricle = currentArticle {
            bookmarkButton?.customView?.tintColor = currentAricle.isBookmarked == true ? UIColor.redColor().colorWithAlphaComponent(0.75) : UIColor.grayColor()
        } else {
            bookmarkButton?.customView?.tintColor = UIColor.grayColor()
        }
    }
    
    @IBAction func showLibrary(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
        let controller = UIStoryboard(name: "Library", bundle: nil).instantiateViewControllerWithIdentifier("LibraryNavController")
        controller.modalPresentationStyle = .Popover
        controller.preferredContentSize = CGSizeMake(400, 500)
        let popoverPresentationController = controller.popoverPresentationController
        popoverPresentationController?.barButtonItem = sender
        self.presentViewController(controller, animated: true, completion: nil)
    }
    @IBOutlet weak var showLibraryButton: UIBarButtonItem!
    
    @IBAction func showSetting(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
        let controller = UIStoryboard(name: "Setting", bundle: nil).instantiateViewControllerWithIdentifier("SettingNavController")
        controller.modalPresentationStyle = .Popover
        controller.preferredContentSize = CGSizeMake(400, 500)
        let popoverPresentationController = controller.popoverPresentationController
        popoverPresentationController?.barButtonItem = sender
        self.presentViewController(controller, animated: true, completion: nil)
    }
}
