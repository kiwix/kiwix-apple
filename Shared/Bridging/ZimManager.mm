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

@interface ZimManager () {
    std::unordered_map<std::string, std::shared_ptr<kiwix::Reader>> readers;
}
@end

@implementation ZimManager

#pragma mark - init

+ (ZimManager *)sharedInstance {
    static ZimManager *sharedInstance = nil;
    static dispatch_once_t onceToken; // onceToken = 0
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ZimManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
# if TARGET_OS_IPHONE
        [self scan];
#endif
        readers.reserve(20);
    }
    return self;
}

#pragma mark - reader management

- (void)scan {
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

- (void)addBookByPath:(NSString *)path {
    std::shared_ptr<kiwix::Reader> reader = std::make_shared<kiwix::Reader>([path cStringUsingEncoding:NSUTF8StringEncoding]);
    std::string identifier = reader->getId();
    readers.insert(std::make_pair(identifier, reader));
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

- (void)enumerateThings:(void (^)(NSString *result))block {
    block(@"test");
}

- (NSArray *)getSearchSuggestions:(NSString *)searchTerm {
    std::string searchTermC = [searchTerm cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *suggestions = [[NSMutableArray alloc] init];
    
    unsigned int count = 5;
    for(auto iter: readers) {
        std::shared_ptr<kiwix::Reader> reader = iter.second;
        reader->searchSuggestionsSmart(searchTermC, count);
        
        std::string titleC;
        std::string pathC;
        
        while (reader->getNextSuggestion(titleC, pathC)) {
            NSString *title = [NSString stringWithCString:titleC.c_str() encoding:NSUTF8StringEncoding];
            NSString *path = [NSString stringWithCString:pathC.c_str() encoding:NSUTF8StringEncoding];
            [suggestions addObject:@{@"title": title, @"path": path}];
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
