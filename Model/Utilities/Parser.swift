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
import SwiftSoup
import Fuzi

class Parser {
    private let document: Document
    private lazy var firstParagraph: Element? = try? document.body()?.getElementsByTag("p").first()
    
    static private let boldFont = NSUIFont.systemFont(ofSize: 12.0, weight: .medium)
    
    init(document: Document) {
        self.document = document
    }
    
    convenience init(html: String) throws {
        self.init(document: try SwiftSoup.parse(html))
    }
    
    convenience init(zimFileID: String, path: String) throws {
        guard let data = ZimFileService.shared.getData(zimFileID: zimFileID, contentPath: path),
            let html = String(data: data, encoding: .utf8) else { throw NSError() }
        try self.init(html: html)
    }

    func getGeoCoordinate() -> CLLocationCoordinate2D? {
        do {
            let elements = try document.select("head > meta[name='geo.position']")
            let content = try elements.first()?.attr("content")
            guard let parts = content?.split(separator: ";"), parts.count == 2,
                let lat = Double(parts[0]), let lon = Double(parts[1]) else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } catch { return nil }
    }
    
    func getOutlineItems() -> [OutlineItem] {
        var items = [OutlineItem]()
        do {
            let elements = try document.select("h1, h2, h3, h4, h5, h6")
            for (index, element) in elements.enumerated() {
                guard let level = Int(element.tagName().suffix(1)), let text = try? element.text() else { continue }
                let item = OutlineItem(index: index, text: text, level: level)
                items.append(item)
            }
        } catch { }
        return items
    }
    
    class func parseBodyFragment(_ bodyFragment: String) -> NSAttributedString? {
        let snippet = NSMutableAttributedString()
        let document = try? SwiftSoup.parseBodyFragment(bodyFragment)
        for node in document?.body()?.getChildNodes() ?? [] {
            if let element = node as? Element, let text = try? element.text(), element.tagName() == "b" {
                snippet.append(NSAttributedString(string: text, attributes: [.font: Parser.boldFont]))
            } else if let text = try? node.outerHtml() {
                snippet.append(NSAttributedString(string: text.trimmingCharacters(in: .newlines)))
            }
        }
        return snippet
    }
}

class Parser2 {
    private let document: HTMLDocument
    
    static private let boldFont = NSUIFont.systemFont(ofSize: 12.0, weight: .medium)
    
    init(document: HTMLDocument) {
        self.document = document
    }
    
    convenience init(html: Data) throws {
        self.init(document: try HTMLDocument(data: html))
    }
    
    convenience init(zimFileID: String, path: String) throws {
        guard let data = ZimFileService.shared.getData(zimFileID: zimFileID, contentPath: path) else { throw NSError() }
        try self.init(html: data)
    }
    
    func getTitle() -> String? {
        document.title
    }
    
    func getFirstParagraph() -> NSAttributedString? {
        guard let firstParagraph = document.firstChild(xpath: "//p") else { return nil }
        let snippet = NSMutableAttributedString()
        for child in firstParagraph.childNodes(ofTypes: [.Text, .Element]) {
            if let element = child as? XMLElement {
                let attributedSting = NSAttributedString(
                    string: element.stringValue,
                    attributes: element.tag == "b" ? [.font: Parser2.boldFont] : nil
                )
                snippet.append(attributedSting)
            } else {
                snippet.append(NSAttributedString(string: child.stringValue))
            }
        }
        return snippet.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : snippet
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

    class func test() {
        let url = URL(string: "kiwix://aca10302-c60d-f47e-1733-4a6ae9d88c07/A/Global_catastrophic_risk")!
        let content = ZimFileService.shared.getURLContent(url: url)!.data
        let t = (try! Parser2(html: content)).getFirstParagraph()
        print(t)
    }
}
