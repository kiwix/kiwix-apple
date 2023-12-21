//
//  DefaultLanguages.swift
//  Kiwix
//

import Foundation
import Defaults

/// Enforce the selected languages on start up time
/// It fully works on 2nd launch, as @main cannot be easily overriden in SwiftUI
/// For the first launch we can override the bundle we use for localization
enum DefaultLanguages {
    /// We need a work around bundle with a specific
    static var currentBundle: Bundle = Bundle.main

    static func enforce(language: String) {
        if UserDefaults.standard[.isFirstLaunch] {
            UserDefaults.standard[.isFirstLaunch] = false
            // override the system picked languages at start
            UserDefaults.standard.set([language], forKey: "AppleLanguages")

            // override the bundle used on first launch of the app:
            if let path = Bundle.main.path(forResource: language, ofType: "lproj") {
                if let langBundle = Bundle.init(path: path) {
                    currentBundle = langBundle
                }
            }
        }
    }
}
