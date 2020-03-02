//
//  EmptyContentView.swift
//  iOS
//
//  Created by Chris Li on 1/12/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class EmptyContentView: UIView {
    let content = UIStackView()
    
    convenience init(image: UIImage, title: String, subtitle: String? = nil) {
        self.init(frame: .zero)
        
        let labels: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 5
            
            let titleLabel = TitleLabel(text: title)
            stackView.addArrangedSubview(titleLabel)
            
            if let subtitle = subtitle {
                stackView.addArrangedSubview(SubtitleLabel(text: subtitle))
            }
            return stackView
        }()
        
        let imageView: UIImageView = {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            return imageView
        }()
        
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
            rightAnchor.constraint(greaterThanOrEqualTo: content.rightAnchor, constant: 20),
            content.widthAnchor.constraint(lessThanOrEqualToConstant: 400)
        ])
    }
}

class LibraryCategoryBackgroundView: EmptyContentView {
    private let statusContainer = UIStackView()
    let button = RoundedButton()
    let activityIndicator = UIActivityIndicatorView()
    let statusLabel = StatusLabel()
    
    convenience init() {
        self.init(image: #imageLiteral(resourceName: "shelf"), title: "No Zim Files are Available")
        
        statusContainer.heightAnchor.constraint(equalToConstant: 30).isActive = true
        statusContainer.addArrangedSubview(activityIndicator)
        statusContainer.addArrangedSubview(statusLabel)
        content.addArrangedSubview(statusContainer)
        
        button.setTitle("Refresh Library", for: .normal)
        button.setTitle("Refreshing...", for: .disabled)
        content.addArrangedSubview(button)
    }
}

private class TitleLabel: UILabel {
    convenience init(text: String) {
        self.init()
        self.text = text
        textAlignment = .center
        adjustsFontSizeToFitWidth = true
        font = UIFont.systemFont(ofSize: 20, weight: .medium)
        textColor = {
            if #available(iOS 13.0, *) {
                return .label
            } else {
                return .gray
            }
        }()
    }
}

private class SubtitleLabel: UILabel {
    convenience init(text: String) {
        self.init()
        self.text = text
        textAlignment = .center
        adjustsFontSizeToFitWidth = true
        font = UIFont.systemFont(ofSize: 15)
        numberOfLines = 0
        textColor = {
            if #available(iOS 13.0, *) {
                return .secondaryLabel
            } else {
                return .lightGray
            }
        }()
    }
}

class StatusLabel: UILabel {
    convenience init() {
        self.init(frame: .zero)
        self.text = text
        textAlignment = .center
        adjustsFontSizeToFitWidth = true
        font = UIFont.systemFont(ofSize: 15)
        numberOfLines = 0
        textColor = {
            if #available(iOS 13.0, *) {
                return .systemRed
            } else {
                return .red
            }
        }()
    }
}
