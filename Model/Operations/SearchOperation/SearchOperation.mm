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
#import "zim/suggestion.h"
#pragma clang diagnostic pop

#import "SearchOperation.h"
#import "SearchResult.h"
#import "ZimFileService.h"

struct SharedReaders {
    NSArray *readerIDs;
    std::vector<std::shared_ptr<kiwix::Reader>> readers;
    std::vector<zim::Archive> archives;
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
        self.results = [[NSMutableSet alloc] initWithCapacity:35];
        self.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    return self;
}

- (void)performSearch:(BOOL)withFullTextSnippet; {
    struct SharedReaders sharedReaders = [[ZimFileService sharedInstance] getSharedReaders:self.identifiers];
    NSMutableSet *results = [[NSMutableSet alloc] initWithCapacity:35];
    
    NSArray *fullTextResults = [self getFullTextSearchResults:sharedReaders withFullTextSnippet:withFullTextSnippet];
    NSUInteger readerCount = sharedReaders.readers.size();
    if (readerCount > 0) {
        NSUInteger count = max((35 - [fullTextResults count]) / readerCount, (NSUInteger)3);
        NSArray *titleResults = [self getTitleSearchResults:sharedReaders.archives count:count];
        [results addObjectsFromArray:titleResults];
    }
    [results addObjectsFromArray:fullTextResults];
    
    self.results = [results allObjects];
}

- (NSArray *)getFullTextSearchResults:(struct SharedReaders)sharedReaders withFullTextSnippet:(BOOL)withFullTextSnippet {
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:25];
    
    // initialize full text search
    if (self.isCancelled) { return results; }
    zim::Searcher searcher = zim::Searcher(sharedReaders.archives);
    
    // start full text search
    if (self.isCancelled) { return results; }
    zim::Query query = zim::Query([self.searchText cStringUsingEncoding:NSUTF8StringEncoding]);
    zim::SearchResultSet resultSet = searcher.search(query).getResults(0, 25);
    
    // retrieve full text search results
    for (auto result = resultSet.begin(); result != resultSet.end(); result++) {
        zim::Entry entry = (*result).getRedirectEntry();
        NSUUID *zimFileID = [[NSUUID alloc] initWithUUIDBytes:(unsigned char *)result.getZimId().data];
        NSString *path = [NSString stringWithCString:entry.getPath().c_str() encoding:NSUTF8StringEncoding];
        NSString *title = [NSString stringWithCString:entry.getTitle().c_str() encoding:NSUTF8StringEncoding];
        
        SearchResult *searchResult = [[SearchResult alloc] initWithZimFileID:[zimFileID UUIDString] path:path title:title];
        searchResult.probability = [[NSNumber alloc] initWithFloat:result.getScore() / 100];
        
        // optionally, add snippet
        if (self.includeSnippet) {
            NSString *html = [NSString stringWithCString:result.getSnippet().c_str() encoding:NSUTF8StringEncoding];
            searchResult.htmlSnippet = html;
        }
        
        if (searchResult != nil) { [results addObject:searchResult]; }
        if (self.isCancelled) { break; }
    }
    return results;
}

/// Add search results based on matching article titles with search text
/// @param archives archives to retrieve search results from
/// @param count number of articles to retrieve for each archive
- (NSArray *)addTitleSearchResults:(std::vector<zim::Archive>)archives count:(int)count {
    std::string searchTermC = [self.searchText cStringUsingEncoding:NSUTF8StringEncoding];
    for (zim::Archive archive: archives) {
        if (self.isCancelled) { break; }
        NSUUID *zimFileID = [[NSUUID alloc] initWithUUIDBytes:(unsigned char *)archive.getUuid().data];
        auto results = zim::SuggestionSearcher(archive).suggest(searchTermC).getResults(0, count);
        for (auto result = results.begin(); result != results.end(); result++) {
            if (self.isCancelled) { break; }
            zim::Item item = result.getEntry().getRedirect();
            NSString *path = [NSString stringWithCString:item.getPath().c_str() encoding:NSUTF8StringEncoding];
            NSString *title = [NSString stringWithCString:item.getTitle().c_str() encoding:NSUTF8StringEncoding];
            SearchResult *searchResult = [[SearchResult alloc] initWithZimFileID:[zimFileID UUIDString] path:path title:title];
            if (searchResult != nil) { [self.results addObject:searchResult]; }
        }
    }
}

@end
