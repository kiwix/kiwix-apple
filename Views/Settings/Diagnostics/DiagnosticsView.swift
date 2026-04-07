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
import Combine

/// NOTE: This view is not translated on purpose.
/// We want to make sure users only send us reports in English
@MainActor
struct DiagnosticsView: View {
   
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.integrityCheckablePredicate()
    ) private var zimFiles: FetchedResults<ZimFile>
    @ObservedObject var model = GlobalDiagnosticsModel.shared
    
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
                switch model.state {
                case .initial:
#if os(macOS)
                    runButton(again: false)
#endif
                case .running:
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
                case let .complete(logs):
                    emailButton(logs: logs)
#if os(macOS)
                    saveButton(logs: logs)
                    runButton(again: true)
#else
                    shareButton(logs: logs)
#endif
                }
            }
            Spacer(minLength: Const.verticalSpace)
        }
        .frame(maxWidth: 500)
        .navigationTitle("Diagnostic Report")
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                switch model.state {
                case .initial:
                    runButton(again: false)
                        .padding(.horizontal)
                case .complete:
                    runButton(again: true)
                        .padding(.horizontal)
                case .running:
                    cancelButton
                        .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .padding(.horizontal, 40)
#else
        .tabItem { Label("Diagnostics", systemImage: "exclamationmark.bubble") }
#endif
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
            .listRowSpacing(-10)
            #endif
            .listStyle(.plain)
            .onChange(of: model.state) {
                adjustScroll(using: proxy)
            }
            .onChange(of: model.items) {
                scrollToFirstInitialItem(using: proxy)
            }
            .task {
                adjustScroll(using: proxy)
            }
        }
    }
    
    private func adjustScroll(using proxy: ScrollViewProxy) {
        switch model.state {
        case .initial, .running:
            scrollToFirstInitialItem(using: proxy)
        case .complete:
            scrollToLastItem(using: proxy)
        }
    }
    
    private func scrollToFirstInitialItem(using proxy: ScrollViewProxy) {
        if let firstInitial = model.items.first(where: { item in
            item.status == .initial
        }) {
            proxy.scrollTo(firstInitial.id)
        }
    }
    
    private func scrollToLastItem(using proxy: ScrollViewProxy) {
        if let lastItem = model.items.last {
            proxy.scrollTo(lastItem.id)
        }
    }
    
    @ViewBuilder
    var cancelButton: some View {
        Button(LocalString.common_button_cancel, role: .destructive) {
            model.cancel()
        }
    }
    
    @ViewBuilder
    func runButton(again: Bool) -> some View {
        AsyncButton {
            withAnimation {
                model.start(using: zimFiles.reversed())
            }
        } label: {
#if os(macOS)
            let title: String = again ? "Run again" : "Run"
            Label(title, systemImage: "exclamationmark.bubble")
                .symbolEffect(.bounce, value: model.state == .running)
#else
            let title: String = again ? "Run again" : "Run"
            Text(title)
#endif
        }
#if os(iOS)
        .buttonStyle(.borderless)
#endif
    }
    
    @ViewBuilder
    func emailButton(logs: [String]) -> some View {
        AsyncButton {
            let emailLogs = logs.joined(separator: Email.separator())
            let email = Email(logs: emailLogs)
            email.create()
        } label: {
            Label("Email", systemImage: "paperplane")
                .symbolEffect(.bounce, value: model.state == .running)
        }
#if os(iOS)
        .buttonStyle(.borderless)
#endif
    }
    
#if os(macOS)
    @ViewBuilder
    func saveButton(logs: [String]) -> some View {
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
                .symbolEffect(.bounce, value: model.state == .running)
        }
    }
#endif
    
#if os(iOS)
    @ViewBuilder
    func shareButton(logs: [String]) -> some View {
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
                .symbolEffect(.bounce, value: model.state == .running)
        }
        .buttonStyle(.borderless)
    }
#endif
}
