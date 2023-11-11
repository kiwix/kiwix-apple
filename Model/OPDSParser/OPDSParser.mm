//
//  OPDSParser.mm
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2023 Chris Li. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include "kiwix/book.h"
#include "kiwix/library.h"
#include "kiwix/manager.h"
#pragma clang diagnostic pop

#import "OPDSParser.h"
#import "ZimFileMetaData.h"

@interface OPDSParser ()

@property kiwix::LibraryPtr library;

@end

@implementation OPDSParser

- (instancetype _Nonnull)init {
    self = [super init];
    if (self) {
        self.library = kiwix::Library::create();
    }
    return self;
}

- (BOOL)parseData:(nonnull NSData *)data {
    try {
        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        std::shared_ptr<kiwix::Manager> manager = std::make_shared<kiwix::Manager>(self.library);
        return manager->readOpds([content cStringUsingEncoding:NSUTF8StringEncoding],
                                 [@"https://library.kiwix.org" cStringUsingEncoding:NSUTF8StringEncoding]);
    } catch (std::exception) {
        return false;
    }
}

- (NSSet *)getZimFileIDs {
    NSMutableArray *uuids = [[NSMutableArray alloc] initWithCapacity:self.library->getBookCount(false, true)];
    for (std::string identifierC: self.library->getBooksIds()) {
        NSString *identifier = [NSString stringWithUTF8String:identifierC.c_str()];
        [uuids addObject:[[NSUUID alloc] initWithUUIDString:identifier]];
    }
    return [[NSSet alloc] initWithArray:uuids];
}

- (ZimFileMetaData *)getZimFileMetaData:(NSUUID *)identifier {
    std::string identifierC = [[[identifier UUIDString] lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding];
    try {
        kiwix::Book book = self.library->getBookById(identifierC);
        return [[ZimFileMetaData alloc] initWithBook: &book];
    } catch (std::out_of_range) {
        return nil;
    }
}

@end
