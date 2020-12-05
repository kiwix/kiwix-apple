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
            window?.rootViewController = {
                if #available(iOS 14.0, *), FeatureFlags.swiftUIBasedAppEnabled{
                    return UINavigationController(rootViewController: RootController_iOS14())
                } else {
                    return UINavigationController(rootViewController: RootViewController())
                }
            }()
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
              let navigationController = window?.rootViewController as? UINavigationController,
              let rootViewController = navigationController.topViewController as? RootViewController else {return}
        if context.url.isKiwixURL {
            rootViewController.openURL(context.url)
        } else if context.url.isFileURL {
//            rootViewController.openFileURL(context.url, canOpenInPlace: context.options.openInPlace)
        }
    }
    
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        guard let shortcut = Shortcut(rawValue: shortcutItem.type),
              let navigationController = window?.rootViewController as? UINavigationController,
              let rootViewController = navigationController.topViewController as? RootViewController else { completionHandler(false); return }
        switch shortcut {
        case .bookmark:
            rootViewController.toggleBookmarks()
        case .search:
            rootViewController.searchController.isActive = true
        }
        completionHandler(true)
    }
}
