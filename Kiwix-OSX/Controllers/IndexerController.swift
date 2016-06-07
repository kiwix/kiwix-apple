//
//  IndexerController.swift
//  Kiwix
//
//  Created by Chris Li on 6/3/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa

class IndexerController: NSViewController, ZimIndexerDelegate {
    
    let indexer = ZimIndexer();

    @IBOutlet weak var zimTextField: NSTextField!
    @IBOutlet weak var indexFolderTextField: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    @IBAction func startButtonPushed(sender: NSButton) {
        let zimFileURL = NSURL(fileURLWithPath: zimTextField.stringValue)
        let indexFolderURL = NSURL(fileURLWithPath: indexFolderTextField.stringValue)
        indexer.start(zimFileURL, indexFolderURL: indexFolderURL)
    }
    @IBAction func stopButtonPushed(sender: NSButton) {
//        indexer.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        indexer.delegate = self
        
        zimTextField.stringValue = "/Volumes/Data/ZIM Files/vikidia_en_all_2016-04.zim"
        indexFolderTextField.stringValue = "/Volumes/Data/ZIM Files/index"
    }
    
    // MARK: - ZimIndexerDelegate
    
    func didProcessArticle(processedArticleCount: UInt, totalArticleCount: UInt) {
        let progress = Double(processedArticleCount) / Double(totalArticleCount)
        NSOperationQueue.mainQueue().addOperationWithBlock { 
            self.progressIndicator.incrementBy(progress - self.progressIndicator.doubleValue)
        }
        
    }
}
