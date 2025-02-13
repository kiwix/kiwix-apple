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
import QuartzCore

@MainActor
final class DownloadTime {
    
    /// Only consider these last seconds, when calculating the average speed, hence the remaining time
    private let considerLastSeconds: Double
    /// sampled data: seconds to % of download
    private var samples: [CFTimeInterval: Int64] = [:]
    private let totalAmount: Int64
    
    init(considerLastSeconds: Double = 2, total: Int64) {
        assert(considerLastSeconds > 0)
        assert(total > 0)
        self.considerLastSeconds = considerLastSeconds
        self.totalAmount = total
    }
    
    func update(downloaded: Int64, now: CFTimeInterval = CACurrentMediaTime()) {
        filterOutSamples(now: now)
        samples[now] = downloaded
    }
    
    func remainingTime(now: CFTimeInterval = CACurrentMediaTime()) -> CFTimeInterval {
        filterOutSamples(now: now)
        guard samples.count > 1, let (latestTime, latestAmount) = latestSample() else {
            return .infinity
        }
        let average = averagePerSecond()
        let remainingAmount = totalAmount - latestAmount
        let remaingTime = Double(remainingAmount) / average - (now - latestTime)
        guard remaingTime > 0 else {
            return 0
        }
        return remaingTime
    }
    
    private func filterOutSamples(now: CFTimeInterval) {
        samples = samples.filter { time, _ in
            time + considerLastSeconds > now
        }
    }
    
    private func averagePerSecond() -> Double {
        var time: CFTimeInterval?
        var amount: Int64?
        var averages: [Double] = []
        for key in samples.keys.sorted() {
            let value = samples[key]!
            if let time, let amount {
                let took = key - time
                let downloaded = value - amount
                if took > 0, downloaded > 0 {
                    averages.append(Double(downloaded) / took)
                }
            }
            time = key
            amount = value
        }
        return mean(averages)
    }
    
    private func latestSample() -> (CFTimeInterval, Int64)? {
        guard let lastTime = samples.keys.sorted().reversed().first,
              let lastAmount = samples[lastTime] else {
            return nil
        }
        return (lastTime, lastAmount)
    }
    
    private func mean(_ values: [Double]) -> Double {
        let sum = values.reduce(0) { partialResult, value in
            partialResult + value
        }
        let average = sum / Double(values.count)
        return average
    }
}
