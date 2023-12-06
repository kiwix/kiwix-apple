//
//  Attribute.swift
//  Kiwix
//
//  Created by Chris Li on 10/21/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

struct Attribute: View {
    let title: String
    let detail: String?
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(detail ?? "attribute.detail.unknown".localized).foregroundColor(.secondary)
        }
    }
}

struct AttributeBool: View {
    let title: String
    let detail: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            #if os(macOS)
            Text(detail ? "common.button.yes".localized : "common.button.no".localized).foregroundColor(.secondary)
            #elseif os(iOS)
            if detail {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            } else {
                Image(systemName: "multiply.circle.fill").foregroundColor(.orange)
            }
            #endif
        }
    }
}
