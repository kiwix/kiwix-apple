//
//  ZimFileCell.swift
//  Kiwix
//
//  Created by Chris Li on 9/5/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
struct ZimFileCell: View {
    let zimFile: ZimFile
    let withIncludedInSearchIcon: Bool
    var tapped: (() -> Void)?
    
    init (_ zimFile: ZimFile, withIncludedInSearchIcon: Bool = false, tapped: (() -> Void)? = nil) {
        self.zimFile = zimFile
        self.withIncludedInSearchIcon = withIncludedInSearchIcon
        self.tapped = tapped
    }
    
    var body: some View {
        Button(action: {
            tapped?()
        }, label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 10) {
                    Favicon(zimFile: zimFile)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(zimFile.title).font(.headline)
                        if zimFile.fileDescription.count > 0 {
                            Text(zimFile.fileDescription).font(.caption).lineLimit(2)
                        }
                    }
                    if withIncludedInSearchIcon {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .hidden(!zimFile.includedInSearch)
                            .padding(.trailing, 10)
                    }
                }
                Divider()
                HStack {
                    Label(zimFile.sizeDescription ?? "Unknown", systemImage: "internaldrive")
                    Spacer()
                    Label(zimFile.articleCountShortDescription ?? "Unknown", systemImage: "doc.text")
                    Spacer()
                    Label(zimFile.creationDateDescription ?? "Unknown", systemImage: "calendar")
                }.font(.caption).foregroundColor(.secondary)
            }
        })
        .buttonStyle(ZimFileCellButtonStyle())
    }
}

@available(iOS 14.0, *)
private struct Favicon: View {
    let zimFile: ZimFile
    
    var body: some View {
        let image: Image = {
            if let data = zimFile.faviconData, let image = UIImage(data: data) {
                return Image(uiImage: image)
            } else {
                return Image("GenericZimFile")
            }
        }()
        let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
        return image.resizable()
            .frame(width: 24, height: 24)
            .background(Color(.white))
            .clipShape(shape)
            .overlay(shape.stroke(Color(.white).opacity(0.9), lineWidth: 1))
    }
}

@available(iOS 14.0, *)
private struct ZimFileCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let fillColor = Color(configuration.isPressed ? .systemGray5 : .secondarySystemGroupedBackground)
        let background = RoundedRectangle(cornerRadius: 10, style: .continuous).fill(fillColor)
        return configuration.label
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
            .background(background)
    }
}

@available(iOS 14.0, *)
struct ZimFileCell_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(1..<10) { _ in
                    ZimFileCell(ZimFile(value: [
                        "title": "ZimFile Title",
                        "fileDescription": "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
                        "size": 10000000000,
                        "articleCount": 500000,
                        "creationDate": Date(),
                    ]))
                }
            }
            .padding(.all, 10)
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .environment(\.colorScheme, .dark)
        .previewDevice(PreviewDevice(rawValue: "iPhone 11"))
    }
}
