//
//  OPDSParser.swift
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2023 Chris Li. All rights reserved.
//

protocol Parser {
    var zimFileIDs: Set<UUID> { get }
    func parse(data: Data) throws
    func getMetaData(id: UUID) -> ZimFileMetaData?
}

extension OPDSParser: Parser {
    var zimFileIDs: Set<UUID> {
        __getZimFileIDs() as? Set<UUID> ?? Set<UUID>()
    }
    
    func parse(data: Data) throws {
        if !self.__parseData(data) {
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

    func parse(data: Data) throws {
    }

    func getMetaData(id: UUID) -> ZimFileMetaData? {
        nil
    }
}
