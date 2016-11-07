//
//  ExtensionAndTypealias.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

typealias ZimID = String
typealias ArticlePath = String

extension ZimReader {
    var metaData: [String: AnyObject] {
        var metadata = [String: AnyObject]()
        
        if let id = getID() {metadata["id"] = id as AnyObject?}
        if let title = getTitle() {metadata["title"] = title as AnyObject?}
        if let description = getDesc() {metadata["description"] = description as AnyObject?}
        if let creator = getCreator() {metadata["creator"] = creator as AnyObject?}
        if let publisher = getPublisher() {metadata["publisher"] = publisher as AnyObject?}
        if let favicon = getFavicon() {metadata["favicon"] = favicon as AnyObject?}
        if let date = getDate() {metadata["date"] = date as AnyObject?}
        if let articleCount = getArticleCount() {metadata["articleCount"] = articleCount as AnyObject?}
        if let mediaCount = getMediaCount() {metadata["mediaCount"] = mediaCount as AnyObject?}
        if let fileSize = getFileSize() {metadata["size"] = fileSize}
        if let langCode = getLanguage() {metadata["language"] = langCode as AnyObject?}
        
        return metadata
    }
}
