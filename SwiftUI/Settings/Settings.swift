//
//  Settings.swift
//  Kiwix
//
//  Created by Chris Li on 6/10/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

#if os(macOS)
struct SettingSection<Content: View>: View {
    let name: String
    var content: () -> Content
    
    init(name: String, @ViewBuilder content: @escaping () -> Content) {
        self.name = name
        self.content = content
    }
    
    var body: some View {
        HStack(alignment :.top) {
            Text("\(name):").frame(width: 80, alignment: .trailing)
            VStack(alignment: .leading, spacing: 16, content: content)
            Spacer()
        }
    }
}
#elseif os(iOS)
struct Settings: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink("Library") { LibrarySettings() }
                }
                Section {
                    NavigationLink("About") { About() }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
#endif
