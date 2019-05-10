//
//  TableViewSectionFooterLabel.swift
//  iOS
//
//  Created by Chris Li on 8/9/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class UITableViewSectionFooterLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        textAlignment = .center
        textColor = UIColor.darkGray
        font = UIFont.systemFont(ofSize: 13)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
