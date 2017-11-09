//
//  SearchResultView.swift
//  Kiwix
//
//  Created by Chris Li on 9/8/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class SearchResultView: UIView {
    let tableView = UITableView()
    let emptyResult = EmptyResultView()
    let searching = SearchingView()
    private var bottomAnchorConstraints = [NSLayoutConstraint]()
    
    init() {
        super.init(frame: CGRect.zero)
        configureViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }
    
    var bottomInset: CGFloat = 0 {
        didSet {
            bottomAnchorConstraints.forEach({$0.constant = -bottomInset})
        }
    }
    
    private func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        let views = [tableView, emptyResult, searching]
        views.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .clear
            addSubview(view)
            let bottomConstraint = view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomInset)
            NSLayoutConstraint.activate([
                view.leftAnchor.constraint(equalTo: leftAnchor),
                view.rightAnchor.constraint(equalTo: rightAnchor),
                view.topAnchor.constraint(equalTo: topAnchor),
                bottomConstraint])
            addConstraints(constraints)
            bottomAnchorConstraints.append(bottomConstraint)
        }
        emptyResult.isHidden = false
        tableView.isHidden = true
        searching.isHidden = true
    }
}

class SearchingView: UIView {
    let activityIndicator = UIActivityIndicatorView()
    
    init() {
        super.init(frame: CGRect.zero)
        addActivityIndicator()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func addActivityIndicator() {
        activityIndicator.activityIndicatorViewStyle = .gray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        addConstraints([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}

class EmptyResultView: UIView {
    let noResult = UILabel()
    
    init() {
        super.init(frame: CGRect.zero)
        addNoResultLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func addNoResultLabel() {
        noResult.text = "No Results"
        noResult.translatesAutoresizingMaskIntoConstraints = false
        addSubview(noResult)
        addConstraints([
            noResult.centerXAnchor.constraint(equalTo: centerXAnchor),
            noResult.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
