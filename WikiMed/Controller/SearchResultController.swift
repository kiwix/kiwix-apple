//
//  SearchResultController.swift
//  WikiMed
//
//  Created by Chris Li on 9/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class SearchResultController: UIViewController, UIViewControllerTransitioningDelegate {
    let tableView = UITableView()
    let visual = VisualEffectShadowView()
    let background = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        view.removeConstraints(visual.constraints)
        if traitCollection.horizontalSizeClass == .regular {
            tableView.removeFromSuperview()
            addBackgroundView()
            addVisualView()
        } else if traitCollection.horizontalSizeClass == .compact {
            background.removeFromSuperview()
            visual.removeFromSuperview()
            addTableView()
        }
    }
    
    func addTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.removeFromSuperview()
        tableView.backgroundColor = .white
        view.addSubview(tableView)
        view.addConstraints([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
    }
    
    func addBackgroundView() {
        background.translatesAutoresizingMaskIntoConstraints = false
        background.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25)
        view.addSubview(background)
        if background.gestureRecognizers?.count ?? 0 == 0 {
            background.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundViewTapped)))
        }
        view.addSubview(background)
        view.addConstraints([
            background.topAnchor.constraint(equalTo: view.topAnchor),
            background.leftAnchor.constraint(equalTo: view.leftAnchor),
            background.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            background.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
    }
    
    func addVisualView() {
        visual.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visual)
        let widthPropotion = visual.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75)
        widthPropotion.priority = .defaultHigh
        view.addConstraints([
            visual.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            visual.topAnchor.constraint(equalTo: view.topAnchor, constant: -visual.shadow.blur),
            visual.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.75),
            widthPropotion,
            visual.widthAnchor.constraint(lessThanOrEqualToConstant: 800)
        ])
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.removeFromSuperview()
        tableView.backgroundColor = .clear
        let contentView = visual.visualEffectView.contentView
        contentView.addSubview(tableView)
        contentView.addConstraints([
            tableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tableView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        ])
    }
    
    @objc func backgroundViewTapped() {
        guard let main = parent as? MainController else {return}
        main.searchBar.resignFirstResponder()
    }
}
