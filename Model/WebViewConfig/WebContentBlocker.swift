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

import Foundation
import WebKit

/// Create a block-list for html resources (js, img, css etc)
/// so only zim:// schema type urls are allowed to be loaded
enum WebContentBlocker {
    
    @MainActor
    static var ruleList: WKContentRuleList?
    
    @MainActor
    static func compilePolicy() async {
        guard let blockListStore = WKContentRuleListStore.default() else {
            Log.URLSchemeHandler.error("blockListStore cannot be initialized")
            return
        }
        let contentRules =
"""
[
    {
        "action": {
            "type": "block"
        },
        "trigger": {
            "url-filter": ".*"
        }
    },
    {
        "action": {
            "type": "ignore-previous-rules"
        },
        "trigger": {
            "url-filter": "zim://"
        }
    }
]
"""
        guard let ruleList: WKContentRuleList = try? await blockListStore.compileContentRuleList(
            forIdentifier: "externalUrls",
            encodedContentRuleList: contentRules
        ) else {
            Log.URLSchemeHandler.error("blockList failed to compile")
            return
        }
        Self.ruleList = ruleList
    }
}
