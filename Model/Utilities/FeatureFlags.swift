//
//  FeatureFlags.swift
//  Kiwix
//
//  Created by Chris Li on 9/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Foundation

enum FeatureFlags {
#if DEBUG
    static let wikipediaDarkUserCSS: Bool = true
    static let map: Bool = true
#else
    static let wikipediaDarkUserCSS: Bool = false
    static let map: Bool = false
#endif
}
