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
        
        if let id = getID() {metadata["id"] = id}
        if let title = getTitle() {metadata["title"] = title}
        if let description = getDesc() {metadata["description"] = description}
        if let creator = getCreator() {metadata["creator"] = creator}
        if let publisher = getPublisher() {metadata["publisher"] = publisher}
        if let favicon = getFavicon() {metadata["favicon"] = favicon}
        if let date = getDate() {metadata["date"] = date}
        if let articleCount = getArticleCount() {metadata["articleCount"] = articleCount}
        if let mediaCount = getMediaCount() {metadata["mediaCount"] = mediaCount}
        if let fileSize = getFileSize() {metadata["size"] = fileSize}
        if let langCode = getLanguage() {metadata["language"] = langCode}
        
        return metadata
    }
}
