//
//  LibrarySplitViewController.swift
//  Kiwix
//
//  Created by Chris Li on 8/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData

class LibrarySplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredDisplayMode = .allVisible
        minimumPrimaryColumnWidth = 320.0
        delegate = self
        
        configureDismissButton()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection != previousTraitCollection else {return}
        let controller: LibraryBaseController? = {
            let nav = viewControllers.first as? UINavigationController
            let tab = nav?.topViewController as? UITabBarController
            return tab?.selectedViewController as? LibraryBaseController
        }()
        //controller?.tableView.reloadData()
        controller?.tableView.indexPathsForVisibleRows?.forEach({ (indexPath) in
            guard let cell = controller?.tableView.cellForRow(at: indexPath) else {return}
            controller?.configureCell(cell, atIndexPath: indexPath)
        })
    }
    
    func configureDismissButton() {
        guard let master = viewControllers.first as? UINavigationController else {return}
        let barButtonItem = UIBarButtonItem(image: UIImage(named: "Cross"), style: .plain, target: self, action: #selector(dismiss(sender:)))
        master.topViewController?.navigationItem.leftBarButtonItem = barButtonItem
    }
    
    func dismiss(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        let secondaryTopController = (secondaryViewController as? UINavigationController)?.topViewController
        if let _ = secondaryTopController as? LanguageFilterController {
            return false
        } else if (secondaryTopController as? BookDetailController)?.book != nil {
            return false
        } else {
            return true
        }
    }
    
    var isShowingLangFilter: Bool {
        return ((viewControllers[safe: 1] as? UINavigationController)?.topViewController is LanguageFilterController)
    }
}

class LibraryBaseController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        
    }
    
    // MARK: - Fetched Result Controller Delegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else {return}
            tableView.insertRows(at: [newIndexPath], with: .fade)
        case .delete:
            guard let indexPath = indexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .fade)
        case .update:
            guard let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) else {return}
            configureCell(cell, atIndexPath: indexPath)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.insertRows(at: [newIndexPath], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
