//
//  SearchOperation.swift
//  Kiwix
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#if os(OSX)
    import Cocoa
#elseif os(iOS)
    import UIKit
#endif
import SwiftSoup

extension SearchOperation {
    var results: [SearchResult] { get { __results as? [SearchResult] ?? [] } }
    static private let boldFont = NSUIFont.boldSystemFont(ofSize: 12.0)
    
    open override func main() {
        __results = getSearchResults()
        
        for result in results {
            if let snippet = result.snippet {
                result.snippet = nil
                result.attributedSnippet = parse(html: snippet)
            }
        }
    }
    
    func parse(html: String) -> NSAttributedString? {
        guard let body = try? SwiftSoup.parseBodyFragment(html).body() else { return nil }
        let snippet = NSMutableAttributedString()
        for node in body.getChildNodes() {
            if let element = node as? Element, let text = try? element.text(), element.tagName() == "b" {
                snippet.append(NSAttributedString(string: text, attributes: [.font: SearchOperation.boldFont]))
            } else if let text = try? node.outerHtml() {
                snippet.append(NSAttributedString(string: text.trimmingCharacters(in: .newlines)))
            }
        }
        return snippet
    }
}
