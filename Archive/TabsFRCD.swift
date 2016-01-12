//
//  TabsFRCD.swift
//  Kiwix
//
//  Created by Chris on 12/22/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit
import CoreData

extension TabsCVC {
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        collectionView?.performBatchUpdates({ () -> Void in
            switch type {
            case .Insert:
                self.collectionView?.insertSections(NSIndexSet(index: sectionIndex))
            case .Delete:
                self.collectionView?.deleteSections(NSIndexSet(index: sectionIndex))
            default:
                return
            }
            }, completion: { (completed) -> Void in
                
        })
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        collectionView?.performBatchUpdates({ () -> Void in
            switch type {
            case .Insert:
                self.collectionView?.insertItemsAtIndexPaths([newIndexPath!])
            case .Delete:
                self.collectionView?.deleteItemsAtIndexPaths([indexPath!])
            case .Update:
                guard let cell = self.collectionView?.cellForItemAtIndexPath(indexPath!) else {break}
                self.configureCell(cell, atIndexPath: indexPath!)
            case .Move:
                self.collectionView?.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
            }
            }, completion: { (completed) -> Void in
                
        })
    }
}