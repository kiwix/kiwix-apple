//
//  SceneDelegate.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 11/28/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

@available(iOS 13, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    // MARK: - Lifecycle
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
            window?.rootViewController = RootSplitViewController()
            window?.makeKeyAndVisible()
        }
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        let scan = LibraryScanOperation(directoryURL: URL.documentDirectory)
        LibraryOperationQueue.shared.addOperation(scan)
    }
    
    // MARK: - URL Handling & Actions
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first,
            let rootViewController = window?.rootViewController as? RootSplitViewController else {return}
        let url = context.url
        if url.isKiwixURL {
            rootViewController.openKiwixURL(url)
        } else if url.isFileURL {
            rootViewController.openFileURL(url, canOpenInPlace: context.options.openInPlace)
        }
    }
    
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        guard let rootViewController = window?.rootViewController as? RootSplitViewController,
            let shortcut = Shortcut(rawValue: shortcutItem.type) else { completionHandler(false); return }
        rootViewController.openShortcut(shortcut)
        completionHandler(true)
    }
}
