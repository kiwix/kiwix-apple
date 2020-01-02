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
    
    init?(html: String) throws {
        self.document = try SwiftSoup.parse(html)
    }
    
    convenience init?(zimFileId: String, path: String) throws {
        try self.init(html: "")
    }
    
    func getTitle() -> String? {
        do {
            let elements = try document.select("head > title")
            return try elements.first()?.text()
        } catch { return nil }
    }
    
    func getGeoCoordinate() -> CLLocationCoordinate2D? {
        do {
            let elements = try document.getElementsByAttributeValue("name", "geo.position")
            let content = try elements.first()?.attr("content")
            guard let parts = content?.split(separator: ";"), parts.count == 2,
                let lat = Double(parts[0]), let lon = Double(parts[1]) else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } catch { return nil }
    }
}
