//
//  SearchContainer.swift
//  Kiwix
//
//  Created by Chris Li on 11/14/16.
//  Copyright © 2016 Wikimedia CH. All rights reserved.
//

import UIKit

class SearchContainer: UIViewController {
    
    @IBOutlet weak var dimView: UIView!
    
    var delegate: SearchContainerDelegate?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleDimViewTap))
        dimView.addGestureRecognizer(tap)
    }
    
    func handleDimViewTap() {
        delegate?.didTapDimView()
    }

}

protocol SearchContainerDelegate: class {
    func didTapDimView()
}
