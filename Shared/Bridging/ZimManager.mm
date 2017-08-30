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

@implementation ZimManager

std::unordered_map<std::string, std::shared_ptr<kiwix::Reader>> readers;
kiwix::Searcher *searcher = NULL;
std::vector<std::string> *searcherZimIDs = NULL;

#if TARGET_OS_MAC
    NSMutableDictionary *zimURLs;
#endif

#pragma mark - init

+ (ZimManager *)sharedInstance {
    static ZimManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ZimManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        readers.reserve(20);
#if TARGET_OS_MAC
        zimURLs = [[NSMutableDictionary alloc] init];
#elif TARGET_OS_IPHONE
        [self scan];
#endif
    }
    return self;
}

- (void)dealloc {
    [self removeAllBooks];
}

#pragma mark - reader management

- (void)scan {
    // TODO: reuse other functions
    NSURL *docDirURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:docDirURL includingPropertiesForKeys:nil options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants) error:nil];
    
    std::set<std::string> existing;
    for(auto const &reader: readers) {
        existing.insert(reader.first);
    }
    
    for (NSURL *file in files) {
        try {
            std::shared_ptr<kiwix::Reader> reader = std::make_shared<kiwix::Reader>([file fileSystemRepresentation]);
            std::string identifier = reader->getId();
            readers.insert(std::make_pair(identifier, reader));
            existing.erase(identifier);
        } catch (const std::exception &e) { }
    }
    
    for(std::string const &identifier: existing) {
        readers.erase(identifier);
    }
}

- (void)addBookByURL:(NSURL *)url {
    try {
#if TARGET_OS_MAC
        [url startAccessingSecurityScopedResource];
#endif
        std::shared_ptr<kiwix::Reader> reader = std::make_shared<kiwix::Reader>([url fileSystemRepresentation]);
        std::string identifierC = reader->getId();
        readers.insert(std::make_pair(identifierC, reader));

#if TARGET_OS_MAC
        NSString *identifier = [NSString stringWithCString:identifierC.c_str() encoding:NSUTF8StringEncoding];
        zimURLs[identifier] = url;
#endif
    } catch (const std::exception &e) { }
}

- (void)removeBookByID:(NSString *)bookID {
    std::string bookIDC = [bookID cStringUsingEncoding:NSUTF8StringEncoding];
    readers.erase(bookIDC);

#if TARGET_OS_MAC
    [zimURLs[bookID] stopAccessingSecurityScopedResource];
    [zimURLs removeObjectForKey:bookID];
#endif
}

- (void)removeAllBooks {
    for (NSString *bookID in zimURLs) {
        [self removeBookByID:bookID];
    }
}

- (NSArray *)getReaderIdentifiers {
    NSMutableArray *identifiers = [[NSMutableArray alloc] init];
    for(auto reader: readers) {
        NSString *identifier = [NSString stringWithCString:reader.first.c_str() encoding:NSUTF8StringEncoding];
        [identifiers addObject:identifier];
    }
    return identifiers;
}

# pragma mark - get content

- (NSDictionary *)getContent:(NSString *)bookID contentURL:(NSString *)contentURL {
    std::string bookIDC = [bookID cStringUsingEncoding:NSUTF8StringEncoding];
    std::string contentURLC = [contentURL cStringUsingEncoding:NSUTF8StringEncoding];
    
    auto found = readers.find(bookIDC);
    if (found == readers.end()) {
        return nil;
    } else {
        std::shared_ptr<kiwix::Reader> reader = found->second;
        
        std::string content;
        std::string title;
        unsigned int contentLength;
        std::string contentType;
        
        bool success = reader->getContentByUrl(contentURLC, content, title, contentLength, contentType);
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
