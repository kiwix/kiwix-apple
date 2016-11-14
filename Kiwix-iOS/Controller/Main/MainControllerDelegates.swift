//
//  MainControllerDelegates.swift
//  Kiwix
//
//  Created by Chris Li on 11/14/16.
//  Copyright © 2016 Wikimedia CH. All rights reserved.
//

import UIKit

extension MainController: SearchBarDelegate, ButtonDelegates, SearchContainerDelegate {
    
    // MARK: - SearchBarDelegate
    
    func didBecomeFIrstResponder() {
        showSearch(animated: true)
    }
    
    func didResignFirstResponder() {
        hideSearch(animated: true)
    }
    
    // MARK: - Button Delegates
    
    func didTapCancelButton() {
        _ = searchBar.resignFirstResponder()
    }
    
    // MARK: - SearchContainerDelegate
    
    func didTapDimView() {
        _ = searchBar.resignFirstResponder()
    }

}
