//
//  ButtonProvider.swift
//  Kiwix
//
//  Created by Chris Li on 12/13/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import WebKit
import RealmSwift

class ButtonProvider {
    weak var rootViewController: RootViewController? { didSet { setupTargetActions() } }
    
    private let chevronLeftButton = BarButton(imageName: "chevron.left")
    private let chevronRightButton = BarButton(imageName: "chevron.right")
    private let outlineButton = BarButton(imageName: "list.bullet")
    private let bookmarkButton = BookmarkButton(imageName: "star", bookmarkedImageName: "star.fill")
    private let diceButton = BarButton(imageName: "die.face.5")
    private let houseButton = BarButton(imageName: "house")
    private let libraryButton = BarButton(imageName: "folder")
    private let settingsButton = BarButton(imageName: "gear")
    private let moreButton = BarButton(imageName: "ellipsis.circle")
    private let bookmarkLongPressGestureRecognizer = UILongPressGestureRecognizer()
    
    let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    var navigationLeftButtons: [BarButton] { [chevronLeftButton, chevronRightButton, outlineButton, bookmarkButton] }
    var navigationRightButtons: [BarButton] { [diceButton, houseButton, libraryButton, settingsButton] }
    var toolbarButtons: [BarButton] { [chevronLeftButton, chevronRightButton, outlineButton, bookmarkButton, diceButton, moreButton] }
    
    private let onDeviceZimFiles = Queries.onDeviceZimFiles()?.sorted(byKeyPath: "size", ascending: false)
    private var webViewURLObserver: NSKeyValueObservation?
    private var webViewCanGoBackObserver: NSKeyValueObservation?
    private var webViewCanGoForwardObserver: NSKeyValueObservation?
    private var bookmarksObserver: NotificationToken?
    private var onDeviceZimFilesObserver: NotificationToken?
    
    init(webView: WKWebView) {
        bookmarkButton.addGestureRecognizer(bookmarkLongPressGestureRecognizer)
        webViewURLObserver = webView.observe(\.url, changeHandler: { webView, _ in
            guard let url = webView.url else { return }
            self.bookmarkButton.isBookmarked = BookmarkService().get(url: url) != nil
        })
        webViewCanGoBackObserver = webView.observe(\.canGoBack, options: [.initial, .new], changeHandler: { webView, _ in
            self.chevronLeftButton.isEnabled = webView.canGoBack
        })
        webViewCanGoForwardObserver = webView.observe(\.canGoForward, options: [.initial, .new], changeHandler: { webView, _ in
            self.chevronRightButton.isEnabled = webView.canGoForward
        })
        bookmarksObserver = BookmarkService.list()?.observe { change in
            guard case .update = change, let url = webView.url else { return }
            self.bookmarkButton.isBookmarked = BookmarkService().get(url: url) != nil
        }
        onDeviceZimFilesObserver = Queries.onDeviceZimFiles()?
            .sorted(byKeyPath: "size", ascending: false)
            .observe { change in
                switch change {
                case .initial, .update:
                    if #available(iOS 14.0, *) {
                        self.configureDiceButtonMenu()
                        self.configureHouseButtonMenu()
                        self.configureMoreButtonMenu()
                    }
                default:
                    break
                }
            }
    }
    
    private func setupTargetActions() {
        guard let controller = rootViewController else { return }
        chevronLeftButton.addTarget(controller, action: #selector(controller.chevronLeftButtonTapped), for: .touchUpInside)
        chevronRightButton.addTarget(controller, action: #selector(controller.chevronRightButtonTapped), for: .touchUpInside)
        outlineButton.addTarget(controller, action: #selector(controller.outlineButtonTapped), for: .touchUpInside)
        bookmarkButton.addTarget(controller, action: #selector(controller.bookmarkButtonTapped), for: .touchUpInside)
        diceButton.addTarget(controller, action: #selector(controller.diceButtonTapped), for: .touchUpInside)
        houseButton.addTarget(controller, action: #selector(controller.houseButtonTapped), for: .touchUpInside)
        libraryButton.addTarget(controller, action: #selector(controller.libraryButtonTapped), for: .touchUpInside)
        settingsButton.addTarget(controller, action: #selector(controller.settingsButtonTapped), for: .touchUpInside)
        moreButton.addTarget(controller, action: #selector(controller.moreButtonTapped), for: .touchUpInside)
        
        bookmarkLongPressGestureRecognizer.addTarget(controller, action: #selector(controller.bookmarkButtonLongPressed))
        cancelButton.target = controller
        cancelButton.action = #selector(controller.dismissSearch)
    }
    
    @available(iOS 14.0, *)
    private func configureDiceButtonMenu() {
        if let zimFiles = onDeviceZimFiles, !zimFiles.isEmpty {
            let items = zimFiles.map { zimFile in
                UIAction(title: zimFile.title) { _ in self.rootViewController?.openRandomPage(zimFileID: zimFile.fileID) }
            }
            diceButton.menu = UIMenu(children: Array(items))
        } else {
            let items = [UIAction(title: "No Zim File Available", attributes: .disabled, handler: { _ in })]
            diceButton.menu = UIMenu(children: items)
        }
    }
    
    @available(iOS 14.0, *)
    private func configureHouseButtonMenu() {
        var items = [UIMenuElement]()
        if let zimFiles = onDeviceZimFiles, !zimFiles.isEmpty {
            items.append(UIMenu(options: .displayInline, children: zimFiles.map { zimFile in
                UIAction(title: zimFile.title) { _ in self.rootViewController?.openMainPage(zimFileID: zimFile.fileID) }
            }))
        } else {
            items.append(UIAction(title: "No Zim File Available", attributes: .disabled, handler: { _ in }))
        }
        houseButton.menu = UIMenu(children: items)
    }
    
    @available(iOS 14.0, *)
    private func configureMoreButtonMenu() {
        var items: [UIMenuElement] = [
            UIAction(title: "Library", image: UIImage(systemName: "folder"), handler: { _ in self.rootViewController?.libraryButtonTapped() }),
            UIAction(title: "Settings", image: UIImage(systemName: "gear"), handler: { _ in self.rootViewController?.settingsButtonTapped() }),
        ]
        if let zimFiles = onDeviceZimFiles, !zimFiles.isEmpty {
            items.insert(UIMenu(options: .displayInline, children: zimFiles.map { zimFile in
                UIAction(title: zimFile.title, image: UIImage(systemName: "house")) { _ in self.rootViewController?.openMainPage(zimFileID: zimFile.fileID) }
            }), at: 0)
        }
        moreButton.menu = UIMenu(children: items)
        moreButton.showsMenuAsPrimaryAction = true
    }
}
