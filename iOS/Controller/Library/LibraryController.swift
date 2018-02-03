//
//  LibraryController.swift
//  Kiwix
//
//  Created by Chris Li on 10/10/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData
import ProcedureKit
import SwiftyUserDefaults

class LibraryController: UIViewController {
    private var localBookIDs = Set(Book.fetch(states: [.local], context: CoreDataContainer.shared.viewContext).map({ $0.id }))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        config()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextObjectsDidChange(notification:)),
                                               name: .NSManagedObjectContextObjectsDidChange,
                                               object: CoreDataContainer.shared.viewContext)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextObjectsDidChange, object: CoreDataContainer.shared.viewContext)
    }
    
    fileprivate func config() {
        // To show library split controller, either refresh the library, or add a book to the app
        if Defaults[.libraryLastRefreshTime] != nil || localBookIDs.count > 0 {
            guard !(childViewControllers.first is LibrarySplitController) else {return}
            setChild(controller: LibrarySplitController())
        } else {
            guard !(childViewControllers.first is UINavigationController) else {return}
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LibraryOnboardingController")
            setChild(controller: UINavigationController(rootViewController: controller))
        }
    }
    
    private func setChild(controller: UIViewController) {
        view.subviews.forEach({ $0.removeFromSuperview() })
        childViewControllers.forEach({ $0.removeFromParentViewController() })
        
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller)
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: controller.view.leftAnchor),
            view.rightAnchor.constraint(equalTo: controller.view.rightAnchor),
            view.topAnchor.constraint(equalTo: controller.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)])
        controller.didMove(toParentViewController: self)
    }
    
    @objc func managedObjectContextObjectsDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let inserts = (userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.flatMap({ $0 as? Book }).filter({ $0.state == .local }) {
            inserts.forEach({ localBookIDs.insert($0.id) })
        }

        if let updates = (userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>)?.flatMap({ $0 as? Book }) {
            updates.forEach({ (book) in
                if book.state == .local {
                    localBookIDs.insert(book.id)
                } else {
                    localBookIDs.remove(book.id)
                }
            })
        }

        if let deletes = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.flatMap({ $0 as? Book }).filter({ $0.state == .local }) {
            deletes.forEach({ localBookIDs.remove($0.id) })
        }
        
        config()
    }
}

class LibraryOnboardingController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var downloadButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        view.backgroundColor = .groupTableViewBackground
        title = NSLocalizedString("Library", comment: "Library title")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
        
        titleLabel.text = NSLocalizedString("Download Library Catalogue", comment: "Library Onboarding")
        subtitleLabel.text = NSLocalizedString("After that, browse and download a book. Zim files added through iTunes File Sharing will automatically show up.", comment: "Library Onboarding")
        subtitleLabel.numberOfLines = 0
        downloadButton.setTitle(NSLocalizedString("Download", comment: "Library Onboarding"), for: .normal)
        downloadButton.setTitle(NSLocalizedString("Downloading...", comment: "Library Onboarding"), for: .disabled)
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func downloadButtonTapped(_ sender: UIButton) {
        let procedure = LibraryRefreshProcedure()
        procedure.add(observer: WillExecuteObserver(willExecute: { (_, _) in
            OperationQueue.main.addOperation({
                self.activityIndicator.startAnimating()
                self.downloadButton.isEnabled = false
            })
        }))
        procedure.add(observer: DidFinishObserver(didFinish: { (_, errors) in
            OperationQueue.main.addOperation({
                self.activityIndicator.stopAnimating()
                if errors.count == 0 {
                    if let libraryController = self.navigationController?.parent as? LibraryController {
                        libraryController.config()
                    }
                } else {
                    self.downloadButton.isEnabled = true
                }
            })
        }))
        Queue.shared.add(libraryRefresh: procedure)
    }
}

class LibraryNavigationController: UINavigationController {
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class LibrarySplitController: UISplitViewController, UISplitViewControllerDelegate {
    init() {
        super.init(nibName: nil, bundle: nil)
        config()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        config()
    }
    
    private func config() {
        // set at least one view controller in viewControllers to supress a warning produced by split view controller
        viewControllers = [UIViewController()]
        
        preferredDisplayMode = .allVisible
        delegate = self
        
        let master = LibraryMasterController()
        let detail = UIViewController()
        detail.view.backgroundColor = .groupTableViewBackground
        viewControllers = [
            UINavigationController(rootViewController: master),
            UINavigationController(rootViewController: detail)]
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}
