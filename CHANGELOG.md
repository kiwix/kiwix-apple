## 1.9.7 (Jul 7, 2019)

- fix: memory usage issue when performing searches
- maintance updates:
  - swift 5.2, version bump of libkiwix, realm and SwiftyUserDefaults
  - removed third party library ProcedureKit, now use Foundation.OperationQueue to handle async tasks

## 1.9.6 (May 10, 2019)

- updated user feedback email address to `contact.kiwix.org`
- dropped support for external indexes
- improved iOS 12 support
- new version of libkiwix and Swift 4.2

## 1.9.4 (August 22, 2018)
- NEW: sort languages in library language filter both by count or alphabetically
- NEW: search for a zim file by name in library online catalog

## 1.9.1 (June 10, 2018)
- Use Realm in replace of CoreData as database
- Added Wiktionary, Wikiquote and Wikisource categories
- Fix: unable to detect embedded index in some situations
- Fix: unable to cancel erroneous download tasks

## 1.9.0 (May 09, 2018)

- New Library Design:
  - ZIM files are grouped by topic categories
  - ZIM file detail view
  - Downloading content and catalog are displayed in one place
  - On iPads, using a split view with ZIM file / categories on the left and detail on the right
- Bookmark
  - Now displayed as a side panel on iPad
  - Add / remove bookmark interface is now presented as a HUD and does not cover up all the screen space
- Reading
  - Now ask users for confirmation when opening external links. Can be turned on or off in settings
- Core
  - Massive multiple improvement of the ZIM file mgmt through introduction of Kiwix lib 2.0.
- An effort has been made to keep compatibility with iOS 10.

## 1.8.0 (March 03, 2017)

- Library has a new look
- Support zim files with build in index
- Performance optimization
- Now in Swift 3.1

## 1.7.1 (September 14, 2016)

- Improved iOS 10 compatibility

## 1.7.0 (August 05, 2016)

- Informative bookmarks
- New add / remove bookmarks interface
- Bookmarks Today Widget
- Bug fixes and performance improvements

## 1.6.0 (July 07, 2016)

### New
- show recent search terms
- search system now fetch result from both title search and index search and use a new ranking system to sort them
- table of content
- enhanced layout javascript on iPhone
- Use SafariViewController to handle external links
- access download.kiwix.org using https
- enhanced UI when hSizeClass is regular

### Fixed
- downloading / paused book purged when they are removed from online library
- removed code that mistakenly indicates app use Wallet
- open main page when first book finish downloaded
