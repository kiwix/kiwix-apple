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

import CoreLocation
import NaturalLanguage
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

import Fuzi

class HTMLParser {
    private let document: HTMLDocument

    #if os(macOS)
    static private let boldFont = NSFont.systemFont(ofSize: 12.0, weight: .medium)
    #elseif os(iOS)
    static private let boldFont = UIFont.systemFont(ofSize: 12.0, weight: .medium)
    #endif

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
            if let element = child as? Fuzi.XMLElement, element.attributes["class"]?.contains("mw-ref") == true {
                continue
            } else if let element = child as? Fuzi.XMLElement {
                let attributedSting = NSAttributedString(
                    string: element.stringValue.replacingOccurrences(of: "\n", with: ""),
                    attributes: element.tag == "b" ? [.font: HTMLParser.boldFont] : nil
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
        return (try? HTMLParser(html: html))?.getFirstParagraph()
    }
}
