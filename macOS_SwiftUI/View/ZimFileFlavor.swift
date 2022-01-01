//
//  ZimFileFlavor.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct ZimFileFlavor: View {
    let flavor: Flavor
    
    init(_ flavor: Flavor) {
        self.flavor = flavor
    }
    
    var body: some View {
        Text(flavor.description)
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
        switch flavor {
        case .max:
            return .green
        case .noPic:
            return .blue
        case .mini:
            return .orange
        }
    }
    
    var help: String {
        switch flavor {
        case .max:
            return "everything except large media files like video/audio"
        case .noPic:
            return "most pictures have been removed"
        case .mini:
            return "only a subset of the text is available, probably the first section"
        }
    }
}

struct Tag_Previews: PreviewProvider {
    static var previews: some View {
        ZimFileFlavor(Flavor(rawValue: "maxi")!).padding()
        ZimFileFlavor(Flavor(rawValue: "nopic")!).padding()
        ZimFileFlavor(Flavor(rawValue: "mini")!).padding()
    }
}
