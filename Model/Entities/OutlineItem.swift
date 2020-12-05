//
//  OutlineItem.swift
//  Kiwix
//
//  Created by Chris Li on 12/5/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

struct OutlineItem {
    let index: Int
    let text: String
    let level: Int
    
    init?(rawValue: [String: Any]) {
        if let index = rawValue["index"] as? Int,
            let tagName = rawValue["tagName"] as? String,
            let level = Int(tagName.replacingOccurrences(of: "H", with: "")),
            let text = (rawValue["textContent"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        {
            self.index = index
            self.level = level
            self.text = text
        } else {
            return nil
        }
    }
}
