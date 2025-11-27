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

import SwiftUI

extension ZimFileDetail {
    struct ServiceWorkerWarning: View {
        var body: some View {
            Label {
                Text(LocalString.service_worker_warning_label_description)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill").renderingMode(.original)
            }
        }
    }
}
