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
    
    private weak var scan: ScanProcedure?
    func add(scanProcedure: ScanProcedure) {
        if let previous = scan {
            scanProcedure.addDependency(previous)
        }
        add(operation: scanProcedure)
        self.scan = scanProcedure
    }
}
