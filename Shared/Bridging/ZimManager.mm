//
//  ZimManager.mm
//  Kiwix
//
//  Created by Chris Li on 8/17/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

#include <set>
#include <unordered_map>
#include "reader.h"
#include "searcher.h"
#import "ZimManager.h"

@interface ZimManager () {
    std::unordered_map<std::string, kiwix::Reader> readers;
}
@end

@implementation ZimManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [self scan];
    }
    return self;
}

- (void)scan {
    NSURL *docDirURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:docDirURL includingPropertiesForKeys:nil options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants) error:nil];
    
    std::set<std::string> existing;
    for(auto const &reader: readers) {
        existing.insert(reader.first);
    }
    
    for (NSURL *file in files) {
        try {
            kiwix::Reader reader = kiwix::Reader([file fileSystemRepresentation]);
            std::string identifier = reader.getId();
            readers.insert(std::pair<std::string, kiwix::Reader>(identifier, reader));
            existing.erase(identifier);
        } catch (const std::exception &e) { }
    }
    
    for(std::string const &identifier: existing) {
        readers.erase(identifier);
    }
}

//- (void)dealloc {
//}

@end
