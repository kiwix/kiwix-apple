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
    let button = ProminentButton(theme: .blue)
    
    enum WelcomePageStatus {
        case openLibrary, openMainPage, readLast
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stackView.arrangedSubviews.forEach { (subView) in
            stackView.removeArrangedSubview(subView)
            subView.removeFromSuperview()
        }
        stackView.addArrangedSubview(button)
        
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "LibraryScanFinished"), object: nil, queue: nil) { (notification) in
            OperationQueue.main.addOperation({ 
                self.configureButtons()
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func configureButtons() {
        UIView.animate(withDuration: 0.2) {
            if ZimMultiReader.shared.readers.count == 0 {
                self.button.theme = .blue
                self.button.configureText(title: "Open Library", subtitle: "Download or import a book")
                self.button.addTarget(Controllers.main, action: #selector(MainController.didTapLibraryButton), for: .touchUpInside)
            } else {
                self.button.theme = .green
                self.button.configureText(title: "Start Reading", subtitle: "Open main page of placeholder")
                self.button.addTarget(Controllers.main, action: #selector(MainController.didTapLibraryButton), for: .touchUpInside)
            }
        }
    }
}

class ProminentButton: UIButton {
    var theme: Theme {
        didSet {
            configureColor()
        }
    }
    
    init(theme: Theme) {
        self.theme = theme
        super.init(frame: CGRect.zero)
        
        layer.cornerRadius = 10.0
        layer.masksToBounds = true
        configureColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isHighlighted: Bool {
        didSet {
            configureColor()
        }
    }
    
    private func configureColor() {
        switch theme {
        case .blue:
            backgroundColor = isHighlighted ? Color.Blue.highlighted : Color.Blue.normal
        case .green:
            backgroundColor = isHighlighted ? Color.Green.highlighted : Color.Green.normal
        case .orange:
            backgroundColor = isHighlighted ? Color.Orange.highlighted : Color.Orange.normal
        }
    }
    
    func configureText(title: String, subtitle: String?) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let title = NSMutableAttributedString(string: subtitle == nil ? title : (title + "\n"), attributes: [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium),
            NSParagraphStyleAttributeName: style])
        if let subtitle = subtitle {
            let attributedSubtitle = NSMutableAttributedString(string: subtitle, attributes: [
                NSForegroundColorAttributeName: UIColor.white,
                NSFontAttributeName: UIFont.systemFont(ofSize: 13, weight: UIFontWeightRegular),
                NSParagraphStyleAttributeName: style])
            title.append(attributedSubtitle)
        }
        titleLabel?.numberOfLines = 0
        setAttributedTitle(title, for: .normal)
    }
    
    enum Theme {
        case blue, green, orange
    }
    
    fileprivate class Color {
        fileprivate class Blue {
            fileprivate static let normal = UIColor(colorLiteralRed: 1/255, green: 121/255, blue: 1, alpha: 1)
            fileprivate static let highlighted = UIColor(colorLiteralRed: 125/255, green: 185/255, blue: 248/255, alpha: 1)
        }
        fileprivate class Green {
            fileprivate static let normal = UIColor(colorLiteralRed: 72/255, green: 218/255, blue: 104/255, alpha: 1)
            fileprivate static let highlighted = UIColor(colorLiteralRed: 54/255, green: 197/255, blue: 91/255, alpha: 1)
        }
        fileprivate class Orange {
            fileprivate static let normal = UIColor(colorLiteralRed: 1/255, green: 121/255, blue: 1, alpha: 1)
            fileprivate static let highlighted = UIColor(colorLiteralRed: 125/255, green: 185/255, blue: 248/255, alpha: 1)
        }
    }
}
