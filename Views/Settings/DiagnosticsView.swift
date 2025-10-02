// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import SwiftUI

struct DiagnosticsView: View {
    
    @State private var languageSettings = true
    @State private var applicationLogs = true
    @State private var zimFiles = true
    @State private var deviceDetails = true
    @State private var fileSystem = true
    
    #if os(iOS)
    private var alignment: HorizontalAlignment = .center
    #else
    private var alignment: HorizontalAlignment = .leading
    #endif
    
    var body: some View {
        VStack(alignment: alignment) {
            Text("""
                    Please share the following details, so we can diagnose the problem.
                    """)
            .font(.headline)
            
            Toggle("Your language settings", isOn: $languageSettings)
            Toggle("Application logs", isOn: $applicationLogs)
            Toggle("List of your ZIM files", isOn: $zimFiles)
            Toggle("Device details", isOn: $deviceDetails)
            Toggle("File system details", isOn: $fileSystem)
            
            AsyncButton {
                await Diagnostics.entries()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            #if os(iOS)
            .buttonStyle(.borderless)
            #endif
            .padding()
        }
        .frame(maxWidth: 400)
        .navigationTitle("Diagnostic Report")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #else
        .tabItem { Label("Diagnostics", systemImage: "exclamationmark.bubble") }
        #endif
        .padding(.horizontal, 40)
    }
}
