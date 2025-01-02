// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import Combine
import CoreData
import CoreLocation
import WebKit
import Defaults
import os
import CoreKiwix

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
final class BrowserViewModel: NSObject, ObservableObject,
                              WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate,
                              NSFetchedResultsControllerDelegate {

    @MainActor
    private static var cache: OrderedCache<NSManagedObjectID, BrowserViewModel>?

    @MainActor
    static func getCached(tabID: NSManagedObjectID) -> BrowserViewModel {
        if let cachedModel = cache?.findBy(key: tabID) {
            return cachedModel
        }
        if cache == nil {
            cache = .init()
        }
        let viewModel = BrowserViewModel(tabID: tabID)
        cache?.removeValue(forKey: tabID)
        cache?.setValue(viewModel, forKey: tabID)
        return viewModel
    }

    static func purgeCache() {
        Task { @MainActor in
            cache?.removeOlderThan(Date.now.advanced(by: -360)) // 6 minutes
        }
    }

    nonisolated static func keepOnlyTabsByIds(_ ids: Set<NSManagedObjectID>) {
        Task { @MainActor in
            if let cache {
                for browser in cache.removeNotMatchingWith(keys: ids) {
                    await browser.destroy()
                }
            }
        }
    }
    
    // MARK: - Properties

    @Published private(set) var isLoading: Bool?
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var articleTitle: String = ""
    @Published private(set) var zimFileName: String = ""
    @Published private(set) var articleBookmarked = false
    @Published private(set) var outlineItems = [OutlineItem]()
    @Published private(set) var outlineItemTree = [OutlineItem]()
    @MainActor @Published private(set) var hasURL: Bool = false
    @MainActor @Published private(set) var url: URL? {
        didSet {
            if !FeatureFlags.hasLibrary, url == nil {
                loadMainArticle()
            }
            if url != oldValue {
                bookmarkFetchedResultsController.fetchRequest.predicate = Self.bookmarksPredicateFor(url: url)
                try? bookmarkFetchedResultsController.performFetch()
            }
            hasURL = url != nil
        }
    }
    @MainActor var zimFileId: UUID? { url?.zimFileID }
    @Published var externalURL: URL?
    private var metaData: URLContentMetaData?

#if os(macOS)
    private var windowURLs: [URL] {
        UserDefaults.standard[.windowURLs]
    }
#endif
    let webView: WKWebView
    let tabID: NSManagedObjectID
    private var isLoadingObserver: NSKeyValueObservation?
    private var canGoBackObserver: NSKeyValueObservation?
    private var canGoForwardObserver: NSKeyValueObservation?
    private var titleURLObserver: AnyCancellable?
    private let bookmarkFetchedResultsController: NSFetchedResultsController<Bookmark>

    // MARK: - Lifecycle

    // swiftlint:disable:next function_body_length
    @MainActor private init(tabID: NSManagedObjectID) {
        self.tabID = tabID
        webView = WKWebView(frame: .zero, configuration: WebViewConfiguration())
        if !Bundle.main.isProduction, #available(iOS 16.4, macOS 13.3, *) {
                webView.isInspectable = true
        }
        // Bookmark fetching:
        bookmarkFetchedResultsController = NSFetchedResultsController(
            fetchRequest: Bookmark.fetchRequest(), // initially empty
            managedObjectContext: Database.shared.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        super.init()

        bookmarkFetchedResultsController.delegate = self

        // configure web view
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.defaultWebpagePreferences.preferredContentMode = .mobile // for font adjustment to work
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "headings")
        webView.configuration.userContentController.add(self, name: "headings")
        webView.navigationDelegate = self
        webView.uiDelegate = self

        restoreBy(tabID: tabID)

        // get outline items if something is already loaded
        if webView.url != nil {
            webView.evaluateJavaScript("getOutlineItems();")
        }

        // setup web view property observers
        canGoBackObserver = webView.observe(\.canGoBack, options: .initial) { [weak self] webView, _ in
            Task { [weak self] in
                await MainActor.run { [weak self] in
                    self?.canGoBack = webView.canGoBack
                }
            }
        }
        canGoForwardObserver = webView.observe(\.canGoForward, options: .initial) { [weak self] webView, _ in
            Task { [weak self] in
                await MainActor.run { [weak self] in
                    self?.canGoForward = webView.canGoForward
                }
            }
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

        isLoadingObserver = webView.observe(\.isLoading, options: .new) { [weak self] _, change in
            Task { @MainActor [weak self] in
                if change.newValue != self?.isLoading {
                    self?.isLoading = change.newValue
                }
            }
        }
    }

    @MainActor
    func destroy() async {
        bookmarkFetchedResultsController.delegate = nil
        canGoBackObserver?.invalidate()
        canGoForwardObserver?.invalidate()
        titleURLObserver?.cancel()
        isLoadingObserver?.invalidate()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        #if os(iOS)
        webView.scrollView.delegate = nil
        #endif
        await clear()
    }

    @MainActor
    func clear() async {
        await webView.setAllMediaPlaybackSuspended(true)
        await webView.closeAllMediaPresentations()
        webView.stopLoading()
        url = nil
        articleTitle = ""
        zimFileName = ""
        outlineItems = []
        outlineItemTree = []
        // !important to make the webView disappear,
        // until new content is not starting to load
        // as complete clear of webView is not possible
        isLoading = nil
    }

    /// Get the webpage in a binary format
    /// - Returns: PDF of the current page (if text type) or binary data of the content
    /// and the file extension, if known
    func pageDataWithExtension() async -> (Data, String?)? {
        if metaData?.isTextType == true,
           let pdfData = try? await webView.pdf() {
            return (pdfData, metaData?.exportFileExtension)
        } else if let url = await webView.url,
                  let contentData = await ZimFileService.shared.getURLContent(url: url)?.data {
            let pathExtesion = url.pathExtension
            let fileExtension: String?
            if !pathExtesion.isEmpty {
                fileExtension = pathExtesion
            } else {
                fileExtension = metaData?.exportFileExtension
            }
            return (contentData, fileExtension)
        }
        return nil
    }

    func forceLoadingState() {
        isLoading = true
    }

    private func didUpdate(title: String, url: URL) {
        let zimFile: ZimFile? = {
            guard let zimFileID = url.zimFileID else { return nil }
            return try? Database.shared.viewContext.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first
        }()

        Task { @MainActor in
            metaData = await ZimFileService.shared.getContentMetaData(url: url)
            if title.isEmpty {
                articleTitle = metaData?.zimTitle ?? ""
            } else {
                articleTitle = title
            }
            // update view model
            zimFileName = zimFile?.name ?? ""
            self.url = url

            // update tab data
            let context = Database.shared.viewContext
            if let tab = try? context.existingObject(with: tabID) as? Tab {
                tab.title = articleTitle
                tab.zimFile = zimFile
            }
            if context.hasChanges {
                try? context.save()
            }
            #if os(macOS)
            disableVideoContextMenu()
            #endif
        }
    }

    @MainActor
    func updateLastOpened() {
        guard let tab = try? Database.shared.viewContext.existingObject(with: tabID) as? Tab else { return }
        tab.lastOpened = Date()
    }

    @MainActor
    func persistState() {
        guard let tab = try? Database.shared.viewContext.existingObject(with: tabID) as? Tab else {
            return
        }
        tab.interactionState = webView.interactionState as? Data
        try? Database.shared.viewContext.save()
    }

    // MARK: - Content Loading
    @MainActor
    func load(url: URL) {
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
        self.url = url
    }

    @MainActor
    func loadRandomArticle(zimFileID: UUID? = nil) {
        let zimFileID = zimFileID ?? webView.url?.zimFileID
        Task { @ZimActor [weak self] in
            guard let url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFileID) else { return }
            await MainActor.run { [weak self] in
                self?.load(url: url)
            }
        }
    }

    @MainActor
    func loadMainArticle(zimFileID: UUID? = nil) {
        let zimFileID = zimFileID ?? webView.url?.zimFileID
        Task { @ZimActor [weak self] in
            guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
            await MainActor.run { [weak self] in
                self?.load(url: url)
            }
        }
    }

    private func restoreBy(tabID: NSManagedObjectID) {
        if let tab = try? Database.shared.viewContext.existingObject(with: tabID) as? Tab {
            webView.interactionState = tab.interactionState
            if webView.url != nil {
                // make sure category(.list) is not displayed
                // while restoring a tab
                isLoading = true
            }
            Task { [weak self] in
                await MainActor.run { [weak self] in
                    // migrate the tab urls on demand to ZIM scheme
                    self?.url = self?.webView.url?.updatedToZIMSheme()
                    if let webURL = self?.webView.url, webURL.isKiwixURL {
                        self?.load(url: webURL.updatedToZIMSheme())
                    }
                }
            }
        }
    }

    // MARK: - Video fixes
    func pauseVideoWhenNotInPIP() {
        // webView.pauseAllMediaPlayback() is not good enough
        // as that pauses in Picture in Picture mode as well.
        // Detecting PiP on a AVPictureInPictureController created by WKWebView
        // is currently non-trivial from the swift side
        webView.evaluateJavaScript("pauseVideoWhenNotInPIP();")
    }

    @MainActor
    func refreshVideoState() {
        Task { [weak webView] in
            await MainActor.run { [weak webView] in
                webView?.evaluateJavaScript("refreshVideoState();")
            }
        }
    }

    #if os(macOS)
    /// Disable the right-click context menu on video components
    @MainActor
    func disableVideoContextMenu() {
        webView.evaluateJavaScript("disableVideoContextMenu();")
    }
    #endif

    // MARK: - New Tab Creation

