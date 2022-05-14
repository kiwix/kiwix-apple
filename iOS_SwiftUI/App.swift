//
//  iOS_SwiftUIApp.swift
//  iOS_SwiftUI
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

@main
struct Kiwix: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State var isShowingLibrary = false
    
    var body: some View {
        Button("Show Library") {
            isShowingLibrary = true
        }.sheet(isPresented: $isShowingLibrary) {
            Library().environment(\.managedObjectContext, Database.shared.container.viewContext)
        }
    }
}
