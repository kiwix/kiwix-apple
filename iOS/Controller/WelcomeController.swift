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
        logoImageView.image = #imageLiteral(resourceName: "Kiwix").withRenderingMode(.alwaysTemplate)
        logoImageView.tintColor = .darkGray
        button.setTitle(NSLocalizedString("Open Library", comment: "Welcome"), for: .normal)
    }
    
    @IBAction func leftButtonTapped(_ sender: Any) {
        guard let mainController = parent as? MainController else {return}
        mainController.present(mainController.libraryController, animated: true, completion: nil)
    }
    
    @IBAction func rightButtonTapped(_ sender: Any) {
        
    }
}
