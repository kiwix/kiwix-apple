//
//  ZimFileViewModifiers.swift
//  Kiwix
//
//  Created by Chris Li on 5/14/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

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

struct ZimFileDeleteAlert: ViewModifier {
    @Binding var isPresented: Bool
    
    let zimFile: ZimFile
    
    func body(content: Content) -> some View {
        content.alert(isPresented: $isPresented) {
            Alert(
                title: Text("Delete \(zimFile.name)"),
                message: Text("The zim file and all bookmarked articles linked to this zim file will be deleted."),
                primaryButton: .destructive(Text("Delete"), action: {
                    
                }),
                secondaryButton: .cancel()
            )
        }
    }
}

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
                    
                }),
                secondaryButton: .cancel()
            )
        }
    }
}
