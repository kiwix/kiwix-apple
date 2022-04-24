//
//  LibraryContent.swift
//  Kiwix
//
//  Created by Chris Li on 4/24/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct LibraryContent: View {
    let topic: Library.Topic
    
    var body: some View {
        switch topic {
        case .opened:
            Text("Show opened zim files")
        case .new:
            if #available(iOS 15.0, *) {
                ZimFileGrid(topic: topic)
            } else {
                ZimFileList(topic: topic)
            }
        case .downloads:
            Text("Show zim files being downloaded")
        case .categories:
            List {
                ForEach(Category.allCases.map{ Library.Topic.category($0) }) { topic in
                    NavigationLink {
                        LibraryContent(topic: topic)
                    } label: {
                        Text(topic.name)
                    }
                }
            }.listStyle(.plain)
        case .category(let category):
            if #available(iOS 15.0, *) {
                switch category {
                case .ted, .stackExchange:
                    ZimFileList(topic: topic)
                default:
                    ZimFileGrid(topic: topic)
                }
            } else {
                ZimFileList(topic: topic)
            }
        }
    }
}

struct LibraryContent_Previews: PreviewProvider {
    static var previews: some View {
        LibraryContent(topic: .new)
    }
}
