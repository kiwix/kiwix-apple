//
//  BookmarksViewController.swift
//  Kiwix
//
//  Created by Chris Li on 10/26/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit


class BookmarksViewController: UIHostingController<BookmarksView> {
    convenience init() {
        self.init(rootView: BookmarksView())
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Done", style: .done, target: self, action: #selector(dismissController)
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if splitViewController != nil {
            navigationController?.navigationBar.isHidden = true
        }
    }
    
    @objc private func dismissController() {
        dismiss(animated: true)
    }
}

struct BookmarksView: View {
    var body: some View {
        Text("Hello!")
    }
}
