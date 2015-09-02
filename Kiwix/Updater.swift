//
//  Updater.swift
//  Kiwix
//
//  Created by Chris Li on 8/24/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class Updater {
    class func updateToVersion1_1() {
        if Preference.versionNumber < 1.1 {
            excludeDocAndLibDirFromICloudBackup()
        }
        Preference.versionNumber = 1.1
    }
    
    class func excludeDocAndLibDirFromICloudBackup() {
        let docURL = NSURL(fileURLWithPath: Utilities.docDirPath())
        let libURL = NSURL(fileURLWithPath: Utilities.libDirPath())
        do {
            try docURL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
            try libURL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
        } catch let error as NSError {
            // failure
            print("excludeDocAndLibDirFromICloudBackup failed: \(error.localizedDescription)")
        }
        
    }
}
