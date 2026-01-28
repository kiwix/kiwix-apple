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

import XCTest
@testable import Kiwix

final class OPDSParserTests: XCTestCase {
    /// Test OPDSParser.parse throws error when OPDS data is invalid.
    @ZimActor
    func testInvalidOPDSData() {
        let content = "Invalid OPDS Data"
        XCTAssertThrowsError(
            try OPDSParser().parse(data: content.data(using: .utf8)!, urlHost: "")
        )
    }

    @ZimActor
    func testNonCompatibleDataWithUT8() throws {
        let content = "any data"
        let incompatibleEncodings: [String.Encoding] = [.unicode, .utf16, .utf32]
        try incompatibleEncodings.forEach { encoding in
            XCTAssertThrowsError(
                try OPDSParser().parse(data: content.data(using: encoding)!, urlHost: ""),
                "parsing with enconding \(encoding.description) should fail"
            )
        }
    }

    /// Test OPDSParser.getMetaData returns nil when no metadata available with the given ID.
    func testMetadataNotFound() async {
        let zimFileID = UUID(uuidString: "1ec90eab-5724-492b-9529-893959520de4")!
        let metadata = await OPDSParser().getMetaData(id: zimFileID, fetchFavicon: false)
        XCTAssertNil(metadata)
    }

    /// Test OPDSParser can parse and extract zim file metadata.
    @ZimActor
    func test() throws {
        let content = """
        <feed xmlns="http://www.w3.org/2005/Atom"
              xmlns:dc="http://purl.org/dc/terms/"
              xmlns:opds="http://opds-spec.org/2010/catalog">
          <entry>
            <id>urn:uuid:1ec90eab-5724-492b-9529-893959520de4</id>
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
        
        // Parse data
        let responseTestURL = URL(string: "https://resp-test.org/")!
        let parser = OPDSParser()
        XCTAssertNoThrow(
            try parser.parse(
                data: content.data(using: .utf8)!,
                urlHost: responseTestURL.absoluteString
            )
        )

        // check one zim file is populated
        let zimFileID = UUID(uuidString: "1ec90eab-5724-492b-9529-893959520de4")!
        XCTAssertEqual(parser.zimFileIDs, Set([zimFileID]))

        // check zim file metadata
        let metadata = try XCTUnwrap(parser.getMetaData(id: zimFileID, fetchFavicon: false))
        XCTAssertEqual(metadata.fileID, zimFileID)
        XCTAssertEqual(metadata.groupIdentifier, "wikipedia_en_top")
        XCTAssertEqual(metadata.title, "Best of Wikipedia")
        XCTAssertEqual(metadata.fileDescription, "A selection of the best 50,000 Wikipedia articles")
        // !important make sure the language code is put into the DB as a 3 letter string
        XCTAssertEqual(metadata.languageCodes, "eng")
        XCTAssertEqual(metadata.category, "wikipedia")
        XCTAssertEqual(metadata.creationDate, try! Date("2023-01-07T00:00:00Z", strategy: .iso8601))
        XCTAssertEqual(metadata.size, 6515656704)
        XCTAssertEqual(metadata.articleCount, 50001)
        XCTAssertEqual(metadata.mediaCount, 566835)
        XCTAssertEqual(metadata.creator, "Wikipedia")
        XCTAssertEqual(metadata.publisher, "Kiwix")
        XCTAssertEqual(metadata.hasDetails, true)
        XCTAssertEqual(metadata.hasPictures, true)
        XCTAssertEqual(metadata.hasVideos, false)
        XCTAssertEqual(metadata.requiresServiceWorkers, false)

        XCTAssertEqual(
            metadata.downloadURL,
            URL(string: "https://download.kiwix.org/zim/wikipedia/wikipedia_en_top_maxi_2023-01.zim.meta4")
        )
        XCTAssertEqual(
            metadata.faviconURL,
            URL(string: "https://resp-test.org/catalog/v2/illustration/1ec90eab-5724-492b-9529-893959520de4/")
        )
        XCTAssertEqual(metadata.flavor, "maxi")
    }
}
