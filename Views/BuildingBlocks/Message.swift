//
//  Message.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 2/12/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Message: View {
    let text: String
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(text).font(.title2).foregroundColor(.secondary)
                Spacer()
            }
            Spacer()
        }
    }
}

struct Message_Previews: PreviewProvider {
    static var previews: some View {
        Message(text: "message.preview.nothing".localized)
            .frame(width: 250, height: 200)
    }
}
