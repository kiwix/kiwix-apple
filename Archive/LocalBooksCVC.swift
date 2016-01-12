//
//  LocalBooksCVC.swift
//  Kiwix
//
//  Created by Chris on 12/26/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit
import CoreData

class LocalBooksCVC: UICollectionViewController, NSFetchedResultsControllerDelegate, BookCollectionCellDelegate, UICollectionViewDelegateFlowLayout {

    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        let langDescriptor = NSSortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = NSPredicate(format: "isLocal == true")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "LocalBookCVCFRC")
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        collectionView?.backgroundColor = UIColor.whiteColor()
    }

    // MARK: - Data Source
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Book", forIndexPath: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UICollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? BookCollectionCell else {return}
        guard let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        cell.delegate = self
        cell.titleLabel.text = book.title
        if let favIcon = book.favIcon {
            cell.backgroundImageView.image = UIImage(data: favIcon)
        }
    }
    
    // MARK: - Flow Layout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(150, 150)
    }

    // MARK: - FRC
    
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
    
    // MARK: - BookCollectionCellDelegate
    
    func didTapOnCell(cell: BookCollectionCell) {
        
    }

}
