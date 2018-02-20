//
//  ZimMultiReader.mm
//  Kiwix
//
//  Created by Chris Li on 8/17/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

#include <set>
#include <unordered_map>
#include "entry.h"
#include "reader.h"
#include "searcher.h"
#import "ZimMultiReader.h"

@implementation ZimMultiReader

std::unordered_map<std::string, std::shared_ptr<kiwix::Reader>> readers;
std::unordered_map<std::string, std::shared_ptr<kiwix::Searcher>> externalSearchers;
kiwix::Searcher *searcher = new kiwix::Searcher;
//std::vector<std::string> *searcherZimIDs = new std::vector<std::string>;
NSMutableArray *searcherZimIDs = [[NSMutableArray alloc] init];
NSMutableDictionary *fileURLs = [[NSMutableDictionary alloc] init]; // [ID: FileURL]

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        readers.reserve(20);
    }
    return self;
}

- (NSArray *)getReaderIdentifiers {
    return [fileURLs allKeys];
}

- (NSURL *)getReaderFileURL:(NSString *)identifier {
    return fileURLs[identifier];
}

#pragma mark - reader management

- (void)addReaderByURL:(NSURL *)url {
    try {
        // if url does not ends with "zim" or "zimaa", skip it
        NSString *pathExtension = [[url pathExtension] lowercaseString];
        if (![pathExtension isEqualToString:@"zim"] && ![pathExtension isEqualToString:@"zimaa"]) {
            return;
        }
        
        // if we have previously added this url, skip it
        if ([[fileURLs allKeysForObject:url] count] > 0) {
            return;
        }
        
#if TARGET_OS_MAC
        [url startAccessingSecurityScopedResource];
#endif
        
        // add the reader
        std::shared_ptr<kiwix::Reader> reader = std::make_shared<kiwix::Reader>([url fileSystemRepresentation]);
        std::string identifier = reader->getId();
        readers.insert(std::make_pair(identifier, reader));
        
        // store file URL
        NSString *identifierObjC = [NSString stringWithCString:identifier.c_str() encoding:NSUTF8StringEncoding];
        fileURLs[identifierObjC] = url;
        
        // check if there is an external idx directory
        NSURL *idxDirURL = [[url URLByDeletingPathExtension] URLByAppendingPathExtension:@"zim.idx"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[idxDirURL path]]) {
            kiwix::Searcher *searcher = new kiwix::Searcher([idxDirURL fileSystemRepresentation], reader.get(), identifier);
            externalSearchers.insert(std::make_pair(identifier, searcher));
        }
    } catch (...) { }
}

- (void)removeReaderByID:(NSString *)bookID {
    std::string identifier = [bookID cStringUsingEncoding:NSUTF8StringEncoding];
    readers.erase(identifier);
    externalSearchers.erase(identifier);
#if TARGET_OS_MAC
    [fileURLs[bookID] stopAccessingSecurityScopedResource];
#endif
    [fileURLs removeObjectForKey:bookID];
}

- (void)removeStaleReaders {
    for (NSString *identifier in [fileURLs allKeys]) {
        NSURL *url = fileURLs[identifier];
        NSString *path = [url path];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [self removeReaderByID:identifier];
        }
    }
}

# pragma mark - check index

