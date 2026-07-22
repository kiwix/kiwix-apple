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

/// Intermediate represenation of PayWithApplePayButtonLabel
/// which might crash on resolving directly in an async manner
/// so we first resolve it to this type (optionally)
/// and only if available trying to use PayWithApplePayButtonLabel
/// see: https://github.com/kiwix/kiwix-apple/issues/1651
enum PaymentButtonType {
    case setUp
    case donate
}
