//
//  ZimMultiReader.mm
//  Kiwix
//
//  Created by Chris Li on 8/17/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

#include <set>
#include <unordered_map>
#include "reader.h"
#include "searcher.h"
#import "ZimMultiReader.h"

@implementation ZimMultiReader

std::unordered_map<std::string, std::shared_ptr<kiwix::Reader>> readers;
NSMutableDictionary *urls = [[NSMutableDictionary alloc] init]; // [ID: URL]
kiwix::Searcher *searcher = NULL;
std::vector<std::string> *searcherZimIDs = NULL;

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        readers.reserve(20);
    }
    return self;
}

- (NSArray *)getReaderIdentifiers {
    return [urls allKeys];
}

#pragma mark - reader management

- (void)addBookByURL:(NSURL *)url {
    try {
        // if url does not ends with "zim" or "zimaa", skip it
        NSString *pathExtension = [[url pathExtension] lowercaseString];
        if (![pathExtension isEqualToString:@"zim"] && ![pathExtension isEqualToString:@"zimaa"]) {
            return;
        }
        
        // if we have previously added this url, skip it
        if ([[urls allKeysForObject:url] count] > 0) {
            return;
        }
        
#if TARGET_OS_MAC
        [url startAccessingSecurityScopedResource];
#endif
        
        std::shared_ptr<kiwix::Reader> reader = std::make_shared<kiwix::Reader>([url fileSystemRepresentation]);
        std::string identifier = reader->getId();
        NSString *identifierObjC = [NSString stringWithCString:identifier.c_str() encoding:NSUTF8StringEncoding];
        
        readers.insert(std::make_pair(identifier, reader));
        urls[identifierObjC] = url;
        
    } catch (const std::exception &e) { }
}

- (void)removeBookByID:(NSString *)bookID {
#if TARGET_OS_MAC
    [urls[bookID] stopAccessingSecurityScopedResource];
#endif
    
    readers.erase([bookID cStringUsingEncoding:NSUTF8StringEncoding]);
    [urls removeObjectForKey:bookID];
}

- (void)removeStaleReaders {
    for (NSString *identifier in urls) {
        NSURL *url = urls[identifier];
        NSString *path = [url path];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [self removeBookByID:identifier];
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
        
        std::string content;
        std::string title;
        unsigned int contentLength;
        std::string contentType;
        
        bool success = reader->getContentByUrl([contentURL cStringUsingEncoding:NSUTF8StringEncoding], content, title, contentLength, contentType);
        if (success) {
            NSData *data = [NSData dataWithBytes:content.data() length:contentLength];
            NSString *mime = [NSString stringWithUTF8String:contentType.c_str()];
            NSNumber *length = [NSNumber numberWithUnsignedInt:contentLength];
            return @{@"data": data, @"mime": mime, @"length": length};
        } else {
            return nil;
        }
    }
}

- (ZimMetaData *)getMetaData:(NSString *)zimFileID {
    NSURL *url = urls[zimFileID];
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

- (void)startSearch:(NSString *)searchTerm {
    if (searcherZimIDs == NULL) {
        searcherZimIDs = new std::vector<std::string>;
    } else {
        searcherZimIDs->clear();
    }
    if (searcher == NULL) {
        searcher = new kiwix::Searcher;
        for(auto pair: readers) {
            searcher->add_reader(pair.second.get(), pair.first);
            searcherZimIDs->push_back(pair.first);
        }
    }
    
    std::string searchTermC = [searchTerm cStringUsingEncoding:NSUTF8StringEncoding];
    int offset = 0;
    int limit = 20;
    searcher->search(searchTermC, offset, limit);
}

- (NSDictionary *)getNextSearchResult {
    if (searcher == NULL || searcherZimIDs == NULL) {return nil;}
    
    kiwix::Result *result = searcher->getNextResult();
    if (result != NULL) {
        NSString *identifier = [NSString stringWithCString:searcherZimIDs->at(result->get_readerIndex()).c_str() encoding:NSUTF8StringEncoding];
        NSString *title = [NSString stringWithCString:result->get_title().c_str() encoding:NSUTF8StringEncoding];
        NSString *path = [NSString stringWithCString:result->get_url().c_str() encoding:NSUTF8StringEncoding];
        NSString *snippet = [NSString stringWithCString:result->get_snippet().c_str() encoding:NSUTF8StringEncoding];
        delete result;
        return @{@"id": identifier, @"title": title, @"path": path, @"snippet": snippet};
    } else {
        return nil;
    }
}

- (void)stopSearch {
    delete searcher;
    delete searcherZimIDs;
    searcher = NULL;
    searcherZimIDs = NULL;
}

- (NSArray *)getSearchSuggestions:(NSString *)searchTerm {
    std::string searchTermC = [searchTerm cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *suggestions = [[NSMutableArray alloc] init];
    
    unsigned int count = max(5, int(30 / readers.size()));
    
    for(auto iter: readers) {
        std::shared_ptr<kiwix::Reader> reader = iter.second;
        reader->searchSuggestionsSmart(searchTermC, count);
        
        std::string titleC;
        std::string pathC;
        
        NSString *identifier = [NSString stringWithCString:iter.first.c_str() encoding:NSUTF8StringEncoding];
        while (reader->getNextSuggestion(titleC, pathC)) {
            NSString *title = [NSString stringWithCString:titleC.c_str() encoding:NSUTF8StringEncoding];
            NSString *path = [NSString stringWithCString:pathC.c_str() encoding:NSUTF8StringEncoding];
            [suggestions addObject:@{@"id": identifier, @"title": title, @"path": path}];
        }
    }
    
    if (readers.size() > 1) {
        [suggestions sortUsingComparator:^NSComparisonResult(NSDictionary * _Nonnull obj1, NSDictionary * _Nonnull obj2) {
            NSString *title1 = [obj1 objectForKey:@"title"];
            NSString *title2 = [obj2 objectForKey:@"title"];
            return [title1 caseInsensitiveCompare:title2];
        }];
    }
    
    return suggestions;
}

@end
