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

@ZimActor
protocol Parser {
    var zimFileIDs: Set<UUID> { get }
    func parse(data: Data, urlHost: String) throws
    func getMetaData(id: UUID, fetchFavicon: Bool) -> ZimFileMetaStruct?
}

extension OPDSParser: Parser {
    var zimFileIDs: Set<UUID> {
        __getZimFileIDs() as? Set<UUID> ?? Set<UUID>()
    }

    @ZimActor
    func parse(data: Data, urlHost: String) throws {
        if !self.__parseData(data, using: urlHost.removingSuffix("/")) {
            throw LibraryRefreshError.parse
        }
    }

    @ZimActor
    func getMetaData(id: UUID, fetchFavicon: Bool) -> ZimFileMetaStruct? {
        guard let metadata = __getZimFileMetaData(id, fetchFavicon: fetchFavicon) else {
            return nil
        }
        return ZimFileMetaStruct(
            fileID: metadata.fileID,
            groupIdentifier: metadata.groupIdentifier,
            title: metadata.title,
            fileDescription: metadata.fileDescription,
            languageCodes: metadata.languageCodes,
            category: metadata.category,
            creationDate: metadata.creationDate,
            size: Int64(truncating: metadata.size),
            articleCount: Int64(truncating: metadata.articleCount),
            mediaCount: Int64(truncating: metadata.mediaCount),
            creator: metadata.creator,
            publisher: metadata.publisher,
            downloadURL: metadata.downloadURL,
            faviconURL: metadata.faviconURL,
            faviconData: metadata.faviconData,
            flavor: metadata.flavor,
            hasDetails: metadata.hasDetails,
            hasPictures: metadata.hasPictures,
            hasVideos: metadata.hasVideos,
            requiresServiceWorkers: metadata.requiresServiceWorkers
        )
    }
}

/// An empty Parser we can use to delete zim entries
/// Based on the assumption we insert new ones, delete the ones not on the list
/// Therefore an empty list will delete everything, using the same method
/// @see: LibraryViewModel.process(parser: Parser)
struct DeletingParser: Parser {
    let zimFileIDs: Set<UUID> = .init()

    func parse(data: Data, urlHost: String) throws {
    }

    func getMetaData(id: UUID, fetchFavicon: Bool) -> ZimFileMetaStruct? {
        nil
    }
}
