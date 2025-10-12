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
#if os(iOS)
import MessageUI
#endif

/// NOTE: This view is not translated on purpose.
/// We want to make sure users only send us reports in English
struct DiagnosticsView: View {
    
    @State private var isLoading: Bool = false
    
    private let alignment = HorizontalAlignment.leading
#if os(iOS)
    @State private var email: Email?
#elseif os(macOS)
    @State private var currentView: NSView?
#endif
    
    @ViewBuilder
    var description: some View {
        Text("""
                    Please share the following details, so we can diagnose the problem.
                    """)
        .font(.headline)
        
        VStack(alignment: .leading) {
            Text("Application logs")
            Text("Your language settings")
            Text("List of your ZIM files")
            Text("Device details")
            Text("File system details")
        }
    }
    
    @ViewBuilder
    var emailButton: some View {
        AsyncButton {
            isLoading = true
            defer { isLoading = false }
            let logs = await Diagnostics.entries(separator: Email.separator())
            let email = Email(logs: logs)
            email.create()
        } label: {
            Label("Email", systemImage: "paperplane")
        }
#if os(iOS)
        .buttonStyle(.borderless)
        .padding(.vertical)
#endif
    }
    
    @ViewBuilder
    var shareButton: some View {
#if os(macOS)
        if let currentView {
            AsyncButton {
                isLoading = true
                defer { isLoading = false }
                let logs = await Diagnostics.entries(separator: "\n")
                guard let data = logs.data(using: .utf8) else {
                    return
                }
                let exportData = FileExportData(data: data, fileName: "diagnostics", fileExtension: "log")
                guard let url = FileExporter.tempFileFrom(exportData: exportData) else {
                    return
                }
                NSSharingServicePicker(items: [url]).show(
                    relativeTo: NSRect(origin: CGPoint(x: 64, y: 330),
                                       size: CGSize(width: 320, height: 54)
                    ),
                    of: currentView,
                    preferredEdge: .minY
                )
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
#else
        // TODO: implement for iOS
        EmptyView()
#endif
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: 16) {
            Spacer()
            description
            
            HStack {
                emailButton
                shareButton
                
                if isLoading {
                    Text("Please wait...")
                }
            }
            Spacer()
        }
        .frame(maxWidth: 400)
        .navigationTitle("Diagnostic Report")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .padding(.horizontal, 40)
#else
        .tabItem { Label("Diagnostics", systemImage: "exclamationmark.bubble") }
        .withHostingWindow { hostWindow in
            _currentView.wrappedValue = hostWindow?.contentView
        }
#endif
    }
}
