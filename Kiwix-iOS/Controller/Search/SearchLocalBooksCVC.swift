//
//  SearchLocalBooksCVC.swift
//  Kiwix
//
//  Created by Chris Li on 1/30/16.
//  Copyright © 2016 Chris. All rights reserved.
//  

import UIKit
import CoreData

class SearchLocalBooksCVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var shouldClipRoundCorner: Bool {
        return traitCollection.verticalSizeClass == .Regular && traitCollection.horizontalSizeClass == .Regular
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        collectionView.contentInset = UIEdgeInsetsMake(0.0, 0, 0, 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0, 0, 0)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.setContentOffset(CGPointMake(0, 0 - collectionView.contentInset.top), animated: false)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SearchLocalBooksCVC.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SearchLocalBooksCVC.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardDidShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: NSValue] else {return}
        guard let keyboardOrigin = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue().origin else {return}
        let point = view.convertPoint(keyboardOrigin, fromView: UIApplication.appDelegate.window)
        let buttomInset = view.frame.height - point.y
        collectionView.contentInset = UIEdgeInsetsMake(0.0, 0, buttomInset, 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0, buttomInset, 0)
    }

    func keyboardWillHide(notification: NSNotification) {
        collectionView.contentInset = UIEdgeInsetsMake(0.0, 0, 0, 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0, 0, 0)
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
        guard let cell = cell as? BookCollectionCell else {return}
        guard let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        cell.favIcon.image = book.favIconImage
        cell.titleLabel.text = book.title
        cell.languageLabel.text = book.language?.name
        cell.dateLabel.text = book.dateFormatted
    }
    
    // MARK: - CollectionView Delegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let mainVC = parentViewController?.parentViewController?.parentViewController as? MainVC,
              let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book,
              let bookID = book.id else {return}
        mainVC.hideSearch()
        mainVC.loadMainPage(bookID)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    var hInset: CGFloat {
        let inset = floor(self.collectionView.frame.width * 0.1064 - 24.0426)
        return min(inset, 20.0)
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10, hInset, 10, hInset)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return hInset
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10.0
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var itemsPerRow = round(collectionView.frame.width / 100)
        itemsPerRow = max(itemsPerRow, 4)
        let hSpacingSum = CGFloat(itemsPerRow + 1) * hInset
        let width = (view.frame.width - hSpacingSum) / CGFloat(itemsPerRow)
        return CGSizeMake(width, width * 0.8 + 60.0)
    }
    
    // MARK: - Fetched Result Controller
    
    var shouldReloadCollectionView = false
    var blockOperation = NSBlockOperation()
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.fetchBatchSize = 20
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        let predicate = NSPredicate(format: "isLocal = true")
        fetchRequest.sortDescriptors = [titleDescriptor]
        fetchRequest.predicate = predicate
        //fetchRequest.fetchLimit = 100
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "LocalMainPageFRC")
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
    var fetchedResultsProcessingOperations = [NSBlockOperation]()
    
    private func addFetchedResultsProcessingBlock(processingBlock:(Void)->Void) {
        fetchedResultsProcessingOperations.append(NSBlockOperation(block: processingBlock))
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            addFetchedResultsProcessingBlock {self.collectionView.insertItemsAtIndexPaths([newIndexPath!])}
        case .Update:
            addFetchedResultsProcessingBlock {self.collectionView.reloadItemsAtIndexPaths([indexPath!])}
        case .Move:
            addFetchedResultsProcessingBlock {self.collectionView.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)}
        case .Delete:
            addFetchedResultsProcessingBlock {self.collectionView.deleteItemsAtIndexPaths([indexPath!])}
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            addFetchedResultsProcessingBlock {self.collectionView.insertSections(NSIndexSet(index: sectionIndex))}
        case .Update:
            addFetchedResultsProcessingBlock {self.collectionView.reloadSections(NSIndexSet(index: sectionIndex))}
        case .Delete:
            addFetchedResultsProcessingBlock {self.collectionView.deleteSections(NSIndexSet(index: sectionIndex))}
        case .Move:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation in self.fetchedResultsProcessingOperations {
                operation.start()
            }
            }, completion: { (finished) -> Void in
                self.fetchedResultsProcessingOperations.removeAll(keepCapacity: false)
        })
    }
    
    deinit {
        for operation in fetchedResultsProcessingOperations {
            operation.cancel()
        }
        fetchedResultsProcessingOperations.removeAll()
    }
}
