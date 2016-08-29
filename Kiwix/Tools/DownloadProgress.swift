//
//  DownloadProgress.swift
//  Kiwix
//
//  Created by Chris Li on 8/29/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class DownloadProgress: NSProgress {
    typealias TimePoint = (completedUnitCount: Int64, timeStamp: NSTimeInterval)
    private var timePoints = [TimePoint]()
    private let timePointMinCount: Int = 20
    private let timePointMaxCount: Int = 200
    
    private lazy var percentFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        formatter.minimumFractionDigits = 1
        formatter.maximumIntegerDigits = 3
        formatter.minimumFractionDigits = 2
        formatter.maximumIntegerDigits = 2
        return formatter
    }()
    
    init(completedUnitCount: Int64 = 0, totalUnitCount: Int64) {
        super.init(parent: nil, userInfo: [NSProgressFileOperationKindKey: NSProgressFileOperationKindDownloading])
        self.kind = NSProgressKindFile
        self.totalUnitCount = totalUnitCount
        self.completedUnitCount = completedUnitCount
    }
    
    override var completedUnitCount: Int64 {
        didSet {
            add(completedUnitCount)
        }
    }
    
    // MARK: - Descriptions
    
    var fractionCompletedDescription: String? {
        return percentFormatter.stringFromNumber(NSNumber(double: fractionCompleted))
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
        
        setUserInfoObject(NSNumber(double: averageSpeed), forKey: NSProgressThroughputKey)
        
        let remainingSeconds = Double(totalUnitCount - completedUnitCount) / averageSpeed
        setUserInfoObject(NSNumber(double: remainingSeconds), forKey: NSProgressEstimatedTimeRemainingKey)
    }
    
    private func add(completedUnitCount: Int64) {
        let timeStamp = NSDate().timeIntervalSince1970
        if let lastPoint = timePoints.last {
            guard timeStamp - lastPoint.timeStamp > 0.2 else {return}
            timePoints.append((completedUnitCount, timeStamp))
            if timePoints.count > timePointMaxCount { timePoints.removeFirst() }
        } else {
            timePoints.append((completedUnitCount, timeStamp))
        }
    }
}
