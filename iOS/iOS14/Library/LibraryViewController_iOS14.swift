//
//  LibraryViewController_iOS14.swift
//  Kiwix
//
//  Created by Chris Li on 11/23/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
class LibraryViewController_iOS14: UIHostingController<AnyView> {
    convenience init() {
        self.init(rootView: AnyView(LibraryView().environmentObject(LibraryViewModel())))
    }
}

@available(iOS 14.0, *)
struct LibraryView: View {
    var body: some View {
        Text("Hello, World!")
    }
}


@available(iOS 14.0, *)
class LibraryViewModel: ObservableObject {
    
}
