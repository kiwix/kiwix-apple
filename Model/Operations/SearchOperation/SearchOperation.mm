//
//  SearchOperation.mm
//  Kiwix
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#import "kiwix/reader.h"
#import "kiwix/searcher.h"
#pragma clang diagnostic pop

#import "SearchOperation.h"
#import "SearchResult.h"
#import "ZimMultiReader.h"

struct SharedReaders {
    NSArray *readerIDs;
    std::vector<std::shared_ptr<kiwix::Reader>> readers;
};

@interface SearchOperation ()

@property (nonatomic, strong) NSSet *identifiers;

@end

@implementation SearchOperation

- (id)initWithSearchText:(NSString *)searchText zimFileIDs:(NSSet *)identifiers {
    self = [super init];
    if (self) {
        self.searchText = searchText;
        self.identifiers = identifiers;
        self.results = @[];
        self.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    return self;
}

- (void)performSearch:(BOOL)withFullTextSnippet; {
    struct SharedReaders sharedReaders = [[ZimMultiReader sharedInstance] getSharedReaders:self.identifiers];
    NSMutableSet *results = [[NSMutableSet alloc] initWithCapacity:15 + 3 * self.identifiers.count];
    [results addObjectsFromArray:[self getTitleSearchResults:sharedReaders.readers]];
    [results addObjectsFromArray:[self getFullTextSearchResults:sharedReaders withFullTextSnippet:withFullTextSnippet]];
    self.results = [results allObjects];
}

- (NSArray *)getFullTextSearchResults:(struct SharedReaders)sharedReaders withFullTextSnippet:(BOOL)withFullTextSnippet {
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:15];
    
    // initialize full text search
    if (self.isCancelled) { return results; }
    kiwix::Searcher searcher = kiwix::Searcher();
    for (auto iter: sharedReaders.readers) {
        searcher.add_reader(iter.get());
    }
    
    // start full text search
    if (self.isCancelled) { return results; }
    searcher.search([self.searchText cStringUsingEncoding:NSUTF8StringEncoding], 0, 15);
    
    // retrieve full text search results
    kiwix::Result *result = searcher.getNextResult();
    while (result != NULL) {
        NSString *zimFileID = sharedReaders.readerIDs[result->get_readerIndex()];
        NSString *path = [NSString stringWithCString:result->get_url().c_str() encoding:NSUTF8StringEncoding];
        NSString *title = [NSString stringWithCString:result->get_title().c_str() encoding:NSUTF8StringEncoding];
        
        SearchResult *searchResult = [[SearchResult alloc] initWithZimFileID:zimFileID path:path title:title];
        searchResult.probability = [[NSNumber alloc] initWithDouble:(double)result->get_score() / double(100)];
        
        // optionally, add snippet
        if (withFullTextSnippet) {
            NSString *html = [NSString stringWithCString:result->get_snippet().c_str() encoding:NSUTF8StringEncoding];
            searchResult.htmlSnippet = html;
        }
        
        if (searchResult != nil) { [results addObject:searchResult]; }
        delete result;
        if (self.isCancelled) { break; }
        result = searcher.getNextResult();
    }
    
    return results;
}

- (NSArray *)getTitleSearchResults:(std::vector<std::shared_ptr<kiwix::Reader>>)readers {
    NSMutableArray *results = [[NSMutableArray alloc] init];
    std::string searchTermC = [self.searchText cStringUsingEncoding:NSUTF8StringEncoding];
    
    for (auto reader: readers) {
        auto suggestions = std::make_shared<kiwix::SuggestionsList_t>();
        reader->searchSuggestionsSmart(searchTermC, 3, *suggestions);
        
        NSString *zimFileID = [NSString stringWithCString:reader->getId().c_str() encoding:NSUTF8StringEncoding];
        for (auto &suggestion : *suggestions) {
            try {
                NSString *title = [NSString stringWithCString:suggestion.at(0).c_str() encoding:NSUTF8StringEncoding];
                NSString *path = [NSString stringWithCString:suggestion.at(1).c_str() encoding:NSUTF8StringEncoding];
                
                SearchResult *searchResult = [[SearchResult alloc] initWithZimFileID:zimFileID path:path title:title];
                if (searchResult != nil) { [results addObject:searchResult]; }
                if (self.isCancelled) { break; }
            } catch (std::out_of_range) {
                continue;
            }
        }
        if (self.isCancelled) { break; }
    }
    return results;
}

@end