#if os(macOS)
    @MainActor
    private func createNewWindow(with url: URL) -> Bool {
        guard let currentWindow = NSApp.keyWindow,
              let windowController = currentWindow.windowController else { return false }
        let context = Database.shared.viewContext
        // create a new Tab DB object, and a new BrowserViewModel (which creates a new WKWebView)
        // and pre-load the url into that
        let newTab = NavigationViewModel.makeTab(context: context)
        let newTabID = newTab.objectID
        BrowserViewModel.getCached(tabID: newTabID).load(url: url)

        // store the tabID statically, so that the new window can pick it up
        NavigationViewModel.tabIDToUseOnNewTab = newTabID

        windowController.newWindowForTab(self)
        guard let newWindow = NSApp.keyWindow, currentWindow != newWindow else {
            // rather impossible case, but rolling back everything from above
            NavigationViewModel.tabIDToUseOnNewTab = nil
            context.delete(newTab)
            if context.hasChanges {
                try? context.save()
            }
            return false
        }
        currentWindow.addTabbedWindow(newWindow, ordered: .above)
        return true
    }
#endif

    // MARK: - WKNavigationDelegate

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    @MainActor func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard navigationAction.targetFrame?.isMainFrame == true else {
            // Allow to load iFrame content via src-doc instead of external src
            return .allow
        }
        guard let url = navigationAction.request.url?.updatedToZIMSheme() else {
            return .cancel
        }

