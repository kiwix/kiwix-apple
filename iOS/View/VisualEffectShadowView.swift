//
//  VisualEffectShadowView.swift
//  Kiwix
//
//  Created by Chris Li on 10/10/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class VisualEffectShadowView: UIView {
    struct Shadow {
        let offset: CGSize
        let blur: CGFloat
        let color: UIColor
    }
    
    let shadow = Shadow(offset: CGSize.zero, blur: 4.0, color: .lightGray)
    let cornerRadius: CGFloat = 10.0
    private let visual = UIVisualEffectView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    private func configure() {
        backgroundColor = UIColor.clear
        addVisualEffectView()
    }
    
    var contentView: UIView {
        get {return visual.contentView}
    }
    
    override func draw(_ rect: CGRect) {
        let contentRect = rect.insetBy(dx: shadow.blur, dy: shadow.blur)
        let shadowPath = UIBezierPath(roundedRect: contentRect, cornerRadius: cornerRadius)
        let context = UIGraphicsGetCurrentContext()!
        
        context.addRect(rect)
        context.addPath(shadowPath.cgPath)
        context.clip(using: .evenOdd)
        
        context.addPath(shadowPath.cgPath)
        context.setShadow(offset: CGSize.zero, blur: shadow.blur, color: shadow.color.cgColor)
        context.fillPath()
    }
    
    private func addVisualEffectView() {
        visual.effect = UIBlurEffect(style: .extraLight)
        visual.translatesAutoresizingMaskIntoConstraints = false
        visual.layer.cornerRadius = cornerRadius
        visual.layer.masksToBounds = true
        addSubview(visual)
        let constraints = [
            visual.leftAnchor.constraint(equalTo: leftAnchor, constant: shadow.blur),
            visual.topAnchor.constraint(equalTo: topAnchor, constant: shadow.blur),
            visual.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -shadow.blur),
            visual.rightAnchor.constraint(equalTo: rightAnchor, constant: -shadow.blur),
            ]
        addConstraints(constraints)
    }
}
