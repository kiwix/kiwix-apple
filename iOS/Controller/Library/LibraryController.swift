//
//  LibraryController.swift
//  Kiwix
//
//  Created by Chris Li on 10/10/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift


/**
 The container for library controllers.
 
 It has two modes, depending on the number of `ZimFile` objects in the database:
 - one or more, LibrarySplitController
 - zero, LibraryOnboardingController
 */
class LibraryController: UIViewController {
    private let zimFiles: Results<ZimFile>?
    private var changeToken: NotificationToken?
    
    private var mode: Mode? {
        didSet {
            guard oldValue != mode, let mode = mode else {return}
            switch mode {
            case .onboarding:
                let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LibraryOnboardingNavController")
                self.setChild(controller: controller)
            case .split:
                self.setChild(controller: LibrarySplitController())
            }
        }
    }
    
    init() {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            zimFiles = database.objects(ZimFile.self)
        } catch { zimFiles = nil }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mode = zimFiles?.count ?? 0 > 0 ? .split : .onboarding
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        changeToken = zimFiles?.observe({ (changes) in
            guard case .update(let results, _, _, _) = changes else {return}
            self.mode = results.count > 0 ? .split : .onboarding
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        changeToken = nil
    }

    private func setChild(controller: UIViewController) {
        view.subviews.forEach({ $0.removeFromSuperview() })
        children.forEach({ $0.removeFromParent() })
        
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(controller)
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: controller.view.leftAnchor),
            view.rightAnchor.constraint(equalTo: controller.view.rightAnchor),
            view.topAnchor.constraint(equalTo: controller.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)])
        controller.didMove(toParent: self)
    }
    
    private enum Mode {
        case onboarding, split
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
        
        titleLabel.text = NSLocalizedString("Download Library Catalog", comment: "Library Onboarding")
        subtitleLabel.text = NSLocalizedString("After that, browse and download a book. Zim files added through iTunes File Sharing will automatically appear.", comment: "Library Onboarding")
        subtitleLabel.numberOfLines = 0
        downloadButton.setTitle(NSLocalizedString("Download", comment: "Library Onboarding"), for: .normal)
        downloadButton.setTitle(NSLocalizedString("Downloading...", comment: "Library Onboarding"), for: .disabled)
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func downloadButtonTapped(_ sender: UIButton) {
        activityIndicator.startAnimating()
        sender.isEnabled = false

        let operation = LibraryRefreshOperation(updateExisting: true)
        operation.completionBlock = {
            OperationQueue.main.addOperation({
                self.activityIndicator.stopAnimating()
                if operation.error != nil {
                    sender.isEnabled = true
                }
            })
        }
        LibraryOperationQueue.shared.addOperation(operation)
    }
}


/**
 The library split view controller.
 
 The master controller lists zim files that are on device or being downloaded,
 along with all available zim files grouped by categories.
 The detail controller could be detail of a zim file or all zim files belong to one category.
 */
class LibrarySplitController: UISplitViewController, UISplitViewControllerDelegate {
    init() {
        super.init(nibName: nil, bundle: nil)
        
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}
