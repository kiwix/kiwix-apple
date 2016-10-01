//
//  SearchBar.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
// not used
class CustomSearchBar: UISearchBar, UITextFieldDelegate {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(frame: CGRectZero)
        self.searchBarStyle = .Minimal
        setImage(UIImage(named: "BlankImage"), forSearchBarIcon: .Search, state: .Normal)
    }
    
    override func layoutSubviews() {
        configure()
        super.layoutSubviews()
    }
    
    override var text: String? {
        get{return customSearchField.text}
        set{customSearchField.text = newValue}
    }
    
    // MARK: - vars
    
    let customSearchField = UITextField()
    let leftImageView = UIImageView(image: UIImage(named: "Wiki")?.imageWithRenderingMode(.AlwaysTemplate))
    let rightImageView = UIImageView(image: UIImage(named: "StarHighlighted"))
    
    // MARK: - Configure
    
    func configure() {
        let originalSearchField: UITextField? = {
            for view in subviews {
                for view in view.subviews {
                    guard let searchField = view as? UITextField else {continue}
                    searchField.userInteractionEnabled = false
                    return searchField
                }
            }
            return nil
        }()
        
        customSearchField.clearButtonMode = .WhileEditing
        customSearchField.translatesAutoresizingMaskIntoConstraints = false
        customSearchField.font = originalSearchField?.font
        customSearchField.textColor = originalSearchField?.textColor
        customSearchField.placeholder = placeholder
        customSearchField.textAlignment = customSearchField.editing ? .Left : .Center
        customSearchField.autocapitalizationType = .None
        customSearchField.autocorrectionType = .No
        customSearchField.spellCheckingType = .No
        customSearchField.delegate = self
        customSearchField.addTarget(self, action: #selector(CustomSearchBar.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
        addSubview(customSearchField)
        
        placeholder = nil
        showsCancelButton = false
        
        let views = ["searchField": customSearchField]
        let metrics = ["rightInset": -2]
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[searchField]-(rightInset)-|", options: .AlignAllCenterY, metrics: metrics, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[searchField]-|", options: .AlignAllCenterX, metrics: metrics, views: views))
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        customSearchField.textAlignment = .Left
        delegate?.searchBarTextDidBeginEditing?(self)
    }
    
    func textFieldDidChange(textField: UITextField) {
        guard let text = textField.text else {return}
        delegate?.searchBar?(self, textDidChange: text)
    }
}


// Used in v1.4
class SearchBar: UISearchBar, UISearchBarDelegate {
    var searchTerm: String?
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
        Controllers.shared.main.showSearch(animated: true)
        let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.05 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_main_queue(), { [unowned self] in
            self.textField.selectAll(nil)
        })
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        configurePlaceholder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        Controllers.shared.main.hideSearch(animated: true)
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
