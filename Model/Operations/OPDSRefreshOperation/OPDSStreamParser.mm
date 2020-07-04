//
//  OPDSStreamParser.mm
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include "kiwix/book.h"
#include "kiwix/library.h"
#include "kiwix/manager.h"
#pragma clang diagnostic pop

#import "OPDSStreamParser.h"
#import "ZimFileMetaData.h"

@interface OPDSStreamParser ()

@property (assign) kiwix::Library *library;

@end

@implementation OPDSStreamParser

- (instancetype _Nonnull)init {
    self = [super init];
    if (self) {
        self.library = new kiwix::Library();
    }
    return self;
}

- (void)dealloc {
    delete self.library;
}

- (BOOL)parseData:(nonnull NSData *)data error:(NSError **)error {
    try {
        NSString *streamContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        std::shared_ptr<kiwix::Manager> manager = std::make_shared<kiwix::Manager>(self.library);
        manager->readOpds([streamContent cStringUsingEncoding:NSUTF8StringEncoding],
                          [@"https://library.kiwix.org" cStringUsingEncoding:NSUTF8StringEncoding]);
        return true;
    } catch (std::exception) {
        *error = [[NSError alloc] init];
        return false;
    }
}

- (NSArray *)getZimFileIDs {
    NSMutableArray *identifiers = [[NSMutableArray alloc] initWithCapacity:self.library->getBookCount(false, true)];
    for (auto identifierC: self.library->getBooksIds()) {
        NSString *identifier = [NSString stringWithUTF8String:identifierC.c_str()];
        [identifiers addObject:identifier];
    }
    return identifiers;
}

- (ZimFileMetaData *)getZimFileMetaData:(NSString *)identifier {
    std::string identifierC = [identifier cStringUsingEncoding:NSUTF8StringEncoding];
    kiwix::Book book = self.library->getBookById(identifierC);
    return [[ZimFileMetaData alloc] initWithBook: &book];
}

@end
