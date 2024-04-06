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

//
//  Languages.swift
//  Kiwix

import Foundation

enum LanguagesConverter {
    static func convert(codes: Set<String>, validCodes: Set<String>) -> Set<String> {
        let invalidCodes = codes.subtracting(validCodes)
        let validatedCodes = codes.intersection(validCodes)
        // try to convert from iso-2 to iso-3 format:
        let converted = invalidCodes.compactMap(Self.convertToAlpha3(from:))
        let convertedValidatedCodes = Set<String>(converted).intersection(validCodes)
        return validatedCodes.union(convertedValidatedCodes)
    }

    static func convertToAlpha3(from alpha2: String) -> String? {
        if #available(iOS 16, macOS 13, *) {
            return Locale.LanguageCode(alpha2).identifier(.alpha3)
        } else {
            // Fallback on earlier versions
            return AlphaCodesLookUpTable.alpha2ToAlpha3[alpha2]
        }
    }
}
