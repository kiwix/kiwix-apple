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

import Foundation

final class OutlineItem: ObservableObject, Identifiable {
    let id: String
    let index: Int
    let text: String
    let level: Int
    private(set) var children: [OutlineItem]?

    @Published var isExpanded = true

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

enum TableOfContents {
    /// Convert flattened heading element data to a tree of OutlineItems.
    /// - Parameter headings: list of heading element data retrieved from webview
    /// - Parameter articleTitle: of the page
    /// - Returns: A tree of outline items
    @MainActor static func generateOutlineTree(headings: [[String: String]], articleTitle: String) -> [OutlineItem] {
        let root = OutlineItem(index: -1, text: "", level: 0)
        var stack: [OutlineItem] = [root]

        headings.enumerated().forEach { index, heading in
            guard let id = heading["id"],
                  let text = heading["text"],
                  let tag = heading["tag"], let level = Int(tag.suffix(1)) else { return }
            let item = OutlineItem(id: id, index: index, text: text, level: min(6, max(level, 1)))

            // get last item in stack
            // if last item is child of item's sibling, unwind stack until a sibling is found
            guard var lastItem = stack.last else { return }
            while lastItem.level > item.level {
                stack.removeLast()
                lastItem = stack[stack.count - 1]
            }

            // if item is last item's sibling, add item to parent and replace last item with itself in stack
            // if item is last item's child, add item to parent and add item to stack
            if lastItem.level == item.level {
                stack[stack.count - 2].addChild(item)
                stack[stack.count - 1] = item
            } else if lastItem.level < item.level {
                stack[stack.count - 1].addChild(item)
                stack.append(item)
            }
        }

        // if there is only one item at top level, with the same text as the article title
        // do not display it only it's children
        if let rootChildren = root.children, rootChildren.count == 1,
            let rootFirstChild = rootChildren.first,
           rootFirstChild.text.lowercased() == articleTitle.lowercased() {
            return rootFirstChild.children ?? []
        } else {
            return root.children ?? []
        }
    }
}
