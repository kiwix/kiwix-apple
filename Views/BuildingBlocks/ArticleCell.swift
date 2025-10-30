// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import SwiftUI

/// A rounded rect cell displaying preview of an article.
struct ArticleCell: View {
    @State private var isHovering: Bool = false

    let title: String
    let snippet: NSAttributedString?
    let zimFile: ZimFile?
    private let imageName: String?

    init(bookmark: Bookmark) {
        title = bookmark.title
        snippet = nil
        zimFile = bookmark.zimFile
        imageName = nil
    }

    init(result: SearchResult, zimFile: ZimFile?) {
        title = result.title
        snippet = result.snippet
        self.zimFile = zimFile
        imageName = nil
    }
    
    init(searchSuggestion: String) {
        title = searchSuggestion
        snippet = nil
        zimFile = nil
        imageName = "magnifyingglass"
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title).fontWeight(.medium).lineLimit(1)
                Spacer().frame(height: 2)
                Group {
                    if let snippet = snippet {
                        Text(AttributedString(snippet)
                            .settingAttributes(AttributeContainer([.foregroundColor: Color.primary])))
                            .lineLimit(4)
                    }
                }.font(.caption).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            Spacer()
            if let imageName {
                Image(systemName: imageName)
            } else if let zimFile = zimFile, let category = Category(rawValue: zimFile.category) {
                Favicon(category: category, imageData: zimFile.faviconData, imageURL: zimFile.faviconURL)
                    .frame(height: 20)
            }
        }
        .foregroundColor(.primary)
        .padding(12)
        .background(CellBackground.colorFor(isHovering: isHovering))
        .clipShape(CellBackground.clipShapeRectangle)
        .onHover { self.isHovering = $0 }
    }
}

struct ArticleCell_Previews: PreviewProvider {
    
    static let result: SearchResult = {
        let result = SearchResult(zimFileID: UUID(), path: "", title: "Article Title")!
        result.snippet = NSAttributedString(string: """
                    Lorem ipsum dolor sit amet, consectetur adipiscing elit, \
                    sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
                    """)
        return result
    }()

    static var previews: some View {
        ArticleCell(result: ArticleCell_Previews.result, zimFile: nil)
            .frame(width: 500, height: 100)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
