//
//  SearchOperation.mm
//  Kiwix
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import "SearchOperation.h"
#import "SearchResult.h"
#import "ZimMultiReader.h"
#include "reader.h"
#include "searcher.h"

struct SharedReaders {
    NSArray *readerIDs;
    std::vector<std::shared_ptr<kiwix::Reader>> readers;
};

@interface SearchOperation ()

@property (strong) NSString *searchText;
@property (strong) NSSet *identifiers;

@end

@implementation SearchOperation

- (id)initWithSearchText:(NSString *)searchText zimFileIDs:(NSSet *)identifiers {
    self = [super init];
    if (self) {
        self.searchText = searchText;
        self.identifiers = identifiers;
        self.results = @[];
    }
    return self;
}

- (void)main {
    struct SharedReaders sharedReaders = [[ZimMultiReader shared] getSharedReaders:self.identifiers];
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:20];
    
    // initialize kiwix::Search
    kiwix::Searcher searcher = kiwix::Searcher();
    for (auto iter: sharedReaders.readers) {
        searcher.add_reader(iter.get());
    }
    
    // start search
    if (self.isCancelled) { return; }
    searcher.search([self.searchText cStringUsingEncoding:NSUTF8StringEncoding], 0, 20);
    
    // retrieve search results
    kiwix::Result *result = searcher.getNextResult();
    while (result != NULL) {
        SearchResult *searchResult = [[SearchResult alloc] init];
        searchResult.zimFileID = sharedReaders.readerIDs[result->get_readerIndex()];
        searchResult.path = [NSString stringWithCString:result->get_url().c_str() encoding:NSUTF8StringEncoding];
        searchResult.title = [NSString stringWithCString:result->get_title().c_str() encoding:NSUTF8StringEncoding];
        [results addObject:searchResult];
        
        delete result;
        result = searcher.getNextResult();
        if (self.isCancelled) { break; }
    }
    
    self.results = results;
}

@end
