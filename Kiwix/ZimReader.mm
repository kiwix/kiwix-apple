//
//  ZimReader.m
//  KiwixTest
//
//  Created by Chris Li on 8/1/14.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#import "ZimReader.h"
#include "reader.h"
#include "xapian.h"

#define SEARCH_SUGGESTIONS_COUNT 50

@interface ZimReader () {
    kiwix::Reader *_reader;
    Xapian::Database *_db;
}
@end

@implementation ZimReader

- (instancetype)initWithZIMFileURL:(NSURL *)url {
    self = [super init];
    if (self) {
        try {
            _reader = new kiwix::Reader([url fileSystemRepresentation]);
        } catch (const std::exception &e) {
            return nil;
        }
        
        try {
            _db = new Xapian::Database([[url URLByAppendingPathExtension:@"idx"] fileSystemRepresentation]);
        } catch (const Xapian::DatabaseOpeningError &e) {}
        
        self.fileURL = url;
    }
    
    return self;
}

#pragma mark - search

- (NSArray *)search:(NSString *)searchTerm {
    if(_db == nil) {
        return [self searchSuggestionsSmart:searchTerm];
    } else {
        return [self searchUsingIndex:searchTerm];
    }
}

- (NSArray *)searchSuggestionsSmart:(NSString *)searchTerm {
    string searchTermC = [searchTerm cStringUsingEncoding:NSUTF8StringEncoding];
    int count = SEARCH_SUGGESTIONS_COUNT;
    NSString *bookID = [self getID];
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    if(_reader->searchSuggestionsSmart(searchTermC, count)) {
        string titleC;
        while (_reader->getNextSuggestion(titleC)) {
            NSString *title = [NSString stringWithUTF8String:titleC.c_str()];
            [results addObject:@{@"title": title, @"bookID": bookID}];
        }
    }
    return results;
}

- (NSArray *)searchUsingIndex:(NSString *)searchTerm {
    try {
        NSArray *searchTerms = [searchTerm componentsSeparatedByString:@" "];
        NSString *bookID = [self getID];
        Xapian::Enquire enquire(*_db);
        NSMutableArray *results = [[NSMutableArray alloc] init];
        
        vector<string> queryTerms;
        for (NSString *searchTerm in searchTerms) {
            string searchTermC = [searchTerm cStringUsingEncoding:NSUTF8StringEncoding];
            queryTerms.push_back(searchTermC);
        }
        
        Xapian::Query query(Xapian::Query::OP_OR, queryTerms.begin(), queryTerms.end());
        enquire.set_query(query);
        
        
        Xapian::MSet matches = enquire.get_mset(0, SEARCH_SUGGESTIONS_COUNT);
        Xapian::MSetIterator i;
        for (i = matches.begin(); i != matches.end(); ++i) {
            Xapian::Document doc = i.get_document();
            
            NSNumber *percent = [[NSNumber alloc] initWithInt:i.get_percent()];
            NSString *path = [NSString stringWithUTF8String:doc.get_data().c_str()];
            NSString *title = [NSString stringWithUTF8String:doc.get_value(0).c_str()];
            NSString *snippet = [NSString stringWithUTF8String:doc.get_value(1).c_str()];
            
            NSDictionary *result = @{@"percent": percent, @"path": path, @"title": title, @"snippet": snippet, @"bookID": bookID};
            [results addObject:result];
        }
        return results;
    } catch(const Xapian::Error &error) {
        cout << "Xapian Exception: "  << error.get_msg() << endl;
        return  nil;
    }
}

#pragma mark - index

- (BOOL)hasIndex {
    return _db != nil;
}

#pragma mark - validation

- (BOOL)isCorrupted {
    return _reader->isCorrupted();
}

#pragma mark - getContents
- (NSDictionary *)dataWithContentURLString:(NSString *)contentURLString {
    NSData *contentData;
    NSString *mimeType;
    NSNumber *dataLength;
    
    string pageURLStringC = [contentURLString cStringUsingEncoding:NSUTF8StringEncoding];
    string content;
    string contentType;
    unsigned int contentLength = 0;
    if (_reader->getContentByUrl(pageURLStringC, content, contentLength, contentType)) {
        contentData = [NSData dataWithBytes:content.data() length:contentLength];
        mimeType = [NSString stringWithUTF8String:contentType.c_str()];
        dataLength = [NSNumber numberWithUnsignedInt:contentLength];
        return @{@"data": contentData, @"mime": mimeType, @"length": dataLength};
    } else {
        return @{};
    }
}

