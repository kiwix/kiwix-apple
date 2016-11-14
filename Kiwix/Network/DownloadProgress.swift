//
//  DownloadProgress.swift
//  Kiwix
//
//  Created by Chris Li on 8/29/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class DownloadProgress: Progress {
    typealias TimePoint = (completedUnitCount: Int64, timeStamp: TimeInterval)
    fileprivate var timePoints = [TimePoint]()
    fileprivate let timePointMinCount: Int = 20
    fileprivate let timePointMaxCount: Int = 200
    
    init(completedUnitCount: Int64, totalUnitCount: Int64) {
        super.init(parent: nil, userInfo: [ProgressUserInfoKey.fileOperationKindKey: Progress.FileOperationKind.downloading])
        self.kind = ProgressKind.file
        self.totalUnitCount = totalUnitCount
        self.completedUnitCount = completedUnitCount
    }
    
    // MARK: - Descriptions
    
    var fractionCompletedDescription: String? {
        return DownloadTask.percentFormatter.string(from: NSNumber(value: fractionCompleted as Double))
    }
    
    var progressAndSpeedDescription: String! {
        calculateSpeed()
        return localizedAdditionalDescription
    }
    
    func calculateSpeed() {
        guard self.timePoints.count >= timePointMinCount else {return}
        
        let smoothingFactor = 1 / Double(self.timePoints.count)
        var timePoints = self.timePoints
        var oldPoint = timePoints.removeFirst()
        let recentPoint = timePoints.removeFirst()
        var averageSpeed: Double = Double(recentPoint.completedUnitCount - oldPoint.completedUnitCount) / (recentPoint.timeStamp - oldPoint.timeStamp)
        oldPoint = recentPoint
        
        for recentPoint in timePoints {
            let lastSpeed = Double(recentPoint.completedUnitCount - oldPoint.completedUnitCount) / (recentPoint.timeStamp - oldPoint.timeStamp)
            oldPoint = recentPoint
            averageSpeed = smoothingFactor * lastSpeed + (1 - smoothingFactor) * averageSpeed
        }
        
        setUserInfoObject(NSNumber(value: averageSpeed as Double), forKey: ProgressUserInfoKey.throughputKey)
        
        let remainingSeconds = Double(totalUnitCount - completedUnitCount) / averageSpeed
        setUserInfoObject(NSNumber(value: remainingSeconds as Double), forKey: ProgressUserInfoKey.estimatedTimeRemainingKey)
    }
    
    func addObservation(_ totalBytesWritten: Int64) {
        completedUnitCount = totalBytesWritten
        let timeStamp = Date().timeIntervalSince1970
        if let lastPoint = timePoints.last {
            guard timeStamp - lastPoint.timeStamp > 0.2 else {return}
            timePoints.append((completedUnitCount, timeStamp))
            if timePoints.count > timePointMaxCount { timePoints.removeFirst() }
        } else {
            timePoints.append((completedUnitCount, timeStamp))
        }
    }
}
