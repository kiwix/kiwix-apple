//
//  ZimFileViewModifiers.swift
//  Kiwix
//
//  Created by Chris Li on 5/14/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

/// Context menu for a zim file.
struct ZimFileContextMenu: ViewModifier {
    @Binding var selected: ZimFile?
    let zimFile: ZimFile
    
    func body(content: Content) -> some View {
        content.contextMenu {
            Button {
                selected = zimFile
            } label: {
                Label("Show Detail", systemImage: "info.circle")
            }
            if let downloadURL = zimFile.downloadURL {
                Button {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(downloadURL.absoluteString, forType: .URL)
                    #elseif os(iOS)
                    UIPasteboard.general.setValue(downloadURL.absoluteString, forPasteboardType: UTType.url.identifier)
                    #endif
                } label: {
                    Label("Copy URL", systemImage: "doc.on.doc")
                }
            }
            Button {
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(zimFile.fileID.uuidString, forType: .string)
                #elseif os(iOS)
                UIPasteboard.general.setValue(zimFile.fileID.uuidString, forPasteboardType: UTType.plainText.identifier)
                #endif
            } label: {
                Label("Copy ID", systemImage: "barcode.viewfinder")
            }
        }
    }
}

/// On iOS, converts the modified view to a NavigationLink that goes to the zim file detail.
struct ZimFileSelection: ViewModifier {
    @Binding var selected: ZimFile?
    let zimFile: ZimFile
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content
        #elseif os(iOS)
        NavigationLink(tag: zimFile, selection: $selected) {
            ZimFileDetail(zimFile: zimFile)
        } label: {
            content
        }
        #endif
    }
}

/// On macOS, adds a panel to the right of the modified view to show zim file detail.
struct ZimFileDetailPanel: ViewModifier {
    let zimFile: ZimFile?
    
    func body(content: Content) -> some View {
        #if os(macOS)
        VStack(spacing: 0) {
            Divider()
            content.safeAreaInset(edge: .trailing, spacing: 0) {
                HStack(spacing: 0) {
                    Divider()
                    if let zimFile = zimFile {
                        ZimFileDetail(zimFile: zimFile)
                    } else {
                        HStack {
                            Spacer()
                            Text("select a zim file")
                            Spacer()
                        }.frame(maxHeight: .infinity)
                        .background(.regularMaterial)
                    }
                }.frame(width: 275).background(.ultraThinMaterial)
            }
        }
        #elseif os(iOS)
        content
        #endif
    }
}

/// Alert to confirm deleting zim file.
struct ZimFileDeleteAlert: ViewModifier {
    @Binding var isPresented: Bool
    
    let zimFile: ZimFile
    
    func body(content: Content) -> some View {
        content.alert(isPresented: $isPresented) {
            Alert(
                title: Text("Delete \(zimFile.name)"),
                message: Text("The zim file and all bookmarked articles linked to this zim file will be deleted."),
                primaryButton: .destructive(Text("Delete"), action: {
                    LibraryViewModel.delete(zimFileID: zimFile.fileID)
                }),
                secondaryButton: .cancel()
            )
        }
    }
}

/// Alert to confirm unlinking zim file.
struct ZimFileUnlinkAlert: ViewModifier {
    @Binding var isPresented: Bool
    
    let zimFile: ZimFile
    
    func body(content: Content) -> some View {
        content.alert(isPresented: $isPresented) {
            Alert(
                title: Text("Unlink \(zimFile.name)"),
                message: Text("""
                All bookmarked articles linked to this zim file will be deleted, \
                but the original file will remain in place.
                """),
                primaryButton: .destructive(Text("Unlink"), action: {
                    LibraryViewModel.unlink(zimFileID: zimFile.fileID)
                }),
                secondaryButton: .cancel()
            )
        }
    }
}
