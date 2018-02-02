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


class SearchResult: Equatable, Hashable, CustomStringConvertible {
    let zimFileID: ZimFileID
    let url: URL
    let title: String
    let probability: Double?
    let snippet: String?
    let attributedSnippet: NSAttributedString?
    
    init?(zimFileID: ZimFileID, path: String, title: String, probability: Double? = nil, snippet: String? = nil) {
        guard let url = URL(bookID: zimFileID, contentPath: path) else {return nil}
        self.zimFileID = zimFileID
        self.url = url
        self.title = title
        self.probability = probability
        
        guard let snippet = snippet, snippet != "" else {
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
    
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.url.absoluteString == rhs.url.absoluteString
    }
    
    var hashValue: Int {
        return url.absoluteString.hashValue
    }
    
    var description: String {
        return url.absoluteString
    }
}
