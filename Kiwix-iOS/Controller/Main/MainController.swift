
//
//  MainController.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import ProcedureKit
import SafariServices

class MainController: UIViewController {
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var tocVisiualEffectView: UIVisualEffectView!
    @IBOutlet weak var tocTopToSuperViewBottomSpacing: NSLayoutConstraint!
    @IBOutlet weak var tocHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tocLeadSpacing: NSLayoutConstraint!
    
    // MARK: - Properties
    
    let activityType = "org.kiwix.kiwix.article-view"
    fileprivate var webViewInitialURL: URL?
    fileprivate(set) var context: UnsafeMutableRawPointer? = nil
    var isShowingTableOfContents = false
    fileprivate(set) var tableOfContentsController: TableOfContentsController?
    let searchBar = SearchBar()

    var article: Article? {
        willSet(newArticle) {
            article?.removeObserver(self, forKeyPath: "isBookmarked")
            newArticle?.addObserver(self, forKeyPath: "isBookmarked", options: .new, context: context)
        }
        didSet {
            searchBar.articleTitle = article?.title
            configureBookmarkButton()
            configureUserActivity()
        }
    }
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        ZimMultiReader.shared.delegate = self
        navigationItem.titleView = searchBar
        
        UserDefaults.standard.addObserver(self, forKeyPath: "webViewZoomScale", options: .new, context: context)
        
        configureButtonColor()
        showGetStartedAlert()
        showWelcome()
    }
    
    deinit {
        article?.removeObserver(self, forKeyPath: "isBookmarked")
        UserDefaults.standard.removeObserver(self, forKeyPath: "webViewZoomScale")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == self.context, let keyPath = keyPath else {return}
        switch keyPath {
        case "webViewZoomScale":
            webView.reload()
        case "isBookmarked":
            configureBookmarkButton()
        default:
            return
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            configureUIElements(traitCollection.horizontalSizeClass)
        }
        configureTOCViewConstraints()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbeddedTOCController" {
            guard let destinationViewController = segue.destination as? TableOfContentsController else {return}
            tableOfContentsController = destinationViewController
            tableOfContentsController?.delegate = self
        }
    }
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        defer { super.updateUserActivityState(activity) }
        guard let article = article, let url = article.url?.absoluteString else {return}
        activity.title = article.title
        activity.addUserInfoEntries(from: ["ArticleURL": url])
        super.updateUserActivityState(activity)
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        guard activity.activityType == activityType,
            let urlString = activity.userInfo?["ArticleURL"] as? String,
            let url = URL(string: urlString),
            let host = url.host else {return}
//        if ZimMultiReader.shared.readers.keys.contains(host) {
//            let operation = ArticleLoadOperation(url: url)
//            GlobalQueue.shared.add(load: operation)
//        } else {
//            let operation = CannotFinishHandoffAlert(context: self)
//            GlobalQueue.shared.addOperation(operation)
//        }
    }
    
    // MARK: - Configure
    
    func configureUIElements(_ horizontalSizeClass: UIUserInterfaceSizeClass) {
        switch horizontalSizeClass {
        case .regular:
            navigationController?.isToolbarHidden = true
            toolbarItems?.removeAll()
            navigationItem.leftBarButtonItems = [navigateLeftButton, navigateRightButton, tableOfContentButton]
            navigationItem.rightBarButtonItems = [settingButton, libraryButton, bookmarkButton]
            searchBar.setShowsCancelButton(false, animated: true)
        case .compact:
            if !searchBar.isFirstResponder {navigationController?.isToolbarHidden = false}
            if searchBar.isFirstResponder {searchBar.setShowsCancelButton(true, animated: true)}
            navigationItem.leftBarButtonItems?.removeAll()
            navigationItem.rightBarButtonItems?.removeAll()
            let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolbarItems = [navigateLeftButton, spaceButton, navigateRightButton, spaceButton, tableOfContentButton, spaceButton, bookmarkButton, spaceButton, libraryButton, spaceButton, settingButton]            
            if UIDevice.current.userInterfaceIdiom == .pad && searchBar.isFirstResponder {
                navigationItem.setRightBarButton(cancelButton, animated: true)
            }
        case .unspecified:
            break
        }
    }
    
    func configureButtonColor() {
        configureNavigationButtonTint()
        tableOfContentButton.tintColor = UIColor.gray
        libraryButton.tintColor = UIColor.gray
        settingButton.tintColor = UIColor.gray
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.themeColor
    }
    
    func configureNavigationButtonTint() {
        navigateLeftButton.tintColor = webView.canGoBack ? nil : UIColor.gray
        navigateRightButton.tintColor = webView.canGoForward ? nil : UIColor.gray
    }
    
    func configureBookmarkButton() {
        bookmarkButton.customImageView?.isHighlighted = article?.isBookmarked ?? false
    }
    
    func configureTableOfContents() {
        guard isShowingTableOfContents else {return}
        guard tableOfContentsController?.articleURL != article?.url else {return}
        tableOfContentsController?.headings = JS.getTableOfContents(webView)
    }
    
    func configureUserActivity() {
        userActivity = userActivity ?? NSUserActivity(activityType: activityType)
        guard let title = article?.title, let url = article?.url?.absoluteString else {return}
        userActivity?.title = title
        userActivity?.userInfo = ["ArticleURL": url]
        userActivity?.isEligibleForHandoff = true
        userActivity?.supportsContinuationStreams = true
        userActivity?.becomeCurrent()
    }

    // MARK: - Buttons

    lazy var navigateLeftButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "LeftArrow", target: self, action: #selector(MainController.navigateLeftButtonTapped))
    lazy var navigateRightButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "RightArrow", target: self, action: #selector(MainController.navigateRightButtonTapped))
    lazy var tableOfContentButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "TableOfContent", target: self, action: #selector(MainController.tableOfContentButtonTapped))
    lazy var bookmarkButton: LPTBarButtonItem = LPTBarButtonItem(imageName: "Star", highlightedImageName: "StarHighlighted", delegate: self)
    lazy var libraryButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Library", target: self, action: #selector(MainController.showLibraryButtonTapped))
    lazy var settingButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Setting", target: self, action: #selector(MainController.showSettingButtonTapped))
    lazy var cancelButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(MainController.cancelButtonTapped))
    
    // MARK: - Actions
    
    func navigateLeftButtonTapped() {
        webView.goBack()
    }
    
    func navigateRightButtonTapped() {
        webView.goForward()
    }
    
    func tableOfContentButtonTapped(_ sender: UIBarButtonItem) {
        guard let _ = article else {return}
        isShowingTableOfContents ? hideTableOfContentsController() : showTableOfContentsController()
    }
    
    func showLibraryButtonTapped() {
        let controller = Controllers.library
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    func showSettingButtonTapped() {
        let controller = Controllers.setting
        controller.modalPresentationStyle = .formSheet
        present(controller, animated: true, completion: nil)
    }
    
    func cancelButtonTapped() {
        hideSearch(animated: true)
        navigationItem.setRightBarButton(nil, animated: true)
    }
    
    @IBAction func dimViewTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        hideTableOfContentsController()
    }
}
