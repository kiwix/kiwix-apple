//
//  BackgroundStackView.swift
//  iOS
//
//  Created by Chris Li on 1/12/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

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
