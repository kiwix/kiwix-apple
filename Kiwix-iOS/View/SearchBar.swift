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
    
    private var textField: UITextField {
        return valueForKey("searchField") as! UITextField
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(frame: CGRectZero)
        self.searchBarStyle = .Minimal
        self.autocapitalizationType = .None
        self.placeholder = LocalizedStrings.search
        self.returnKeyType = .Go
        self.delegate = self
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        text = searchTerm
        configurePlaceholder()
        Controllers.main.showSearch(animated: true)
        let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.05 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_main_queue(), { [unowned self] in
            self.textField.selectAll(nil)
        })
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        text = nil
        configurePlaceholder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        Controllers.main.hideSearch(animated: true)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchTerm = searchText
        Controllers.search.startSearch(searchText, delayed: true)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        Controllers.search.searchResultController?.selectFirstResultIfPossible()
    }
    
    // MARK: - Helper
    
    private func configurePlaceholder() {
        if textField.editing {
            placeholder = LocalizedStrings.search
        } else {
            placeholder = articleTitle ?? LocalizedStrings.search
        }
    }
    
    private func truncatedPlaceHolderString(string: String?, searchBar: UISearchBar) -> String? {
        guard let string = string,
            let labelFont = textField.font else {return nil}
        let preferredSize = CGSizeMake(searchBar.frame.width - 45.0, 1000)
        var rect = (string as NSString).boundingRectWithSize(preferredSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: labelFont], context: nil)
        
        var truncatedString = string as NSString
        var istruncated = false
        while rect.height > textField.frame.height {
            istruncated = true
            truncatedString = truncatedString.substringToIndex(truncatedString.length - 2)
            rect = truncatedString.boundingRectWithSize(preferredSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: labelFont], context: nil)
        }
        return truncatedString as String + (istruncated ? "..." : "")
    }
}
