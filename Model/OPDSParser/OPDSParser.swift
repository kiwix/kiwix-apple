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

protocol Parser {
    var zimFileIDs: Set<UUID> { get }
    @ZimActor
    func parse(data: Data, urlHost: String) throws
    func getMetaData(id: UUID) -> ZimFileMetaData?
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

    func getMetaData(id: UUID) -> ZimFileMetaData? {
        return __getZimFileMetaData(id)
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

    func getMetaData(id: UUID) -> ZimFileMetaData? {
        nil
    }
}
