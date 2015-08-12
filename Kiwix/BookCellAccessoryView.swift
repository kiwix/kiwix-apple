//
//  BookCellAccessoryView.swift
//  Kiwix
//
//  Created by Chris Li on 8/3/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

@IBDesignable
class BookCellAccessoryView: UIView {
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let frame = CGRectInset(self.bounds, -9, -9)
        return CGRectContainsPoint(frame, point) ? self : nil
    }
}

class DownloadGoAheadIconView: UIView {
    var color: UIColor = UIColor.greenColor().colorWithAlphaComponent(0.75)
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        BookCellAccessoryDraw.drawDownloadIcon(size: rect.size, color: color)
    }
}

class DownloadWithCautionIconView: UIView {
    var color: UIColor = UIColor.orangeColor().colorWithAlphaComponent(0.75)
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        BookCellAccessoryDraw.drawDownloadIcon(size: rect.size, color: color)
    }
}

class DownloadNotAllowedIconView: UIView {
    var color: UIColor = UIColor.grayColor().colorWithAlphaComponent(0.75)
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        BookCellAccessoryDraw.drawDownloadIcon(size: rect.size, color: color)
    }
}

class DownloadPauseIconView: UIView {
    var color: UIColor = UIColor.orangeColor().colorWithAlphaComponent(0.75)
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        BookCellAccessoryDraw.drawPauseIcon(size: rect.size, color: color)
    }
}

class DownloadResumeIconView: UIView {
    var color: UIColor = UIColor.greenColor().colorWithAlphaComponent(0.75)
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        BookCellAccessoryDraw.drawResumeIcon(size: rect.size, color: color)
    }
}

class DownloadFinishedIconView: UIView {
    var color: UIColor = UIColor.redColor().colorWithAlphaComponent(0.75)
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        BookCellAccessoryDraw.drawCrossIcon(size: rect.size, color: color)
    }
}
