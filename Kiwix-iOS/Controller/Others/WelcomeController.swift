//
//  WelcomeController.swift
//  Kiwix
//
//  Created by Chris Li on 9/21/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class WelcomeController: UIViewController {
    @IBOutlet weak var stackView: UIStackView!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let button = OpenLibraryButton()
        stackView.addArrangedSubview(button)
    }

}

class OpenLibraryButton: UIButton {
    init() {
        super.init(frame: CGRect.zero)
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attributedTitle = NSMutableAttributedString(string: "Open Library\n", attributes: [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium),
            NSParagraphStyleAttributeName: style
            ]
        )
        let attributedSubtitle = NSMutableAttributedString(string: "Download or import a book", attributes: [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont.systemFont(ofSize: 13, weight: UIFontWeightRegular),
            NSParagraphStyleAttributeName: style
            ])
        attributedTitle.append(attributedSubtitle)
        
        titleLabel?.numberOfLines = 0
        setAttributedTitle(attributedTitle, for: UIControlState.normal)
        setTitleColor(UIColor.white, for: UIControlState.normal)
        layer.cornerRadius = 10.0
        backgroundColor = UIColor.blue
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.lightGray : UIColor.orange
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
