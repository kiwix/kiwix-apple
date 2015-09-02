//
//  ZimReader.m
//  KiwixTest
//
//  Created by Chris Li on 8/1/14.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#import "ZimReader.h"
#include "reader.h"

#define SEARCH_SUGGESTIONS_COUNT 50

@interface ZimReader () {
    kiwix::Reader *_reader;
}

@property NSURL *fileURL;
@end

@implementation ZimReader

- (instancetype)initWithZIMFileURL:(NSURL *)url {
    self = [super init];
    if (self) {
        try {
            _reader = new kiwix::Reader([url fileSystemRepresentation]);
        } catch (const std::exception& e) {
            return nil;
        }
        
        self.fileURL = url;
    }
    
    return self;
}

#pragma mark - validation

- (BOOL)isCorrupted {
    return _reader->isCorrupted();
}

#pragma mark - contents
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

#pragma mark - search
- (NSArray *)searchSuggestionsSmart:(NSString *)searchTerm {
    string searchTermC = [searchTerm cStringUsingEncoding:NSUTF8StringEncoding];
    int count = SEARCH_SUGGESTIONS_COUNT;
    NSMutableArray *searchSuggestionsArray = [[NSMutableArray alloc] init];
    
    if(_reader->searchSuggestionsSmart(searchTermC, count)) {
        //NSLog(@"%s, %d", searchTermC.c_str(), count);
        string titleC;
        while (_reader->getNextSuggestion(titleC)) {
            NSString *title = [NSString stringWithUTF8String:titleC.c_str()];
            [searchSuggestionsArray addObject:title];
        }
    }
    //NSLog(@"count = %lu", (unsigned long)[searchSuggestionsArray count]);
    return searchSuggestionsArray;
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
    NSString *idString = nil;
    
    string idStringC;
    idStringC = _reader->getId();
    idString = [NSString stringWithCString:idStringC.c_str() encoding:NSUTF8StringEncoding];
    
    return idString;
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
}

@end
