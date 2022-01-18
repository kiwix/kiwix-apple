//
//  OutlineItem.swift
//  Kiwix
//
//  Created by Chris Li on 12/5/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

class OutlineItem: Identifiable {
    var id: Int { index }
    let index: Int
    let text: String
    let level: Int
    private(set) var children: [OutlineItem]?
    
    init(index: Int, text: String, level: Int) {
        self.index = index
        self.text = text
        self.level = level
    }
    
    func addChild(_ item: OutlineItem) {
        if children != nil {
            children?.append(item)
        } else {
            children = [item]
        }
    }
}
