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
            .clipShape(Capsule(style: .continuous))
            .overlay(Capsule(style: .continuous).stroke(Color.gray, lineWidth: 0.5))
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
            return "flavor-max-description".localized
        case .noPic:
            return "flavor-no-pic-description".localized
        case .mini:
            return "flavor-mini-description".localized
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
