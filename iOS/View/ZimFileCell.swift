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
    var tapped: ((ZimFile) -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var sceneViewModel: SceneViewModel
    
    var body: some View {
        Button(action: {
            tapped?(zimFile)
            sceneViewModel.loadMainPage(zimFile: zimFile)
        }, label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 10) {
                    if colorScheme == .light {
                        FavIcon(zimFile: zimFile).cornerRadius(4)
                    } else {
                        FavIcon(zimFile: zimFile)
                            .background(Color(.white))
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(.white).opacity(0.9), lineWidth: 1))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(zimFile.title).font(.headline)
                        if zimFile.fileDescription.count > 0 {
                            Text(zimFile.fileDescription).font(.caption).lineLimit(2)
                        }
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
        .buttonStyle(RoundedRectButtonStyle())
    }
}

@available(iOS 14.0, *)
private struct FavIcon: View {
    let zimFile: ZimFile
    
    var body: some View {
        let image: Image = {
            if let data = zimFile.faviconData, let image = UIImage(data: data) {
                return Image(uiImage: image)
            } else {
                return Image("GenericZimFile")
            }
        }()
        return image.resizable().frame(width: 24, height: 24)
    }
}

@available(iOS 14.0, *)
private struct RoundedRectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
            .background(Color({ () -> UIColor in
                if configuration.isPressed {
                    return .systemGray5
                } else {
                    return .secondarySystemGroupedBackground
                }
            }()))
            .cornerRadius(10)
    }
}

@available(iOS 14.0, *)
struct ZimFileCell_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(1..<10) { _ in
                    ZimFileCell(zimFile: ZimFile(value: [
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
