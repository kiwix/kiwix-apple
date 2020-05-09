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
#import "ZimFileMetaData.h"
#include "book.h"

struct SharedReaders {
    NSArray *readerIDs;
    std::vector<std::shared_ptr<kiwix::Reader>> readers;
};

@interface ZimMultiReader ()

@property (assign) std::unordered_map<std::string, std::shared_ptr<kiwix::Reader>> *readers;
@property (strong) NSMutableDictionary *fileURLs; // [ID: FileURL]

@end

@implementation ZimMultiReader

kiwix::Searcher *searcher = nullptr;
NSMutableArray *searcherZimIDs = [[NSMutableArray alloc] init];

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        self.readers = new std::unordered_map<std::string, std::shared_ptr<kiwix::Reader>>();
        self.readers->reserve(10);
        self.fileURLs = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return self;
}

+ (ZimMultiReader *)shared {
    static ZimMultiReader *sharedInstance = nil;
    static dispatch_once_t onceToken; // onceToken = 0
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ZimMultiReader alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc {
    delete self.readers;
}

- (NSArray *)getReaderIdentifiers {
    return [self.fileURLs allKeys];
}

- (NSURL *)getReaderFileURL:(NSString *)identifier {
    return self.fileURLs[identifier];
}

#pragma mark - reader management

- (void)addReaderByURL:(NSURL *)url {
    try {
        // if url does not ends with "zim", skip it
        NSString *pathExtension = [[url pathExtension] lowercaseString];
        if (![pathExtension isEqualToString:@"zim"]) {
            return;
        }
        
        // if we have previously added this url, skip it
        if ([[self.fileURLs allKeysForObject:url] count] > 0) {
            return;
        }

        // add the reader
        [url startAccessingSecurityScopedResource];
        std::shared_ptr<kiwix::Reader> reader = std::make_shared<kiwix::Reader>([url fileSystemRepresentation]);
        std::string identifier = reader->getId();
        self.readers->insert(std::make_pair(identifier, reader));
        
        // store file URL
        NSString *identifierObjC = [NSString stringWithCString:identifier.c_str() encoding:NSUTF8StringEncoding];
        self.fileURLs[identifierObjC] = url;
    } catch (std::exception e) { }
}

- (struct SharedReaders)getSharedReaders:(nonnull NSSet *)identifiers {
    NSMutableArray *readerIDs = [[NSMutableArray alloc] initWithCapacity:[identifiers count]];
    auto readers = std::vector<std::shared_ptr<kiwix::Reader>>();
    
    for(auto iter: *self.readers) {
        NSString *identifier = [NSString stringWithCString:iter.first.c_str() encoding:NSUTF8StringEncoding];
        if (![identifiers containsObject:identifier]) {
            continue;
        }
        [readerIDs addObject:identifier];
        readers.push_back(iter.second);
    }
    
    struct SharedReaders sharedReaders;
    sharedReaders.readerIDs = readerIDs;
    sharedReaders.readers = readers;
    return sharedReaders;
}

- (void)removeReaderByID:(NSString *)bookID {
    std::string identifier = [bookID cStringUsingEncoding:NSUTF8StringEncoding];
    self.readers->erase(identifier);
    [self.fileURLs[bookID] stopAccessingSecurityScopedResource];
    [self.fileURLs removeObjectForKey:bookID];
}

- (void)removeStaleReaders {
    for (NSString *identifier in [self.fileURLs allKeys]) {
        NSURL *url = self.fileURLs[identifier];
        NSString *path = [url path];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [self removeReaderByID:identifier];
        }
    }
}

# pragma mark - meta data

