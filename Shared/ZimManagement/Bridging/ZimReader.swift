//
//  ZimReader.swift
//  Kiwix
//
//  Created by Chris Li on 10/16/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

extension ZimReader {
    var id: String {return __getID()}
    var mainPageURL: URL? {return URL(string: __getMainPageURL())}
    
    convenience init?(fileURL: URL) {
        self.init(__zimFileURL: fileURL)
    }
    
    func getContent(path: String) -> (data: Data, mime: String, length: Int)? {
        guard let content = __getContent(path),
            let data = content["data"] as? Data,
            let mime = content["mime"] as? String,
            let length = content["length"] as? Int else {return nil}
        return (data, mime, length)
    }
}