#if os(macOS)
        // detect cmd + click event
        if navigationAction.modifierFlags.contains(.command) {
            if createNewWindow(with: url) {
                return .cancel
            }
        }
#endif

        if url.isZIMURL, let redirectedURL = await ZimFileService.shared.getRedirectedURL(url: url) {
            if webView.url != redirectedURL {
                webView.load(URLRequest(url: redirectedURL))
            }
            return .cancel
        } else if url.isZIMURL {
            guard await ZimFileService.shared.getContentSize(url: url) != nil else {
                os_log(
                    "Missing content at url: %@ => %@",
                    log: Log.URLSchemeHandler,
                    type: .error,
                    url.absoluteString,
                    url.contentPath
                )
                if navigationAction.request.mainDocumentURL == url {
                    // only show alerts for missing main document
                    NotificationCenter.default.post(
                        name: .alert,
                        object: nil,
                        userInfo: ["rawValue": ActiveAlert.articleFailedToLoad.rawValue]
                    )
                }
                return .cancel
            }
            return .allow
        } else if url.isUnsupported {
            externalURL = url
            return .cancel
        } else if url.isGeoURL {
            if FeatureFlags.map {
                let _: CLLocation? = {
                    let parts = url.absoluteString.replacingOccurrences(of: "geo:", with: "").split(separator: ",")
                    guard let latitudeString = parts.first,
                          let longitudeString = parts.last,
                          let latitude = Double(latitudeString),
                          let longitude = Double(longitudeString) else { return nil }
                    return CLLocation(latitude: latitude, longitude: longitude)
                }()
            } else {
                let coordinate = url.absoluteString.replacingOccurrences(of: "geo:", with: "")
                if let url = URL(string: "http://maps.apple.com/?ll=\(coordinate)") {
#if os(macOS)
                    NSWorkspace.shared.open(url)
#elseif os(iOS)
                    await UIApplication.shared.open(url)
#endif
                }
            }
            return .cancel
        } else {
            return .cancel
        }
    }

    private var canShowMimeType = true

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        canShowMimeType = navigationResponse.canShowMIMEType
        guard canShowMimeType else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    @MainActor
    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        webView.evaluateJavaScript("expandAllDetailTags(); getOutlineItems();")
