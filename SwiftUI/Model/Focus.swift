//
//  Focus.swift
//  Kiwix
//
//  Created by Chris Li on 5/27/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct CanGoBackKey: FocusedValueKey {
    typealias Value = Bool
}

struct CanGoForwardKey: FocusedValueKey {
    typealias Value = Bool
}

struct NavigationItemKey: FocusedValueKey {
    typealias Value = Binding<NavigationItem?>
}

struct ReaderViewModelKey: FocusedValueKey {
    typealias Value = ReaderViewModel
}

struct SearchFieldFocusActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct URLKey: FocusedValueKey {
    typealias Value = URL?
}

extension FocusedValues {
    var canGoBack: CanGoBackKey.Value? {
        get { self[CanGoBackKey.self] }
        set { self[CanGoBackKey.self] = newValue }
    }
    
    var canGoForward: CanGoForwardKey.Value? {
        get { self[CanGoForwardKey.self] }
        set { self[CanGoForwardKey.self] = newValue }
    }
    
    var navigationItem: NavigationItemKey.Value? {
        get { self[NavigationItemKey.self] }
        set { self[NavigationItemKey.self] = newValue }
    }
    
    var readerViewModel: ReaderViewModelKey.Value? {
        get { self[ReaderViewModelKey.self] }
        set { self[ReaderViewModelKey.self] = newValue }
    }
    
    var searchFieldFocusAction: SearchFieldFocusActionKey.Value? {
        get { self[SearchFieldFocusActionKey.self] }
        set { self[SearchFieldFocusActionKey.self] = newValue }
    }
    
    var url: URLKey.Value? {
        get { self[URLKey.self] }
        set { self[URLKey.self] = newValue }
    }
}
