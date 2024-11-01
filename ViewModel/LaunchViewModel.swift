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

    var shouldShowCatalog: Bool {
        switch self {
        case .loadingData: return true
        case .webPage: return false
        case .catalog(.fetching): return true
        case .catalog(.welcome): return true
        case .catalog(.list): return false
        }
    }
}

enum CatalogSequence: Equatable {
    case fetching
    case list
    case welcome(WelcomeViewState)
}

enum WelcomeViewState: Equatable {
    case loading
    case error
    case complete
}

protocol LaunchProtocol: ObservableObject {
    var state: LaunchSequence { get }
    func updateWith(hasZimFiles: Bool, hasSeenCategories: Bool)
}

// MARK: No Library (custom apps)

/// Keeps us int the .loadingData state,
/// while the main page is not fully loaded for the first time
final class NoCatalogLaunchViewModel: LaunchViewModelBase {

    private static var wasLoaded = false

    convenience init(browser: BrowserViewModel) {
        self.init(browserIsLoading: browser.$isLoading)
    }

    /// - Parameter browserIsLoading: assumed to start with a nil value (see: WKWebView.isLoading)
    init(browserIsLoading: Published<Bool?>.Publisher) {
        super.init()
        browserIsLoading.sink { [weak self] (isLoading: Bool?) in
            guard let self = self else { return }
            switch isLoading {
            case .none:
                updateTo(.loadingData)
            case .some(true):
                if !Self.wasLoaded {
                    updateTo(.loadingData)
                } else {
                    updateTo(.webPage(isLoading: true))
                }
            case .some(false):
                Self.wasLoaded = true
                updateTo(.webPage(isLoading: false))
            }
        }.store(in: &cancellables)
    }

    override func updateWith(hasZimFiles: Bool, hasSeenCategories: Bool) {
        // to be ignored on purpose
    }
}

// MARK: With Catalog Library
final class CatalogLaunchViewModel: LaunchViewModelBase {

    private var hasZIMFiles = PassthroughSubject<Bool, Never>()
    private var hasSeenCategoriesOnce = PassthroughSubject<Bool, Never>()

    convenience init(library: LibraryViewModel,
                     browser: BrowserViewModel) {
        self.init(libraryState: library.$state, browserIsLoading: browser.$isLoading)
    }

    // swiftlint:disable closure_parameter_position
    init(libraryState: Published<LibraryState>.Publisher,
         browserIsLoading: Published<Bool?>.Publisher) {
        super.init()

        hasZIMFiles.combineLatest(
            libraryState,
            browserIsLoading,
            hasSeenCategoriesOnce
        ).sink { [weak self] (
            hasZIMs: Bool,
            libState: LibraryState,
            isBrowserLoading: Bool?,
            hasSeenCategories: Bool
        ) in
            guard let self = self else { return }

            switch (isBrowserLoading, hasZIMs, libState) {

            // MARK: initial app start state
            case (_, _, .initial): updateTo(.loadingData)

            // MARK: browser must be empty as there are no ZIMs:
            case (_, false, .inProgress):
                if hasSeenCategories {
                    updateTo(.catalog(.welcome(.loading)))
                } else {
                    updateTo(.catalog(.fetching))
                }
            case (_, false, .complete):
                if hasSeenCategories {
                    updateTo(.catalog(.welcome(.complete)))
                } else {
                    updateTo(.catalog(.fetching))
                }
            case (_, false, .error):
                // safety path to display the welcome buttons
                // in case of a fetch error, the user can try again
                hasSeenCategoriesOnce.send(true)
                updateTo(.catalog(.welcome(.error)))

            // MARK: has zims and opens a new empty tab
            case (.none, true, _): updateTo(.catalog(.list))

            // MARK: actively browsing
            case (.some(true), true, _): updateTo(.webPage(isLoading: true))
            case (.some(false), true, _): updateTo(.webPage(isLoading: false))
            }
        }.store(in: &cancellables)
    }
    // swiftlint:enable closure_parameter_position

    override func updateWith(hasZimFiles: Bool, hasSeenCategories: Bool) {
        hasZIMFiles.send(hasZimFiles)
        hasSeenCategoriesOnce.send(hasSeenCategories)
    }
}

class LaunchViewModelBase: LaunchProtocol, ObservableObject {
    var state: LaunchSequence = .loadingData
    var cancellables = Set<AnyCancellable>()

    func updateTo(_ newState: LaunchSequence) {
        guard newState != state else { return }
        state = newState
    }

    func updateWith(hasZimFiles: Bool, hasSeenCategories: Bool) {
        fatalError("should be overriden")
    }
}
