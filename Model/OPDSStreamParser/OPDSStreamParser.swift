//
//  OPDSStreamParser.swift
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

extension OPDSStreamParser {
    var zimFileIDs: Set<UUID> {
        get { __getZimFileIDs() as? Set<UUID> ?? Set<UUID>() }
    }
    
    func parse(data: Data) throws {
        do {
            try self.__parseData(data)
        } catch {
            throw OPDSRefreshError.parse
        }
    }
    
    func getMetaData(id: UUID) -> ZimFileMetaData? {
        return __getZimFileMetaData(id)
    }
}
