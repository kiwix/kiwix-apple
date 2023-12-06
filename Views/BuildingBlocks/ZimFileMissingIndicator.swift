//
//  ZimFileMissingIndicator.swift
//  Kiwix
//
//  Created by Chris Li on 7/17/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct ZimFileMissingIndicator: View {
    var body: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .renderingMode(.original)
            .help("zim_file_missing_indicator.help".localized)
    }
}
