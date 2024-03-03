//
//  LibBookmarks.swift
//  Kiwix

import Foundation

struct LibBookmarks {

    static let shared = LibBookmarks()
    private let bridge = LibBookmarksBridge()

    private init() {}

    func isBookmarked(url: URL, inZIMFile zimFileID: UUID) -> Bool {
        return bridge.__isBookmarked(url, inZIM: zimFileID)
    }

    func addBookmark(_ bookmark: LibBookmark) {
        bridge.__add(bookmark)
    }

    func removeBookmark(_ bookmark: LibBookmark) {
        bridge.__remove(bookmark)
    }


}
