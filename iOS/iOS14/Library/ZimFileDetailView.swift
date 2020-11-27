//
//  ZimFileDetailView.swift
//  iOS
//
//  Created by Chris Li on 11/27/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct ZimFileDetailView: View {
    let id: String
    init(id: String) {
        self.id = id
        print("test")
    }
    var body: some View {
        Text("Hello, World!")
    }
}

@available(iOS 14.0, *)
struct ZimFileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ZimFileDetailView(id: "")
    }
}
