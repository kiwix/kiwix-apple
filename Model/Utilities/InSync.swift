//
//  InSync.swift
//  Kiwix

import Foundation

struct InSync {
    private let queue: DispatchQueue

    init(label: String) {
        queue = DispatchQueue(label: label, attributes: [.concurrent])
    }

    func read<T>(_ work: () -> T) -> T {
        queue.sync(execute: work)
    }

    func execute(_ work: @escaping () -> Void) {
        queue.async(flags: .barrier, execute: work)
    }
}
