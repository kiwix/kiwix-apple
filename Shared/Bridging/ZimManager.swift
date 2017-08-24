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
    
    func addBook(path: String) {__addBook(byPath: path)}
    func addBooks(paths: [String]) {paths.forEach({__addBook(byPath: $0)})}
    func removeBooks(id: String) {__removeBook(byID: id)}
    func getReaderIDs() -> [String] {return __getReaderIdentifiers().flatMap({$0 as? String})}
    
    func getContent(bookID: String, contentPath: String) -> (data: Data, mime: String, length: Int)? {
        guard let content = __getContent(bookID, contentURL: contentPath),
            let data = content["data"] as? Data,
            let mime = content["mime"] as? String,
            let length = content["length"] as? Int else {return nil}
        return (data, mime, length)
    }
    
    func getMainPagePath(bookID: String) -> String? {
        return __getMainPageURL(bookID)
    }
    
    func getSearchSuggestions(searchTerm: String) -> [(title: String, path: String)] {
        guard let suggestions = __getSearchSuggestions(searchTerm) else {return []}
        return suggestions.flatMap { suggestion -> (String, String)? in
            guard let suggestion = suggestion as? Dictionary<String, String>,
                let title = suggestion["title"],
                let path = suggestion["path"] else {return nil}
            return (title, path)
        }
    }
    
    func getSearchResults(searchTerm: String) -> [(id: String, title: String, path: String, snippet: NSAttributedString)] {
        guard let results = __getSearchResults(searchTerm) else {return []}
        return results.flatMap { result -> (String, String, String, NSAttributedString)? in
            guard let result = result as? Dictionary<String, String>,
                let id = result["id"],
                let title = result["title"],
                let path = result["path"],
                let snippet = parseSnippet(string: result["snippet"]) else {return nil}
            return (id, title, path, snippet)
        }
    }
    
    private func parseSnippet(string: String?) -> NSAttributedString? {
        let options: [String: Any] = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                      NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue]
        guard let snippetData = string?.data(using: String.Encoding.utf8),
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
