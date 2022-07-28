//
//  SearchResultCell.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 6/3/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SearchResultCell: View {
    @State var isHovering: Bool = false
    
    let result: SearchResult
    let zimFile: ZimFile?
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(result.title).fontWeight(.medium)
                if let snippet = result.snippet {
                    Group {
                        if #available(iOS 15, *) {
                            Text(AttributedString(snippet))
                        } else {
                            Text(snippet.string)
                        }
                    }.font(.caption).multilineTextAlignment(.leading)
                }
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

struct SearchResultCell_Previews: PreviewProvider {
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
        SearchResultCell(result: SearchResultCell_Previews.result, zimFile: nil)
            .frame(width: 500)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
