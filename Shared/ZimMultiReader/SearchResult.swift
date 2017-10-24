//
//  SearchResult.swift
//  Kiwix
//
//  Created by Chris Li on 9/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

#if os(OSX)
    import Cocoa
#elseif os(iOS)
    import UIKit
#endif


class SearchResult {
    let url: URL
    let title: String
    let snippet: String?
    let attributedSnippet: NSAttributedString?
    
    var hasSnippet: Bool {
        return snippet != nil || attributedSnippet != nil
    }
    
    init?(bookID: String, path: String, title: String, snippet: String? = nil) {
        guard let url = URL(bookID: bookID, contentPath: path) else {return nil}
        self.url = url
        self.title = title
        
        guard let snippet = snippet else {
            self.snippet = nil
            self.attributedSnippet = nil
            return
        }
        if snippet.contains("<b>"), let snippet = SearchResult.parseSnippet(html: snippet) {
            self.snippet = nil
            self.attributedSnippet = snippet
        } else {
            self.snippet = snippet
            self.attributedSnippet = nil
        }
    }
    
    private static func parseSnippet(html: String) -> NSAttributedString? {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType: NSAttributedString.DocumentType.html,
                                                                           .characterEncoding: String.Encoding.utf8.rawValue]
        guard let snippetData = html.data(using: .utf8),
            let snippet = try? NSMutableAttributedString(data: snippetData, options: options, documentAttributes: nil) else {return nil}
        let wholeRange = NSRange(location: 0, length: snippet.length)
        #if os(OSX)
            snippet.enumerateAttribute(NSAttributedStringKey.font, in: wholeRange, options: .longestEffectiveRangeNotRequired, using: { (font, range, stop) in
                guard let font = font as? NSFont else {return}
                let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
                let newFont: NSFont = {
                    if #available(OSX 10.11, *) {
                        return NSFont.systemFont(ofSize: 12, weight: isBold ? .semibold : .regular)
                    } else {
                        return isBold ? NSFont.boldSystemFont(ofSize: 12) : NSFont.systemFont(ofSize: 12)
                    }
                }()
                snippet.addAttribute(NSAttributedStringKey.font, value: newFont, range: range)
            })
            snippet.addAttribute(NSAttributedStringKey.foregroundColor, value: NSColor.labelColor, range: wholeRange)
        #elseif os(iOS)
            snippet.enumerateAttribute(NSAttributedStringKey.font, in: wholeRange, options: .longestEffectiveRangeNotRequired, using: { (font, range, stop) in
                guard let font = font as? UIFont else {return}
                let isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
                let newFont = UIFont.systemFont(ofSize: 12, weight: isBold ? .semibold : .regular)
                snippet.addAttribute(NSAttributedStringKey.font, value: newFont, range: range)
            })
            snippet.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.darkText, range: wholeRange)
        #endif
        
        return snippet
    }
}
