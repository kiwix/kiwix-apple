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
    private var bookCount = Book.fetchAllCount(context: CoreDataContainer.shared.viewContext)
    
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
        let controller: UIViewController = {
            // To show library split controller, either refresh the library, or add a book to the app
            if Defaults[.libraryLastRefreshTime] != nil || bookCount > 0 {
                return LibrarySplitController()
            } else {
                let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LibraryOnboardingController")
                return UINavigationController(rootViewController: controller)
            }
        }()
        setChild(controller: controller)
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
        if let inserts = (userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.flatMap({ $0 as? Book }) {
            bookCount += inserts.count
        }
        if let deletes = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.flatMap({ $0 as? Book }) {
            bookCount -= deletes.count
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
        view.backgroundColor = .groupTableViewBackground
        title = NSLocalizedString("Library", comment: "Library title")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        titleLabel.text = NSLocalizedString("Download Library Catalogue", comment: "")
        subtitleLabel.text = NSLocalizedString("After that, browse and download a book. Zim files added through iTunes File Sharing will automatically show up.", comment: "")
        subtitleLabel.numberOfLines = 0
        downloadButton.setTitle(NSLocalizedString("Download", comment: ""), for: .normal)
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func downloadButtonTapped(_ sender: UIButton) {
        let procedure = LibraryRefreshProcedure()
        procedure.add(observer: WillExecuteObserver(willExecute: { (_, event) in
            OperationQueue.main.addOperation({
                self.activityIndicator.startAnimating()
                self.downloadButton.isEnabled = false
            })
        }))
        procedure.add(observer: DidFinishObserver(didFinish: { (procedure, errors) in
            OperationQueue.main.addOperation({
                self.activityIndicator.stopAnimating()
                if errors.count == 0 {
                    self.showLanguageFilter()
                } else {
                    self.downloadButton.isEnabled = true
                }
            })
        }))
        Queue.shared.add(libraryRefresh: procedure)
    }
    
    private func showLanguageFilter() {
        let deviceLanguageCodes = Locale.preferredLanguages.flatMap({ $0.components(separatedBy: "-").first })
        let deviceLanguageNames: [String] = {
            let names = NSMutableOrderedSet()
            deviceLanguageCodes.flatMap({ (Locale.current as NSLocale).displayName(forKey: .identifier, value: $0) }).forEach({ names.add($0) })
            return names.flatMap({ $0 as? String})
        }()
        
        let message = String(format: NSLocalizedString("You have set %@ as the preferred language(s) of the device. Would you like to hide books in other languages?", comment: "Language Filter"), deviceLanguageNames.joined(separator: ", "))
        
        func handleAlertAction(onlyShowDeviceLanguage: Bool) {
            let context = CoreDataContainer.shared.viewContext
            context.performAndWait {
                let languages = Language.fetchAll(context: context)
                if onlyShowDeviceLanguage {
                    languages.forEach({ $0.isDisplayed = deviceLanguageCodes.contains($0.code) })
                } else {
                    languages.forEach({$0.isDisplayed = false})
                }
                if context.hasChanges {
                    try? context.save()
                }
            }
            if let libraryController = navigationController?.parent as? LibraryController {
                libraryController.config()
            }
        }
        
        let alert = UIAlertController(title: NSLocalizedString("Language Filter", comment: "Language Filter"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Hide Other Language", comment: "Language Filter"), style: .default, handler: { (action) in
            handleAlertAction(onlyShowDeviceLanguage: true)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Skip and Show All", comment: "Language Filter"), style: .default, handler: { (action) in
            handleAlertAction(onlyShowDeviceLanguage: false)
        }))
        present(alert, animated: true)
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
        delegate = self
        preferredDisplayMode = .allVisible
        
        let master = LibraryMasterController()
        let detail = LibraryCategoryController(category: master.categories.first, title: master.categoryNames.first)
        viewControllers = [
            UINavigationController(rootViewController: master),
            UINavigationController(rootViewController: detail)]
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}
