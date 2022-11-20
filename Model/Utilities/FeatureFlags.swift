//
//  FeatureFlags.swift
//  Kiwix
//
//  Created by Chris Li on 9/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Foundation

struct FeatureFlags {
    static var wikipediaDarkUserCSS: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
    
    static var map: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}
