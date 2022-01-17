//
//  Outlines.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 1/17/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Outline: View {
    @Binding var url: URL?
    
    var body: some View {
        List {
            Text("Hello, World!")
        }.task {
            await loadTableOfContents()
        }
    }
    
    private func loadTableOfContents() async {
        do {
            guard let url = url else { return }
            let parser = try Parser(url: url)
            let items = parser.getOutlineItems()
            print(items)
        } catch {}
    }
}

struct TableOfContents_Previews: PreviewProvider {
    static var previews: some View {
        Outline(url: .constant(nil))
    }
}
