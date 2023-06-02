//
//  ViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 9/3/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import MapKit
import WebKit

import Defaults

class ViewModel: ObservableObject {
    @Published var navigationItem: NavigationItem? = .reading
}
