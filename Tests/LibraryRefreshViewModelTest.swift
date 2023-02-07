//
//  LibraryRefreshViewModelTest.swift
//  Tests
//
//  Created by Chris Li on 1/16/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import CoreData
import XCTest

import Defaults
@testable import Kiwix

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

final class LibraryRefreshViewModelTest: XCTestCase {
    private var urlSession: URLSession?

    override func setUpWithError() throws {
        self.urlSession = {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [HTTPTestingURLProtocol.self]
            return URLSession(configuration: config)
        }()
    }

    override func tearDownWithError() throws {
        HTTPTestingURLProtocol.handler = nil
    }
    
    private func makeOPDSData(zimFileID: UUID) -> String {
        """
        <feed xmlns="http://www.w3.org/2005/Atom"
              xmlns:dc="http://purl.org/dc/terms/"
              xmlns:opds="http://opds-spec.org/2010/catalog">
          <entry>
            <id>urn:uuid:\(zimFileID.uuidString.lowercased())</id>
            <title>Best of Wikipedia</title>
            <updated>2023-01-07T00:00:00Z</updated>
            <summary>A selection of the best 50,000 Wikipedia articles</summary>
            <language>eng</language>
            <name>wikipedia_en_top</name>
            <flavour>maxi</flavour>
            <category>wikipedia</category>
            <tags>wikipedia;_category:wikipedia;_pictures:yes;_videos:no;_details:yes;_ftindex:yes</tags>
            <articleCount>50001</articleCount>
            <mediaCount>566835</mediaCount>
            <link rel="http://opds-spec.org/image/thumbnail"
                  href="/catalog/v2/illustration/1ec90eab-5724-492b-9529-893959520de4/"
                  type="image/png;width=48;height=48;scale=1"/>
            <link type="text/html" href="/content/wikipedia_en_top_maxi_2023-01"/>
            <author><name>Wikipedia</name></author>
            <publisher><name>Kiwix</name></publisher>
            <dc:issued>2023-01-07T00:00:00Z</dc:issued>
            <link rel="http://opds-spec.org/acquisition/open-access" type="application/x-zim"
              href="https://download.kiwix.org/zim/wikipedia/wikipedia_en_top_maxi_2023-01.zim.meta4" length="6515656704"/>
          </entry>
        </feed>
        """
    }
    
    /// Test time out fetching library data.
    @MainActor
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
    @MainActor
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
    @MainActor
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

        let viewModel = LibraryRefreshViewModel(urlSession: urlSession)
        await viewModel.start(isUserInitiated: true)

        XCTExpectFailure("Requires work in dependency to resolve the issue.")
        XCTAssertEqual(
            viewModel.error?.localizedDescription,
            "Error parsing library data."
        )
    }
    
    /// Test zim file metadata is saved
    @MainActor
    func testZimFileProperties() async throws {
        let zimFileID = UUID()
        HTTPTestingURLProtocol.handler = { urlProtocol in
            let response = HTTPURLResponse(
                url: URL(string: "https://library.kiwix.org/catalog/root.xml")!,
                statusCode: 200, httpVersion: nil, headerFields: [:]
            )!
            let data = self.makeOPDSData(zimFileID: zimFileID).data(using: .utf8)!
            urlProtocol.client?.urlProtocol(urlProtocol, didLoad: data)
            urlProtocol.client?.urlProtocol(urlProtocol, didReceive: response, cacheStoragePolicy: .notAllowed)
            urlProtocol.client?.urlProtocolDidFinishLoading(urlProtocol)
        }
        
        let viewModel = LibraryRefreshViewModel(urlSession: urlSession)
        await viewModel.start(isUserInitiated: true)
        
        // check no error has happened
        XCTAssertNil(viewModel.error)
        
        // check one zim file is in the database
        let context = Database.shared.container.viewContext
        let zimFiles = try context.fetch(ZimFile.fetchRequest())
        XCTAssertEqual(zimFiles.count, 1)
        XCTAssertEqual(zimFiles[0].id, zimFileID)
        
        // check zim file can be retrieved by id, and properties are populated
        let zimFile = try XCTUnwrap(try context.fetch(ZimFile.fetchRequest(fileID: zimFileID)).first)
        XCTAssertEqual(zimFile.id, zimFileID)
        XCTAssertEqual(zimFile.articleCount, 50001)
        XCTAssertEqual(zimFile.category, Category.wikipedia.rawValue)
        XCTAssertEqual(zimFile.created, try! Date("2023-01-07T00:00:00Z", strategy: .iso8601))
        XCTAssertEqual(
            zimFile.downloadURL,
            URL(string: "https://download.kiwix.org/zim/wikipedia/wikipedia_en_top_maxi_2023-01.zim.meta4")
        )
        XCTAssertNil(zimFile.faviconData)
        XCTAssertEqual(
            zimFile.faviconURL,
            URL(string: "https://library.kiwix.org/catalog/v2/illustration/1ec90eab-5724-492b-9529-893959520de4/")
        )
        XCTAssertEqual(zimFile.fileDescription, "A selection of the best 50,000 Wikipedia articles")
        XCTAssertEqual(zimFile.fileID, zimFileID)
        XCTAssertNil(zimFile.fileURLBookmark)
        XCTAssertEqual(zimFile.flavor, Flavor.max.rawValue)
        XCTAssertEqual(zimFile.hasDetails, true)
        XCTAssertEqual(zimFile.hasPictures, true)
        XCTAssertEqual(zimFile.hasVideos, false)
        XCTAssertEqual(zimFile.includedInSearch, true)
        XCTAssertEqual(zimFile.isMissing, false)
        XCTAssertEqual(zimFile.languageCode, "en")
        XCTAssertEqual(zimFile.mediaCount, 566835)
        XCTAssertEqual(zimFile.name, "Best of Wikipedia")
        XCTAssertEqual(zimFile.persistentID, "wikipedia_en_top")
        XCTAssertEqual(zimFile.requiresServiceWorkers, false)
        XCTAssertEqual(zimFile.size, 6515656704)
        
//        XCTAssertEqual(metadata.creator, "Wikipedia")
//        XCTAssertEqual(metadata.publisher, "Kiwix")
    }
}
