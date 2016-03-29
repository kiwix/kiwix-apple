//
//  BookDownloadProgress.swift
//  Kiwix
//
//  Created by Chris on 12/16/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class BookDownloadProgress: NSProgress {
    private let numberOfSpeedsRecorded = 5
    private let speedUpdateFrequency = 1.0
    let book: Book
    weak var task: NSURLSessionDownloadTask?
    var lastSnapshot: (totalBytesWritten: Int64, timeStamp: NSDate)?
    var speeds = [(speed: Double, timeStamp: NSDate)]()
    
    init(book: Book) {
        self.book = book
        super.init(parent: nil, userInfo: [NSProgressFileOperationKindKey: NSProgressFileOperationKindDownloading])
        self.kind = NSProgressKindFile
        self.totalUnitCount = book.fileSize?.longLongValue ?? 0
        self.completedUnitCount = {
            if let completedUnitCount = book.downloadTask?.totalBytesWritten {
                return completedUnitCount
            } else {
                return 0
            }
        }()
    }
    
    func resetSpeed() {
        speeds.removeAll()
        lastSnapshot = nil
        setUserInfoObject(nil, forKey: NSProgressThroughputKey)
        setUserInfoObject(nil, forKey: NSProgressEstimatedTimeRemainingKey)
    }
    
    func updateSpeed(totalBytesWritten: Int64 = 0) {
        let now = NSDate()
        guard let lastSnapshot = lastSnapshot else {self.lastSnapshot = (totalBytesWritten, now); return}
        
        // Update every speedUpdateFrequency (e.g. every 1 second)
        let timeInterval = now.timeIntervalSinceDate(lastSnapshot.timeStamp)
        guard timeInterval >= speedUpdateFrequency else {return}
        
        // Speed since last update
        let speed = Double(totalBytesWritten - lastSnapshot.totalBytesWritten) / timeInterval
        speeds.insert((speed, now), atIndex: 0)
        
        // See if there are enough samples
        guard speeds.count > numberOfSpeedsRecorded else {return}
        speeds.removeLast()
        self.lastSnapshot = (totalBytesWritten, now)
        
        calculateCurrentSpeed()
    }
    
    func calculateCurrentSpeed() {
        let alpha = 0.5
        var remainingWeight = 1.0
        var speedMA = 0.0
        
        guard speeds.count > 0 else {return}
        for index in 0..<speeds.count-1 {
            let weight = alpha * pow(1.0 - alpha, Double(index))
            remainingWeight -= weight
            speedMA += weight * speeds[index].speed
        }
        speedMA += remainingWeight * (speeds.last?.speed ?? 0.0)
        
        setUserInfoObject(NSNumber(double: speedMA), forKey: NSProgressThroughputKey)
        
        guard let totalBytesWritten = lastSnapshot?.totalBytesWritten else {return}
        let remainingSeconds = Double(totalUnitCount - totalBytesWritten) / speedMA
        setUserInfoObject(NSNumber(double: remainingSeconds), forKey: NSProgressEstimatedTimeRemainingKey)
    }
    
    var sizeDescription: String {
        return localizedAdditionalDescription.componentsSeparatedByString(" — ").first ?? ""
    }
    
    var speedAndRemainingTimeDescription: String? {
        let components = localizedAdditionalDescription.componentsSeparatedByString(" — ")
        if components.count > 1 {
            return components.last
        } else {
            return nil
        }
    }
    
    var percentDescription: String {
        return Utilities.formattedPercentString(NSNumber(double: fractionCompleted)) ?? ""
    }
    
    var sizeAndPercentDescription: String {
        var strings = [String]()
        strings.append(sizeDescription)
        strings.append(percentDescription)
        return strings.joinWithSeparator(" - ")
    }
    
    override var description: String {
        guard let state = book.downloadTask?.state else {return " \n "}
        switch state {
        case .Queued: return sizeAndPercentDescription + "\n" + LocalizedStrings.queued
        case .Downloading: return sizeAndPercentDescription + "\n" + (speedAndRemainingTimeDescription ?? LocalizedStrings.estimatingSpeedAndRemainingTime)
        case .Paused: return sizeAndPercentDescription + "\n" + LocalizedStrings.paused
        case .Error: return sizeDescription + "\n" + LocalizedStrings.downloadError
        }
    }
}

extension LocalizedStrings {
    class var starting: String {return NSLocalizedString("Starting", comment: "Library: Download task description")}
    class var resuming: String {return NSLocalizedString("Resuming", comment: "Library: Download task description")}
    class var paused: String {return NSLocalizedString("Paused", comment: "Library: Download task description")}
    class var downloadError: String {return NSLocalizedString("Download Error", comment: "Library: Download task description")}
    class var queued: String {return NSLocalizedString("Queued", comment: "Library: Download task description")}
    class var estimatingSpeedAndRemainingTime: String {return NSLocalizedString("Estimating speed and remaining time", comment: "Library: Download task description")}
}
