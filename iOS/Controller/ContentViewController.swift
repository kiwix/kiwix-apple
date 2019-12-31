//
//  ContentViewController.swift
//  iOS
//
//  Created by Chris Li on 12/8/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift

@available(iOS 13.0, *)
class ContentViewController: UIViewController, UISearchControllerDelegate, WebViewControllerDelegate,
    OutlineControllerDelegate, BookmarkControllerDelegate {
    private let sideBarButton = Button(imageSystemName: "sidebar.left")
    private let chevronLeftButton = Button(imageSystemName: "chevron.left")
    private let chevronRightButton = Button(imageSystemName: "chevron.right")
    private let outlineButton = Button(imageSystemName: "list.bullet")
    private let bookmarkButton = BookmarkButton()
    private let bookmarkToggleButton = BookmarkToggleButton()
    private let libraryButton = Button(imageSystemName: "folder")
    private let settingButton = Button(imageSystemName: "gear")
    private let bookmarkLongPressGestureRecognizer = UILongPressGestureRecognizer()
     
    let searchController: UISearchController
    private let searchResultsController: SearchResultsController
    private lazy var searchCancelButton = UIBarButtonItem(
        barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearch))
    private var webViewControllers: [WebKitWebController] = []
    var currentWebViewController: WebKitWebController? { return webViewControllers.first }
    private(set) lazy var welcomeController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeController") as! WelcomeController
    
    init() {
        self.searchResultsController = SearchResultsController()
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        
        super.init(nibName: nil, bundle: nil)
        
        sideBarButton.addTarget(self, action: #selector(toggleSideBar), for: .touchUpInside)
        chevronLeftButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        chevronRightButton.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        outlineButton.addTarget(self, action: #selector(openOutline), for: .touchUpInside)
        bookmarkButton.addTarget(self, action: #selector(openBookmark), for: .touchUpInside)
        bookmarkToggleButton.addTarget(self, action: #selector(toggleBookmark), for: .touchUpInside)
        libraryButton.addTarget(self, action: #selector(openLibrary), for: .touchUpInside)
        settingButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        
        bookmarkButton.addGestureRecognizer(bookmarkLongPressGestureRecognizer)
        bookmarkLongPressGestureRecognizer.addTarget(self, action: #selector(toggleBookmark))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        navigationItem.titleView = searchController.searchBar
        definesPresentationContext = true
        view.backgroundColor = .systemBackground
        searchController.delegate = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.automaticallyShowsCancelButton = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.showsSearchResultsController = true
        searchController.searchResultsUpdater = searchResultsController
        
        configureToolbar()
        createNewTab()
        setChildControllerIfNeeded(welcomeController)
    }
    
    func load(url: URL) {
        setChildControllerIfNeeded(currentWebViewController)
        currentWebViewController?.load(url: url)
    }
    
    // MARK: - View and Controller Management
    
    func configureToolbar() {
        if splitViewController?.isCollapsed == true {
            let group = ButtonGroupView(buttons: [
                chevronLeftButton, chevronRightButton, outlineButton, bookmarkButton, libraryButton, settingButton,
            ])
            toolbarItems = [UIBarButtonItem(customView: group)]
        } else {
            let left = ButtonGroupView(buttons: [sideBarButton, chevronLeftButton, chevronRightButton], spacing: 10)
            let right = ButtonGroupView(buttons: [bookmarkToggleButton, libraryButton, settingButton], spacing: 10)
            toolbarItems = [
                UIBarButtonItem(customView: left),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(customView: right),
            ]
        }
    }
    
    private func createNewTab() {
        let controller = WebKitWebController()
        webViewControllers.append(controller)
        switchToTab(controller: controller)
    }
    
    private func switchToTab(controller: WebViewController) {
        var controller = controller
        controller.delegate = self
        
        chevronLeftButton.isEnabled = controller.canGoBack
        chevronRightButton.isEnabled = controller.canGoForward
        outlineButton.isEnabled = controller.currentURL != nil
        bookmarkToggleButton.isEnabled = controller.currentURL != nil
    }
    
    private func setView(_ subView: UIView?) {
        view.subviews.forEach({ $0.removeFromSuperview() })
        if let subView = subView {
            subView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subView)
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: subView.topAnchor),
                view.leftAnchor.constraint(equalTo: subView.leftAnchor),
                view.bottomAnchor.constraint(equalTo: subView.bottomAnchor),
                view.rightAnchor.constraint(equalTo: subView.rightAnchor),
            ])
        }
    }
    
    private func setChildControllerIfNeeded(_ newChild: UIViewController?) {
        if let newChild = newChild, children.contains(newChild) {return}
        
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        if let child = newChild {
            child.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(child.view)
            NSLayoutConstraint.activate([
                view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: child.view.topAnchor),
                view.leftAnchor.constraint(equalTo: child.view.leftAnchor),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: child.view.bottomAnchor),
                view.rightAnchor.constraint(equalTo: child.view.rightAnchor),
            ])
            addChild(child)
            child.didMove(toParent: self)
        }
    }
    
    private func presentBookmarkHUDController(isBookmarked: Bool) {
        let controller = HUDController()
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = controller
        controller.direction = isBookmarked ? .down : .up
        controller.imageView.image = isBookmarked ? #imageLiteral(resourceName: "StarAdd") : #imageLiteral(resourceName: "StarRemove")
        controller.label.text = isBookmarked ?
            NSLocalizedString("Added", comment: "Bookmark HUD") :
            NSLocalizedString("Removed", comment: "Bookmark HUD")
        
        splitViewController?.present(controller, animated: true, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                controller.dismiss(animated: true, completion: nil)
            })
            self.bookmarkButton.isBookmarked = isBookmarked
            self.bookmarkToggleButton.isBookmarked = isBookmarked
