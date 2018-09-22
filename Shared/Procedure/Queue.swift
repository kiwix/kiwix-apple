//
//  Queue.swift
//  Kiwix
//
//  Created by Chris Li on 10/24/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import ProcedureKit

class Queue: ProcedureQueue {
    static let shared = Queue()
    override private init() {}
    
    var isRefreshingLibrary: Bool {
        if let procedure = currentRefreshLibraryProcedure {
            print("getter unwrapped: \(operations.contains(procedure))")
            return operations.contains(procedure)
        } else {
            return false
        }
    }
    
    private(set) weak var currentRefreshLibraryProcedure: LibraryRefreshProcedure?
    
    func add(libraryRefreshProcedure procedure: LibraryRefreshProcedure) {
        guard currentRefreshLibraryProcedure == nil else {return}
        addOperation(procedure)
        currentRefreshLibraryProcedure = procedure
    }
    
    private (set) weak var refreshLibraryProcedure: LibraryRefreshProcedure?
    func add(libraryRefresh procedure: LibraryRefreshProcedure) {
        guard refreshLibraryProcedure == nil else {return}
        addOperation(procedure)
        self.refreshLibraryProcedure = procedure
    }
    
    private weak var scan: ScanProcedure?
    func add(scanProcedure: ScanProcedure) {
        if let previous = scan {
            scanProcedure.addDependency(previous)
        }
        addOperation(scanProcedure)
        self.scan = scanProcedure
    }
}
