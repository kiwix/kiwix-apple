//
//  LibraryOnboardingController.swift
//  iOS
//
//  Created by Chris Li on 4/30/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import ProcedureKit

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
                    //                    if let libraryController = self.navigationController?.parent as? LibraryController {
                    //                        libraryController.config()
                    //                    }
                } else {
                    self.downloadButton.isEnabled = true
                }
            })
        }))
        Queue.shared.add(libraryRefresh: procedure)
    }
}
