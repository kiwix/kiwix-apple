//
//  Parser.swift
//  Kiwix
//
//  Created by Chris Li on 1/1/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import CoreLocation
#if canImport(NaturalLanguage)
    import NaturalLanguage
#endif
import Fuzi

class Parser {
    private let document: HTMLDocument
    
    static private let boldFont = NSUIFont.systemFont(ofSize: 12.0, weight: .medium)
    
    init(document: HTMLDocument) {
        self.document = document
    }
    
    convenience init(html: String) throws {
        self.init(document: try HTMLDocument(string: html))
    }
    
    convenience init(data: Data) throws {
        self.init(document: try HTMLDocument(data: data))
    }
    
    convenience init(url: URL) throws {
        guard let content = ZimFileService.shared.getURLContent(url: url) else { throw NSError() }
        try self.init(data: content.data)
    }
    
    var title: String? { document.title }
    
    func getFirstParagraph() -> NSAttributedString? {
        guard let firstParagraph = document.firstChild(xpath: "//p") else { return nil }
        let snippet = NSMutableAttributedString()
        for child in firstParagraph.childNodes(ofTypes: [.Text, .Element]) {
            if let element = child as? XMLElement, element.attributes["class"]?.contains("mw-ref") == true {
                continue
            } else if let element = child as? XMLElement {
                let attributedSting = NSAttributedString(
                    string: element.stringValue.replacingOccurrences(of: "\n", with: ""),
                    attributes: element.tag == "b" ? [.font: Parser.boldFont] : nil
                )
                snippet.append(attributedSting)
            } else {
                let text = child.stringValue.replacingOccurrences(of: "\n", with: "")
                snippet.append(NSAttributedString(string: text))
            }
        }
        return snippet.length > 0 ? snippet : nil
    }
    
    func getFirstSentence(languageCode: String?) -> NSAttributedString? {
        guard let firstParagraph = self.getFirstParagraph() else { return nil }
        let text = firstParagraph.string
        var firstSentence: NSAttributedString?
        
        let tokenizer = NLTokenizer(unit: .sentence)
        if let languageCode = languageCode {tokenizer.setLanguage(NLLanguage(languageCode))}
        tokenizer.string = text
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            firstSentence = firstParagraph.attributedSubstring(from: NSRange(range, in: firstParagraph.string))
            return false
        }
        return firstSentence
    }
    
    func getFirstImagePath() -> String? {
        guard let firstImage = document.firstChild(xpath: "//img") else { return nil }
        return firstImage.attributes["src"]
    }
    
    func getOutlineItems() -> [OutlineItem] {
        document.css("h1, h2, h3, h4, h5, h6").enumerated().compactMap { index, element in
            guard let tag = element.tag, let level = Int(tag.suffix(1)) else { return nil }
            let text = element.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            return OutlineItem(index: index, text: text, level: level)
        }
    }
    
//    func getGeoCoordinate() -> CLLocationCoordinate2D? {
//        do {
//            let elements = try document.select("head > meta[name='geo.position']")
//            let content = try elements.first()?.attr("content")
//            guard let parts = content?.split(separator: ";"), parts.count == 2,
//                let lat = Double(parts[0]), let lon = Double(parts[1]) else { return nil }
//            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
//        } catch { return nil }
//    }
    
    class func parseBodyFragment(_ bodyFragment: String) -> NSAttributedString? {
        let html = "<!DOCTYPE html><html><head></head><body><p>\(bodyFragment)</p></body></html>"
        return (try? Parser(html: html))?.getFirstParagraph()
    }
}
