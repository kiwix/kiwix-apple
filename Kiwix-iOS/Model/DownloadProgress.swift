//
//  DownloadProgress.swift
//  Kiwix
//
//  Created by Chris Li on 3/23/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class DownloadProgress: NSProgress {
    let book: Book
    private let observationCount = 9
    private let sampleFrequency: NSTimeInterval = 0.3
    private var speeds = [Double]()
    private var timer: NSTimer?
    private weak var task: NSURLSessionDownloadTask?
    
    init(book: Book) {
        self.book = book
        super.init(parent: nil, userInfo: [NSProgressFileOperationKindKey: NSProgressFileOperationKindDownloading])
        self.kind = NSProgressKindFile
        self.totalUnitCount = book.fileSize
        self.completedUnitCount = book.downloadTask?.totalBytesWritten ?? 0
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func downloadStarted(task: NSURLSessionDownloadTask) {
        self.task = task
        recordSpeed()
        timer = NSTimer.scheduledTimerWithTimeInterval(sampleFrequency, target: self, selector: #selector(DownloadProgress.recordSpeed), userInfo: nil, repeats: true)
    }
    
    func downloadTerminated() {
        timer?.invalidate()
        speeds.removeAll()
        setUserInfoObject(nil, forKey: NSProgressThroughputKey)
        setUserInfoObject(nil, forKey: NSProgressEstimatedTimeRemainingKey)
    }
    
    func recordSpeed() {
        guard let task = task else {return}
        
        /*
            Check if the countOfBytesReceived and countOfBytesExpectedToReceive in NSURLSessionDownloadTask
            object is both zero. When a NSURLSessionDownloadTask resumes, these two value will be zero at first.
            We don't want to accidently set these two values in this progress object to be all 0.
        */
        guard task.countOfBytesReceived != 0 && task.countOfBytesExpectedToReceive != 0 else {return}
        
        let previousCompletedUnitCount = completedUnitCount
        completedUnitCount = task.countOfBytesReceived
        totalUnitCount = task.countOfBytesExpectedToReceive
        let speed = Double(completedUnitCount - previousCompletedUnitCount) / sampleFrequency
        speeds.insert(speed, atIndex: 0)
        if speeds.count > observationCount {speeds.popLast()}
    }
    
    var maSpeed: Double? {
        let alpha = 0.5
        var remainingWeight = 1.0
        var speedMA = 0.0
        
        guard speeds.count >= observationCount else {return nil}
        for index in 0..<speeds.count {
            let weight = alpha * pow(1.0 - alpha, Double(index))
            remainingWeight -= weight
            speedMA += weight * speeds[index]
        }
        speedMA += remainingWeight * (speeds.last ?? 0.0)
        return speedMA > 0.0 ? speedMA : nil
    }
    
    // MARK: - Descriptions
    
    var sizeDescription: String {
        return localizedAdditionalDescription.componentsSeparatedByString(" — ").first ?? ""
    }
    
    var speedAndRemainingTimeDescription: String? {
        guard let maSpeed = self.maSpeed else {return nil}
        setUserInfoObject(NSNumber(double: maSpeed), forKey: NSProgressThroughputKey)
        
        let remainingSeconds = Double(totalUnitCount - completedUnitCount) / maSpeed
        setUserInfoObject(NSNumber(double: remainingSeconds), forKey: NSProgressEstimatedTimeRemainingKey)
        
        let components = localizedAdditionalDescription.componentsSeparatedByString(" — ")
        return components.count > 1 ? components.last : nil
    }
    
    var percentDescription: String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        formatter.maximumIntegerDigits = 3
        formatter.maximumFractionDigits = 0
        formatter.locale = NSLocale.currentLocale()
        return formatter.stringFromNumber(NSNumber(double: fractionCompleted)) ?? ""
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