#if os(iOS)
        // on iOS 17 on the iPhone, the video starts with a black screen
        // if there's a poster attribute
        if #available(iOS 17, *), Device.current == .iPhone {
            webView.evaluateJavaScript("fixVideoElements();")
        }
        webView.adjustTextSize()
#else
        persistState()
#endif
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation _: WKNavigation!,
        withError error: Error
    ) {
        let error = error as NSError
        Task { @MainActor in
            webView.stopLoading()
            (webView.configuration
                .urlSchemeHandler(forURLScheme: KiwixURLSchemeHandler.ZIMScheme) as? KiwixURLSchemeHandler)?
                .didFailProvisionalNavigation()
        }
        guard error.code != NSURLErrorCancelled else { return }
        guard canShowMimeType else {
            guard let kiwixURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL else {
                return
            }
            NotificationCenter.saveContent(url: kiwixURL)
            return
        }
        NotificationCenter.default.post(
            name: .alert, object: nil, userInfo: ["rawValue": ActiveAlert.articleFailedToLoad.rawValue]
        )
    }

    // MARK: - WKScriptMessageHandler

    @MainActor
    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "headings", let headings = message.body as? [[String: String]] {
            self.generateOutlineList(headings: headings)
            self.generateOutlineTree(headings: headings)
        }
    }

    // MARK: - WKUIDelegate

#if os(macOS)
    @MainActor
    func webView(
        _: WKWebView,
        createWebViewWith _: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures _: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        guard let newUrl = navigationAction.request.url else { return nil }

        // open external link in default browser
        guard newUrl.isUnsupported == false else {
            externalURL = newUrl
            return nil
        }

        _ = createNewWindow(with: newUrl)
        return nil
    }
#else
    @MainActor
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let newURL = navigationAction.request.url else { return nil }
        if let frame = navigationAction.targetFrame, frame.isMainFrame {
            return nil
        }
        guard newURL.isUnsupported == false else {
            externalURL = newURL
            return nil
        }
        NotificationCenter.openURL(newURL, inNewTab: true)
        return nil
    }
#endif

#if os(iOS)
    func webView(
        _ webView: WKWebView,
        contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
        completionHandler: @escaping (UIContextMenuConfiguration?) -> Void
    ) {
        guard let url = elementInfo.linkURL, url.isZIMURL else { completionHandler(nil); return }
        let configuration = UIContextMenuConfiguration(
            previewProvider: {
                let webView = WKWebView(frame: .zero, configuration: WebViewConfiguration())
                if !Bundle.main.isProduction, #available(iOS 16.4, *) {
                        webView.isInspectable = true
                }
                webView.load(URLRequest(url: url))
                return WebViewController(webView: webView)
            },
            actionProvider: { [weak self] _ in
                guard let self else { return UIMenu(children: []) }
                var actions = [UIAction]()

                // open url
                actions.append(
                    UIAction(title: "common.dialog.button.open".localized,
                             image: UIImage(systemName: "doc.text")) { [weak self] _ in
                                 self?.webView.load(URLRequest(url: url))
                    }
                )
                actions.append(
                    UIAction(title: "common.dialog.button.open_in_new_tab".localized,
                             image: UIImage(systemName: "doc.badge.plus")) { [weak self] _ in
                                 guard let self else { return }
                                 Task { @MainActor in
                                     NotificationCenter.openURL(url, inNewTab: true)
                                 }
                    }
                )

                // bookmark
                let bookmarkAction: UIAction = { [weak self] in
                    let context = Database.shared.viewContext
                    let predicate = NSPredicate(format: "articleURL == %@", url as CVarArg)
                    let request = Bookmark.fetchRequest(predicate: predicate)

                    if let bookmarks = try? context.fetch(request),
                       !bookmarks.isEmpty {
                        return UIAction(title: "common.dialog.button.remove_bookmark".localized,
                                        image: UIImage(systemName: "star.slash.fill")) { [weak self] _ in
                            self?.deleteBookmark(url: url)
                        }
                    } else {
                        return UIAction(
                            title: "common.dialog.button.bookmark".localized,
                            image: UIImage(systemName: "star")
                        ) { [weak self] _ in
                            Task { @MainActor [weak self] in self?.createBookmark(url: url) }
                        }
                    }
                }()
                actions.append(bookmarkAction)

                return UIMenu(children: actions)
            }
        )
        completionHandler(configuration)
    }