//            self.updateBookmarkWidgetData()
        })
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        navigationItem.setRightBarButton(searchCancelButton, animated: true)
        navigationController?.isToolbarHidden = true
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        navigationItem.setRightBarButton(nil, animated: true)
        navigationController?.isToolbarHidden = false
    }
    
    // MARK: WebViewControllerDelegate
    
    func webViewDidTapOnGeoLocation(controller: WebViewController, url: URL) {
        
    }
    
    func webViewDidFinishLoading(controller: WebViewController) {
        // update buttons isEnabled
        chevronLeftButton.isEnabled = controller.canGoBack
        chevronRightButton.isEnabled = controller.canGoForward
        outlineButton.isEnabled = controller.currentURL != nil
        bookmarkToggleButton.isEnabled = controller.currentURL != nil
        
        // update bookmark button
        if let url = controller.currentURL, let zimFileID = url.host {
            do {
                let database = try Realm(configuration: Realm.defaultConfig)
                let predicate = NSPredicate(format: "zimFile.id == %@ AND path == %@", zimFileID, url.path)
                let resultCount = database.objects(Bookmark.self).filter(predicate).count
                bookmarkButton.isBookmarked = resultCount > 0
                bookmarkToggleButton.isBookmarked = resultCount > 0
            } catch {}
        } else {
            bookmarkButton.isBookmarked = false
            bookmarkToggleButton.isBookmarked = false
        }
        
        // if outline view is visible, update outline items
        if let rootSplitController = splitViewController as? RootSplitController,
            !rootSplitController.isCollapsed,
            rootSplitController.displayMode != .primaryHidden {
            let selectedNavController = rootSplitController.sideBarViewController.selectedViewController
            let selectedController = (selectedNavController as? UINavigationController)?.topViewController
            if let outlineController = selectedController as? OutlineController {
                outlineController.updateContent()
            }
        }
    }
    
    // MARK: OutlineControllerDelegate
    
    func didTapOutlineItem(index: Int, item: TableOfContentItem) {
        currentWebViewController?.scrollToTableOfContentItem(index: index)
    }
    
    // MARK: BookmarkControllerDelegate
    
    func didTapBookmark(url: URL) {
        load(url: url)
    }
    
    func didDeleteBookmark(url: URL) {
        
    }
    
    // MARK: - Actions
    
    @objc func cancelSearch() {
        /*
         We have to dismiss the `searchController` first, so that the `isBeingDismissed` property is correct on the
         `searchResultsController`. We rely on `isBeingDismissed` to understand if the search text is cleared because
         of user tapped cancel button or manually cleared the serach field.
         */
        searchController.dismiss(animated: true)
        searchController.isActive = false
    }
    
    @objc func toggleSideBar() {
        UIView.animate(withDuration: 0.2) {
            let current = self.splitViewController?.preferredDisplayMode
            self.splitViewController?.preferredDisplayMode = current == .primaryHidden ? .allVisible : .primaryHidden
        }
    }
    
    @objc func goBack() {
        currentWebViewController?.goBack()
    }
    
    @objc func goForward() {
        currentWebViewController?.goForward()
    }
    
    @objc func openOutline() {
        let outlineController = OutlineController()
        let navigationController = UINavigationController(rootViewController: outlineController)
        outlineController.delegate = self
        splitViewController?.present(navigationController, animated: true)
    }
    
    @objc func openBookmark() {
        let controller = BookmarkController()
        let navigationController = UINavigationController(rootViewController: controller)
        controller.delegate = self
        splitViewController?.present(navigationController, animated: true)
    }
    
    @objc func toggleBookmark(sender: Any) {
        if let recognizer = sender as? UILongPressGestureRecognizer, recognizer.state != .began {
            return
        }
        
        guard let webKitWebController = currentWebViewController,
            let url = webKitWebController.currentURL,
            let zimFileID = url.host else {return}
        
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "zimFile.id == %@ AND path == %@", zimFileID, url.path)
            if let bookmark = database.objects(Bookmark.self).filter(predicate).first {
                presentBookmarkHUDController(isBookmarked: false)
                try database.write {
                    database.delete(bookmark)
                }
            } else {
                guard let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else {return}
                let bookmark = Bookmark()
                bookmark.zimFile = zimFile
                bookmark.path = url.path
                bookmark.title = webKitWebController.currentTitle ?? ""
                bookmark.date = Date()
                
                let group = DispatchGroup()
                group.enter()
                webKitWebController.extractSnippet(completion: { (snippet) in
                    bookmark.snippet = snippet
                    group.leave()
                })
                if zimFile.hasPicture {
                    group.enter()
                    webKitWebController.extractImageURLs(completion: { (urls) in
                        bookmark.thumbImagePath = urls.first?.path
                        group.leave()
                    })
                }
                group.notify(queue: .main, execute: {
                    self.presentBookmarkHUDController(isBookmarked: true)
                    do {
                        let database = try Realm(configuration: Realm.defaultConfig)
                        try database.write {
                            database.add(bookmark)
                        }
                    } catch {}
                })
            }
        } catch {return}
    }
    
    @objc func openLibrary() {
        guard let splitController = splitViewController as? RootSplitController else {return}
        splitController.present(splitController.libraryController, animated: true)
    }
    
    @objc func openSettings() {
        splitViewController?.present(SettingNavigationController(), animated: true)
    }
    
    @objc func openTabsView() {
        splitViewController?.present(TabsController(), animated: true)
    }
}

