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
import Testing
@testable import Kiwix

@MainActor
struct TableOfContentsTests {
    
    @Test(arguments: [ [[String: String]()], [] ])
    func isEmptyFor(headings: [[String: String]]) async throws {
        let tree = TableOfContents.generateOutlineTree(headings: headings, articleTitle: "testing")
        #expect(tree.isEmpty)
    }
    
    @Test
    func dropHeaderIfSameAsTitle() async throws {
        let title = "Documentation Ubuntu"
        let headings: [[String: String]] = [
            ["tag": "H1", "id": "documentation_ubuntu", "text": title],
            ["tag": "H3", "id": "outils-pour-utilisateurs", "text": "Outils pour utilisateurs"],
            ["tag": "H3", "id": "outils-du-site", "text": "Outils du site"],
            ["tag": "H3", "id": "outils-de-la-page", "text": "Outils de la page"],
            ["tag": "H3", "id": "drivers", "text": "Drivers"]
        ]
        let tree = TableOfContents.generateOutlineTree(headings: headings, articleTitle: title)
        #expect(tree.count == 4)
    }
    
    @Test
    func invalidTag() async throws {
        let title = "Documentation Ubuntu"
        let headings: [[String: String]] = [
            ["tag": "H1", "id": "documentation_ubuntu", "text": title],
            ["tag": "H0", "id": "outils-pour-utilisateurs", "text": "Outils pour utilisateurs"],
            ["tag": "H3", "id": "outils-du-site", "text": "Outils du site"],
            ["tag": "H3", "id": "outils-de-la-page", "text": "Outils de la page"],
            ["tag": "H9999", "id": "drivers", "text": "Drivers"]
        ]
        let tree = TableOfContents.generateOutlineTree(headings: headings, articleTitle: title)
        #expect(tree.count == 2)
        #expect(tree.first?.id == "documentation_ubuntu")
        #expect(tree.last?.id == "outils-pour-utilisateurs")
        #expect(tree.last?.level == 1)
        #expect(tree.last?.children?.count == 2)
        #expect(tree.last?.children?.last?.children?.count == 1)
        #expect(tree.last?.children?.last?.children?.first?.level == 6)
        #expect(tree.last?.children?.last?.children?.first?.id == "drivers")
    }
}
