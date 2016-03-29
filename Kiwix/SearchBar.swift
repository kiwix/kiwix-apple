//
//  SearchBar.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

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
        customSearchField.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)
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
class SearchBar: UISearchBar {
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
        //listSubviewOfView(self)
    }
    
    func listSubviewOfView(view: UIView) {
        for subView in view.subviews {
            print(subviews.description)
            listSubviewOfView(subView)
        }
    }
    
    // MARK: - 
    
    func setScale(scale: CGFloat) {
        layer.transform = CATransform3DMakeScale(scale, scale, 1.0)
    }
}