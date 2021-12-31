//
//  ZimFileMetaData.mm
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include "kiwix/book.h"
#pragma clang diagnostic pop

#import "ZimFileMetaData.h"

#define SAFE_READ(X, Y) try {X = Y;} catch (std::exception) {X = nil;}
#define SAFE_READ_BOOL(X, Y) try {X = Y;} catch (std::exception) {X = false;}

@implementation ZimFileMetaData

- (nullable instancetype)initWithBook:(void *)book {
    self = [super init];
    if (self) {
        kiwix::Book *_book = static_cast<kiwix::Book *>(book);
        
        try {
            self.identifier = [NSString stringWithUTF8String:_book->getId().c_str()];
            self.fileID = [[NSUUID alloc] initWithUUIDString:self.identifier];
            self.title = [NSString stringWithUTF8String:_book->getTitle().c_str()];
            self.groupIdentifier = [NSString stringWithUTF8String:_book->getName().c_str()];
            self.fileDescription = [NSString stringWithUTF8String:_book->getDescription().c_str()];
            self.languageCode = [self getLanguageCodeFromBook:_book];
            self.category = [self getCategoryFromBook:_book];
            self.creationDate = [self getCreationDateFromBook:_book];
            self.size = [NSNumber numberWithUnsignedLongLong:_book->getSize()];
            self.articleCount = [NSNumber numberWithUnsignedLongLong:_book->getArticleCount()];
            self.mediaCount = [NSNumber numberWithUnsignedLongLong:_book->getMediaCount()];
            self.creator = [NSString stringWithUTF8String:_book->getCreator().c_str()];
            self.publisher = [NSString stringWithUTF8String:_book->getPublisher().c_str()];
        } catch (std::exception) {
            return nil;
        }
        
        // fail if required property is nil
        if (self.fileID == nil) { return nil; }
        if (self.creationDate == nil) { return nil; }
        if (self.size == nil) { return nil; }
        if (self.articleCount == nil) { return nil; }
        if (self.mediaCount == nil) { return nil; }
        if (self.creator == nil) { return nil; }
        if (self.publisher == nil) { return nil; }
        
        SAFE_READ(self.downloadURL, [self getURL:_book->getUrl()]);
        SAFE_READ(self.faviconURL, [self getURL:_book->getFaviconUrl()]);
        SAFE_READ(self.faviconData, [self getFaviconData:_book]);
        SAFE_READ(self.tag, [self getTag:_book->getUrl()]);
        
        SAFE_READ_BOOL(self.hasDetails, _book->getTagBool("details"));
        SAFE_READ_BOOL(self.hasPictures, _book->getTagBool("pictures"));
        SAFE_READ_BOOL(self.hasVideos, _book->getTagBool("videos"));
        SAFE_READ_BOOL(self.requiresServiceWorker, _book->getTagBool("sw"));
    }
    return self;
}

- (NSString *)getLanguageCodeFromBook:(kiwix::Book *)book {
    NSString *code = [NSString stringWithUTF8String:book->getLanguage().c_str()];
    return [NSLocale canonicalLanguageIdentifierFromString:code];
}

- (NSString *)getCategoryFromBook:(kiwix::Book *)book {
    try {
        return [NSString stringWithUTF8String:book->getTagStr("category").c_str()];
    } catch (std::out_of_range e) {
        return @"other";
    }
}

- (NSDate *)getCreationDateFromBook:(kiwix::Book *)book {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    return [formatter dateFromString:[NSString stringWithUTF8String:book->getDate().c_str()]];
}

- (NSURL *)getURL:(std::string)urlString {
    if (urlString.length() == 0) { return nil; }
    return [NSURL URLWithString:[NSString stringWithUTF8String:urlString.c_str()]];
}

- (NSData *)getFaviconData:(kiwix::Book *)book {
    if (self.faviconURL != nil) { return nil; }
    std::string favicon = book->getFavicon();
    return [NSData dataWithBytes:favicon.c_str() length:favicon.length()];
}

- (NSString *)getTag:(std::string)urlString {
    NSString *url = [NSString stringWithUTF8String:urlString.c_str()];
    if ([url containsString:@"maxi"]) {
        return @"max";
    } else if ([url containsString:@"nopic"]) {
        return @"nopic";
    } else if ([url containsString:@"mini"]) {
        return @"mini";
    } else {
        return nil;
    }
}

@end
