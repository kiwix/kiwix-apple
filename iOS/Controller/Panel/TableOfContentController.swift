//
//  TableOfContentController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class TableOfContentController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView()
    private weak var stackView: UIStackView?
    var headings = [HTMLHeading]() {
        didSet {
            configure()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configure()
    }
    
    func configure() {
        if headings.count == 0 {
            configure(stackView: BackgroundStackView(image: #imageLiteral(resourceName: "Compass"), text: NSLocalizedString("Table of content not available", comment: "Empty Library Help")))
        } else {
            configureTableView()
        }
    }

    func configureTableView() {
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
        view.subviews.forEach({ $0.removeFromSuperview() })
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            view.leftAnchor.constraint(lessThanOrEqualTo: stackView.leftAnchor, constant: 20),
            view.rightAnchor.constraint(greaterThanOrEqualTo: stackView.rightAnchor, constant: 20)])
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return headings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let heading = headings[indexPath.row]
        cell.textLabel?.text = heading.textContent
        cell.indentationLevel = (heading.level - 1) * 2
        return cell
    }
}

class BackgroundStackView: UIStackView {
    init(image: UIImage, text: String) {
        let imageView: UIImageView = {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.addConstraints([
                imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 100),
                imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 100)])
            return imageView
        }()
        
        let label: UILabel = {
            let label = UILabel()
            label.text = text
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.textColor = UIColor.gray
            label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
            label.numberOfLines = 0
            return label
        }()
        
        super.init(frame: .zero)
        
        axis = .vertical
        spacing = 25
        distribution = .equalSpacing
        alignment = .center
        
        addArrangedSubview(imageView)
        addArrangedSubview(label)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}
