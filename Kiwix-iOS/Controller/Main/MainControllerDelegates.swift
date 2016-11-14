//
//  MainControllerDelegates.swift
//  Kiwix
//
//  Created by Chris Li on 11/14/16.
//  Copyright © 2016 Wikimedia CH. All rights reserved.
//

import UIKit

extension MainController: SearchBarDelegate {
    
    // MARK: - SearchBarDelegate
    
    func didBecomeFIrstResponder() {
        showSearch(animated: true)
    }
    
    func didResignFirstResponder() {
        
    }

}
