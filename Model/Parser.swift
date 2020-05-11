//
//  Parser.swift
//  Kiwix
//
//  Created by Chris Li on 1/1/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import CoreLocation
import SwiftSoup

class Parser {
    private let document: Document
    private lazy var firstParagraph: Element? = try? document.body()?.getElementsByTag("p").first()
    
    static private let boldFont = NSUIFont.boldSystemFont(ofSize: 12.0)
    
    init(document: Document) {
        self.document = document
    }
    
    convenience init?(html: String) throws {
        self.init(document: try SwiftSoup.parse(html))
    }
    
    convenience init?(bodyFragment: String) throws {
        self.init(document: try SwiftSoup.parseBodyFragment(bodyFragment))
    }
    
    convenience init?(zimFileID: String, path: String) throws {
        guard let content = ZimMultiReader.shared.getContent(bookID: zimFileID, contentPath: path),
            let html = String(data: content.data, encoding: .utf8) else { return nil }
        try self.init(html: html)
    }
    
    func getTitle() -> String? {
        do {
            let elements = try document.select("head > title")
            return try elements.first()?.text()
        } catch { return nil }
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
    
    func getBody() -> NSAttributedString? {
        let snippet = NSMutableAttributedString()
        for node in document.body()?.getChildNodes() ?? [] {
            if let element = node as? Element, let text = try? element.text(), element.tagName() == "b" {
                snippet.append(NSAttributedString(string: text, attributes: [.font: Parser.boldFont]))
            } else if let text = try? node.outerHtml() {
                snippet.append(NSAttributedString(string: text.trimmingCharacters(in: .newlines)))
            }
        }
        return snippet
    }
    
    func getFirstParagraph() -> NSAttributedString? {
        let snippet = NSMutableAttributedString()
        for node in firstParagraph?.getChildNodes() ?? [] {
            if let element = node as? Element {
                if let className = try? element.className(), className == "mw-ref" {
                    continue
                } else if element.tagName() == "b", let text = try? element.text() {
                    snippet.append(NSAttributedString(string: text, attributes: [.font: Parser.boldFont]))
                } else if let text = try? element.text() {
                    snippet.append(NSAttributedString(string: text))
                }
            } else if let text = try? node.outerHtml() {
                snippet.append(NSAttributedString(string: text))
            }
        }
        return snippet
    }
}
