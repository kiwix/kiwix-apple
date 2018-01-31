//
//  VisualEffectShadowView.swift
//  Kiwix
//
//  Created by Chris Li on 10/10/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

// A View similiar to a UIVisualEffectView but with shadow around it
class VisualEffectShadowView: UIView {
    struct Shadow {
        let offset: CGSize
        let blur: CGFloat
        let color: UIColor
    }
    
    let shadow = Shadow(offset: CGSize.zero, blur: 4.0, color: .lightGray)
    var roundingCorners: UIRectCorner? = .allCorners
    var cornerRadius: CGFloat = 10.0
    private let visual = UIVisualEffectView()
    
    var contentView: UIView {
        get {return visual.contentView}
    }
    
    init() {
        super.init(frame: .zero)
        addVisualEffectView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addVisualEffectView()
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        guard let corners = roundingCorners else {
            context.clear(rect)
            visual.layer.mask = nil
            return
        }
        
        // shadow
        let contentRect = rect.insetBy(dx: shadow.blur, dy: shadow.blur)
        let shadowPath = UIBezierPath(roundedRect: contentRect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        
        context.addRect(rect)
        context.addPath(shadowPath.cgPath)
        context.clip(using: .evenOdd)
        
        context.addPath(shadowPath.cgPath)
        context.setShadow(offset: CGSize.zero, blur: shadow.blur, color: shadow.color.cgColor)
        context.fillPath()
        
        // mask visualView
        let maskPath = UIBezierPath(roundedRect: contentRect.offsetBy(dx: -contentRect.origin.x, dy: -contentRect.origin.y), byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        let visualViewMask = CAShapeLayer()
        visualViewMask.path = maskPath.cgPath
        visual.layer.mask = visualViewMask
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    private func addVisualEffectView() {
        visual.effect = UIBlurEffect(style: .extraLight)
        visual.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visual)
        NSLayoutConstraint.activate([
            visual.leftAnchor.constraint(equalTo: leftAnchor, constant: shadow.blur),
            visual.topAnchor.constraint(equalTo: topAnchor, constant: shadow.blur),
            visual.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -shadow.blur),
            visual.rightAnchor.constraint(equalTo: rightAnchor, constant: -shadow.blur)])
    }
}
