//
//  ZimFileCell.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct ZimFileCell: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @State var isHovering: Bool = false
    
    let zimFile: ZimFile
    let prominent: Prominent
    
    init(_ zimFile: ZimFile, prominent: Prominent = .size) {
        self.zimFile = zimFile
        self.prominent = prominent
    }
    
    var body: some View {
        VStack(spacing: 8) {
            switch prominent {
            case .size:
                HStack(alignment: .top) {
                    Text(zimFile.size.formatted(.byteCount(style: .file)))
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    if let flavor = Flavor(rawValue: zimFile.flavor) {
                        ZimFileFlavor(flavor)
                    }
                }
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text("\(zimFile.articleCount.formatted(.number.notation(.compactName))) articles")
                            .font(.caption)
                        Text(zimFile.created.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                    }
                    Spacer()
                }
            case .title:
                HStack {
                    Text(
                        zimFile.category == Category.stackExchange.rawValue ?
                        zimFile.name.replacingOccurrences(of: "Stack Exchange", with: "") :
                        zimFile.name
                    ).font(.title2).fontWeight(.semibold).lineLimit(1)
                    Spacer()
                    Favicon(
                        category: Category(rawValue: zimFile.category) ?? .other,
                        imageData: zimFile.faviconData,
                        imageURL: zimFile.faviconURL
                    ).frame(height: 20)
                }
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text(zimFile.size.formatted(.byteCount(style: .file)))
                            .font(.caption)
                        Text(zimFile.created.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                    }
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onHover { self.isHovering = $0 }
    }
    
    private var backgroundColor: Color {
        switch (colorScheme, isHovering) {
        case (.dark, true):
            return Color.gray.opacity(0.15)
        case (.dark, false):
            return Color.gray.opacity(0.2)
        case (.light, true):
            return Color.white.opacity(0.75)
        default:
            return Color.white
        }
    }
    
    enum Prominent {
        case size, title
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
            ZimFileCell(ZimFileCell_Previews.zimFile)
                .preferredColorScheme(.light)
                .padding()
                .background(Color(.sRGB, red: 239, green: 240, blue: 243, opacity: 0))
                .frame(width: 300, height: 100)
            ZimFileCell(ZimFileCell_Previews.zimFile)
                .preferredColorScheme(.dark)
                .padding()
                .background(Color(.sRGB, red: 37, green: 41, blue: 48, opacity: 0))
                .frame(width: 300, height: 100)
            ZimFileCell(ZimFileCell_Previews.zimFile, prominent: .title)
                .preferredColorScheme(.light)
                .padding()
                .background(Color(.sRGB, red: 239, green: 240, blue: 243, opacity: 0))
                .frame(width: 300, height: 100)
            ZimFileCell(ZimFileCell_Previews.zimFile, prominent: .title)
                .preferredColorScheme(.dark)
                .padding()
                .background(Color(.sRGB, red: 37, green: 41, blue: 48, opacity: 0))
                .frame(width: 300, height: 100)
        }
    }
}
