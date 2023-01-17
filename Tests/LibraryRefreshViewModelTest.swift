//
//  LibraryRefreshViewModelTest.swift
//  Tests
//
//  Created by Chris Li on 1/16/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

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
//            client?.urlProtocol(self, didFailWithError: URLError(URLError.Code.timedOut))
        }
    }
}

final class LibraryRefreshViewModelTest: XCTestCase {
    private var urlSession: URLSession?

    override func setUpWithError() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [HTTPTestingURLProtocol.self]
        self.urlSession = URLSession(configuration: config)
    }

    override func tearDownWithError() throws {
        HTTPTestingURLProtocol.handler = nil
    }
    
    func testFetchError() async throws {
        HTTPTestingURLProtocol.handler = { urlProtocol in
            urlProtocol.client?.urlProtocol(urlProtocol, didFailWithError: URLError(URLError.Code.timedOut))
        }
        
        let viewModel = LibraryRefreshViewModel(urlSession: urlSession)
        await viewModel.start()
        XCTAssert(viewModel.error is LibraryRefreshError)
        XCTAssert(viewModel.error!.localizedDescription
            .hasPrefix("Error retrieving library data. The operation couldn’t be completed."))
    }

    func testFetchBadStatusCode() throws {
    }
}
