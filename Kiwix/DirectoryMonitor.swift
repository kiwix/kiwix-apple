/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
`DirectoryMonitor` is used to monitor the contents of the provided directory by using a GCD dispatch source.
*/

import Foundation

/// A protocol that allows delegates of `DirectoryMonitor` to respond to changes in a directory.
protocol DirectoryMonitorDelegate: class {
    func directoryMonitorDidObserveChange()
}

class DirectoryMonitor {
    // MARK: Properties
    
    /// The `DirectoryMonitor`'s delegate who is responsible for responding to `DirectoryMonitor` updates.
    weak var delegate: DirectoryMonitorDelegate?
    
    /// A file descriptor for the monitored directory.
    var monitoredDirectoryFileDescriptor: CInt = -1
    
    /// A dispatch queue used for sending file changes in the directory.
    let directoryMonitorQueue = dispatch_queue_create("org.kiwix.directorymonitor", DISPATCH_QUEUE_CONCURRENT)
    
    /// A dispatch source to monitor a file descriptor created from the directory.
    var directoryMonitorSource: dispatch_source_t?
    
    /// URL for the directory being monitored.
    var URL: NSURL
    
    // MARK: Initializers
    init(URL: NSURL) {
        self.URL = URL
    }
    
    // MARK: Monitoring
    
    func startMonitoring() {
        // Listen for changes to the directory (if we are not already).
        if directoryMonitorSource == nil && monitoredDirectoryFileDescriptor == -1 {
            // Open the directory referenced by URL for monitoring only.
            monitoredDirectoryFileDescriptor = open(URL.path!, O_EVTONLY)
            
            // Define a dispatch source monitoring the directory for additions, deletions, and renamings.
            directoryMonitorSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, UInt(monitoredDirectoryFileDescriptor), DISPATCH_VNODE_WRITE, directoryMonitorQueue)
            
            // Define the block to call when a file change is detected.
            dispatch_source_set_event_handler(directoryMonitorSource!) {
                // Call out to the `DirectoryMonitorDelegate` so that it can react appropriately to the change.
                self.directoryContentDidChange()
                return
            }
            
            // Define a cancel handler to ensure the directory is closed when the source is cancelled.
            dispatch_source_set_cancel_handler(directoryMonitorSource!) {
                close(self.monitoredDirectoryFileDescriptor)
                
                self.monitoredDirectoryFileDescriptor = -1
                
                self.directoryMonitorSource = nil
            }
            
            // Start monitoring the directory via the source.
            dispatch_resume(directoryMonitorSource!)
        }
    }
    
    func stopMonitoring() {
        // Stop listening for changes to the directory, if the source has been created.
        if directoryMonitorSource != nil {
            // Stop monitoring the directory via the source.
            dispatch_source_cancel(directoryMonitorSource!)
        }
    }
    
    // MARK: - Custom Methods
    
    var isCheckingChanges = false
    var previousDirectoryHash: [String]? = nil
    var currentDirectoryHash: [String]? = nil
    var hashEqualCheck = 0
    
    func directoryContentDidChange() {
        hashEqualCheck = 0
        if isCheckingChanges == false {
            checkDirectoryChanges()
        }
    }
    
    func checkDirectoryChanges() {
        isCheckingChanges = true
        
        previousDirectoryHash = currentDirectoryHash
        currentDirectoryHash = directoryHashes()
        if let previousDirectoryHash = previousDirectoryHash, let currentDirectoryHash = currentDirectoryHash {
            if previousDirectoryHash == currentDirectoryHash {
                hashEqualCheck += 1
                if hashEqualCheck > 2 {
                    hashEqualCheck = 0
                    isCheckingChanges = false
                    self.previousDirectoryHash = nil
                    self.currentDirectoryHash = nil
                    directoryDidReachStasis()
                } else {
                    waitAndCheckAgain()
                }
            } else {
                hashEqualCheck = 0
                waitAndCheckAgain()
            }
        } else {
            checkDirectoryChanges()
        }
    }
    
    func directoryDidReachStasis() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC/10)) , dispatch_get_main_queue(), { () -> Void in
            self.delegate?.directoryMonitorDidObserveChange()
        })
    }
    
    func waitAndCheckAgain() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC/2)) , directoryMonitorQueue, { () -> Void in
            self.checkDirectoryChanges()
        })
    }
    
    // MARK: - Generate directory file info array
    
    func directoryHashes() -> [String] {
        var hashes = [String]()
        if let path = self.URL.path {
            do {
                let contents = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)
                for file in contents {
                    if let hash = fileHash(file) {
                        hashes.append(hash)
                    }
                }
            } catch let error as NSError {
                // failure
                print("contentsOfDirectoryAtPath failed: \(error.localizedDescription)")
            }
        }
        return hashes
    }
    
    func fileHash(fileName: String) -> String? {
        if let fileSize = fileSize(fileName) {
            return fileName + "_\(fileSize)"
        } else {
            return nil
        }
    }
    
    func fileSize(fileName: String) -> Int64? {
        if let path = self.URL.URLByAppendingPathComponent(fileName).path {
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                do {
                    let attributes = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
                    let fileSize = attributes[NSFileSize] as? NSNumber
                    return fileSize?.longLongValue
                } catch let error as NSError {
                    // failure
                    print("attributesOfItemAtPath failed: \(error.localizedDescription)")
                }
            }
        }
        return nil
    }
}