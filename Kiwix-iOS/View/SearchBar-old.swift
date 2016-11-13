//
//  SearchBar.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class SearchBar: UISearchBar, UISearchBarDelegate {
    var searchTerm: String? {
        didSet {
            text = searchTerm
        }
    }
    
    var articleTitle: String? {
        didSet {
            configurePlaceholder()
        }
    }
    
    fileprivate var textField: UITextField {
        return value(forKey: "searchField") as! UITextField
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        self.searchBarStyle = .minimal
        self.autocapitalizationType = .none
        self.placeholder = LocalizedStrings.search
        self.returnKeyType = .go
        self.delegate = self
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        text = searchTerm
        configurePlaceholder()
        Controllers.main.showSearch(animated: true)
        let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(0.05 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: { [unowned self] in
            self.textField.selectAll(nil)
        })
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        text = nil
        configurePlaceholder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        Controllers.main.hideSearch(animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTerm = searchText
        Controllers.search.startSearch(searchText, delayed: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        Controllers.search.searchResultController?.selectFirstResultIfPossible()
    }
    
    // MARK: - Helper
    
    fileprivate func configurePlaceholder() {
        if textField.isEditing {
            placeholder = LocalizedStrings.search
        } else {
            placeholder = articleTitle ?? LocalizedStrings.search
        }
    }
    
    fileprivate func truncatedPlaceHolderString(_ string: String?, searchBar: UISearchBar) -> String? {
        guard let string = string,
            let labelFont = textField.font else {return nil}
        let preferredSize = CGSize(width: searchBar.frame.width - 45.0, height: 1000)
        var rect = (string as NSString).boundingRect(with: preferredSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: labelFont], context: nil)
        
        var truncatedString = string as NSString
        var istruncated = false
        while rect.height > textField.frame.height {
            istruncated = true
            truncatedString = truncatedString.substring(to: truncatedString.length - 2) as NSString
            rect = truncatedString.boundingRect(with: preferredSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: labelFont], context: nil)
        }
        return truncatedString as String + (istruncated ? "..." : "")
    }
}