- (BOOL)hasEmbeddedIndex:(NSString *_Nonnull)zimFileID {
    auto found = readers.find([zimFileID cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == readers.end()) {
        return NO;
    } else {
        std::shared_ptr<kiwix::Reader> reader = found->second;
        return reader->hasFulltextIndex();
    }
}

- (BOOL)hasExternalIndex:(NSString *_Nonnull)zimFileID {
    auto found = externalSearchers.find([zimFileID cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == externalSearchers.end()) {
        return NO;
    } else {
        return YES;
    }
}

# pragma mark - check redirection

- (NSString *_Nullable)getRedirectedPath:(NSString *_Nonnull)zimFileID contentPath:(NSString *_Nonnull)contentPath {
    auto found = readers.find([zimFileID cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == readers.end()) {
        return nil;
    } else {
        std::shared_ptr<kiwix::Reader> reader = found->second;
        std::string contentPathC = [contentPath cStringUsingEncoding:NSUTF8StringEncoding];
        
        try {
            kiwix::Entry entry = reader->getEntryFromUrl(contentPathC);
            entry = entry.getFinalEntry();
            
            std::string redirectedContentPathC = entry.getUrl();
            if (redirectedContentPathC.substr(0, 1) != "/") {
                redirectedContentPathC = "/" + redirectedContentPathC;
            }
            
            if (contentPathC == redirectedContentPathC) {
                return nil;
            } else {
                return [NSString stringWithUTF8String:redirectedContentPathC.c_str()];
            }
        } catch (kiwix::NoEntry) {
            return nil;
        }
    }
}

# pragma mark - get content

- (NSDictionary *)getContent:(NSString *)zimFileID contentURL:(NSString *)contentURL {
    auto found = readers.find([zimFileID cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == readers.end()) {
        return nil;
    } else {
        std::shared_ptr<kiwix::Reader> reader = found->second;
        
        try {
            kiwix::Entry entry = reader->getEntryFromUrl([contentURL cStringUsingEncoding:NSUTF8StringEncoding]);
            NSData *data = [NSData dataWithBytes:entry.getContent().data() length:entry.getSize()];
            NSString *mime = [NSString stringWithUTF8String:entry.getMimetype().c_str()];
            NSNumber *length = [NSNumber numberWithUnsignedInt:entry.getSize()];
            return @{@"data": data, @"mime": mime, @"length": length};
        } catch (kiwix::NoEntry) {
            return nil;
        }
    }
}

- (ZimMetaData *)getMetaData:(NSString *)zimFileID {
    NSURL *url = fileURLs[zimFileID];
    if (url == nil) {return nil;}
    return [[ZimMetaData alloc] initWithZimFileURL:url];
}

# pragma mark - URL handling

- (NSString *)getMainPageURL:(NSString *)bookID {
    auto found = readers.find([bookID cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == readers.end()) {
        return nil;
    } else {
        std::shared_ptr<kiwix::Reader> reader = found->second;
        std::string mainPageURLC = reader->getMainPageUrl();
        return [NSString stringWithCString:mainPageURLC.c_str() encoding:NSUTF8StringEncoding];
    }
}

# pragma mark - Search

- (void)startIndexSearch:(NSString *)searchText zimFileIDs:(NSSet *)zimFileIDs {
    std::string searchTextC = [searchText cStringUsingEncoding:NSUTF8StringEncoding];
    
    for(auto iter: readers) {
        NSString *identifier = [NSString stringWithCString:iter.first.c_str() encoding:NSUTF8StringEncoding];
        if (![zimFileIDs containsObject:identifier]) {
            continue;
        }
        
        std::shared_ptr<kiwix::Reader> reader = iter.second;
        if (reader->hasFulltextIndex()) {
            // file have embedded index, we will let searcher handle this situation
            searcher->add_reader(reader.get(), iter.first);
            [searcherZimIDs addObject:identifier];
        } else {
            // file does not have embedded index, try find an external index
            auto found = externalSearchers.find(iter.first);
            if (found == externalSearchers.end()) {
                // did not find an external index for this zim file
                continue;
            } else {
                // found an external index
                std::shared_ptr<kiwix::Searcher> searcher = found->second;
                searcher->search(searchTextC, 0, 10);
            }
        }
    }
    
    searcher->search(searchTextC, 0, 20);
}

- (NSDictionary *)convertSearchResultWithIndentifier:(NSString *)identifier result:(kiwix::Result *)result {
    NSString *title = [NSString stringWithCString:result->get_title().c_str() encoding:NSUTF8StringEncoding];
    NSString *path = [NSString stringWithCString:result->get_url().c_str() encoding:NSUTF8StringEncoding];
    NSNumber *probability = [[NSNumber alloc] initWithDouble:(double)result->get_score() / double(100)];
    NSString *snippet = [NSString stringWithCString:result->get_snippet().c_str() encoding:NSUTF8StringEncoding];
    delete result;
    return @{@"id": identifier, @"title": title, @"path": path, @"probability": probability, @"snippet": snippet};
}

- (NSDictionary *)getNextIndexSearchResult {
    kiwix::Result *result = searcher->getNextResult();
    if (result != NULL) {
        NSString *identifier = searcherZimIDs[result->get_readerIndex()];
        return [self convertSearchResultWithIndentifier:identifier result:result];
    } else {
        for(auto iter: externalSearchers) {
            NSString *identifier = [NSString stringWithCString:iter.first.c_str() encoding:NSUTF8StringEncoding];
            result = iter.second->getNextResult();
            if (result != NULL) {
                return [self convertSearchResultWithIndentifier:identifier result:result];
            }
        }
        return nil;
    }
}

- (void)stopIndexSearch {
    searcher = new kiwix::Searcher;
    [searcherZimIDs removeAllObjects];
    for(auto iter: externalSearchers) {
        iter.second->restart_search();
    }
}

- (NSArray *)getTitleSearchResults:(NSString *)searchText zimFileID:(NSString *)zimFileID count:(unsigned int)count {
    std::string searchTermC = [searchText cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *suggestions = [[NSMutableArray alloc] init];
    
    auto found = readers.find([zimFileID cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == readers.end()) {
        return suggestions;
    } else {
        std::shared_ptr<kiwix::Reader> reader = found->second;
        reader->searchSuggestionsSmart(searchTermC, count);
        
        std::string titleC;
        std::string pathC;
        
        while (reader->getNextSuggestion(titleC, pathC)) {
            NSString *title = [NSString stringWithCString:titleC.c_str() encoding:NSUTF8StringEncoding];
            NSString *path = [NSString stringWithCString:pathC.c_str() encoding:NSUTF8StringEncoding];
            [suggestions addObject:@{@"id": zimFileID, @"title": title, @"path": path}];
        }
        return suggestions;
    }
}

@end
