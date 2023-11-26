//  Copyright © 2023 Kiwix. All rights reserved.

import Foundation
import os

enum Brand {
    static let appName: String = Config.value(for: .displayName) ?? "Kiwix"
    static let welcomeLogoImageName: String = "welcomeLogo"
    static var mainZimFileURL: URL? {
        guard let zimFileName: String = Config.value(for: .zimFileMain),
              !zimFileName.isEmpty else { return nil }
        return Bundle.main.url(forResource: zimFileName, withExtension: "zim")
    }

    static var defaultExternalLinkPolicy: ExternalLinkLoadingPolicy {
        guard let policyString: String = Config.value(for: .externalLinkDefaultPolicy),
              let policy = ExternalLinkLoadingPolicy(rawValue: policyString) else {
            return .alwaysAsk
        }
        return policy
    }
}

enum Config: String {

    case displayName = "CFBundleDisplayName"
    case hasLibrary = "HAS_LIBRARY"
    case zimFileMain = "ZIM_FILE_MAIN"
    case showExternalLinkSettings = "SETTINGS_SHOW_EXTERNAL_LINK_OPTION"
    case externalLinkDefaultPolicy = "SETTINGS_DEFAULT_EXTERNAL_LINK_TO"

    static func value<T>(for key: Config) -> T? where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey:key.rawValue) else {
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

