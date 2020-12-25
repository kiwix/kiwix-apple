//
//  WelcomeController.swift
//  iOS
//
//  Created by Chris Li on 1/11/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class WelcomeController: UIViewController {
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var button: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 14.0, *) {
            navigationController?.isNavigationBarHidden = true
        }
        button.setTitle(NSLocalizedString("Open Library", comment: "Welcome"), for: .normal)
    }
    
    @IBAction func leftButtonTapped(_ sender: Any) {
        guard let rootController = splitViewController?.parent as? RootViewController else {return}
        rootController.libraryButtonTapped()
    }
    
    @IBAction func rightButtonTapped(_ sender: Any) {
        
    }
}
