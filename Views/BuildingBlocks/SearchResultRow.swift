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
    let zimFile: ZimFile?
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
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
            if let zimFile = zimFile, let category = Category(rawValue: zimFile.category) {
                Favicon(category: category, imageData: zimFile.faviconData, imageURL: zimFile.faviconURL)
                    .frame(height: 20)
            }
        }
        .foregroundColor(.primary)
    }
}

struct SearchResultRow_Previews: PreviewProvider {
    static let result: SearchResult = {
        let result = SearchResult(zimFileID: UUID(), path: "", title: "article_cell.search_result.title".localized)!
        result.snippet = NSAttributedString(string: "article_cell.search_result.snippet.template".localized)
        return result
    }()
    
    static var previews: some View {
        SearchResultRow(result: SearchResultRow_Previews.result, zimFile: nil)
            .frame(width: 500)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
