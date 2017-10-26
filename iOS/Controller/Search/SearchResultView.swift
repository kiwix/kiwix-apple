//
//  SearchResultView.swift
//  Kiwix
//
//  Created by Chris Li on 9/8/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class SearchResultTitleCell: UITableViewCell {
    let titleLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
        configureLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func configureLabel() {
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        contentView.addConstraints([
            titleLabel.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
            titleLabel.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}

class SearchResultTitleSnippetCell: UITableViewCell {
    let titleLabel = UILabel()
    let snippetLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor.clear
        configureLabels()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func configureLabels() {
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
        snippetLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        snippetLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        snippetLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        contentView.addSubview(snippetLabel)
        contentView.addConstraints([
            titleLabel.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
            titleLabel.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: snippetLabel.topAnchor),
            snippetLabel.leftAnchor.constraint(equalTo: contentView.readableContentGuide.leftAnchor),
            snippetLabel.rightAnchor.constraint(equalTo: contentView.readableContentGuide.rightAnchor),
            snippetLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])
    }
}

class SearchResultHorizontalRegularContainerView: UIView, UIGestureRecognizerDelegate {
    let visualShadowView = VisualEffectShadowView()
    
    init() {
        super.init(frame: CGRect.zero)
        configureViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }
    
    private func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.lightGray.withAlphaComponent(0.25)
        
        visualShadowView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visualShadowView)
        let widthPropotion = visualShadowView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.75)
        widthPropotion.priority = .defaultHigh
        let constraints = [
            visualShadowView.centerXAnchor.constraint(equalTo: centerXAnchor),
            visualShadowView.topAnchor.constraint(equalTo: topAnchor, constant: -visualShadowView.shadow.blur),
            visualShadowView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.75),
            widthPropotion,
            visualShadowView.widthAnchor.constraint(lessThanOrEqualToConstant: 800)
        ]
        addConstraints(constraints)
    }
    
    func add(searchResultView: SearchResultView) {
        let contentView = visualShadowView.contentView
        contentView.addSubview(searchResultView)
        let constraints = [
            searchResultView.topAnchor.constraint(equalTo: contentView.topAnchor),
            searchResultView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            searchResultView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            searchResultView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]
        contentView.addConstraints(constraints)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self
    }
}

class SearchResultHorizontalCompactContainerView: UIView {
    init() {
        super.init(frame: CGRect.zero)
        configureViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }
    
    private func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.white
    }
    
    func add(searchResultView: SearchResultView) {
        addSubview(searchResultView)
        let constraints = [
            searchResultView.topAnchor.constraint(equalTo: topAnchor),
            searchResultView.leftAnchor.constraint(equalTo: leftAnchor),
            searchResultView.rightAnchor.constraint(equalTo: rightAnchor),
            searchResultView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        addConstraints(constraints)
    }
}

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
            let constraints = [
                view.leftAnchor.constraint(equalTo: leftAnchor),
                view.rightAnchor.constraint(equalTo: rightAnchor),
                view.topAnchor.constraint(equalTo: topAnchor),
                bottomConstraint
            ]
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
