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
import CoreData

/// NOTE: This view is not translated on purpose.
/// We want to make sure users only send us reports in English
struct DiagnosticsView: View {
    
    @State private var isLoading: Bool = false
    private let alignment = HorizontalAlignment.leading
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.notYetValidatedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        VStack(alignment: alignment, spacing: 16) {
            Spacer()
            description
            
            HStack(alignment: .firstTextBaseline, spacing: 24) {
                emailButton
#if os(macOS)
                saveButton
#else
                shareButton
#endif
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
#endif
    }
    
    @ViewBuilder
    var description: some View {
        Text("""
                    Diagnostic items:
                    """)
        .font(.headline)
        
        VStack(alignment: .leading) {
            Text("• Application logs")
            Text("• Your language settings")
            Text("• List of your ZIM files")
            Text("• Device details")
            Text("• File system details")
        }
    }
    
    @ViewBuilder
    var emailButton: some View {
        AsyncButton {
            isLoading = true
            defer { isLoading = false }
            await validateRemainingZIMFiles()
            let logs = await Diagnostics.entries(separator: Email.separator())
            let email = Email(logs: logs)
            email.create()
        } label: {
            Label("Email", systemImage: "paperplane")
        }
#if os(iOS)
        .buttonStyle(.borderless)
#endif
    }
    
#if os(macOS)
    @ViewBuilder
    var saveButton: some View {
        AsyncButton {
            isLoading = true
            defer { isLoading = false }
            await validateRemainingZIMFiles()
            let logs = await Diagnostics.entries(separator: "\n")
            guard let data = logs.data(using: .utf8) else { return }
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.log]
            panel.nameFieldStringValue = "\(Diagnostics.fileName(using: Date())).txt"
            if case .OK = panel.runModal(),
               let targetURL = panel.url {
                try? data.write(to: targetURL)
            }
        } label: {
            Label("Save log file", systemImage: "square.and.arrow.down")
        }
    }
#endif
    
#if os(iOS)
    @ViewBuilder
    var shareButton: some View {
        AsyncButton {
            isLoading = true
            defer { isLoading = false }
            await validateRemainingZIMFiles()
            let logs = await Diagnostics.entries(separator: "\n")
            guard let data = logs.data(using: .utf8) else { return }
            let exportData = FileExportData(
                data: data,
                fileName: Diagnostics.fileName(using: Date()),
                fileExtension: "txt"
            )
            NotificationCenter.exportFileData(exportData)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.borderless)
    }
#endif
        
    private func validateRemainingZIMFiles() async {
        await ZimFileValidator.validate(zimFiles: zimFiles.reversed(),
                                        using: Database.shared.viewContext)
    }
}
