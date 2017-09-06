//
//  EmptyContentView.swift
//  iOS
//
//  Created by Chris Li on 1/12/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class EmptyContentView: UIView {
    convenience init(image: UIImage, title: String, subtitle: String? = nil) {
        self.init(frame: .zero)
        
        let labels: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 5
            
            let titleLabel: UILabel = {
                let label = UILabel()
                label.text = title
                label.textAlignment = .center
                label.adjustsFontSizeToFitWidth = true
                label.textColor = UIColor.gray
                label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
                return label
            }()
            stackView.addArrangedSubview(titleLabel)
            
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
                stackView.addArrangedSubview(subtitleLabel)
            }
            return stackView
        }()
        
        let imageView: UIImageView = {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            return imageView
        }()
        
        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 25
        content.distribution = .equalSpacing
        content.alignment = .center
        content.addArrangedSubview(imageView)
        content.addArrangedSubview(labels)
        
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 100),
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 100),
            centerXAnchor.constraint(equalTo: content.centerXAnchor),
            centerYAnchor.constraint(equalTo: content.centerYAnchor),
            leftAnchor.constraint(lessThanOrEqualTo: content.leftAnchor, constant: 20),
            rightAnchor.constraint(greaterThanOrEqualTo: content.rightAnchor, constant: 20)])
    }
}
