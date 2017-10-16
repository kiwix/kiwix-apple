//
//  ZimReader.m
//  KiwixTest
//
//  Created by Chris Li on 8/1/14.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#include "reader.h"
#import "ZimReader.h"

@implementation ZimReader {
    NSURL *url;
    std::shared_ptr<kiwix::Reader> reader;
    std::shared_ptr<std::string> identifier;
}

- (instancetype)initWithZimFileURL:(NSURL *)fileURL {
    self = [super init];
    if (self) {
        try {
            reader = std::make_shared<kiwix::Reader>([fileURL fileSystemRepresentation]);
            identifier = std::make_shared<std::string>(reader->getId());
        } catch (const std::exception &e) {
            return nil;
        }
        url = fileURL;
    }
    return self;
}

- (NSDictionary *)getContent:(NSString *)contentURL {
    std::string contentURLC = [contentURL cStringUsingEncoding:NSUTF8StringEncoding];
    
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

- (NSString *)getMainPageURL {
    std::string mainPageURLC = reader->getMainPageUrl();
    return [NSString stringWithCString:mainPageURLC.c_str() encoding:NSUTF8StringEncoding];
}

- (NSString *)getID {
    return [NSString stringWithCString:identifier->c_str() encoding:NSUTF8StringEncoding];
}

- (NSString *)getTitle {
    return [NSString stringWithCString:(reader->getTitle()).c_str() encoding:NSUTF8StringEncoding];
}








//#pragma mark - search
//
//- (NSArray *)searchSuggestionsSmart:(NSString *)searchTerm {
//    string searchTermC = [searchTerm cStringUsingEncoding:NSUTF8StringEncoding];
//    int count = TITLE_SEARCH_COUNT;
//    NSString *bookID = [self getID];
//    NSMutableArray *results = [[NSMutableArray alloc] init];
//
//    if(_reader->searchSuggestionsSmart(searchTermC, count)) {
//        string titleC;
//        while (_reader->getNextSuggestion(titleC)) {
//            NSString *title = [NSString stringWithUTF8String:titleC.c_str()];
//            [results addObject:@{@"title": title, @"bookID": bookID}];
//        }
//    }
//    return results;
//}
//
//- (NSArray *)searchUsingIndex:(NSString *)searchTerm {
//    kiwix::Searcher searcher = kiwix::Searcher();
//    std::string identifierC = _reader->getId();
//    searcher.add_reader(_reader, identifierC);
//
//    std::string searchTermC = [searchTerm cStringUsingEncoding:NSUTF8StringEncoding];
//    searcher.search(searchTermC, 0, 20);
//
//    NSMutableArray *results = [[NSMutableArray alloc] init];
//    kiwix::Result *result = searcher.getNextResult();
//
//    while (result != NULL) {
//        NSString *identifier = [NSString stringWithCString:identifierC.c_str() encoding:NSUTF8StringEncoding];
//        NSString *title = [NSString stringWithCString:result->get_title().c_str() encoding:NSUTF8StringEncoding];
//        NSString *path = [NSString stringWithCString:result->get_url().c_str() encoding:NSUTF8StringEncoding];
//        NSString *snippet = [NSString stringWithCString:result->get_snippet().c_str() encoding:NSUTF8StringEncoding];
//        int score = result->get_score();
//
//        NSLog([[[NSNumber alloc] initWithInt:score] stringValue]);
//        delete result;
//        result = searcher.getNextResult();
//        [results addObject:@{@"bookID": identifier, @"title": title, @"path": path, @"snippet": snippet}];
//    }
//
//    delete result;
//    return results;
//}
//
//- (NSInteger)levenshteinDistance:(NSString *)strA andString:(NSString *)strB {
//    const string str1 = [strA cStringUsingEncoding:NSUTF8StringEncoding];
//    const string str2 = [strB cStringUsingEncoding:NSUTF8StringEncoding];
//    return levenshtein_distance(str1, str2);
//}
//
//// Source: https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance#C.2B.2B
//int levenshtein_distance(const std::string &s1, const std::string &s2)
//{
//    // To change the type this function manipulates and returns, change
//    // the return type and the types of the two variables below.
//    int s1len = (int)s1.size();
//    int s2len = (int)s2.size();
//
//    auto column_start = (decltype(s1len))1;
//
//    auto column = new decltype(s1len)[s1len + 1];
//    std::iota(column + column_start, column + s1len + 1, column_start);
//
//    for (auto x = column_start; x <= s2len; x++) {
//        column[0] = x;
//        auto last_diagonal = x - column_start;
//        for (auto y = column_start; y <= s1len; y++) {
//            auto old_diagonal = column[y];
//            auto possibilities = {
//                column[y] + 1,
//                column[y - 1] + 1,
//                last_diagonal + (s1[y - 1] == s2[x - 1]? 0 : 1)
//            };
//            column[y] = std::min(possibilities);
//            last_diagonal = old_diagonal;
//        }
//    }
//    auto result = column[s1len];
//    delete[] column;
//    return result;
//}
//
//#pragma mark - index
//
//- (BOOL)hasIndex {
//    return _db != nil;
//}
//
//#pragma mark - validation
//
//- (BOOL)isCorrupted {
//    return _reader->isCorrupted();
//}
//
//#pragma mark - getContents
//
//#pragma mark - getURLs
//- (NSString *)pageURLFromTitle:(NSString *)title {
//    NSString *pageURL = nil;
//
//    string url;
//    if (_reader->getPageUrlFromTitle([title cStringUsingEncoding:NSUTF8StringEncoding], url)) {
//        pageURL = [NSString stringWithUTF8String:url.c_str()];
//    }
//    if (!pageURL) NSLog(@"zimReader: Cannot find URL of a page titled %@", title);
//    return pageURL;
//}
//
//
//- (NSString *)getRandomPageUrl {
//    string url = _reader->getRandomPageUrl();
//    return [NSString stringWithUTF8String:url.c_str()];
//}
//
//#pragma mark - getCounts
//
//- (NSString *)getArticleCount {
//    return [NSString stringWithFormat:@"%u", _reader->getArticleCount()];
//}
//
//- (NSString *)getMediaCount {
//    return [NSString stringWithFormat:@"%u", _reader->getMediaCount()];
//}
//
//- (NSString *)getGlobalCount {
//    return [NSString stringWithFormat:@"%u", _reader->getGlobalCount()];
//}
//
//#pragma mark - get File Attributes
//
//- (NSString *)getID {
//    string idC;
//    idC = _reader->getId();
//    return [NSString stringWithCString:idC.c_str() encoding:NSUTF8StringEncoding];
//}
//
//
//- (NSString *)getDesc {
//    string descriptionC;
//    descriptionC = _reader->getDescription();
//    return [NSString stringWithCString:descriptionC.c_str() encoding:NSUTF8StringEncoding];
//}
//
//- (NSString *)getLanguage {
//    string languageC;
//    languageC = _reader->getLanguage();
//    return [NSString stringWithCString:languageC.c_str() encoding:NSUTF8StringEncoding];
//}
//
//- (NSString *)getName {
//    string nameC;
//    nameC = _reader->getName();
//    return [NSString stringWithCString:nameC.c_str() encoding:NSUTF8StringEncoding];
//}
//
//- (NSString *)getTags {
//    string tagsC;
//    tagsC = _reader->getTags();
//    return [NSString stringWithCString:tagsC.c_str() encoding:NSUTF8StringEncoding];
//}
//
//- (NSString *)getDate {
//    string dateC;
//    dateC = _reader->getDate();
//    return [NSString stringWithCString:dateC.c_str() encoding:NSUTF8StringEncoding];
//}
//
//- (NSString *)getCreator {
//    string creatorC;
//    creatorC = _reader->getCreator();
//    return [NSString stringWithCString:creatorC.c_str() encoding:NSUTF8StringEncoding];
//}
//
//- (NSString *)getPublisher {
//    string publisherC;
//    publisherC = _reader->getOrigId();
//    return [NSString stringWithCString:publisherC.c_str() encoding:NSUTF8StringEncoding];
//}
//
//- (NSString *)getOriginID {
//    string originIDC;
//    originIDC = _reader->getOrigId();
//    return [NSString stringWithCString:originIDC.c_str() encoding:NSUTF8StringEncoding];
//}
//
//- (NSString *)getFileSize {
//    return [[[NSNumber alloc] initWithUnsignedInt:_reader->getFileSize()] stringValue];
//}
//
//- (NSString *)getFavicon {
//    NSData *data;
//    string content;
//    string mimeType;
//    if (_reader->getFavicon(content, mimeType)) {
//        data = [NSData dataWithBytes:content.c_str() length:content.length()];
//    }
//    NSString * str = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
//    return str;
//}
//
//- (NSString *)parseURL:(NSString *)urlPath {
//    NSString *title;
//    string cURL = [urlPath cStringUsingEncoding:NSUTF8StringEncoding];
//    char ns;
//    string cTitle;
//    if (_reader->parseUrl(cURL, &ns, cTitle)) {
//        title = [NSString stringWithUTF8String:cTitle.c_str()];
//    }
//    return title;
//}
//
//#pragma mark - dealloc
//
//+ (NSInteger)levenshtein:(NSString *)strA anotherString:(NSString *)strB {
//    const string str1 = [strA cStringUsingEncoding:NSUTF8StringEncoding];
//    const string str2 = [strB cStringUsingEncoding:NSUTF8StringEncoding];
//    return levenshtein_distance(str1, str2);
//}

@end
