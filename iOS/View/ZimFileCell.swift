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
    @State private var tapped: Bool = false
    
    var body: some View {
        Button(action: {}, label: {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(width: 36, height: 36)
                    Image(systemName: "text.book.closed")
                }
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(zimFile.title).font(.headline)
                        if zimFile.fileDescription.count > 0 {
                            Text(zimFile.fileDescription)
                                .font(.caption)
                        }
                    }
                    Divider()
                    HStack {
                        Label(zimFile.sizeDescription ?? "Unknown", systemImage: "internaldrive")
                            .font(.caption)
                        Spacer()
                        Label(zimFile.articleCountDescription ?? "Unknown", systemImage: "doc.text")
                            .font(.caption)
                        Spacer()
                        Label(zimFile.creationDateDescription ?? "Unknown", systemImage: "calendar")
                            .font(.caption)
                    }
                }
            }
        })
        .buttonStyle(RoundedRectButtonStyle())
    }
}

@available(iOS 14.0, *)
struct RoundedRectButtonStyle: ButtonStyle {
    @Environment (\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
            .background(Color({ () -> UIColor in
                switch (colorScheme, configuration.isPressed) {
                case (.light, true):
                    return .systemGray4
                case (.light, false):
                    return .systemBackground
                case (.dark, true):
                    return .purple
                case (.dark, false):
                    return .green
                default:
                    return .systemBackground
                }
            }()))
            .cornerRadius(10)
            .animation(.easeOut)
        
    }
}

@available(iOS 14.0, *)
struct ZimFileCell_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(1..<100) { _ in
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
