//
//  Logo.swift
//  Kiwix
//
//  Created by Chris on 12/30/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit
@IBDesignable

class Logo: UIView {
    override func drawRect(rect: CGRect) {
        let fillColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)
        let fillColor2 = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
        let color2 = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
        
        //// Frames
        let frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
        
        //// Subframes
        let scaleX = rect.size.width / 200
        let scaleY = rect.size.height / 200
        let bird: CGRect = CGRectMake(frame.minX + 38 * scaleX, frame.minY + 52 * scaleY, frame.width - 75.46 * scaleX, frame.height - 104.28 * scaleY)
        
        
        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalInRect: CGRectMake(frame.minX, frame.minY, frame.width, frame.height))
        UIColor.grayColor().setFill()
        ovalPath.fill()
        
        
        //// Oval 2 Drawing
        let oval2Path = UIBezierPath(ovalInRect: CGRectMake(frame.minX + 5 * scaleX, frame.minY + 5 * scaleX, frame.width - 10 * scaleX, frame.height - 10 * scaleX))
        color2.setFill()
        oval2Path.fill()
        
        
        //// Bird
        //// ball Drawing
        let ballPath = UIBezierPath(ovalInRect: CGRectMake(bird.minX + floor(bird.width * 0.56138 - 0.41) + 0.91, bird.minY + floor(bird.height * 0.53988 + 0.46) + 0.04, floor(bird.width * 0.90665 - 0.41) - floor(bird.width * 0.56138 - 0.41), floor(bird.height * 0.96820 + 0.46) - floor(bird.height * 0.53988 + 0.46)))
        fillColor.setFill()
        ballPath.fill()
        
        
        //// body Drawing
        let bodyPath = UIBezierPath()
        bodyPath.moveToPoint(CGPointMake(bird.minX + 0.29404 * bird.width, bird.minY + 0.00004 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.10758 * bird.width, bird.minY + 0.62219 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.05653 * bird.width, bird.minY + 0.00433 * bird.height), controlPoint2: CGPointMake(bird.minX + -0.12441 * bird.width, bird.minY + 0.32819 * bird.height))
        bodyPath.addLineToPoint(CGPointMake(bird.minX + 0.16941 * bird.width, bird.minY + 0.82400 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.16027 * bird.width, bird.minY + 1.00000 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.17968 * bird.width, bird.minY + 0.87013 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.14486 * bird.width, bird.minY + 0.97165 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.20598 * bird.width, bird.minY + 0.88707 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.17803 * bird.width, bird.minY + 0.95647 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.18251 * bird.width, bird.minY + 0.89424 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.34288 * bird.width, bird.minY + 0.98211 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.24728 * bird.width, bird.minY + 0.92322 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.30836 * bird.width, bird.minY + 0.93549 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.25964 * bird.width, bird.minY + 0.88795 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.35578 * bird.width, bird.minY + 0.93691 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.30346 * bird.width, bird.minY + 0.91383 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.35925 * bird.width, bird.minY + 0.91317 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.30060 * bird.width, bird.minY + 0.89642 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.32893 * bird.width, bird.minY + 0.86891 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.34625 * bird.width, bird.minY + 0.85979 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.36371 * bird.width, bird.minY + 0.89078 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.35807 * bird.width, bird.minY + 0.87366 * bird.height))
        bodyPath.addLineToPoint(CGPointMake(bird.minX + 0.32773 * bird.width, bird.minY + 0.82840 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.46679 * bird.width, bird.minY + 0.89030 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.36198 * bird.width, bird.minY + 0.85094 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.44721 * bird.width, bird.minY + 0.85080 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.36887 * bird.width, bird.minY + 0.81872 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.47436 * bird.width, bird.minY + 0.81556 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.40269 * bird.width, bird.minY + 0.84109 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.43431 * bird.width, bird.minY + 0.81227 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.39081 * bird.width, bird.minY + 0.82210 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.41262 * bird.width, bird.minY + 0.80856 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.40375 * bird.width, bird.minY + 0.78382 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.42850 * bird.width, bird.minY + 0.79131 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.41851 * bird.width, bird.minY + 0.78224 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.28081 * bird.width, bird.minY + 0.50545 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.28740 * bird.width, bird.minY + 0.81820 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.27921 * bird.width, bird.minY + 0.57456 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.72038 * bird.width, bird.minY + 0.42918 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.43700 * bird.width, bird.minY + 0.42331 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.59474 * bird.width, bird.minY + 0.57066 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.98359 * bird.width, bird.minY + 0.72046 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.76152 * bird.width, bird.minY + 0.35300 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.93132 * bird.width, bird.minY + 0.55197 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.77403 * bird.width, bird.minY + 0.33942 * bird.height), controlPoint1: CGPointMake(bird.minX + 1.06175 * bird.width, bird.minY + 0.67949 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.83878 * bird.width, bird.minY + 0.41188 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.55702 * bird.width, bird.minY + 0.13732 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.80785 * bird.width, bird.minY + 0.22799 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.67607 * bird.width, bird.minY + 0.06577 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.29404 * bird.width, bird.minY + 0.00004 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.47324 * bird.width, bird.minY + 0.03871 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.37995 * bird.width, bird.minY + -0.00151 * bird.height))
        bodyPath.closePath()
        bodyPath.moveToPoint(CGPointMake(bird.minX + 0.23101 * bird.width, bird.minY + 0.60225 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.25338 * bird.width, bird.minY + 0.62542 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.24240 * bird.width, bird.minY + 0.60194 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.25161 * bird.width, bird.minY + 0.60964 * bird.height))
        bodyPath.addLineToPoint(CGPointMake(bird.minX + 0.27865 * bird.width, bird.minY + 0.77502 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.26180 * bird.width, bird.minY + 0.82723 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.26503 * bird.width, bird.minY + 0.77987 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.25911 * bird.width, bird.minY + 0.79676 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.28322 * bird.width, bird.minY + 0.80904 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.26757 * bird.width, bird.minY + 0.81879 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.26995 * bird.width, bird.minY + 0.80438 * bird.height))
        bodyPath.addLineToPoint(CGPointMake(bird.minX + 0.31449 * bird.width, bird.minY + 0.85891 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.18144 * bird.width, bird.minY + 0.67147 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.20812 * bird.width, bird.minY + 0.86922 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.19993 * bird.width, bird.minY + 0.79471 * bird.height))
        bodyPath.addCurveToPoint(CGPointMake(bird.minX + 0.23101 * bird.width, bird.minY + 0.60225 * bird.height), controlPoint1: CGPointMake(bird.minX + 0.18708 * bird.width, bird.minY + 0.62573 * bird.height), controlPoint2: CGPointMake(bird.minX + 0.21202 * bird.width, bird.minY + 0.60276 * bird.height))
        bodyPath.closePath()
        bodyPath.miterLimit = 4;
        
        fillColor.setFill()
        bodyPath.fill()
        
        
        //// sclera Drawing
        let scleraPath = UIBezierPath(ovalInRect: CGRectMake(bird.minX + floor(bird.width * 0.59068 - 0.06) + 0.56, bird.minY + floor(bird.height * 0.20662 + 0.46) + 0.04, floor(bird.width * 0.69186 + 0.34) - floor(bird.width * 0.59068 - 0.06) - 0.4, floor(bird.height * 0.34139 - 0.44) - floor(bird.height * 0.20662 + 0.46) + 0.9))
        fillColor2.setFill()
        scleraPath.fill()
        
        
        //// iris Drawing
        let irisPath = UIBezierPath(ovalInRect: CGRectMake(bird.minX + floor(bird.width * 0.62280 - 0.06) + 0.56, bird.minY + floor(bird.height * 0.27923 - 0.09) + 0.59, floor(bird.width * 0.68865 - 0.26) - floor(bird.width * 0.62280 - 0.06) + 0.2, floor(bird.height * 0.34609 - 0.49) - floor(bird.height * 0.27923 - 0.09) + 0.4))
        fillColor.setFill()
        irisPath.fill()
    }
}
