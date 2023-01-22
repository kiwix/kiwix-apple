//
//  LibraryRefreshViewModelTest.swift
//  Tests
//
//  Created by Chris Li on 1/16/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import CoreData
import XCTest

import Kiwix

private class HTTPTestingURLProtocol: URLProtocol {
    static var handler: ((URLProtocol) -> Void)? = nil
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() { }
    
    override func startLoading() {
        if let handler = HTTPTestingURLProtocol.handler {
            handler(self)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}

private class PersistentContainer: NSPersistentContainer {
    convenience init(inMemory: Bool = false) {
        self.init(name: "DataModel")
        guard let description = persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        loadPersistentStores { description, error in
            
        }
    }
}

final class LibraryRefreshViewModelTest: XCTestCase {
    private var urlSession: URLSession?
    private var container: NSPersistentContainer?

    override func setUpWithError() throws {
        self.urlSession = {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [HTTPTestingURLProtocol.self]
            return URLSession(configuration: config)
        }()
        let container = PersistentContainer(inMemory: true)
    }

    override func tearDownWithError() throws {
        HTTPTestingURLProtocol.handler = nil
        container = nil
    }
    
    /// Test time out fetching library data.
    func testFetchTimeOut() async {
        HTTPTestingURLProtocol.handler = { urlProtocol in
            urlProtocol.client?.urlProtocol(urlProtocol, didFailWithError: URLError(URLError.Code.timedOut))
        }
        
        let viewModel = LibraryRefreshViewModel(urlSession: urlSession)
        await viewModel.start(isUserInitiated: true)
        XCTAssert(viewModel.error is LibraryRefreshError)
        XCTAssertEqual(
            viewModel.error?.localizedDescription,
            "Error retrieving library data. The operation couldn’t be completed. (NSURLErrorDomain error -1001.)"
        )
    }

    /// Test fetching library data response contains non-success status code.
    func testFetchBadStatusCode() async {
        HTTPTestingURLProtocol.handler = { urlProtocol in
            let response = HTTPURLResponse(
                url: URL(string: "https://library.kiwix.org/catalog/root.xml")!,
                statusCode: 404, httpVersion: nil, headerFields: [:]
            )!
            urlProtocol.client?.urlProtocol(urlProtocol, didReceive: response, cacheStoragePolicy: .notAllowed)
            urlProtocol.client?.urlProtocolDidFinishLoading(urlProtocol)
        }
        
        let viewModel = LibraryRefreshViewModel(urlSession: urlSession)
        await viewModel.start(isUserInitiated: true)
        XCTAssert(viewModel.error is LibraryRefreshError)
        XCTAssertEqual(
            viewModel.error?.localizedDescription,
            "Error retrieving library data. HTTP Status 404."
        )
    }
    
    /// Test OPDS data is invalid.
    func testInvalidOPDSData() async {
        HTTPTestingURLProtocol.handler = { urlProtocol in
            let response = HTTPURLResponse(
                url: URL(string: "https://library.kiwix.org/catalog/root.xml")!,
                statusCode: 200, httpVersion: nil, headerFields: [:]
            )!
            urlProtocol.client?.urlProtocol(urlProtocol, didLoad: "Invalid OPDS Data".data(using: .utf8)!)
            urlProtocol.client?.urlProtocol(urlProtocol, didReceive: response, cacheStoragePolicy: .notAllowed)
            urlProtocol.client?.urlProtocolDidFinishLoading(urlProtocol)
        }
        
        let viewModel = LibraryRefreshViewModel(urlSession: urlSession, context: container?.viewContext)
        await viewModel.start(isUserInitiated: true)
        
        XCTExpectFailure("Requires work in dependency to resolve the issue.")
        XCTAssertEqual(
            viewModel.error?.localizedDescription,
            "Error retrieving library data. HTTP Status 404."
        )
    }
    
    func testNewZimFile() {
        
    }
}
