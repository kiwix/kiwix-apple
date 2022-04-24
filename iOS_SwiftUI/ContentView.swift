//
//  ContentView.swift
//  iOS_SwiftUI
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var isShowingLibrary = false
    
    var body: some View {
        Button("Show Library") {
            isShowingLibrary = true
        }.sheet(isPresented: $isShowingLibrary) {
            Library()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Library()
    }
}
