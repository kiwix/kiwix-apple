//
//  RefreshLibControl.swift
//  Kiwix
//
//  Created by Chris Li on 9/7/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class RefreshLibControl: UIRefreshControl {
    
    static let pullDownToRefresh = NSLocalizedString("Pull Down To Refresh", comment: "Refresh Library Control")
    static let lastRefresh = NSLocalizedString("Last Refresh: %@ ago", comment: "Refresh Library Control")
    
    override var isHidden: Bool {
        didSet {
            guard isHidden != oldValue && isHidden == false else {return}
            updateTitle()
        }
    }
    
    private func updateTitle() {
        let string: String = {
            guard let lastRefreshTime = Preference.libraryLastRefreshTime else {return RefreshLibControl.pullDownToRefresh}
            let interval = lastRefreshTime.timeIntervalSinceNow * -1
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = interval < 60.0 ? [.second] : [.day, .hour, .minute]
            let string = formatter.string(from: interval) ?? ""
            return String(format: RefreshLibControl.lastRefresh, string)
        }()
        let attributes = [NSForegroundColorAttributeName: UIColor.black]
        attributedTitle = NSAttributedString(string: string, attributes: attributes)
    }
}
