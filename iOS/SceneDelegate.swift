//
//  SceneDelegate.swift
//  iOS
//
//  Created by Chris Li on 11/28/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit

@available(iOS 13, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
            window?.rootViewController = RootSplitViewController()
            window?.makeKeyAndVisible()
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first,
            let rootViewController = window?.rootViewController as? RootSplitViewController else {return}
        rootViewController.dismiss(animated: false)
        if context.url.scheme?.caseInsensitiveCompare("kiwix") == .orderedSame {
            rootViewController.contentViewController.load(url: context.url)
        } else if context.url.scheme == "file" {
            
        }
    }
}
