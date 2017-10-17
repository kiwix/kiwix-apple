//
//  LibraryDetailController.swift
//  Kiwix
//
//  Created by Chris Li on 10/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class LibraryDetailController: UIViewController {
    enum DisplayMode {
        case downloadProgress, bookDetail, category, empty
    }
    
    private let stackView = UIStackView()
    private var displayMode = DisplayMode.empty
    private lazy var categoryController = LibraryCategoryController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .groupTableViewBackground
        if displayMode == .empty {
            configStackView()
        }
    }
    
    func prepare(category: BookCategory, name: String) {
        displayMode = .category
        view.subviews.forEach({$0.removeFromSuperview()})
        childViewControllers.forEach({$0.removeFromParentViewController()})
        title = name
        
        categoryController.category = category
        let childView = categoryController.view!
        childView.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(categoryController)
        view.addSubview(childView)
        view.addConstraints([
            view.topAnchor.constraint(equalTo: childView.topAnchor),
            view.leftAnchor.constraint(equalTo: childView.leftAnchor),
            view.bottomAnchor.constraint(equalTo: childView.bottomAnchor),
            view.rightAnchor.constraint(equalTo: childView.rightAnchor)])
        categoryController.didMove(toParentViewController: self)
    }
    
    private func configStackView() {
        displayMode = .empty
        view.subviews.forEach({$0.removeFromSuperview()})
        childViewControllers.forEach({$0.removeFromParentViewController()})
        title = NSLocalizedString("Detail", comment: "Library placeholder text")
        
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



