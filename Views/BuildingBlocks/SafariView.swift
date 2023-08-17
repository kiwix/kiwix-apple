//
//  SafariView.swift
//  Kiwix
//
//  Created by Chris Li on 8/14/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SafariServices
import SwiftUI

#if os(iOS)
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
}
#endif
