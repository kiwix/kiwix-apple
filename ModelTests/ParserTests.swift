//
//  ParserTest.swift
//  ParserTest
//
//  Created by Chris Li on 1/1/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import XCTest
import CoreLocation

class TitleTest: XCTestCase {
    func test() {
        [
            ("<html><head><title>I am a title!</title></head></html>", "I am a title!"),
            ("<html><head></head></html>", nil),
        ].forEach { html, expected in
            let parser = try? Parser(html: html)
            let title = parser?.getTitle()
            XCTAssert(title == expected)
        }
    }
}

class GeoCoordinateTest: XCTestCase {
    func testSuccess() {
        let html = "<html><head><meta name='geo.position' content='42.10833333;-72.07916667'></head></html>"
        let parser = try? Parser(html: html)
        let coordinate = parser?.getGeoCoordinate()
        assert(coordinate?.latitude == 42.10833333)
        assert(coordinate?.longitude == -72.07916667)
    }
    
    func testFailure() {
        [
            "<html><head><meta name='geo.position' content='-72.07916667'></head></html>",
            "<html><head><meta name='geo.position' content='42.10833333'></head></html>",
            "<html><head><h1>I am a header</h1></head></html>"
        ].forEach { html in
            let parser = try? Parser(html: html)
            let coordinate = parser?.getGeoCoordinate()
            XCTAssertNil(coordinate)
        }
    }
}
