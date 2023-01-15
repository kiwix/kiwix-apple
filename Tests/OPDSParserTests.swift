//
//  Tests.swift
//  Tests
//
//  Created by Chris Li on 1/15/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import XCTest

final class OPDSParserTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    /// Test OPDSParser.parse throws error when OPDS data is invalid.
    func testInvalidOPDSData() {
        let content = "Invalid OPDS Data"
        XCTAssertNoThrow(
            try OPDSParser().parse(data: content.data(using: .utf8) ?? Data())
        )
    }
}
