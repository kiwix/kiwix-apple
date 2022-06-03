//
//  SearchResultRow.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 6/3/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(result.title).fontWeight(.medium)
                if let snippet = result.snippet {
                    Group {
                        if #available(iOS 15, *) {
                            Text(AttributedString(snippet))
                        } else {
                            Text(snippet.string)
                        }
                    }.font(.caption).lineLimit(4).multilineTextAlignment(.leading)
                }
            }
            Spacer()
        }
        .foregroundColor(.primary)
    }
}

struct SearchResultRow_Previews: PreviewProvider {
    static let result: SearchResult = {
        let result = SearchResult(zimFileID: UUID(), path: "", title: "Article Title")!
        result.snippet = NSAttributedString(string:
            """
            Lorem ipsum dolor sit amet, consectetur adipiscing elit, \
            sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
            """
        )
        return result
    }()
    
    static var previews: some View {
        SearchResultRow(result: SearchResultRow_Previews.result)
            .frame(width: 500)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
