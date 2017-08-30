//
//  ZimManager.swift
//  Kiwix
//
//  Created by Chris Li on 8/21/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import AppKit

extension ZimManager {
    class var shared: ZimManager {return ZimManager.__sharedInstance()}
    
    func addBook(url: URL) {__addBook(by: url)}
    func addBook(urls: [URL]) {urls.forEach({__addBook(by: $0)})}
    func removeBook(id: String) {__removeBook(byID: id)}
    func removeBooks() {__removeAllBooks()}
    func getReaderIDs() -> [String] {return __getReaderIdentifiers().flatMap({$0 as? String})}
    
    func getContent(bookID: String, contentPath: String) -> (data: Data, mime: String, length: Int)? {
        guard let content = __getContent(bookID, contentURL: contentPath),
            let data = content["data"] as? Data,
            let mime = content["mime"] as? String,
            let length = content["length"] as? Int else {return nil}
        return (data, mime, length)
    }
    
    func getMainPageURL(bookID: String) -> URL? {
        guard let path = __getMainPageURL(bookID) else {return nil}
        return URL(bookID: bookID, contentPath: path)
    }
    
    func startSearch(term: String) {__startSearch(term)}
    
    func getNextSearchResult() -> SearchResult? {
        guard let result = __getNextSearchResult() as? Dictionary<String, String>,
            let id = result["id"],
            let path = result["path"],
            let title = result["title"],
            let snippet = result["snippet"] else {return nil}
        return SearchResult(bookID: id, path: path, title: title, snippet: snippet)
    }
    
    func getSearchSuggestions(term: String) -> [SearchResult] {
        guard let suggestions = __getSearchSuggestions(term) else {return []}
        return suggestions.flatMap { suggestion -> SearchResult? in
            guard let suggestion = suggestion as? Dictionary<String, String>,
                let id = suggestion["id"],
                let title = suggestion["title"],
                let path = suggestion["path"] else {return nil}
            return SearchResult(bookID: id, path: path, title: title)
        }
    }
}

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
        let options: [String: Any] = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                      NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue]
        guard let snippetData = html.data(using: String.Encoding.utf8),
            let snippet = try? NSMutableAttributedString(data: snippetData, options: options, documentAttributes: nil) else {return nil}
        let wholeRange = NSRange(location: 0, length: snippet.length)
        snippet.enumerateAttribute(NSFontAttributeName, in: wholeRange, options: .longestEffectiveRangeNotRequired, using: { (font, range, stop) in
            guard let font = font as? NSFont else {return}
            let traits = font.fontDescriptor.symbolicTraits
            let isBold = NSFontTraitMask(rawValue: UInt(traits)).contains(.boldFontMask)
            let newFont: NSFont = {
                if #available(OSX 10.11, *) {
                    return NSFont.systemFont(ofSize: 12, weight: isBold ? NSFontWeightSemibold : NSFontWeightRegular)
                } else {
                    return isBold ? NSFont.boldSystemFont(ofSize: 12) : NSFont.systemFont(ofSize: 12)
                }
            }()
            snippet.addAttribute(NSFontAttributeName, value: newFont, range: range)
        })
        snippet.addAttribute(NSForegroundColorAttributeName, value: NSColor.labelColor, range: wholeRange)
        return snippet
    }
    
}
