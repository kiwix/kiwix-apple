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

#include <unordered_map>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#import "zim/item.h"
#import "zim/search.h"
#import "zim/suggestion.h"
#pragma clang diagnostic pop

#import "SearchOperation.h"
#import "SearchResult.h"
#import "ZimFileService.h"

@interface SearchOperation ()

@property (assign) std::string searchText_C;
@property (nonatomic, strong) NSSet *zimFileIDs;

@end

@implementation SearchOperation

- (id)initWithSearchText:(NSString *)searchText zimFileIDs:(NSSet *)zimFileIDs {
    self = [super init];
    if (self) {
        self.searchText = searchText;
        self.searchText_C = [searchText cStringUsingEncoding:NSUTF8StringEncoding];
        self.zimFileIDs = zimFileIDs;
        self.results = [[NSMutableOrderedSet alloc] initWithCapacity:35];
        self.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    return self;
}

/// Perform index and title based searches.
- (void)performSearch {
    // get a list of archives that are included in search
    typedef std::unordered_map<std::string, zim::Archive> archives_map;
    auto *allArchives = static_cast<archives_map *>([[ZimFileService sharedInstance] getArchives]);

    std::vector<zim::Archive> indexSearchArchives = std::vector<zim::Archive>();
    std::vector<zim::Archive> titleSearchArchives = std::vector<zim::Archive>();
    for (NSUUID *zimFileID in self.zimFileIDs) {
        std::string zimFileID_C = [[[zimFileID UUIDString] lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding];
        try {
            auto archive = allArchives->at(zimFileID_C);
            if (archive.hasFulltextIndex()) {
                indexSearchArchives.push_back(archive);
            }
            titleSearchArchives.push_back(archive);
        } catch (std::exception) { }
    }

    // perform index and title search
    try {
        [self addIndexSearchResults:indexSearchArchives];
    } catch (std::exception) { }
    if (titleSearchArchives.size() > 0) {
        int count = std::max((35 - (int)[self.results count]) / (int)titleSearchArchives.size(), 5);
        [self addTitleSearchResults:titleSearchArchives count:(int)count];
    }
}

/// Add search results based on search index.
/// @param archives archives to retrieve search results from
- (void)addIndexSearchResults:(std::vector<zim::Archive>)archives {
    // initialize and start full text search
    if (self.isCancelled) { return; }
    if (archives.empty()) { return; }
    zim::Searcher searcher = zim::Searcher(archives);
    zim::SearchResultSet resultSet = searcher.search(zim::Query(self.searchText_C)).getResults(0, 25);
    
    // retrieve full text search results
    for (auto result = resultSet.begin(); result != resultSet.end(); result++) {
        if (self.isCancelled) { break; }
        
        zim::Item item = result->getItem(result->isRedirect());
        NSUUID *zimFileID = [[NSUUID alloc] initWithUUIDBytes:(unsigned char *)result.getZimId().data];
        NSString *path = [NSString stringWithCString:item.getPath().c_str() encoding:NSUTF8StringEncoding];
        NSString *title = [NSString stringWithCString:item.getTitle().c_str() encoding:NSUTF8StringEncoding];
        if (title.length == 0) {
            title = path; // display the path as a fallback
        }
        SearchResult *searchResult = [[SearchResult alloc] initWithZimFileID:zimFileID path:path title:title];
        searchResult.probability = [[NSNumber alloc] initWithFloat:result.getScore() / 100];
        
        // optionally, add snippet
        if (self.extractMatchingSnippet) {
            NSString *html = [NSString stringWithCString:result.getSnippet().c_str() encoding:NSUTF8StringEncoding];
            searchResult.htmlSnippet = html;
        }
        
        if (searchResult != nil) { [self.results addObject:searchResult]; }
    }
}

/// Add search results based on matching article titles with search text.
/// @param archives archives to retrieve search results from
/// @param count number of articles to retrieve for each archive
- (void)addTitleSearchResults:(std::vector<zim::Archive>)archives count:(int)count {
    for (zim::Archive archive: archives) {
        if (self.isCancelled) { break; }
        
        NSUUID *zimFileID = [[NSUUID alloc] initWithUUIDBytes:(unsigned char *)archive.getUuid().data];
        auto results = zim::SuggestionSearcher(archive).suggest(self.searchText_C).getResults(0, count);
        for (auto result = results.begin(); result != results.end(); result++) {
            if (self.isCancelled) { break; }
            NSString *path = [NSString stringWithCString:result->getPath().c_str() encoding:NSUTF8StringEncoding];
            NSString *title = [NSString stringWithCString:result->getTitle().c_str() encoding:NSUTF8StringEncoding];
            if (title.length > 0) {
                SearchResult *searchResult = [[SearchResult alloc] initWithZimFileID:zimFileID path:path title:title];
                if (searchResult != nil) {
                    [self.results addObject:searchResult];
                }
            }
        }
    }
}

@end
