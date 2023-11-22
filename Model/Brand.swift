//  Copyright © 2023 Kiwix. All rights reserved.

import Foundation

enum Brand {
    static let appName: String = Bundle.main.appDisplayName ?? "Kiwix"
    static let welcomeLogoImageName: String = "welcomeLogo"
}


public extension Bundle {
    var appDisplayName: String? {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
    }
}
