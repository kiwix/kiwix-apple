//
//  OutlineItem.swift
//  Kiwix
//
//  Created by Chris Li on 12/5/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

struct OutlineItem: Identifiable {
    var id: Int { index }
    let index: Int
    let text: String
    let level: Int
}
