//
//  ZimMultiReader.mm
//  Kiwix
//
//  Created by Chris Li on 8/17/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

#include <set>
#include <unordered_map>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#include "kiwix/book.h"
#include "kiwix/entry.h"
#include "kiwix/reader.h"
#include "kiwix/searcher.h"
#pragma clang diagnostic pop

#import "ZimMultiReader.h"
#import "ZimFileMetaData.h"

struct SharedReaders {
    NSArray *readerIDs;
    std::vector<std::shared_ptr<kiwix::Reader>> readers;
};

@interface ZimMultiReader ()

@property (assign) std::unordered_map<std::string, std::shared_ptr<kiwix::Reader>> *readers;
@property (assign) std::unordered_map<std::string, kiwix::Reader> *readers2;
@property (strong) NSMutableDictionary *fileURLs; // [ID: FileURL]

@end

@implementation ZimMultiReader

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

+ (ZimMultiReader *)sharedInstance {
    static ZimMultiReader *sharedInstance = nil;
    static dispatch_once_t onceToken;
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
    
    for (NSString *identifier in identifiers) {
        try {
            auto reader = self.readers->at([identifier cStringUsingEncoding:NSUTF8StringEncoding]);
            [readerIDs addObject:identifier];
            readers.push_back(reader);
        } catch (std::out_of_range) { }
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

@end
