//
//  BackgroundStackView.swift
//  iOS
//
//  Created by Chris Li on 1/12/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

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
