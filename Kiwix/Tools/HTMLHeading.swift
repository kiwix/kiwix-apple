//
//  HTMLHeading.swift
//  Kiwix
//
//  Created by Chris Li on 9/6/16.
//  Copyright © 2016 Chris. All rights reserved.
//

class HTMLHeading {
    let id: String
    let tagName: String
    let textContent: String
    let level: Int
    
    init?(rawValue: [String: String]) {
        let tagName = rawValue["tagName"] ?? ""
        self.id = rawValue["id"] ?? ""
        self.textContent = (rawValue["textContent"] ?? "").trimmingCharacters(in: .whitespaces)
        self.tagName = tagName
        self.level = Int(tagName.replacingOccurrences(of: "H", with: "")) ?? -1
        
        if id == "" {return nil}
        if tagName == "" {return nil}
        if textContent == "" {return nil}
        if level == -1 {return nil}
    }
    
    var scrollToJavaScript: String {
        return "document.getElementById('\(id)').scrollIntoView();"
    }
}
