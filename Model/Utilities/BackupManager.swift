//
//  BackupManager.swift
//  Kiwix
//
//  Created by Chris Li on 2/7/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

class BackupManager {
    class func updateExcludedFromBackup(urls: [URL], isExcluded: Bool) {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = isExcluded
        urls.forEach { (url) in
            var url = url
            try? url.setResourceValues(resourceValues)
        }
    }
    
    class func updateExcludedFromBackupForDocumentDirectoryContents(isExcluded: Bool) {
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let urls = (try? FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: [.isExcludedFromBackupKey],
                                                                 options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]))?
            .filter({ $0.pathExtension.contains("zim") || $0.pathExtension == "idx" }) ?? [URL]()
        updateExcludedFromBackup(urls: urls, isExcluded: isExcluded)
    }
}
