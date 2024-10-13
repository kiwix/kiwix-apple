// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import Foundation
import Combine
import Defaults

enum LaunchSequence: Equatable {
    case loadingData
    case webPage(isLoading: Bool)
    case catalog(CatalogSequence)
}

enum CatalogSequence: Equatable {
    case fetching
    case error
    case list
    case welcome(isCatalogLoading: Bool)
}

protocol LaunchViewModelProtocol {
    var state: Published<LaunchSequence>.Publisher { get }
}

// MARK: No Library (custom apps)

/// Keeps us int the .loadingData state,
/// while the main page is not fully loaded for the first time
@MainActor
final class NoCatalogLaunchViewModel: LaunchViewModelBase {

    private var wasLoaded = false

    convenience init(browser: BrowserViewModel) {
        self.init(browserIsLoading: browser.$isLoading)
    }

    /// - Parameter browserIsLoading: assumed to start with a nil value (see: WKWebView.isLoading)
    init(browserIsLoading: Published<Bool?>.Publisher) {
        super.init()
        browserIsLoading.sink { [weak self] (isLoading: Bool?) in
            guard let self else { return }
            switch isLoading {
            case .none:
                updateTo(.loadingData)
            case .some(true):
                if !wasLoaded {
                    updateTo(.loadingData)
                } else {
                    updateTo(.webPage(isLoading: true))
                }
            case .some(false):
                wasLoaded = true
                updateTo(.webPage(isLoading: false))
            }
        }.store(in: &cancellables)
    }
}

// MARK: With Catalog Library
@MainActor
final class CatalogLaunchViewModel: LaunchViewModelBase {

    convenience init(hasZIMFiles: Published<Bool>.Publisher,
                     library: LibraryViewModel,
                     browser: BrowserViewModel) {
        self.init(hasZIMFiles: hasZIMFiles,
                  libraryState: library.$state,
                  browserIsLoading: browser.$isLoading,
                  hasSeenCategories: { Defaults[.hasSeenCategories] })
    }

    init(hasZIMFiles: Published<Bool>.Publisher,
         libraryState: Published<LibraryState>.Publisher,
         browserIsLoading: Published<Bool?>.Publisher,
         hasSeenCategories: @escaping () -> Bool) {
        super.init()

        hasZIMFiles.combineLatest(
            libraryState,
            browserIsLoading
        ).sink { [weak self] (
            hasZIMs: Bool,
            libState: LibraryState,
            isBrowserLoading: Bool?
        ) in
            guard let self else { return }

            switch (isBrowserLoading, hasZIMs, libState) {

            // MARK: initial app start state
            case (_, _, .initial): updateTo(.loadingData)

            // MARK: browser must be empty as there are no ZIMs:
            case (_, false, .inProgress):
                if hasSeenCategories() {
                    updateTo(.catalog(.welcome(isCatalogLoading: true)))
                } else {
                    updateTo(.catalog(.fetching))
                }
            case (_, false, .complete): updateTo(.catalog(.welcome(isCatalogLoading: false)))
            case (_, false, .error): updateTo(.catalog(.error))

            // MARK: has zims and opens a new empty tab
            case (.none, true, _): updateTo(.catalog(.list))

            // MARK: actively browsing
            case (.some(true), true, _): updateTo(.webPage(isLoading: true))
            case (.some(false), true, _): updateTo(.webPage(isLoading: false))
            }
        }.store(in: &cancellables)
    }
}

class LaunchViewModelBase: LaunchViewModelProtocol {
    var state: Published<LaunchSequence>.Publisher { $currentState }
    var cancellables = Set<AnyCancellable>()
    @Published private var currentState: LaunchSequence = .loadingData

    func updateTo(_ newState: LaunchSequence) {
        guard newState != currentState else { return }
        currentState = newState
    }
}
