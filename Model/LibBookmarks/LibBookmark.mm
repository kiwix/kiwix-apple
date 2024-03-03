//
//  LibBookmark.m
//  Kiwix

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include "kiwix/bookmark.h"
#include "kiwix/book.h"
#include "zim/archive.h"
#pragma clang diagnostic pop

#import <Foundation/Foundation.h>
#import "LibBookmark.h"
#import "ZimFileService.h"

@interface LibBookmark()
@property (nonatomic, strong) NSURL *_Nonnull url;
@end

@implementation LibBookmark

- (instancetype) init: (NSURL *) url inZIM: (NSUUID *) zimFileID withTitle: (nonnull NSString *) title{
    self = [super init];
    if (self) {
        self.url = url;
        self.zimFileID_c = [[[zimFileID UUIDString] lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding];
        self.url_c = [url fileSystemRepresentation];
        self.title_c = [title cStringUsingEncoding:NSUTF8StringEncoding];
    }
    return self;
}

- (const kiwix::Bookmark &) bridged {
    kiwix::Book book = [ZimFileService getBookForURL: self.url];
    static const kiwix::Bookmark bookmark = kiwix::Bookmark(book, self.url_c, self.title_c);
    return bookmark;
}

@end