- (ZimFileMetaData *)getZimFileMetaData:(NSString *)identifier {
    auto found = self.readers->find([identifier cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == self.readers->end()) {
        return nil;
    } else {
        kiwix::Book book = kiwix::Book();
        book.update(*found->second);
        return [[ZimFileMetaData alloc] initWithBook: &book];
    }
}

+ (ZimFileMetaData *)getMetaDataWithFileURL:(NSURL *)url {
    ZimFileMetaData *metaData = nil;
    [url startAccessingSecurityScopedResource];
    try {
        kiwix::Reader reader = kiwix::Reader([url fileSystemRepresentation]);
        kiwix::Book book = kiwix::Book();
        book.update(reader);
        metaData = [[ZimFileMetaData alloc] initWithBook: &book];
    } catch (std::exception e) { }
    [url stopAccessingSecurityScopedResource];
    return metaData;
}

# pragma mark - check redirection

- (NSString *_Nullable)getRedirectedPath:(NSString *_Nonnull)zimFileID contentPath:(NSString *_Nonnull)contentPath {
    auto found = self.readers->find([zimFileID cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == self.readers->end()) {
        return nil;
    } else {
        std::shared_ptr<kiwix::Reader> reader = found->second;
        std::string contentPathC = [contentPath cStringUsingEncoding:NSUTF8StringEncoding];
        
        try {
            kiwix::Entry entry = reader->getEntryFromPath(contentPathC);
            entry = entry.getFinalEntry();
            
            std::string redirectedContentPathC = entry.getPath();
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
    auto found = self.readers->find([zimFileID cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == self.readers->end()) {
        return nil;
    } else {
        std::shared_ptr<kiwix::Reader> reader = found->second;

        try {
            kiwix::Entry entry = reader->getEntryFromPath([contentURL cStringUsingEncoding:NSUTF8StringEncoding]);
            NSNumber *length = [NSNumber numberWithUnsignedLongLong:entry.getSize()];
            NSData *data = [NSData dataWithBytes:entry.getContent().data() length:length.unsignedLongLongValue];
            NSString *mime = [NSString stringWithUTF8String:entry.getMimetype().c_str()];
            return @{@"data": data, @"mime": mime, @"length": length};
        } catch (kiwix::NoEntry) {
            return nil;
        } catch (std::exception) {
            return nil;
        }
    }
}

# pragma mark - URL handling

- (NSString *)getMainPagePath:(NSString *)bookID {
    auto found = self.readers->find([bookID cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == self.readers->end()) {
        return nil;
    } else {
        std::shared_ptr<kiwix::Reader> reader = found->second;
        kiwix::Entry mainPageEntry = reader->getMainPage();
        std::string mainPagePath = mainPageEntry.getPath();
        return [NSString stringWithCString:mainPagePath.c_str() encoding:NSUTF8StringEncoding];
    }
}

# pragma mark - Text Search

- (void)startIndexSearch:(NSString *)searchText zimFileIDs:(NSSet *)zimFileIDs {
    searcher = new kiwix::Searcher;
    std::string searchTextC = [searchText cStringUsingEncoding:NSUTF8StringEncoding];
    
    for(auto iter: *self.readers) {
        NSString *identifier = [NSString stringWithCString:iter.first.c_str() encoding:NSUTF8StringEncoding];
        if (![zimFileIDs containsObject:identifier]) {
            continue;
        }
        
        std::shared_ptr<kiwix::Reader> reader = iter.second;
        if (reader->hasFulltextIndex()) {
            searcher->add_reader(reader.get());
            [searcherZimIDs addObject:identifier];
        }
    }
    
    searcher->search(searchTextC, 0, 20);
}

- (NSDictionary *)getNextIndexSearchResultWithSnippet:(BOOL)extractSnippet {
    kiwix::Result *result = searcher->getNextResult();
    if (result == NULL) {
        return nil;
    }
    
    NSString *identifier = searcherZimIDs[result->get_readerIndex()];
    NSString *title = [NSString stringWithCString:result->get_title().c_str() encoding:NSUTF8StringEncoding];
    NSString *path = [NSString stringWithCString:result->get_url().c_str() encoding:NSUTF8StringEncoding];
    NSNumber *probability = [[NSNumber alloc] initWithDouble:(double)result->get_score() / double(100)];
    NSString *snippet = @"";
    if (extractSnippet) {
        snippet = [NSString stringWithCString:result->get_snippet().c_str() encoding:NSUTF8StringEncoding];
    }
    
    delete result;
    return @{@"id": identifier, @"title": title, @"path": path, @"probability": probability, @"snippet": snippet};
}

- (void)stopIndexSearch {
    delete searcher;
    [searcherZimIDs removeAllObjects];
}

- (NSArray *)getTitleSearchResults:(NSString *)searchText zimFileID:(NSString *)zimFileID count:(unsigned int)count {
    std::string searchTermC = [searchText cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *suggestions = [[NSMutableArray alloc] init];
    
    auto found = self.readers->find([zimFileID cStringUsingEncoding:NSUTF8StringEncoding]);
    if (found == self.readers->end()) {
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
