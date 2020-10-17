## 1.13.6

- add TED category
- fixed an issue where it could lead to app launch crashes on iOS 12 (iPhone or iPad horizontally compact interface)

## 1.13.5

- added alert for when zim file of a bookmarked article is missing
- article loading speed improvements (especially on articles with a lot of images and on more recent devices)
- updated libkiwix version
- iOS 14 compatibility

## 1.13.4

- bookmark snippets are now using the first sentence (iOS 12 and above) or the first paragraph (iOS 11)
- small tweaks of sidebar and outline for a better UX
- fix: now use zim file title as bookmark title when the article doesn't have a title

## 1.13.3

- stability improvements to the under the hood file download sub-system
- stability improvements to search filters

## 1.13.2

- updated version of libkiwix and dependencies to resolve an issue where the app couldn't open some of the latest zim files
- updated version of realm to 5.2


## 1.13.1

- Resource unavailable alert: shown when a link was taped on, but the zim file is deleted.
- Fixed an issue where app is launched into the incorrect view for iPhones / iPod touch on iOS 11 and 12
- Prevent the snippet from showing up if all it contains is empty chars or new lines

## 1.13

- article outline improvements:
  - show article title in the navigation bar if available
  - prevent too much indentation when there is only one `h1` element in the article
  - list row separators now indent together with the text (so that it is easier to figure out the structure)
  - iPad: fixed an issue where search is not hidden if already visible when tapping on a outline row
  - for MediaWiki based zim files, sections are expanded when reading on horizontally narrow interface; if a section is already collapsed, tap on a outline item will expand that section
- iPad users can customize how side bar is displayed -- automatic, side by side or overlay
- setting for excluding zim files in backup is moved inside the library info interface
- bring back title based search results
- (iOS 13) some UI improvement / updates in search filter interface
  - the "All" button would now change to "None" if all zim files are included in search

Technical:

- Migrated database to Realm 5.0.2. Note once you install the beta app, you will be upgrade to the new database version, which is incompatible with the App Store production version.
- Migrated usage of SwiftyUserDefaults to Defaults. Tester should see if their old settings like external load policy, selected language filter, etc. are persisted after upgrading from App Store production version to 1.13 beta.
- The search filter interface is rewritten with SwiftUI. I have recently seen an uptick of crashes in this area. The old solution is rather hacky anyway, so I just rewrote this in SwiftUI so that issue would be fixed for most users. This is also the first SwiftUI interface in the app.

## 1.12

Speed improvements and more options for search snippets:

- Disabled: no search snippet, fastest
- First Paragraph: first paragraph of the article, max four lines
- First Sentence: from first paragraph, further extract the first sentence with iOS natural language processing engine
- Matches: highlight search term matches in the article (slowest, what we offer before)

Other New Stuff: 

- updated app icon
- new design of search result list

Bug fixes:

- fix: swipe back gesture was not working due to conflict with gesture to show sidebar
- fix: favicon would disappear for existing zim files after library manual refresh
- fix: sometimes the search filters fails to update when a zim file has been added or removed
- fix: Incorrect alphabetical ordering for library lanugage selector

## 1.11.1 (May 7, 2020)

- fix: font size not applied after article is loaded
- fix: snippet text color is too dark to read in dark mode
- fix: sometimes the font size setting prview becomes too tall
- fix: app launching issue for iOS 11 & 12 users
- new: integration with OPDS API for library catalog refreshing


## 1.11 (Jan 12, 2020)

A redesigned iPad interface
Fixing an issue where app creashed when attempting to save image to photo library


## 1.10 (Aug 10, 2019)

Now you can importing zim files by:
- open a zim file in the Files app
- use "open in" feature from any app
Better Files app integration:
- manage files stored in kiwix in Files app

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
