//
//  SearchResultView.swift
//  Kiwix
//
//  Created by Chris Li on 9/8/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class SearchResultContainerView: UIView {
    private var bottomConstraint: NSLayoutConstraint? = nil
    var bottomInset: CGFloat = 0 {
        didSet {
            bottomConstraint?.constant = bottomInset
        }
    }
    
    func setContent(view: UIView) {
        subviews.forEach({ $0.removeFromSuperview() })
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        addSubview(view)
        
        view.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        bottomConstraint = bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottomInset)
        bottomConstraint?.isActive = true
    }
}

class SearchingView: UIView {
    let activityIndicator = UIActivityIndicatorView()
    
    convenience init() {
        self.init(frame: CGRect.zero)
        activityIndicator.activityIndicatorViewStyle = .gray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)])
    }
}

class SearchEmptyResultView: UIView {
    private let noResult = UILabel()
    
    convenience init() {
        self.init(frame: CGRect.zero)
        let label = UILabel()
        label.text = NSLocalizedString("No Results", comment: "Search: no result")
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)])
    }
}
