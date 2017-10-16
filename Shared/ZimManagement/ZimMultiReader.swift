//
//  ZimMultiReader.swift
//  Kiwix
//
//  Created by Chris Li on 10/13/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class ZimMultiReader: DirectoryMonitorDelegate{
    static let shared = ZimMultiReader()
    private var readers = [String: ZimReader]()
    private var montiors = [URL: DirectoryMonitor]()
    
    private init() {
        scan(url: URL.documentDirectory)
        scan(url: URL.resourceDirectory)
    }
    
    func scan(url: URL) {
        let urls = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])) ?? []
        for url in urls {
            guard url.pathExtension == "zim" || url.pathExtension == "zimaa" else {return}
            if let reader = ZimReader(fileURL: url) {
                readers[reader.id] = reader
            }
        }
        print(readers.count)
    }
    
    // MARK: - Monitor
    
    func startMonitoring(url: URL) {
        let monitor = DirectoryMonitor(url: url)
        monitor.start()
        monitor.delegate = self
        montiors[url] = monitor
    }
    
    func stopMonitoring(url: URL) {
        montiors[url]?.stop()
        montiors[url] = nil
    }
    
    func directoryContentDidChange(url: URL) {
        scan(url: url)
    }
}

extension URL {
    static let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    static let resourceDirectory = Bundle.main.resourceURL!
}
