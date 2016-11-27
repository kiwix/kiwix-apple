//
//  HTMLHeading.swift
//  Kiwix
//
//  Created by Chris Li on 9/6/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

class HTMLHeading {
    let index: Int!
    let tagName: String!
    let textContent: String!
    let level: Int!
    
    init?(rawValue: [String: Any]) {
        self.index = rawValue["index"] as? Int
        self.tagName = rawValue["tagName"] as? String
        self.textContent = (rawValue["textContent"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.level = {
            guard let tagName = rawValue["tagName"] as? String else {return nil}
            return Int(tagName.replacingOccurrences(of: "H", with: ""))
        }()
        
        if index == nil || tagName == nil || textContent == nil || level == nil {return nil}
    }
    
    var scrollToJavaScript: String {
        return ""
//        return "document.getElementById('\(id)').scrollIntoView();"
    }
}
