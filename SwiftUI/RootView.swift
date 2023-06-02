//
//  RootView.swift
//  Kiwix
//
//  Created by Chris Li on 8/5/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct RootView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var url: URL?
    @StateObject private var viewModel = ViewModel()
    @StateObject private var readingViewModel = ReadingViewModel()
    
    var body: some View {
        Group {
            #if os(macOS)
            RootViewV2(url: $url)
            #elseif os(iOS)
            RootViewV1(url: $url).ignoresSafeArea(.all)
            #endif
        }
        .modify { view in
            if #available(macOS 12.0, iOS 15.0, *) {
                view
                    .focusedSceneValue(\.navigationItem, $viewModel.navigationItem)
                    .focusedSceneValue(\.url, url)
            } else {
                view
            }
        }
        .onChange(of: url) { _ in
            viewModel.navigationItem = .reading
            readingViewModel.activeSheet = nil
        }
        .onChange(of: horizontalSizeClass) { _ in
            viewModel.navigationItem = .reading
            readingViewModel.activeSheet = nil
        }
        .onOpenURL { url in
            if url.isFileURL {
                guard let metadata = ZimFileService.getMetaData(url: url) else { return }
                LibraryOperations.open(url: url)
                self.url = ZimFileService.shared.getMainPageURL(zimFileID: metadata.fileID)
            } else if url.scheme == "kiwix" {
                self.url = url
            }
        }
        .environmentObject(viewModel)
        .environmentObject(readingViewModel)
    }
}
