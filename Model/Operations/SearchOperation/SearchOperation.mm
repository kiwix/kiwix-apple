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
#import "reader.h"
#import "searcher.h"

struct SharedReaders {
    NSArray *readerIDs;
    std::vector<std::shared_ptr<kiwix::Reader>> readers;
};

@interface SearchOperation ()

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

- (NSArray *)getSearchResults {
    struct SharedReaders sharedReaders = [[ZimMultiReader shared] getSharedReaders:self.identifiers];
    
    // title search
    NSMutableArray *results = [self getTitleSearchResults:self.searchText readers:sharedReaders.readers];
    
    // initialize full text search
    if (self.isCancelled) { return results; }
    kiwix::Searcher searcher = kiwix::Searcher();
    for (auto iter: sharedReaders.readers) {
        searcher.add_reader(iter.get());
    }
    
    // start full text search
    if (self.isCancelled) { return results; }
    searcher.search([self.searchText cStringUsingEncoding:NSUTF8StringEncoding], 0, 20);
    
    // retrieve full text search results
    kiwix::Result *result = searcher.getNextResult();
    while (result != NULL) {
        NSString *zimFileID = sharedReaders.readerIDs[result->get_readerIndex()];
        NSString *path = [NSString stringWithCString:result->get_url().c_str() encoding:NSUTF8StringEncoding];
        NSString *title = [NSString stringWithCString:result->get_title().c_str() encoding:NSUTF8StringEncoding];
        
        SearchResult *searchResult = [[SearchResult alloc] initWithZimFileID:zimFileID path:path title:title];
        searchResult.probability = [[NSNumber alloc] initWithDouble:(double)result->get_score() / double(100)];
        
        // optionally, add snippet
        if (self.extractSnippet) {
            NSString *snippet = [NSString stringWithCString:result->get_snippet().c_str() encoding:NSUTF8StringEncoding];
            searchResult.snippet = snippet;
        }
        
        if (searchResult != nil) { [results addObject:searchResult]; }
        delete result;
        if (self.isCancelled) { break; }
        result = searcher.getNextResult();
    }
    
    return results;
}

- (NSMutableArray *)getTitleSearchResults:(NSString *)searchText readers:(std::vector<std::shared_ptr<kiwix::Reader>>)readers {
    NSMutableArray *results = [[NSMutableArray alloc] init];
    std::string searchTermC = [searchText cStringUsingEncoding:NSUTF8StringEncoding];
    
    for (auto reader: readers) {
        NSString *zimFileID = [NSString stringWithCString:reader->getId().c_str() encoding:NSUTF8StringEncoding];
        reader->searchSuggestionsSmart(searchTermC, 10);
        
        std::string titleC;
        std::string pathC;
        while (reader->getNextSuggestion(titleC, pathC)) {
            NSString *path = [NSString stringWithCString:pathC.c_str() encoding:NSUTF8StringEncoding];
            NSString *title = [NSString stringWithCString:titleC.c_str() encoding:NSUTF8StringEncoding];
            SearchResult *searchResult = [[SearchResult alloc] initWithZimFileID:zimFileID path:path title:title];
            if (searchResult != nil) { [results addObject:searchResult]; }
            if (self.isCancelled) { break; }
        }
        if (self.isCancelled) { break; }
    }
    return results;
}

@end
