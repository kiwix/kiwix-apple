//
//  OutlineItem.swift
//  Kiwix
//
//  Created by Chris Li on 12/5/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

class OutlineItem: Identifiable {
    let id: String
    let index: Int
    let text: String
    let level: Int
    private(set) var children: [OutlineItem]?
    
    init(id: String, index: Int, text: String, level: Int) {
        self.id = id
        self.index = index
        self.text = text
        self.level = level
    }
    
    convenience init(index: Int, text: String, level: Int) {
        self.init(id: String(index), index: index, text: text, level: level)
    }
    
    func addChild(_ item: OutlineItem) {
        if children != nil {
            children?.append(item)
        } else {
            children = [item]
        }
    }
    
    @discardableResult
    func removeAllChildren() -> [OutlineItem] {
        defer { children = nil }
        return children ?? []
    }
}
