//
//  SearchView.swift
//  Kiwix
//
//  Created by Chris Li on 8/19/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SearchView: View {
    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width > 425 {
                HStack {
                    Spacer()
                    content
                        .background(Material.thin)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                        .frame(width: 400, height: min(proxy.size.height * 0.8, 800))
                        .padding(8)
                }
            } else {
                content.background(Color.background)
            }
        }
    }
    
    var content: some View {
        ScrollView {
            LazyVStack {
                Text("result 1")
                Text("result 2")
                Text("result 3")
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
