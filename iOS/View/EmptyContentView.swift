//
//  BackgroundStackView.swift
//  iOS
//
//  Created by Chris Li on 1/12/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class EmptyContentView: UIView {
    convenience init(image: UIImage, title: String, subtitle: String? = nil) {
        self.init(frame: .zero)
        let stackView = BackgroundStackView(
            image: #imageLiteral(resourceName: "StarColor"),
            title: NSLocalizedString("Bookmark your favorite articles", comment: "Help message when there's no bookmark to show"),
            subtitle: NSLocalizedString("To add, long press the star button on the tool bar.", comment: "Help message when there's no bookmark to show"))
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            leftAnchor.constraint(lessThanOrEqualTo: stackView.leftAnchor, constant: 20),
            rightAnchor.constraint(greaterThanOrEqualTo: stackView.rightAnchor, constant: 20)])
    }
}

class BackgroundStackView: UIStackView {
    let labels = UIStackView()
    
    init(image: UIImage, title: String, subtitle: String? = nil) {
        let imageView: UIImageView = {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.addConstraints([
                imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 100),
                imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 100)])
            return imageView
        }()
        
        let titleLabel: UILabel = {
            let label = UILabel()
            label.text = title
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.textColor = UIColor.gray
            label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            label.numberOfLines = 0
            return label
        }()
        labels.addArrangedSubview(titleLabel)
        
        if let subtitle = subtitle {
            let subtitleLabel: UILabel = {
                let label = UILabel()
                label.text = subtitle
                label.textAlignment = .center
                label.adjustsFontSizeToFitWidth = true
                label.textColor = UIColor.lightGray
                label.font = UIFont.systemFont(ofSize: 15)
                label.numberOfLines = 0
                return label
            }()
            labels.addArrangedSubview(subtitleLabel)
        }
        
        super.init(frame: .zero)
        
        axis = .vertical
        spacing = 25
        distribution = .equalSpacing
        alignment = .center
        
        labels.axis = .vertical
        labels.spacing = 5
        
        addArrangedSubview(imageView)
        addArrangedSubview(labels)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}
