//
//  HomeController.swift
//  iOS
//
//  Created by Chris Li on 11/10/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class HomeController: UIViewController {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var libraryButton: RoundedButton!
    @IBOutlet weak var settingsButton: RoundedButton!
    
    override func viewDidLoad() {
        libraryButton.setTitle(NSLocalizedString("Open Library", comment: "Open Library"), for: .normal)
        settingsButton.setTitle(NSLocalizedString("Open Settings", comment: "Open Library"), for: .normal)
    }
    
}

//@IBDesignable
class Logo: UIView {
    override func draw(_ rect: CGRect) {
        let fillColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)
        let fillColor2 = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
        let color2 = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
        
        //// Frames
        let frame = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height)
        
        //// Subframes
        let scaleX = rect.size.width / 200
        let scaleY = rect.size.height / 200
        let bird: CGRect = CGRect(x: frame.minX + 38 * scaleX, y: frame.minY + 52 * scaleY, width: frame.width - 75.46 * scaleX, height: frame.height - 104.28 * scaleY)
        
        
        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height))
        UIColor.gray.setFill()
        ovalPath.fill()
        
        
        //// Oval 2 Drawing
        let oval2Path = UIBezierPath(ovalIn: CGRect(x: frame.minX + 5 * scaleX, y: frame.minY + 5 * scaleX, width: frame.width - 10 * scaleX, height: frame.height - 10 * scaleX))
        color2.setFill()
        oval2Path.fill()
        
        
        //// Bird
        //// ball Drawing
        let ballPath = UIBezierPath(ovalIn: CGRect(x: bird.minX + floor(bird.width * 0.56138 - 0.41) + 0.91, y: bird.minY + floor(bird.height * 0.53988 + 0.46) + 0.04, width: floor(bird.width * 0.90665 - 0.41) - floor(bird.width * 0.56138 - 0.41), height: floor(bird.height * 0.96820 + 0.46) - floor(bird.height * 0.53988 + 0.46)))
        fillColor.setFill()
        ballPath.fill()
        
        
        //// body Drawing
        let bodyPath = UIBezierPath()
        bodyPath.move(to: CGPoint(x: bird.minX + 0.29404 * bird.width, y: bird.minY + 0.00004 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.10758 * bird.width, y: bird.minY + 0.62219 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.05653 * bird.width, y: bird.minY + 0.00433 * bird.height), controlPoint2: CGPoint(x: bird.minX + -0.12441 * bird.width, y: bird.minY + 0.32819 * bird.height))
        bodyPath.addLine(to: CGPoint(x: bird.minX + 0.16941 * bird.width, y: bird.minY + 0.82400 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.16027 * bird.width, y: bird.minY + 1.00000 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.17968 * bird.width, y: bird.minY + 0.87013 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.14486 * bird.width, y: bird.minY + 0.97165 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.20598 * bird.width, y: bird.minY + 0.88707 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.17803 * bird.width, y: bird.minY + 0.95647 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.18251 * bird.width, y: bird.minY + 0.89424 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.34288 * bird.width, y: bird.minY + 0.98211 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.24728 * bird.width, y: bird.minY + 0.92322 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.30836 * bird.width, y: bird.minY + 0.93549 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.25964 * bird.width, y: bird.minY + 0.88795 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.35578 * bird.width, y: bird.minY + 0.93691 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.30346 * bird.width, y: bird.minY + 0.91383 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.35925 * bird.width, y: bird.minY + 0.91317 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.30060 * bird.width, y: bird.minY + 0.89642 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.32893 * bird.width, y: bird.minY + 0.86891 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.34625 * bird.width, y: bird.minY + 0.85979 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.36371 * bird.width, y: bird.minY + 0.89078 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.35807 * bird.width, y: bird.minY + 0.87366 * bird.height))
        bodyPath.addLine(to: CGPoint(x: bird.minX + 0.32773 * bird.width, y: bird.minY + 0.82840 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.46679 * bird.width, y: bird.minY + 0.89030 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.36198 * bird.width, y: bird.minY + 0.85094 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.44721 * bird.width, y: bird.minY + 0.85080 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.36887 * bird.width, y: bird.minY + 0.81872 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.47436 * bird.width, y: bird.minY + 0.81556 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.40269 * bird.width, y: bird.minY + 0.84109 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.43431 * bird.width, y: bird.minY + 0.81227 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.39081 * bird.width, y: bird.minY + 0.82210 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.41262 * bird.width, y: bird.minY + 0.80856 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.40375 * bird.width, y: bird.minY + 0.78382 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.42850 * bird.width, y: bird.minY + 0.79131 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.41851 * bird.width, y: bird.minY + 0.78224 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.28081 * bird.width, y: bird.minY + 0.50545 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.28740 * bird.width, y: bird.minY + 0.81820 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.27921 * bird.width, y: bird.minY + 0.57456 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.72038 * bird.width, y: bird.minY + 0.42918 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.43700 * bird.width, y: bird.minY + 0.42331 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.59474 * bird.width, y: bird.minY + 0.57066 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.98359 * bird.width, y: bird.minY + 0.72046 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.76152 * bird.width, y: bird.minY + 0.35300 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.93132 * bird.width, y: bird.minY + 0.55197 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.77403 * bird.width, y: bird.minY + 0.33942 * bird.height), controlPoint1: CGPoint(x: bird.minX + 1.06175 * bird.width, y: bird.minY + 0.67949 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.83878 * bird.width, y: bird.minY + 0.41188 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.55702 * bird.width, y: bird.minY + 0.13732 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.80785 * bird.width, y: bird.minY + 0.22799 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.67607 * bird.width, y: bird.minY + 0.06577 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.29404 * bird.width, y: bird.minY + 0.00004 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.47324 * bird.width, y: bird.minY + 0.03871 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.37995 * bird.width, y: bird.minY + -0.00151 * bird.height))
        bodyPath.close()
        bodyPath.move(to: CGPoint(x: bird.minX + 0.23101 * bird.width, y: bird.minY + 0.60225 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.25338 * bird.width, y: bird.minY + 0.62542 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.24240 * bird.width, y: bird.minY + 0.60194 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.25161 * bird.width, y: bird.minY + 0.60964 * bird.height))
        bodyPath.addLine(to: CGPoint(x: bird.minX + 0.27865 * bird.width, y: bird.minY + 0.77502 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.26180 * bird.width, y: bird.minY + 0.82723 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.26503 * bird.width, y: bird.minY + 0.77987 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.25911 * bird.width, y: bird.minY + 0.79676 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.28322 * bird.width, y: bird.minY + 0.80904 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.26757 * bird.width, y: bird.minY + 0.81879 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.26995 * bird.width, y: bird.minY + 0.80438 * bird.height))
        bodyPath.addLine(to: CGPoint(x: bird.minX + 0.31449 * bird.width, y: bird.minY + 0.85891 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.18144 * bird.width, y: bird.minY + 0.67147 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.20812 * bird.width, y: bird.minY + 0.86922 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.19993 * bird.width, y: bird.minY + 0.79471 * bird.height))
        bodyPath.addCurve(to: CGPoint(x: bird.minX + 0.23101 * bird.width, y: bird.minY + 0.60225 * bird.height), controlPoint1: CGPoint(x: bird.minX + 0.18708 * bird.width, y: bird.minY + 0.62573 * bird.height), controlPoint2: CGPoint(x: bird.minX + 0.21202 * bird.width, y: bird.minY + 0.60276 * bird.height))
        bodyPath.close()
        bodyPath.miterLimit = 4;
        
        fillColor.setFill()
        bodyPath.fill()
        
        
        //// sclera Drawing
        let scleraPath = UIBezierPath(ovalIn: CGRect(x: bird.minX + floor(bird.width * 0.59068 - 0.06) + 0.56, y: bird.minY + floor(bird.height * 0.20662 + 0.46) + 0.04, width: floor(bird.width * 0.69186 + 0.34) - floor(bird.width * 0.59068 - 0.06) - 0.4, height: floor(bird.height * 0.34139 - 0.44) - floor(bird.height * 0.20662 + 0.46) + 0.9))
        fillColor2.setFill()
        scleraPath.fill()
        
        
        //// iris Drawing
        let irisPath = UIBezierPath(ovalIn: CGRect(x: bird.minX + floor(bird.width * 0.62280 - 0.06) + 0.56, y: bird.minY + floor(bird.height * 0.27923 - 0.09) + 0.59, width: floor(bird.width * 0.68865 - 0.26) - floor(bird.width * 0.62280 - 0.06) + 0.2, height: floor(bird.height * 0.34609 - 0.49) - floor(bird.height * 0.27923 - 0.09) + 0.4))
        fillColor.setFill()
        irisPath.fill()
    }
}
