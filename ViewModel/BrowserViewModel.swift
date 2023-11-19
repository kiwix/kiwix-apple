//
//  BrowserViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 6/21/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import Combine
import CoreData
import CoreLocation
import WebKit
import Defaults

import OrderedCollections

final class BrowserViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    private static var cache = OrderedDictionary<NSManagedObjectID, BrowserViewModel>()

    static func getCached(tabID: NSManagedObjectID) -> BrowserViewModel {
        let viewModel = cache[tabID] ?? BrowserViewModel(tabID: tabID)
        cache.removeValue(forKey: tabID)
        cache[tabID] = viewModel
        return viewModel
    }

    static func purgeCache() {
        guard cache.count > 10 else { return }
        let range = 0 ..< cache.count - 5
        cache.values[range].forEach { viewModel in
            viewModel.persistState()
        }
        cache.removeSubrange(range)
    }

    // MARK: - Properties

    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var articleTitle: String = ""
    @Published private(set) var zimFileName: String = ""
    @Published private(set) var articleBookmarked = false
    @Published private(set) var outlineItems = [OutlineItem]()
    @Published private(set) var outlineItemTree = [OutlineItem]()
    @Published private(set) var url: URL?
    @Published var externalURL: URL?

    private(set) var tabID: NSManagedObjectID? {
        didSet {
            #if os(macOS)
            if let tabID, tabID != oldValue {
                storeTabIDInCurrentWindow()
            }
            #endif
        }
    }
    #if os(macOS)
    private var windowURLs: [URL] {
        UserDefaults.standard[.windowURLs]
    }
    #endif
    let webView: WKWebView
    private var canGoBackObserver: NSKeyValueObservation?
    private var canGoForwardObserver: NSKeyValueObservation?
    private var titleURLObserver: AnyCancellable?
    private var bookmarkFetchedResultsController: NSFetchedResultsController<Bookmark>?
    private let scriptHandler: BrowserScriptHandler
    private let navDelegate: BrowserNavDelegate
    private let uiDelegate: BrowserUIDelegate
    /// A temporary placeholder for the url that should be opened in a new tab, set on macOS only
    static var urlForNewTab: URL?
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Lifecycle

    init(tabID: NSManagedObjectID? = nil) {
        self.tabID = tabID
        webView = WKWebView(frame: .zero, configuration: WebViewConfiguration())
        scriptHandler = BrowserScriptHandler()
        navDelegate = BrowserNavDelegate()
        uiDelegate = BrowserUIDelegate()
        super.init()

        scriptHandler.$outlineItems.assign(to: \.outlineItems, on: self).store(in: &cancellables)
        scriptHandler.$outlineItemTree.assign(to: \.outlineItemTree, on: self).store(in: &cancellables)

        navDelegate.$externalURL.assign(to: \.externalURL, on: self).store(in: &cancellables)

        navDelegate.$didLoadContent.sink { [weak self] didLoad in
            if didLoad == true {
                self?.persistState()
            }
        }.store(in: &cancellables)

        uiDelegate.$externalURL.assign(to: \.externalURL, on: self).store(in: &cancellables)
        uiDelegate.$createBookMark.sink { [weak self] url in self?.createBookmark(url: url) }.store(in: &cancellables)
        uiDelegate.$deleteBookMark.sink { [weak self] url in self?.deleteBookmark(url: url) }.store(in: &cancellables)

        // configure web view
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.defaultWebpagePreferences.preferredContentMode = .mobile // for font adjustment to work
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "headings")
        webView.configuration.userContentController.add(scriptHandler, name: "headings")
        webView.navigationDelegate = navDelegate
        webView.uiDelegate = uiDelegate

        if let tabID {
            restoreBy(tabID: tabID)
        }
        if let urlForNewTab = Self.urlForNewTab {
            url = urlForNewTab
            load(url: urlForNewTab)
        }

        // get outline items if something is already loaded
        if webView.url != nil {
            webView.evaluateJavaScript("getOutlineItems();")
        }

        // setup web view property observers
        canGoBackObserver = webView.observe(\.canGoBack, options: .initial) { [weak self] webView, _ in
            self?.canGoBack = webView.canGoBack
        }
        canGoForwardObserver = webView.observe(\.canGoForward, options: .initial) { [weak self] webView, _ in
            self?.canGoForward = webView.canGoForward
        }
        titleURLObserver = Publishers.CombineLatest(
            webView.publisher(for: \.title, options: .initial),
            webView.publisher(for: \.url, options: .initial)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] title, url in
            guard let title, let url else { return }
            self?.didUpdate(title: title, url: url)
        }
        bookmarkFetchedResultsController?.delegate = self
    }

    private func didUpdate(title: String, url: URL) {
        let zimFile: ZimFile? = {
            guard let zimFileID = UUID(uuidString: url.host ?? "") else { return nil }
            return try? Database.viewContext.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first
        }()

        // update view model
        articleTitle = title
        zimFileName = zimFile?.name ?? ""
        self.url = url

        let currentTabID: NSManagedObjectID = tabID ?? createNewTabID()
        tabID = currentTabID

        // update tab data
        if let tab = try? Database.viewContext.existingObject(with: currentTabID) as? Tab {
            tab.title = title
            tab.zimFile = zimFile
        }

        // setup bookmark fetched results controller
        bookmarkFetchedResultsController = NSFetchedResultsController(
            fetchRequest: Bookmark.fetchRequest(predicate: {
                return NSPredicate(format: "articleURL == %@", url as CVarArg)
            }()),
            managedObjectContext: Database.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        try? bookmarkFetchedResultsController?.performFetch()
    }

    func updateLastOpened() {
        guard let tabID, let tab = try? Database.viewContext.existingObject(with: tabID) as? Tab else { return }
        tab.lastOpened = Date()
    }

    func persistState() {
        guard let tabID,
                let tab = try? Database.viewContext.existingObject(with: tabID) as? Tab else {
            return
        }
        tab.interactionState = webView.interactionState as? Data
        try? Database.viewContext.save()
    }

    // MARK: - Content Loading

    func load(url: URL) {
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }

    func loadRandomArticle(zimFileID: UUID? = nil) {
        guard let url = ZimFileService.shared.getRandomPageURL(zimFileID: zimIdOf(zimFileID)) else { return }
        load(url: url)
    }

    func loadMainArticle(zimFileID: UUID? = nil) {
        guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimIdOf(zimFileID)) else { return }
        load(url: url)
    }

    private func restoreBy(tabID: NSManagedObjectID) {
        if let tab = try? Database.viewContext.existingObject(with: tabID) as? Tab {
           webView.interactionState = tab.interactionState
           url = webView.url
       }
    }

    private func zimIdOf(_ uuid: UUID? = nil) -> UUID? {
        uuid ?? UUID(uuidString: webView.url?.host ?? "")
    }

    // MARK: - TabID management via NSWindow for macOS

    #if os(macOS)
    private (set) var windowNumber: Int?

    // RESTORATION
    func restoreByWindowNumber(
        windowNumber currentNumber: Int,
        urlToTabIdConverter: @escaping (URL?) -> NSManagedObjectID
    ) {
        windowNumber = currentNumber
        let windows = NSApplication.shared.windows
        let tabURL: URL?

        guard let currentWindow = windowBy(number: currentNumber),
              let index = windows.firstIndex(of: currentWindow) else { return }

        // find the url for this window in user defaults, by pure index
        if 0 <= index,
           index < windowURLs.count {
            tabURL = windowURLs[index]
        } else {
            tabURL = nil
        }
        let tabID = urlToTabIdConverter(tabURL) // if url is nil it will create a new tab
        self.tabID = tabID
        restoreBy(tabID: tabID)
    }

    private func indexOf(windowNumber number: Int, in windows: [NSWindow]) -> Int? {
        let windowNumbers = windows.map { $0.windowNumber }
        guard windowNumbers.contains(number),
              let index = windowNumbers.firstIndex(of: number) else {
            return nil
        }
        return index
    }

    // PERSISTENCE:
    func persistAllTabIdsFromWindows() {
        let urls = NSApplication.shared.windows.compactMap { window in
            window.accessibilityURL()
        }
        UserDefaults.standard[.windowURLs] = urls
    }

    private func storeTabIDInCurrentWindow() {
        guard let tabID,
                let windowNumber,
              let currentWindow = windowBy(number: windowNumber) else {
            return
        }
        let url = tabID.uriRepresentation()
        currentWindow.setAccessibilityURL(url)
    }

    private func windowBy(number: Int) -> NSWindow? {
        NSApplication.shared.windows.first { $0.windowNumber == number }
    }
    #endif

    private func createNewTabID() -> NSManagedObjectID {
        if let tabID { return tabID }
        let context = Database.viewContext
        let tab = Tab(context: context)
        tab.created = Date()
        tab.lastOpened = Date()
        try? context.obtainPermanentIDs(for: [tab])
        try? context.save()
        return tab.objectID
    }

    // MARK: - Bookmark

    func controller(_: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        articleBookmarked = !snapshot.itemIdentifiers.isEmpty
    }

    func createBookmark(url: URL? = nil) {
        guard let url = url ?? webView.url else { return }
        Database.performBackgroundTask { context in
            let bookmark = Bookmark(context: context)
            bookmark.articleURL = url
            bookmark.created = Date()
            if let parser = try? HTMLParser(url: url) {
                bookmark.title = parser.title ?? ""
                bookmark.snippet = parser.getFirstSentence(languageCode: nil)?.string
                guard let zimFileID = UUID(uuidString: url.host ?? ""),
                      let zimFile = try? context.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first else { return }
                bookmark.zimFile = zimFile
                if let imagePath = parser.getFirstImagePath() {
                    bookmark.thumbImageURL = URL(zimFileID: zimFileID.uuidString, contentPath: imagePath)
                }
            }
            try? context.save()
        }
    }

    func deleteBookmark(url: URL? = nil) {
        guard let url = url ?? webView.url else { return }
        Database.performBackgroundTask { context in
            let request = Bookmark.fetchRequest(predicate: NSPredicate(format: "articleURL == %@", url as CVarArg))
            guard let bookmark = try? context.fetch(request).first else { return }
            context.delete(bookmark)
            try? context.save()
        }
    }

    // MARK: - Outline

    /// Scroll to an outline item
    /// - Parameter outlineItemID: ID of the outline item to scroll to
    func scrollTo(outlineItemID: String) { webView.evaluateJavaScript("scrollToHeading('\(outlineItemID)')") }
}
