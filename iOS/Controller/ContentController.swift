//
//  ContentController.swift
//  Kiwix
//
//  Created by Chris Li on 12/8/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift

class ContentController: UIViewController, UISearchControllerDelegate, UIAdaptivePresentationControllerDelegate,
    WebViewControllerDelegate, OutlineControllerDelegate, BookmarkControllerDelegate {
    private let sideBarButton = Button(imageName: "sidebar.left")
    private let chevronLeftButton = Button(imageName: "chevron.left")
    private let chevronRightButton = Button(imageName: "chevron.right")
    private let outlineButton = Button(imageName: "list.bullet")
    private let bookmarkButton = BookmarkButton(imageName: "star", bookmarkedImageName: "star.fill")
    private let bookmarkToggleButton = BookmarkButton(imageName: "star.circle.fill", bookmarkedImageName: "star.circle")
    private let libraryButton = Button(imageName: "folder")
    private let settingButton = Button(imageName: "gear")
    private let bookmarkLongPressGestureRecognizer = UILongPressGestureRecognizer()
    
    let searchController: UISearchController
    private let searchResultsController: SearchResultsController
    private lazy var searchCancelButton = UIBarButtonItem(
        barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearch))
    let webViewController = WebViewController()
    private let welcomeController = UIStoryboard(name: "Main", bundle: nil)
        .instantiateViewController(withIdentifier: "WelcomeController") as! WelcomeController
    private var cachedLibraryController: LibraryController?
    
    // MARK:- Initialization
    
    init() {
        self.searchResultsController = SearchResultsController()
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        
        super.init(nibName: nil, bundle: nil)
        
        // button tap
        sideBarButton.addTarget(self, action: #selector(toggleSideBar), for: .touchUpInside)
        chevronLeftButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        chevronRightButton.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        outlineButton.addTarget(self, action: #selector(openOutline), for: .touchUpInside)
        bookmarkButton.addTarget(self, action: #selector(openBookmark), for: .touchUpInside)
        bookmarkToggleButton.addTarget(self, action: #selector(toggleBookmark), for: .touchUpInside)
        libraryButton.addTarget(self, action: #selector(openLibrary), for: .touchUpInside)
        settingButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        
        // button long press
        bookmarkButton.addGestureRecognizer(bookmarkLongPressGestureRecognizer)
        bookmarkLongPressGestureRecognizer.addTarget(self, action: #selector(toggleBookmark))
        
        // view background
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        // search controller
        searchController.delegate = self
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = searchResultsController
        if #available(iOS 13.0, *) {
            searchController.automaticallyShowsCancelButton = false
            searchController.showsSearchResultsController = true
        } else {
            searchController.searchBar.searchBarStyle = .minimal
        }
        
        // misc
        definesPresentationContext = true
        webViewController.delegate = self
        navigationItem.hidesBackButton = true
        navigationItem.titleView = searchController.searchBar
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateToolBarButtonEnabled()
        
        // show welcome controller
        setChildControllerIfNeeded(welcomeController)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func load(url: URL) {
        setChildControllerIfNeeded(webViewController)
        webViewController.load(url: url)
    }
    
    // MARK: - View and Controller Management
    
    func configureToolbar(isGrouped: Bool) {
        if isGrouped {
            let left = ButtonGroupView(buttons: [sideBarButton, chevronLeftButton, chevronRightButton], spacing: 10)
            let right = ButtonGroupView(buttons: [bookmarkToggleButton, libraryButton, settingButton], spacing: 10)
            toolbarItems = [
                UIBarButtonItem(customView: left),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(customView: right),
            ]
        } else {
            let group = ButtonGroupView(buttons: [
                chevronLeftButton, chevronRightButton, outlineButton, bookmarkButton, libraryButton, settingButton,
            ])
            toolbarItems = [UIBarButtonItem(customView: group)]
        }
    }
    
    func dismissPopoverController() {
        guard let style = presentedViewController?.modalPresentationStyle, style == .popover else { return }
        presentedViewController?.dismiss(animated: false)
    }
    
    private func updateToolBarButtonEnabled() {
        chevronLeftButton.isEnabled = webViewController.canGoBack
        chevronRightButton.isEnabled = webViewController.canGoForward
        outlineButton.isEnabled = webViewController.currentURL != nil
        bookmarkToggleButton.isEnabled = webViewController.currentURL != nil
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
            if child == welcomeController {
                NSLayoutConstraint.activate([
                    view.topAnchor.constraint(equalTo: child.view.topAnchor),
                    view.leftAnchor.constraint(equalTo: child.view.leftAnchor),
                    view.bottomAnchor.constraint(equalTo: child.view.bottomAnchor),
                    view.rightAnchor.constraint(equalTo: child.view.rightAnchor),
                ])
            } else {
                NSLayoutConstraint.activate([
                    view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: child.view.topAnchor),
                    view.leftAnchor.constraint(equalTo: child.view.leftAnchor),
                    view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: child.view.bottomAnchor),
                    view.rightAnchor.constraint(equalTo: child.view.rightAnchor),
                ])
            }
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
        if let rootController = splitViewController as? RootController,
            !rootController.isCollapsed,
            rootController.displayMode != .primaryHidden {
            let selectedNavController = rootController.sideBarController.selectedViewController
            let selectedController = (selectedNavController as? UINavigationController)?.topViewController
            if let outlineController = selectedController as? OutlineController {
                outlineController.update()
            }
        }
    }
    
    // MARK: OutlineControllerDelegate
    
    func didTapOutlineItem(item: OutlineItem) {
        if searchController.isActive { searchController.isActive = false }
        webViewController.scrollToOutlineItem(index: item.index)
    }
    
    // MARK: BookmarkControllerDelegate
    
    func didTapBookmark(url: URL) {
        if searchController.isActive { searchController.isActive = false }
        load(url: url)
    }
    
    func didDeleteBookmark(url: URL) {
        guard webViewController.currentURL?.absoluteURL == url.absoluteURL else {return}
        bookmarkButton.isBookmarked = false
        bookmarkToggleButton.isBookmarked = false
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
        guard let splitViewController = self.splitViewController as? RootController else {return}
        UIView.animate(withDuration: 0.2) {
            splitViewController.toggleSideBar()
        }
    }
    
    @objc func goBack() {
        webViewController.goBack()
    }
    
    @objc func goForward() {
        webViewController.goForward()
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
        
        guard let url = webViewController.currentURL,
            let zimFileID = url.host else {return}
        
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "zimFile.id == %@ AND path == %@", zimFileID, url.path)
            if let bookmark = database.objects(Bookmark.self).filter(predicate).first {
                presentBookmarkHUDController(isBookmarked: false)
                try database.write {
                    database.delete(bookmark)
                }
                BookmarkService().updateBookmarkWidgetData()
            } else {
                guard let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else {return}
                let bookmark = Bookmark()
                bookmark.zimFile = zimFile
                bookmark.path = url.path
                bookmark.title = webViewController.currentTitle ?? ""
                bookmark.date = Date()
                
                let group = DispatchGroup()
                group.enter()
                webViewController.extractSnippet(completion: { (snippet) in
                    bookmark.snippet = snippet
                    group.leave()
                })
                if zimFile.hasPictures {
                    group.enter()
                    webViewController.extractImageURLs(completion: { (urls) in
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
                    BookmarkService().updateBookmarkWidgetData()
                })
            }
        } catch {return}
    }
    
    @objc func openLibrary() {
        guard let splitController = splitViewController as? RootController else {return}
        let libraryController = cachedLibraryController ?? LibraryController(onDismiss: {
            let timer = Timer(timeInterval: 60, repeats: false, block: { [weak self] timer in
                self?.cachedLibraryController = nil
            })
            RunLoop.main.add(timer, forMode: .default)
        })
        self.cachedLibraryController = libraryController
        splitController.present(libraryController, animated: true)
    }
    
    @objc func openSettings() {
        splitViewController?.present(SettingNavigationController(), animated: true)
    }
    
    @objc func openTabsView() {
        splitViewController?.present(TabsController(), animated: true)
    }
}

// MARK: - Buttons

private extension UIControl.State {
    static let bookmarked = UIControl.State(rawValue: 1 << 16)
}

private class ButtonGroupView: UIStackView {
    convenience init(buttons: [UIButton], spacing: CGFloat? = nil) {
        self.init(arrangedSubviews: buttons)
        distribution = .equalCentering
        if let spacing = spacing {
            self.spacing = spacing
        }
    }
}

private class Button: UIButton {
    convenience init(imageName: String) {
        self.init(type: .system)
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(scale: .large)
            setImage(UIImage(systemName: imageName, withConfiguration: configuration), for: .normal)
        } else {
            setImage(UIImage(named: imageName), for: .normal)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 36, height: 44)
    }
}

private class BookmarkButton: Button {
    var isBookmarked: Bool = false { didSet { setNeedsLayout() } }
    override var state: UIControl.State{ get { isBookmarked ? [.bookmarked, super.state] : super.state } }
    
    convenience init(imageName: String, bookmarkedImageName: String) {
        if #available(iOS 13.0, *) {
            self.init(imageName: imageName)
            let configuration = UIImage.SymbolConfiguration(scale: .large)
            let bookmarkedImage = UIImage(systemName: bookmarkedImageName, withConfiguration: configuration)?
                .withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
            setImage(bookmarkedImage, for: .bookmarked)
            setImage(bookmarkedImage, for: [.bookmarked, .highlighted])
        } else {
            self.init(type: .system)
            setImage(UIImage(named: imageName), for: .normal)
            let bookmarkedImage = UIImage(named: bookmarkedImageName)
            setImage(bookmarkedImage, for: .bookmarked)
            setImage(bookmarkedImage, for: [.bookmarked, .highlighted])
        }
    }
}
