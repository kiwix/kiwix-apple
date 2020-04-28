//
//  OPDSStreamParser.swift
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

extension OPDSStreamParser {
    var zimFileIDs: [String] { get{ return __getZimFileIDs().compactMap({$0 as? String}) } }
    
    func parse(data: Data) throws {
        do {
            try self.__parseData(data)
        } catch {
            throw OPDSRefreshError.parse
        }
    }
    
    func getZimFileMetaData(id: String) -> ZimFileMetaData? {
        return __getZimFileMetaData(id)
    }
}
