//
//  iOSExtensions.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

// MARK: - UI

enum BuildStatus {
    case alpha, beta, release
}

extension UIApplication {
    class var buildStatus: BuildStatus {
        get {
            return .beta
        }
    }
}

extension UIColor {
    class var defaultTint: UIColor {return UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)}

    class var themeColor: UIColor {
        return UIColor(red: 71.0 / 255.0, green: 128.0 / 255.0, blue: 182.0 / 255.0, alpha: 1.0)
    }
}

class AppColors {
    static let hasPicTintColor = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)
    static let hasIndexTintColor = UIColor(red: 0.304706, green: 0.47158, blue: 1, alpha: 1)
    static let theme = UIColor(red: 71/255, green: 128/255, blue: 182/255, alpha: 1)
}