// MARK: - BarButton

private class ButtonGroupView: UIStackView {
    convenience init(buttons: [UIButton], spacing: CGFloat? = nil) {
        self.init(arrangedSubviews: buttons)
        distribution = .equalCentering
        if let spacing = spacing {
            self.spacing = spacing
        }
    }
}

@available(iOS 13.0, *)
private class Button: UIButton {
    fileprivate let configuration = UIImage.SymbolConfiguration(scale: .large)
    convenience init(imageSystemName: String) {
        self.init(type: .system)
        setImage(UIImage(systemName: imageSystemName, withConfiguration: configuration), for: .normal)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 36, height: 44)
    }
}

@available(iOS 13.0, *)
private class BookmarkButton: Button {
    var isBookmarked: Bool = false { didSet { setNeedsLayout() } }
    override var state: UIControl.State{ get { isBookmarked ? [.bookmarked, super.state] : super.state } }
    
    convenience init() {
        self.init(imageSystemName: "star")
        let filledImage = UIImage(systemName: "star.fill", withConfiguration: configuration)
        setImage(filledImage, for: .bookmarked)
        setImage(filledImage, for: [.bookmarked, .highlighted])
    }
}

@available(iOS 13.0, *)
private class BookmarkToggleButton: Button {
    var isBookmarked: Bool = false { didSet { setNeedsLayout() } }
    override var state: UIControl.State{ get { isBookmarked ? [.bookmarked, super.state] : super.state } }
    
    convenience init() {
        self.init(imageSystemName: "star")
        let filledImage = UIImage(systemName: "star.slash.fill", withConfiguration: configuration)
        setImage(filledImage, for: .bookmarked)
        setImage(filledImage, for: [.bookmarked, .highlighted])
    }
}

private extension UIControl.State {
    static let bookmarked = UIControl.State(rawValue: 1 << 16)
}
