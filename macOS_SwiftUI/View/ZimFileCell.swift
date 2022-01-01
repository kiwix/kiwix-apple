//
//  ZimFileCell.swift
//  macOS_SwiftUI
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct ZimFileCell: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    let zimFile: ZimFile
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(zimFile.size.formatted(.byteCount(style: .file)))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(zimFile.articleCount.formatted(.number.notation(.compactName))) articles")
                        .font(.caption)
                    Text(zimFile.created.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    if let tag = zimFile.tag {
                        ZimFileTag(string: tag)
                    }
                    Spacer()
                    Image(systemName: "arrow.down.to.line.circle.fill")
                }
            }
        }
        .padding(12)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var backgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.gray.opacity(0.2)
        default:
            return Color.white
        }
    }
}

struct ZimFileCell_Previews: PreviewProvider {
    static let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    static let zimFile: ZimFile = {
        let zimFile = ZimFile(context: context)
        zimFile.articleCount = 100
        zimFile.category = "wikipedia"
        zimFile.created = Date()
        zimFile.fileID = UUID()
        zimFile.languageCode = "en"
        zimFile.mediaCount = 100
        zimFile.name = "Wikipedia"
        zimFile.persistentID = ""
        zimFile.size = 1000000000
        zimFile.tag = "max"
        return zimFile
    }()
    
    static var previews: some View {
        Group {
            ZimFileCell(zimFile: ZimFileCell_Previews.zimFile)
                .preferredColorScheme(.light)
                .padding()
                .background(Color(.sRGB, red: 239, green: 240, blue: 243, opacity: 0))
                .frame(width: 300, height: 100)
            ZimFileCell(zimFile: ZimFileCell_Previews.zimFile)
                .preferredColorScheme(.dark)
                .padding()
                .background(Color(.sRGB, red: 37, green: 41, blue: 48, opacity: 0))
                .frame(width: 300, height: 100)
        }
    }
}
