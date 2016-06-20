//
//  LangLocalCVC.swift
//  Kiwix
//
//  Created by Chris Li on 6/19/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData

class LangLocalCVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceHorizontal = true
    }
    
    // MARK: - CollectionView Data Source
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UICollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let language = fetchedResultController.objectAtIndexPath(indexPath) as? Language,
              let cell = cell as? LocalLangCell else {return}
        cell.label.text = language.name
    }
    
    // MARK: - CollectionView Delegate FlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let height: CGFloat = 30
        guard let language = fetchedResultController.objectAtIndexPath(indexPath) as? Language,
              let name = language.name else {return CGSizeMake(30, height)}
        let font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightRegular)
        let size = name.boundingRectWithSize(CGSizeMake(200, height),
                                             options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                                             attributes: [NSFontAttributeName: font], context: nil)
        return CGSizeMake(size.width + 30, height)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let numberOfItems = collectionView.numberOfItemsInSection(section)
        
        var width: CGFloat = 0
        for item in 0..<numberOfItems {
            let size = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAtIndexPath: NSIndexPath(forItem: item, inSection: section))
            width += size.width
        }
        width += 10.0 * CGFloat(numberOfItems - 1)
        
        let hInset = max((collectionView.frame.width - width) / 2, 0)
        return UIEdgeInsetsMake(0, hInset, 0, hInset)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10
    }
    
    // MARK: - Fetched Result Controller
    
    var blockOperation = NSBlockOperation()
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Language")
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        let predicate = NSPredicate(format: "books.isLocal CONTAINS true")
        fetchRequest.sortDescriptors = [descriptor]
        fetchRequest.predicate = predicate
        fetchRequest.fetchBatchSize = 20
        fetchRequest.fetchLimit = 5
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "LangLocalFRC")
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
    private var batchUpdateOperation = [NSBlockOperation]()
    
    private func addUpdateBlock(processingBlock:(Void)->Void) {
        batchUpdateOperation.append(NSBlockOperation(block: processingBlock))
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            guard let newIndexPath = newIndexPath else {return}
            addUpdateBlock {self.collectionView.insertItemsAtIndexPaths([newIndexPath])}
        case .Update:
            guard let indexPath = indexPath else {return}
            addUpdateBlock {self.collectionView.reloadItemsAtIndexPaths([indexPath])}
        case .Move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {return}
            addUpdateBlock {self.collectionView.moveItemAtIndexPath(indexPath, toIndexPath: newIndexPath)}
        case .Delete:
            guard let indexPath = indexPath else {return}
            addUpdateBlock {self.collectionView.deleteItemsAtIndexPaths([indexPath])}
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            addUpdateBlock {self.collectionView.insertSections(NSIndexSet(index: sectionIndex))}
        case .Update:
            addUpdateBlock {self.collectionView.reloadSections(NSIndexSet(index: sectionIndex))}
        case .Delete:
            addUpdateBlock {self.collectionView.deleteSections(NSIndexSet(index: sectionIndex))}
        case .Move:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({ () -> Void in
            for operation in self.batchUpdateOperation {
                operation.start()
            }
            }, completion: { (finished) -> Void in
                self.batchUpdateOperation.removeAll(keepCapacity: false)
        })
    }
    
    deinit {
        for operation in batchUpdateOperation {
            operation.cancel()
        }
        batchUpdateOperation.removeAll()
    }


}