#endif

    // MARK: - Bookmark

    func controller(_: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        articleBookmarked = !snapshot.itemIdentifiers.isEmpty
    }

    @MainActor 
    func createBookmark(url: URL? = nil) {
        guard let url = url ?? webView.url,
              let zimFileID = url.zimFileID else { return }
        let title = webView.title
        Task {
            guard let metaData = await ZimFileService.shared.getContentMetaData(url: url) else { return }
            Database.shared.performBackgroundTask { context in
                let bookmark = Bookmark(context: context)
                bookmark.articleURL = url
                bookmark.created = Date()
                guard let zimFile = try? context.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first else { return }

                bookmark.zimFile = zimFile
                bookmark.title = title ?? metaData.zimTitle
                try? context.save()
            }
        }
    }

    func deleteBookmark(url: URL? = nil) {
        guard let url = url ?? webView.url else { return }
        Database.shared.performBackgroundTask { context in
            let request = Bookmark.fetchRequest(predicate: NSPredicate(format: "articleURL == %@", url as CVarArg))
            guard let bookmark = try? context.fetch(request).first else { return }
            context.delete(bookmark)
            try? context.save()
        }
    }

    // MARK: - Outline

    /// Scroll to an outline item
    /// - Parameter outlineItemID: ID of the outline item to scroll to
    func scrollTo(outlineItemID: String) {
        webView.evaluateJavaScript("scrollToHeading('\(outlineItemID)')")
    }

    /// Convert flattened heading element data to a list of OutlineItems.
    /// - Parameter headings: list of heading element data retrieved from webview
    @MainActor private func generateOutlineList(headings: [[String: String]]) {
        let allLevels = headings.compactMap { Int($0["tag"]?.suffix(1) ?? "") }
        let offset = allLevels.filter { $0 == 1 }.count == 1 ? 2 : allLevels.min() ?? 0
        let outlineItems: [OutlineItem] = headings.enumerated().compactMap { index, heading in
            guard let id = heading["id"],
                  let text = heading["text"],
                  let tag = heading["tag"],
                  let level = Int(tag.suffix(1)) else { return nil }
            return OutlineItem(id: id, index: index, text: text, level: max(level - offset, 0))
        }
        self.outlineItems = outlineItems
    }

    /// Convert flattened heading element data to a tree of OutlineItems.
    /// - Parameter headings: list of heading element data retrieved from webview
    @MainActor private func generateOutlineTree(headings: [[String: String]]) {
        let root = OutlineItem(index: -1, text: "", level: 0)
        var stack: [OutlineItem] = [root]
        var all = [String: OutlineItem]()

        headings.enumerated().forEach { index, heading in
            guard let id = heading["id"],
                  let text = heading["text"],
                  let tag = heading["tag"], let level = Int(tag.suffix(1)) else { return }
            let item = OutlineItem(id: id, index: index, text: text, level: level)
            all[item.id] = item

            // get last item in stack
            // if last item is child of item's sibling, unwind stack until a sibling is found
            guard var lastItem = stack.last else { return }
            while lastItem.level > item.level {
                stack.removeLast()
                lastItem = stack[stack.count - 1]
            }

            // if item is last item's sibling, add item to parent and replace last item with itself in stack
            // if item is last item's child, add item to parent and add item to stack
            if lastItem.level == item.level {
                stack[stack.count - 2].addChild(item)
                stack[stack.count - 1] = item
            } else if lastItem.level < item.level {
                stack[stack.count - 1].addChild(item)
                stack.append(item)
            }
        }

        // if there is only one h1, flatten one level
        if let rootChildren = root.children, rootChildren.count == 1, let rootFirstChild = rootChildren.first {
            let children = rootFirstChild.removeAllChildren()
            self.outlineItemTree = [rootFirstChild] + children
        } else {
            self.outlineItemTree = root.children ?? []
        }
    }

    private static func bookmarksPredicateFor(url: URL?) -> NSPredicate? {
        guard let url else { return nil }
        return NSPredicate(format: "articleURL == %@", url as CVarArg)
    }
}
