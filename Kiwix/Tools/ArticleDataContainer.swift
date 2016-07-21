//
//  ArticleDataContainer.swift
//  Kiwix
//
//  Created by Chris Li on 7/21/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class ArticleDataContainer: NSObject, NSCoding {
    let title: String
    let thumbImageData: NSData
    
    init(title: String, thumbImageData: NSData) {
        self.title = title
        self.thumbImageData = thumbImageData
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let title = aDecoder.decodeObjectForKey("title") as? String,
            let thumbImageData = aDecoder.decodeObjectForKey("thumbImageData") as? NSData else {return nil}
        self.init(title: title, thumbImageData: thumbImageData)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(title, forKey: "title")
        aCoder.encodeObject(thumbImageData, forKey: "thumbImageData")
    }

}
