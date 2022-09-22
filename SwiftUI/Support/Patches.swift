//
//  Patches.swift
//  Kiwix
//
//  Created by Chris Li on 6/11/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import Foundation

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}
