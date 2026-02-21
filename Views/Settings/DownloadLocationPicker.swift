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

#if os(macOS)
import SwiftUI
import AppKit
import Defaults

/// A view that allows users to select a custom download directory on macOS.
/// When a custom directory is set, downloads will write directly to that location
/// instead of using the system temp directory first.
struct DownloadLocationPicker: View {
    @State private var currentDirectory: URL?
    @State private var availableSpace: String = ""
    @State private var volumeName: String = ""
    @State private var isCustomDirectory: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Current location display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentDirectoryPath)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    HStack(spacing: 12) {
                        if !volumeName.isEmpty {
                            Label(volumeName, systemImage: "externaldrive")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if !availableSpace.isEmpty {
                            Label(availableSpace + " " + LocalString.download_location_available,
                                  systemImage: "internaldrive")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    Button(LocalString.download_location_button_choose) {
                        chooseDirectory()
                    }
                    
                    if isCustomDirectory {
                        Button(LocalString.download_location_button_reset) {
                            resetToDefault()
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            // Info text
            if isCustomDirectory {
                Text(LocalString.download_location_info_custom)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text(LocalString.download_location_info_default)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            refreshCurrentDirectory()
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentDirectoryPath: String {
        currentDirectory?.path ?? LocalString.download_location_unknown
    }
    
    // MARK: - Actions
    
    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.title = LocalString.download_location_panel_title
        panel.message = LocalString.download_location_panel_message
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        
        // Start in the current directory if available
        if let currentDir = currentDirectory {
            panel.directoryURL = currentDir
        }
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                setCustomDirectory(url)
            }
        }
    }
    
    private func setCustomDirectory(_ url: URL) {
        // Validate the directory is writable
        guard FileManager.default.isWritableFile(atPath: url.path) else {
            // Show error alert
            let alert = NSAlert()
            alert.messageText = LocalString.download_location_error_title
            alert.informativeText = LocalString.download_location_error_not_writable
            alert.alertStyle = .warning
            alert.addButton(withTitle: LocalString.common_button_ok)
            alert.runModal()
            return
        }
        
        // Save the directory
        if DownloadDestination.setCustomDownloadDirectory(url) {
            refreshCurrentDirectory()
        } else {
            // Show error alert
            let alert = NSAlert()
            alert.messageText = LocalString.download_location_error_title
            alert.informativeText = LocalString.download_location_error_save_failed
            alert.alertStyle = .warning
            alert.addButton(withTitle: LocalString.common_button_ok)
            alert.runModal()
        }
    }
    
    private func resetToDefault() {
        DownloadDestination.clearCustomDownloadDirectory()
        refreshCurrentDirectory()
    }
    
    private func refreshCurrentDirectory() {
        currentDirectory = DownloadDestination.effectiveDownloadFolder()
        isCustomDirectory = DownloadDestination.hasCustomDownloadDirectory
        
        // Update available space
        if let space = DownloadDestination.availableDiskSpace() {
            availableSpace = ByteCountFormatter.string(fromByteCount: space, countStyle: .file)
        } else {
            availableSpace = ""
        }
        
        // Update volume name
        volumeName = DownloadDestination.volumeName() ?? ""
    }
}

// MARK: - Preview

#if DEBUG
struct DownloadLocationPicker_Previews: PreviewProvider {
    static var previews: some View {
        DownloadLocationPicker()
            .padding()
            .frame(width: 500)
    }
}
#endif

#endif
