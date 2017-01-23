//
//  CoreDataCollectionBaseController.swift
//  Kiwix
//
//  Created by Chris Li on 1/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class CoreDataCollectionBaseController: UIViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private(set) var shouldReloadCollectionView = false
    private var closures = [() -> Void]()
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard collectionView.numberOfSections > 0,
                let newIndexPath = newIndexPath,
                collectionView.numberOfItems(inSection: newIndexPath.section) > 0 else {
                    shouldReloadCollectionView = true
                    break
            }
            closures.append({ [weak self] in self?.collectionView.insertItems(at: [newIndexPath]) })
        case .delete:
            guard let indexPath = indexPath else {break}
            closures.append({ [weak self] in self?.collectionView.deleteItems(at: [indexPath]) })
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {break}
            closures.append({ [weak self] in self?.collectionView.moveItem(at: indexPath, to: newIndexPath) })
        case .update:
            guard let indexPath = indexPath, collectionView.numberOfItems(inSection: indexPath.section) != 1 else {
                self.shouldReloadCollectionView = true
                break
            }
            closures.append({ [weak self] in self?.collectionView.reloadItems(at: [indexPath]) })
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            closures.append({ [weak self] in self?.collectionView.insertSections(IndexSet(integer: sectionIndex)) })
        case .delete:
            closures.append({ [weak self] in self?.collectionView.deleteSections(IndexSet(integer: sectionIndex)) })
        case .move:
            break
        case .update:
            closures.append({ [weak self] in self?.collectionView.reloadSections(IndexSet(integer: sectionIndex)) })
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        OperationQueue.main.addOperation({
            if self.shouldReloadCollectionView {
                self.collectionView.reloadData()
            } else {
                self.collectionView.performBatchUpdates({
                    self.closures.forEach({ $0() })
                }, completion: { (completed) in
                    self.closures.removeAll()
                })
            }
        })
    }
}
