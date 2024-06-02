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

import Foundation

/// Returns an async sequence of data in chunks defined by range size
struct DataStream<Element>: AsyncSequence {
    typealias AsyncIterator = DataStreamIterator<Element>

    private let iterator: DataStreamIterator<Element>

    /// - Parameters:
    ///   - dataProvider: A place we can read the data from
    ///   - ranges: the byte ranges to read the data from
    init?(dataProvider: any DataProvider<Element>, ranges: [ClosedRange<UInt>]) {
        guard !ranges.isEmpty else { return nil }
        self.iterator = DataStreamIterator<Element>(dataProvider: dataProvider, ranges: ranges)
    }

    func makeAsyncIterator() -> DataStreamIterator<Element> {
        iterator
    }
}

struct DataStreamIterator<Element>: AsyncIteratorProtocol {
    private let dataProvider: any DataProvider<Element>
    private var ranges: [ClosedRange<UInt>]

    init(dataProvider: any DataProvider<Element>, ranges: [ClosedRange<UInt>]) {
        self.dataProvider = dataProvider
        self.ranges = ranges
    }

    mutating func next() async throws -> Element? {
        guard !ranges.isEmpty else {
            return nil
        }
        let range = ranges.removeFirst()
        return await dataProvider.data(from: range.lowerBound, to: range.upperBound)
    }
}

protocol DataProvider<Element> {
    associatedtype Element

    /// Returns a chunk of data
    /// - Parameters:
    ///   - start: range start
    ///   - end: range end
    /// - Returns: data chunk
    func data(from start: UInt, to end: UInt) async -> Element?
}
