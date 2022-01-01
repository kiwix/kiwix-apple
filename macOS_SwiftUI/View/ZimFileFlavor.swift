//
//  ZimFileFlavor.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct ZimFileFlavor: View {
    let string: String
    
    var body: some View {
        Text(string)
            .fontWeight(.medium)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: .infinity, style: .continuous)
                    .stroke(.tertiary, lineWidth: 1)
            )
            .background(
                backgroundColor.opacity(0.75),
                in: RoundedRectangle(cornerRadius: .infinity, style: .continuous)
            )
            .help(help)
    }
    
    var backgroundColor: Color {
        switch string {
        case "max":
            return .green
        case "nopic":
            return .blue
        case "mini":
            return .orange
        default:
            return .gray
        }
    }
    
    var help: String {
        switch string {
        case "max":
            return "everything except large media files like video/audio"
        case "nopic":
            return "most pictures have been removed"
        case "mini":
            return "only a subset of the text is available, probably the first section"
        default:
            return "we have done our best to scrape everything"
        }
    }
}

struct Tag_Previews: PreviewProvider {
    static var previews: some View {
        ZimFileFlavor(string: "max").padding()
        ZimFileFlavor(string: "nopic").padding()
        ZimFileFlavor(string: "mini").padding()
        ZimFileFlavor(string: "other").padding()
    }
}
