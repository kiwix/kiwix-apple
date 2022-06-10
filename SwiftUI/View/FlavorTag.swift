//
//  FlavorTag.swift
//  Kiwix
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct FlavorTag: View {
    let flavor: Flavor
    
    init(_ flavor: Flavor) {
        self.flavor = flavor
    }
    
    var body: some View {
        Text(flavor.description)
            .fontWeight(.medium)
            .font(.caption)
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.secondary, lineWidth: 0.5)
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
        HStack(spacing: 20) {
            FlavorTag(Flavor(rawValue: "maxi")!)
            FlavorTag(Flavor(rawValue: "nopic")!)
            FlavorTag(Flavor(rawValue: "mini")!)
        }
        .preferredColorScheme(.light)
        .padding()
        .previewLayout(.sizeThatFits)
        HStack(spacing: 20) {
            FlavorTag(Flavor(rawValue: "maxi")!)
            FlavorTag(Flavor(rawValue: "nopic")!)
            FlavorTag(Flavor(rawValue: "mini")!)
        }
        .preferredColorScheme(.dark)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
