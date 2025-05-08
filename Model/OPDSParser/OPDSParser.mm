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

- (BOOL)parseData:(nonnull NSData *)data using: (nonnull NSString *)urlHost {
    try {
        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (content == nil) {
            return false;
        }
        std::shared_ptr<kiwix::Manager> manager = std::make_shared<kiwix::Manager>(self.library);
        return manager->readOpds([content cStringUsingEncoding:NSUTF8StringEncoding],
                                 [urlHost cStringUsingEncoding:NSUTF8StringEncoding]);
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
