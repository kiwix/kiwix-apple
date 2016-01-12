//
//  TabsCVC.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit
import CoreData

class TabsCVC: UICollectionViewController, UIViewControllerTransitioningDelegate, NSFetchedResultsControllerDelegate {

    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    var selectedIndexPath: NSIndexPath?
    var tabVCs = [Tab: TabVC]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        collectionView?.alwaysBounceHorizontal = true
        collectionView?.alwaysBounceVertical = true
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.libraryRefresher.refreshIfNeeded()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Tab")
        let creationTimeDescriptor = NSSortDescriptor(key: "creationTime", ascending: false)
        fetchRequest.sortDescriptors = [creationTimeDescriptor]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "TabsFRC")
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentTabAnimator()
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissTabAnimator()
    }
    
    // MARK: - Actions

    @IBAction func addTabButtonTapped(sender: UIBarButtonItem) {
        Tab.add(managedObjectContext)
    }
}
