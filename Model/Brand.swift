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
import os

enum AppType {
    case kiwix
    case custom(zimFileURL: URL)

    static let current = AppType()

    static var isCustom: Bool {
        switch current {
        case .kiwix: return false
        case .custom: return true
        }
    }

    private init() {
        guard let zimFileName: String = Config.value(for: .customZimFile),
              !zimFileName.isEmpty else {
            // it's not a custom app as it has no zim file set
            self = .kiwix
            return
        }
        guard let zimURL: URL = Bundle.main.url(forResource: zimFileName, withExtension: "zim") else {
            fatalError("zim file named: \(zimFileName) cannot be found")
        }
        self = .custom(zimFileURL: zimURL)
    }
}

enum Brand {
    static let appName: String = Config.value(for: .displayName) ?? "Kiwix"
    static let appStoreId: String = Config.value(for: .appStoreID) ?? "id997079563"
    static let loadingLogoImage: String = "welcomeLogo"
    static var loadingLogoSize: CGSize = ImageInfo.sizeOf(imageName: loadingLogoImage)!

    static let aboutText: String = Config.value(for: .aboutText) ?? "settings.about.description".localized
    static let aboutWebsite: String = Config.value(for: .aboutWebsite) ?? "https://www.kiwix.org"
    // currently only used by Kiwix brand
    // if this is missing from project.yml we fall back to true
    // and hide the support for donation (for macOS FTP)
    static let hideDonation: Bool = Config.value(for: .hideDonation) ?? false

    static var defaultExternalLinkPolicy: ExternalLinkLoadingPolicy {
        guard let policyString: String = Config.value(for: .externalLinkDefaultPolicy),
              let policy = ExternalLinkLoadingPolicy(rawValue: policyString) else {
            return .alwaysAsk
        }
        return policy
    }

    static var defaultSearchSnippetMode: SearchResultSnippetMode {
        guard FeatureFlags.showSearchSnippetInSettings else {
            // for custom apps, where we do not show this in settings, it should be disabled by default
            return .disabled
        }
        return .matches
    }
}

enum Config: String {

    case appStoreID = "APP_STORE_ID"
    case displayName = "CFBundleDisplayName"

    // this marks if the app is custom or not
    case customZimFile = "CUSTOM_ZIM_FILE"
    case showExternalLinkSettings = "SETTINGS_SHOW_EXTERNAL_LINK_OPTION"
    case externalLinkDefaultPolicy = "SETTINGS_DEFAULT_EXTERNAL_LINK_TO"
    case showSearchSnippetInSettings = "SETTINGS_SHOW_SEARCH_SNIPPET"
    case aboutText = "CUSTOM_ABOUT_TEXT"
    case aboutWebsite = "CUSTOM_ABOUT_WEBSITE"
    case hideDonation = "HIDE_DONATION"

    static func value<T>(for key: Config) -> T? where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key.rawValue) else {
            os_log("Missing key from bundle: %@", log: Log.Branding, type: .error, key.rawValue)
            return nil
        }
        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            os_log("Invalid value type found for key: %@", log: Log.Branding, type: .error, key.rawValue)
            return nil
        }
    }
}
