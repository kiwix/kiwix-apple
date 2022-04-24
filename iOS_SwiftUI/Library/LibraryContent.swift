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
            Text("Show newly added zim files")
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
            }
        case .category(let category):
            switch category {
            case .ted, .stackExchange:
                ZimFileList(topic: topic)
            default:
                Text("Show a specific category: \(category.description)")
            }
        }
    }
}

struct LibraryContent_Previews: PreviewProvider {
    static var previews: some View {
        LibraryContent(topic: .new)
    }
}
