//
//  LibraryDetailController.swift
//  Kiwix
//
//  Created by Chris Li on 10/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class LibraryBlankDetailController: UIViewController {
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .groupTableViewBackground
        title = NSLocalizedString("Detail", comment: "Library placeholder text")
        configStackView()
    }
    
    private func configStackView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        view.addConstraints([
            view.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: stackView.centerYAnchor)])
        
        let imageView = UIImageView(image: #imageLiteral(resourceName: "LibraryColor").withRenderingMode(.alwaysTemplate))
        imageView.tintColor = UIColor.darkText.withAlphaComponent(0.5)
        
        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("Tap on a book or category to view details", comment: "Library placeholder text")
        titleLabel.textColor = UIColor.darkText.withAlphaComponent(0.5)
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
        
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 40
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
    }
}



