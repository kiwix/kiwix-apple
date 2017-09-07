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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        transitioningDelegate = self
        view.backgroundColor = UIColor.brown
    }
    
    func addTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(60)-[table]-(60)-|", options: [], metrics: nil, views: ["table": tableView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[table]-(0)-|", options: [], metrics: nil, views: ["table": tableView]))
    }
}
