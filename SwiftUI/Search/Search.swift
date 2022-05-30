//
//  Search.swift
//  Kiwix
//
//  Created by Chris Li on 5/30/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Search: View {
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                List {
                    Text("zim file 1")
                    Text("zim file 2")
                    Text("zim file 3")
                }
                .listStyle(.sidebar)
                .modifier(SearchFilterBackground())
                .frame(width: 280)
                List {
                    Text("result 1")
                    Text("result 2")
                    Text("result 3")
                }
                .listStyle(.plain)
                .modifier(SearchResultBackground())
            }
            .frame(maxWidth: 1000, idealHeight: 600, maxHeight: 800)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(radius: 4)
            Spacer()
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct SearchFilterBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.safeAreaInset(edge: .trailing) { Divider() }
        } else {
            content.background(Color.white)
        }
    }
}

struct SearchResultBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.background(.white)
        } else {
            content.background(Color.white)
        }
    }
}


struct Search_Previews: PreviewProvider {
    static var previews: some View {
        Search()
    }
}
