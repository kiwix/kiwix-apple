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

extension OPDSParser {
    
    @ZimActor
    func parse(data: Data, urlHost: String) async throws {
        if !self.__parseData(data, using: urlHost.removingSuffix("/")) {
            throw LibraryRefreshError.parse
        }
    }
    
    @ZimActor
    func parseMeasure(data: Data, urlHost: String) throws {
        if !self.__parseData(data, using: urlHost.removingSuffix("/")) {
            throw LibraryRefreshError.parse
        }
    }
    
    @ZimActor
    func results() async -> Parsed {
        let zimFileIDs = __getZimFileIDs() as? Set<UUID> ?? Set<UUID>()
        
        var dict: [UUID: ZimFileMetaStruct] = [:]
        for uuid in zimFileIDs {
            // for parsing the whole catalog
            // we don't want to fetch the favicons
            // as it takes forever by doing one after another
            if let meta = getMetaData(id: uuid, fetchFavicon: false) {
                dict[uuid] = meta
            }
        }
        return Parsed(results: dict)
    }
    
    @ZimActor
    func resultsMeasure() -> Parsed {
        let zimFileIDs = __getZimFileIDs() as? Set<UUID> ?? Set<UUID>()
        
        var dict: [UUID: ZimFileMetaStruct] = [:]
        for uuid in zimFileIDs {
            // for parsing the whole catalog
            // we don't want to fetch the favicons
            // as it takes forever by doing one after another
            if let meta = getMetaData(id: uuid, fetchFavicon: false) {
                dict[uuid] = meta
            }
        }
        return Parsed(results: dict)
    }
    
    @ZimActor
    func getMetaData(id: UUID, fetchFavicon: Bool) -> ZimFileMetaStruct? {
        ZimFileService.metaStruct(from: __getZimFileMetaData(id, fetchFavicon: fetchFavicon))
    }
}