#pragma mark - getURLs
- (NSString *)pageURLFromTitle:(NSString *)title {
    NSString *pageURL = nil;
    
    string url;
    if (_reader->getPageUrlFromTitle([title cStringUsingEncoding:NSUTF8StringEncoding], url)) {
        pageURL = [NSString stringWithUTF8String:url.c_str()];
    }
    if (!pageURL) NSLog(@"zimReader: Cannot find URL of a page titled %@", title);
    return pageURL;
}

- (NSString *)mainPageURL {
    NSString *mainPageURL = nil;
    
    string mainPageURLC;
    mainPageURLC = _reader->getMainPageUrl();
    mainPageURL = [NSString stringWithCString:mainPageURLC.c_str() encoding:NSUTF8StringEncoding];
    if (!mainPageURL) NSLog(@"zimReader: Cannot find URL of main page");
    return mainPageURL;
}

- (NSString *)getRandomPageUrl {
    string url = _reader->getRandomPageUrl();
    return [NSString stringWithUTF8String:url.c_str()];
}

#pragma mark - getCounts

- (NSString *)getArticleCount {
    return [NSString stringWithFormat:@"%u", _reader->getArticleCount()];
}

- (NSString *)getMediaCount {
    return [NSString stringWithFormat:@"%u", _reader->getMediaCount()];
}

- (NSString *)getGlobalCount {
    return [NSString stringWithFormat:@"%u", _reader->getGlobalCount()];
}

#pragma mark - get File Attributes

- (NSString *)getID {
    NSString *id = nil;
    
    string idC;
    idC = _reader->getId();
    id = [NSString stringWithCString:idC.c_str() encoding:NSUTF8StringEncoding];
    
    return id;
}

- (NSString *)getTitle {
    NSString *title = nil;
    
    string titleC;
    titleC = _reader->getTitle();
    title = [NSString stringWithCString:titleC.c_str() encoding:NSUTF8StringEncoding];
    
    return title;
}

- (NSString *)getDesc {
    NSString *description = nil;
    
    string descriptionC;
    descriptionC = _reader->getDescription();
    description = [NSString stringWithCString:descriptionC.c_str() encoding:NSUTF8StringEncoding];
    
    return description;
}

- (NSString *)getLanguage {
    NSString *language = nil;
    
    string languageC;
    languageC = _reader->getLanguage();
    language = [NSString stringWithCString:languageC.c_str() encoding:NSUTF8StringEncoding];
    
    return language;
}

- (NSString *)getDate {
    string dateC;
    dateC = _reader->getDate();
    NSString *dateString = [NSString stringWithCString:dateC.c_str() encoding:NSUTF8StringEncoding];
    
    return dateString;
}

- (NSString *)getCreator {
    NSString *creator = nil;
    
    string creatorC;
    creatorC = _reader->getCreator();
    creator = [NSString stringWithCString:creatorC.c_str() encoding:NSUTF8StringEncoding];
    
    return creator;
}

- (NSString *)getPublisher {
    NSString *publisher = nil;
    
    string publisherC;
    publisherC = _reader->getOrigId();
    publisher = [NSString stringWithCString:publisherC.c_str() encoding:NSUTF8StringEncoding];
    
    return publisher;
}

- (NSString *)getOriginID {
    NSString *originID = nil;
    
    string originIDC;
    originIDC = _reader->getOrigId();
    originID = [NSString stringWithCString:originIDC.c_str() encoding:NSUTF8StringEncoding];
    
    return originID;
}

- (NSString *)getFileSize {
    return [NSString stringWithFormat:@"%u", _reader->getFileSize()];
}

- (NSData *)getFavicon {
    NSData *data;
    string content;
    string mimeType;
    if (_reader->getFavicon(content, mimeType)) {
        data = [NSData dataWithBytes:content.c_str() length:content.length()];
    }
    return data;
}

- (NSString *)parseURL:(NSString *)urlPath {
    NSString *title;
    string cURL = [urlPath cStringUsingEncoding:NSUTF8StringEncoding];
    char ns;
    string cTitle;
    if (_reader->parseUrl(cURL, &ns, cTitle)) {
        title = [NSString stringWithUTF8String:cTitle.c_str()];
    }
    return title;
}

#pragma mark - dealloc
- (void)dealloc {
    if (_reader != NULL) {
        _reader->~Reader();
    }
    
    if (_db != NULL) {
        _db->~Database();
    }
}

@end
