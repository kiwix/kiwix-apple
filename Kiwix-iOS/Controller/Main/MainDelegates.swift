//
//  MainControllerDelegates.swift
//  Kiwix
//
//  Created by Chris Li on 11/14/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

extension MainController: SearchBarDelegate, ButtonDelegates, SearchContainerDelegate {
    
    // MARK: - SearchBarDelegate
    
    func didBecomeFirstResponder(searchBar: SearchBar) {
        showSearch(animated: true)
    }
    
    func didResignFirstResponder(searchBar: SearchBar) {
        hideSearch(animated: true)
    }
    
    func textDidChange(text: String, searchBar: SearchBar) {
        controllers.search.searchText = text
    }
    
    // MARK: - Button Delegates
    
    func didTapLibraryButton() {
        present(controllers.library, animated: true, completion: nil)
    }
    
    func didTapCancelButton() {
        _ = searchBar.resignFirstResponder()
    }
    
    // MARK: - SearchContainerDelegate
    
    func didTapDimView() {
        _ = searchBar.resignFirstResponder()
    }

}
