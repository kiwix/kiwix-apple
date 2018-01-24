//
//  BaseController.swift
//  iOS
//
//  Created by Chris Li on 1/24/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class BaseController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    func configure(tableView: UITableView) {
        guard !view.subviews.contains(tableView) else {return}
        tableView.backgroundColor = .clear
        view.subviews.forEach({ $0.removeFromSuperview() })
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: tableView.topAnchor),
            view.leftAnchor.constraint(equalTo: tableView.leftAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            view.rightAnchor.constraint(equalTo: tableView.rightAnchor)])
    }
    
    func configure(stackView : UIStackView) {
        guard !view.subviews.contains(stackView) else {return}
        view.subviews.forEach({ $0.removeFromSuperview() })
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            view.leftAnchor.constraint(lessThanOrEqualTo: stackView.leftAnchor, constant: 20),
            view.rightAnchor.constraint(greaterThanOrEqualTo: stackView.rightAnchor, constant: 20)])
    }
}
