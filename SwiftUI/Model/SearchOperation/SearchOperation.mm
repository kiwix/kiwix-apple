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
#import "kiwix/spelling_correction.h"
#import <filesystem>
#pragma clang diagnostic pop

#import "SearchOperation.h"
#import "SearchResult.h"
#import "ZimFileService.h"
#import "xapian.h"

@interface NSURL (PathManipulation)
- (NSURL * _Nonnull) withTrailingSlash;
@end

@implementation NSURL (PathManipulation)
- (NSURL * _Nonnull) withTrailingSlash {
    if ([self.absoluteString hasSuffix:@"/"]) {
        return self;
    } else {
        NSString *lastPathComponent = self.lastPathComponent;
        if(lastPathComponent == nil) {
            return self;
        } else {
            NSString *lastPath = [lastPathComponent stringByAppendingString:@"/"];
            NSURL* withoutLastPath = [self URLByDeletingLastPathComponent];
            if(withoutLastPath == nil) {
                return self;
            } else {
                NSURL *newURL = [withoutLastPath URLByAppendingPathComponent: lastPath];
                if(newURL == nil) {
                    return self;
                } else {
                    return newURL;
                }
            }
        }
    }
}

@end


@interface SearchOperation ()

@property (assign) std::string searchText_C;

@end

@implementation SearchOperation

- (id)initWithSearchText:(NSString *)searchText zimFileIDs:(NSSet *)zimFileIDs withSpellingCacheDir:(NSURL *)spellCacheDir {
    self = [super init];
    if (self) {
        if([searchText canBeConvertedToEncoding: NSUTF8StringEncoding]) {
            const char *_Nullable searchText_c_pointer = [searchText cStringUsingEncoding:NSUTF8StringEncoding];
            if (searchText_c_pointer == nil) {
                self.searchText = @"";
                self.searchText_C = "";
            } else {
                self.searchText = searchText;
                self.searchText_C = searchText_c_pointer;
            }
        } else {
            self.searchText = @"";
            self.searchText_C = "";
        }
        self.zimFileIDs = zimFileIDs;
        self.spellCacheDir = spellCacheDir;
        self.results = [[NSMutableOrderedSet alloc] initWithCapacity:35];
        self.corrections = [[NSMutableOrderedSet alloc] init];
        self.foundURLs = [[NSMutableSet alloc] initWithCapacity:35];
        self.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    return self;
}

/// Perform index and title based searches.
- (void)performSearch {
    // get a list of archives that are included in search
    typedef std::unordered_map<std::string, zim::Archive> archives_map;
    auto *allArchives = static_cast<archives_map *>([[ZimFileService sharedInstance] getArchives]);

    for (NSUUID *zimFileID in self.zimFileIDs) {
        // should be fine for utf-8 encoding
        std::string zimFileID_C = [[[zimFileID UUIDString] lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding];
        try {
            auto archive = allArchives->at(zimFileID_C);
            if (archive.hasFulltextIndex()) {
                [self addIndexSearchResults:archive count: 25];
            }
            [self addTitleSearchResults:archive count: 25];
        } catch (std::exception &e) {
            NSLog(@"perform search exception: %s", e.what());
        }
    }
}

/// Add search results based on search index.
/// @param archive to retrieve search results from
/// @param count number of articles to retrieve
- (void)addIndexSearchResults:(zim::Archive)archive count:(int)count {
    // initialize and start full text search
    if (self.isCancelled) { return; }
    try {
        std::vector<zim::Archive> archives = std::vector<zim::Archive>();
        archives.push_back(archive);
        zim::Searcher searcher = zim::Searcher(archives);
        zim::SearchResultSet resultSet = searcher.search(zim::Query(self.searchText_C)).getResults(0, count);

        // retrieve full text search results
        for (auto result = resultSet.begin(); result != resultSet.end(); result++) {
            if (self.isCancelled) { break; }

            zim::Item item = result->getItem(result->isRedirect());
            NSUUID *zimFileID = [[NSUUID alloc] initWithUUIDBytes:(unsigned char *)result.getZimId().data];
            NSString *_Nullable path = [NSString stringWithCString:item.getPath().c_str() encoding:NSUTF8StringEncoding];
            NSString *_Nullable title = [NSString stringWithCString:item.getTitle().c_str() encoding:NSUTF8StringEncoding];
            if (title == nil || title.length == 0) {
                title = path; // display the path as a fallback
            }
            if (path != nil && title != nil) {
                SearchResult *searchResult = [[SearchResult alloc] initWithZimFileID:zimFileID path:path title:title];
                searchResult.probability = [[NSNumber alloc] initWithFloat:result.getScore() / 100];

                // optionally, add snippet
                if (self.extractMatchingSnippet) {
                    NSString *_Nullable html = [NSString stringWithCString:result.getSnippet().c_str() encoding:NSUTF8StringEncoding];
                    if (html != nil) {
                        searchResult.htmlSnippet = html;
                    }
                }
                if (searchResult != nil) {
                    [self addResult: searchResult];
                }
            }
        }
    } catch (std::exception &e) {
        NSLog(@"index search error: %s", e.what());
    }
}

/// Add search results based on matching article titles with search text.
/// @param archive to retrieve search results from
/// @param count number of articles to retrieve
- (void)addTitleSearchResults:(zim::Archive) archive count:(int)count {
    if (self.isCancelled) { return; }
    try {
        NSUUID *zimFileID = [[NSUUID alloc] initWithUUIDBytes:(unsigned char *)archive.getUuid().data];
        auto results = zim::SuggestionSearcher(archive).suggest(self.searchText_C).getResults(0, count);
        for (auto result = results.begin(); result != results.end(); result++) {
            if (self.isCancelled) { return; }
            NSString *_Nullable path = [NSString stringWithCString:result->getPath().c_str() encoding:NSUTF8StringEncoding];
            NSString *_Nullable title = [NSString stringWithCString:result->getTitle().c_str() encoding:NSUTF8StringEncoding];
            if (path != nil && title != nil && title.length > 0) {
                SearchResult *searchResult = [[SearchResult alloc] initWithZimFileID:zimFileID path:path title:title];
                if (searchResult != nil) {
                    [self addResult: searchResult];
                }
            }
        }
    } catch (std::exception &e) {
        NSLog(@"title search error: %s", e.what());
    }
}

-(void) addResult: (SearchResult *_Nonnull) searchResult {
    // only for comparison add a trailing slash to the URL (if not there yet)
    NSURL *url = [searchResult.url withTrailingSlash];
    if ([self.foundURLs containsObject: url]) {
        return; // duplicate
    }
    [self.foundURLs addObject: url]; // store the url for comparison
    // store the result itself, without any modification to the original url
    [self.results addObject: searchResult];
}

NSArray<NSString *> *convertToArray(const std::vector<std::string> &vec) {
    NSMutableArray<NSString *> *result = [NSMutableArray new];
    for (const std::string &s : vec) {
        NSString *value = [NSString stringWithUTF8String: s.c_str()];
        if(value != nil) {
            [result addObject: value];
        }
    }
    return result;
}

@end
