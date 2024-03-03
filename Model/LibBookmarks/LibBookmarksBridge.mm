//
//  LibBookmarksBridge.mm
//  Kiwix

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include "kiwix/library.h"
#include "kiwix/bookmark.h"
#pragma clang diagnostic pop

#import "LibBookmarksBridge.h"

# pragma mark - Private properties
@interface LibBookmarksBridge ()

@property kiwix::LibraryPtr library;

@end


# pragma mark - Implementation

@implementation LibBookmarksBridge

- (instancetype _Nonnull)init {
    self = [super init];
    if (self) {
        self.library = kiwix::Library::create();
    }
    return self;
}

- (BOOL) isBookmarked: (nonnull NSURL *) url inZIM: (nonnull NSUUID *) zimFileID {
    std::string url_c = [url fileSystemRepresentation];
    std::string fileID_c = [[[zimFileID UUIDString] lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding];
    for (kiwix::Bookmark bookmark: self.library->getBookmarks()) {
        if (bookmark.getUrl() == url_c && bookmark.getBookId() == fileID_c) {
            return true;
        }
    }
    return false;
}

- (void) add: (LibBookmark *) bookmark {
    self.library->addBookmark([bookmark bridged]);
}

- (void) remove: (LibBookmark *) bookmark {
    self.library->removeBookmark(bookmark.zimFileID_c, bookmark.url_c);
}

@end
