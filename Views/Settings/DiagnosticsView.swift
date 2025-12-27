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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.integrityCheckablePredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var logs: [String] = []
    @State private var isRunning: Bool = false
    @State private var integrityTask: Task<Void, Error>?
    @ObservedObject private var model = DiagnosticsModel()
    
    private enum Const {
        #if os(iOS)
        static let verticalSpace: CGFloat = 32
        #else
        static let verticalSpace: CGFloat = 12
        #endif
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            diagnosticItems
            Spacer(minLength: Const.verticalSpace)
            HStack(alignment: .firstTextBaseline, spacing: 24) {
                if !logs.isEmpty {
                    emailButton
#if os(macOS)
                    saveButton
#else
                    shareButton
#endif
                } else {
                    if isRunning {
                        VStack(alignment: .center) {
                            ProgressView()
                                .progressViewStyle(.circular)
                            #if os(macOS)
                                .scaleEffect(0.5)
                                .padding(-8)
                            #endif
                            
                            Text("Checking...")
                                .foregroundStyle(.secondary)
                            
                            #if os(macOS)
                            cancelButton
                            #endif
                        }
                        .padding(.vertical)
                    } else {
                        #if os(macOS)
                        runButton
                        #endif
                    }
                }
            }
            Spacer(minLength: Const.verticalSpace)
        }
        .frame(maxWidth: 500)
        .navigationTitle("Diagnostic Items")
        #if os(iOS)
        .toolbar {
            if logs.isEmpty {
                if !isRunning {
                    ToolbarItem(placement: .topBarTrailing) {
                        runButton
                            .padding(.horizontal)
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                       cancelButton
                            .padding(.horizontal)
                    }
                }
            }
        }
        #endif
        .onDisappear(perform: {
           cancel()
        })
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .padding(.horizontal, 40)
#else
        .tabItem { Label("Diagnostics", systemImage: "exclamationmark.bubble") }
#endif
    }
    
    private func cancel() {
        model.cancel()
        integrityTask?.cancel()
        logs = []
        isRunning = false
    }
    
    @ViewBuilder
    var diagnosticItems: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(model.items, id: \.id) { item in
                    Label(item.title, systemImage: item.status.systemImage)
                        .listItemTint(item.status.tintColor)
                        .listRowSeparator(.hidden)
                        .symbolEffect(.bounce, value: item.status.isComplete)
                }
            }
            #if os(iOS)
            .listRowSpacing(-12)
            #endif
            .listStyle(.plain)
            .onChange(of: model.items) {
                if let firstInitial = model.items.first(where: { item in
                    item.status == .initial
                }) {
                    proxy.scrollTo(firstInitial.id)
                }
            }
        }
    }
    
    @ViewBuilder
    var cancelButton: some View {
        Button(LocalString.common_button_cancel, role: .destructive) {
            cancel()
        }
    }
    
    @ViewBuilder
    var runButton: some View {
        AsyncButton {
            withAnimation {
                isRunning = true
                integrityTask = Task {
                    let collectedLogs = await model.start(using: zimFiles.reversed())
                    if !Task.isCancelled {
                        logs = collectedLogs
                        isRunning = false
                    }
                }
            }
        } label: {
            #if os(macOS)
            Label("Run check", systemImage: "exclamationmark.bubble")
                .symbolEffect(.bounce, value: isRunning)
            #else
            Text("Run check")
            #endif
        }
#if os(iOS)
        .buttonStyle(.borderless)
#endif
    }
    
    @ViewBuilder
    var emailButton: some View {
        AsyncButton {
            let emailLogs = logs.joined(separator: Email.separator())
            let email = Email(logs: emailLogs)
            email.create()
        } label: {
            Label("Email", systemImage: "paperplane")
                .symbolEffect(.bounce, value: isRunning)
        }
#if os(iOS)
        .buttonStyle(.borderless)
#endif
    }
    
#if os(macOS)
    @ViewBuilder
    var saveButton: some View {
        AsyncButton {
            let fileLogs = logs.joined(separator: "\n")
            guard let data = fileLogs.data(using: .utf8) else { return }
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.log]
            panel.nameFieldStringValue = "\(Diagnostics.fileName(using: Date())).txt"
            if case .OK = panel.runModal(),
               let targetURL = panel.url {
                try? data.write(to: targetURL)
            }
        } label: {
            Label("Save log file", systemImage: "square.and.arrow.down")
                .symbolEffect(.bounce, value: isRunning)
        }
    }
#endif
    
#if os(iOS)
    @ViewBuilder
    var shareButton: some View {
        AsyncButton {
            let fileLogs = logs.joined(separator: "\n")
            guard let data = fileLogs.data(using: .utf8) else { return }
            let exportData = FileExportData(
                data: data,
                fileName: Diagnostics.fileName(using: Date()),
                fileExtension: "txt"
            )
            NotificationCenter.exportFileData(exportData)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
                .symbolEffect(.bounce, value: isRunning)
        }
        .buttonStyle(.borderless)
    }
#endif
}
