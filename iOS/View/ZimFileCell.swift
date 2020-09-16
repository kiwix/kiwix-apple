//
//  ZimFileCell.swift
//  Kiwix
//
//  Created by Chris Li on 9/5/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct ZimFileCell: View {
    var body: some View {
        VStack {
            Text("test")
            Divider()
        }
    }
}

@available(iOS 13.0, *)
struct ZimFileCell_Previews: PreviewProvider {
    static var previews: some View {
        ZimFileCell().previewDevice(PreviewDevice(rawValue: "iPhone SE"))
    }
}
