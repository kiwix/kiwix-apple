//
//  LibraryTBVCFRC.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit
import CoreData

extension LibraryTBVC {
    
    // MARK: Fetched Result Controller Delegate
    
    func shouldRespondeToModelChange(controller:NSFetchedResultsController) -> Bool {
        let isPresentingOnlineSegment = controller === selectedFetchedResultController && segmentedControl.selectedSegmentIndex == 0
        let isPresentingDownloadSegment = controller === selectedFetchedResultController && segmentedControl.selectedSegmentIndex == 1
        let isPresentingLocalSegment = controller === selectedFetchedResultController && segmentedControl.selectedSegmentIndex == 2
        return isPresentingOnlineSegment || isPresentingDownloadSegment || isPresentingLocalSegment
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if shouldRespondeToModelChange(controller) {
            self.tableView.beginUpdates()
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        if shouldRespondeToModelChange(controller) {
            switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        if shouldRespondeToModelChange(controller) {
            switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
            case .Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            }
            
            switch segmentedControl.selectedSegmentIndex {
            case 1:
                downloadMessageItem.text = messageLabelTextForDownladingTab
            case 2:
                localMessageItem.text = messageLabelTextForLocalTab
            default:
                break
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if shouldRespondeToModelChange(controller) {
            self.tableView.endUpdates()
        }
    }
}