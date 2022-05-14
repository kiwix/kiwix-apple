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

struct ZimFileCellSelection: ViewModifier {
    @Binding var selected: ZimFile?
    let zimFile: ZimFile
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content.onTapGesture {
            selected = zimFile
        }
        #elseif os(iOS)
        NavigationLink {
            ZimFileDetail(zimFile: zimFile)
        } label: {
            content
        }
        #endif
    }
}

struct ZimFileRowSelection: ViewModifier {
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
