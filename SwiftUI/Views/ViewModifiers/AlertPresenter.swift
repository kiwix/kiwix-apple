//
//  AlertPresenter.swift
//  Kiwix
//
//  Created by Chris Li on 6/2/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

struct AlertPresenter: ViewModifier {
    @Binding var activeAlert: ActiveAlert?
    @Binding var activeSheet: ActiveSheet?
    
    func body(content: Content) -> some View {
        content.alert(item: $activeAlert) { activeAlert in
            switch activeAlert {
            case .articleFailedToLoad:
                return Alert(
                    title: Text("Unable to Load Article"),
                    message: Text(
                        "The zim file associated with the article might be missing or the link might be corrupted."
                    )
                )
            case .externalLinkAsk(let url):
                return Alert(
                    title: Text("External Link"),
                    message: Text("An external link is tapped, do you wish to load the link?"),
                    primaryButton: .default(Text("Load the link")) {
                        #if os(macOS)
                        NSWorkspace.shared.open(url)
                        #elseif os(iOS)
                        activeSheet = .safari(url: url)
                        #endif
                    },
                    secondaryButton: .cancel()
                )
            case .externalLinkNotLoading:
                return Alert(
                    title: Text("External Link"),
                    message: Text(
                        "An external link is tapped. However, your current setting does not allow it to be loaded."
                    )
                )
            }
        }
    }
}
