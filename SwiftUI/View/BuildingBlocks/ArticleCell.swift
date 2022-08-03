//
//  ArticleCell.swift
//  Kiwix
//
//  Created by Chris Li on 6/3/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct ArticleCell: View {
    @State var isHovering: Bool = false
    
    let title: String
    let snippet: NSAttributedString?
    let zimFile: ZimFile?
    
    init(bookmark: Bookmark) {
        self.title = bookmark.title
        if let snippet = bookmark.snippet {
            self.snippet = NSAttributedString(string: snippet)
        } else {
            self.snippet = nil
        }
        self.zimFile = bookmark.zimFile
    }
    
    init(result: SearchResult, zimFile: ZimFile?) {
        self.title = result.title
        self.snippet = result.snippet
        self.zimFile = zimFile
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title).fontWeight(.medium)
                Spacer().frame(height: 2)
                Group {
                    if let snippet = snippet {
                        if #available(iOS 15, *) {
                            Text(AttributedString(snippet)).lineLimit(4)
                        } else {
                            Text(snippet.string).lineLimit(4)
                        }
                    } else {
                        Text("No snippet").foregroundColor(.secondary)
                    }
                }.font(.caption).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            Spacer()
            if let zimFile = zimFile, let category = Category(rawValue: zimFile.category) {
                Favicon(category: category, imageData: zimFile.faviconData, imageURL: zimFile.faviconURL)
                    .frame(height: 20)
            }
        }
        .foregroundColor(.primary)
        .padding(12)
        .modifier(CellBackground(isHovering: isHovering))
        .onHover { self.isHovering = $0 }
    }
}

struct ArticleCell_Previews: PreviewProvider {
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
        ArticleCell(result: ArticleCell_Previews.result, zimFile: nil)
            .frame(width: 500)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
