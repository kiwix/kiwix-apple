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
    
#if os(iOS)
    private var alignment: HorizontalAlignment = .center
#else
    private var alignment: HorizontalAlignment = .leading
#endif
    
    var body: some View {
        VStack(alignment: alignment, spacing: 16) {
            Spacer()
            Text("""
                        Please share the following details, so we can diagnose the problem.
                        """)
            .font(.headline)
            
            Text("Your language settings")
            Text("Application logs")
            Text("List of your ZIM files")
            Text("Device details")
            Text("File system details")
            
            
            AsyncButton {
                await Diagnostics.entries()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
#if os(iOS)
            .buttonStyle(.borderless)
            .padding()
#endif
            Spacer()
        }
        .frame(maxWidth: 400)
        .navigationTitle("Diagnostic Report")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .padding(.horizontal, 40)
#else
        .tabItem { Label("Diagnostics", systemImage: "exclamationmark.bubble") }
#endif
    }
}
