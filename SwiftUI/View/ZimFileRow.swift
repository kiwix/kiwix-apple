//
//  ZimFileRow.swift
//  Kiwix
//
//  Created by Chris Li on 5/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

struct ZimFileRow: View {
    let zimFile: ZimFile
    
    init(_ zimFile: ZimFile) {
        self.zimFile = zimFile
    }
    
    var body: some View {
        HStack {
            if #available(iOS 15.0, *) {
                Favicon(
                    category: Category(rawValue: zimFile.category) ?? .other,
                    imageData: zimFile.faviconData,
                    imageURL: zimFile.faviconURL
                ).frame(height: 26)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(zimFile.name).lineLimit(1)
                Text([
                    Library.dateFormatter.string(from: zimFile.created),
                    Library.sizeFormatter.string(fromByteCount: zimFile.size),
                    {
                        if #available(iOS 15.0, *) {
                            return "\(zimFile.articleCount.formatted(.number.notation(.compactName))) articles"
                        } else {
                            return Library.formattedLargeNumber(from: zimFile.articleCount)
                        }
                    }()
                ].joined(separator: ", ")).font(.caption)
            }
        }
    }
}

struct ZimFileRow_Previews: PreviewProvider {
    static let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    static let zimFile: ZimFile = {
        let zimFile = ZimFile(context: context)
        zimFile.articleCount = 100
        zimFile.category = "wikipedia"
        zimFile.created = Date()
        zimFile.fileID = UUID()
        zimFile.flavor = "mini"
        zimFile.languageCode = "en"
        zimFile.mediaCount = 100
        zimFile.name = "Wikipedia Zim File Name"
        zimFile.persistentID = ""
        zimFile.size = 1000000000
        
        return zimFile
    }()
    
    static var previews: some View {
        Group {
            ZimFileRow(ZimFileRow_Previews.zimFile)
                .preferredColorScheme(.light)
                .padding()
                .previewLayout(.sizeThatFits)
            ZimFileRow(ZimFileRow_Previews.zimFile)
                .preferredColorScheme(.dark)
                .padding()
                .previewLayout(.sizeThatFits)
            ZimFileRow(ZimFileRow_Previews.zimFile)
                .preferredColorScheme(.light)
                .padding()
                .previewLayout(.sizeThatFits)
            ZimFileRow(ZimFileRow_Previews.zimFile)
                .preferredColorScheme(.dark)
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
