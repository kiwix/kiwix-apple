//
//  ZimReader.m
//  KiwixTest
//
//  Created by Chris Li on 8/1/14.
//  Copyright (c) 2014 Chris. All rights reserved.
//

#include "reader.h"
#include "xapian.h"
#include <numeric>
#import "ZimReader.h"

#define TITLE_SEARCH_COUNT 10
#define XAPIAN_SEARCH_COUNT 18

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
            zim::File zimFileHandle = *_reader->getZimFileHandler();
            zim::Article xapianArticle = zimFileHandle.getArticle('Z', "/Z/fulltextIndex/xapian");
            if (xapianArticle.good()) {
                zim::offset_type dbOffset = xapianArticle.getOffset();
                int databasefd = open([url fileSystemRepresentation], O_RDONLY);
                lseek(databasefd, dbOffset, SEEK_SET);
                _db = new Xapian::Database(databasefd);
            } else {
                throw "xapian db not in zim";
            }
        } catch (...) {
            try {
                NSString *zimPath = [url absoluteString];
                zimPath = [zimPath stringByReplacingOccurrencesOfString:@".zimaa" withString:@".zim"];
                self.idxFolderURL = [[NSURL fileURLWithPath:zimPath] URLByAppendingPathExtension:@"idx"];
                _db = new Xapian::Database([self.idxFolderURL fileSystemRepresentation]);
            } catch (const Xapian::DatabaseOpeningError &e) {}
        }
        
        self.fileURL = url;
    }
    
    return self;
}

#pragma mark - search

- (NSArray *)searchSuggestionsSmart:(NSString *)searchTerm {
    string searchTermC = [searchTerm cStringUsingEncoding:NSUTF8StringEncoding];
    int count = TITLE_SEARCH_COUNT;
    NSString *bookID = [self getID];
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    if(_reader->searchSuggestionsSmart(searchTermC, count)) {
        string titleC;
        while (_reader->getNextSuggestion(titleC)) {
            NSString *title = [NSString stringWithUTF8String:titleC.c_str()];
            NSString *path = [self pageURLFromTitle:title];
            [results addObject:@{@"title": title,
                                 @"path": path,
                                 @"bookID": bookID}];
        }
    }
    return results;
}

- (NSArray *)searchUsingIndex:(NSString *)searchTerm {
    if(_db == nil) {return @[];}
    try {
        NSArray *searchTerms = [searchTerm componentsSeparatedByString:@" "];
        NSString *bookID = [self getID];
        Xapian::Enquire enquire(*_db);
        NSMutableArray *results = [[NSMutableArray alloc] init];
        
        vector<string> queryTerms;
        
        // Use the whole search term as query, didn't work. If searchTerm contain space, like "new yor", will get zero results
        // string searchTermC = [searchTerm cStringUsingEncoding:NSUTF8StringEncoding];
        // queryTerms.push_back(searchTermC);
        
        for (NSString *searchTerm in searchTerms) {
            string searchTermC = [searchTerm cStringUsingEncoding:NSUTF8StringEncoding];
            queryTerms.push_back(searchTermC);
        }
        
        Xapian::Query query(Xapian::Query::OP_OR, queryTerms.begin(), queryTerms.end());
        enquire.set_query(query);
        
        
        Xapian::MSet matches = enquire.get_mset(0, XAPIAN_SEARCH_COUNT);
        Xapian::MSetIterator i;
        for (i = matches.begin(); i != matches.end(); ++i) {
            Xapian::Document doc = i.get_document();
            
            NSNumber *percent = [[NSNumber alloc] initWithInt:i.get_percent()];
            NSString *path = [NSString stringWithUTF8String:doc.get_data().c_str()];
            NSString *title = [NSString stringWithUTF8String:doc.get_value(0).c_str()];
            NSString *snippet = [NSString stringWithUTF8String:doc.get_value(1).c_str()];
            
            NSDictionary *result = @{@"title": title,
                                     @"path": path,
                                     @"bookID": bookID,
                                     @"probability": percent,
                                     @"snippet": snippet};
            [results addObject:result];
        }
        return results;
    } catch(const Xapian::Error &error) {
        cout << "Xapian Exception: "  << error.get_msg() << endl;
        return  nil;
    }
}

- (NSInteger)levenshteinDistance:(NSString *)strA andString:(NSString *)strB {
    const string str1 = [strA cStringUsingEncoding:NSUTF8StringEncoding];
    const string str2 = [strB cStringUsingEncoding:NSUTF8StringEncoding];
    return levenshtein_distance(str1, str2);
}

// Source: https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance#C.2B.2B
int levenshtein_distance(const std::string &s1, const std::string &s2)
{
    // To change the type this function manipulates and returns, change
    // the return type and the types of the two variables below.
    int s1len = (int)s1.size();
    int s2len = (int)s2.size();
    
    auto column_start = (decltype(s1len))1;
    
    auto column = new decltype(s1len)[s1len + 1];
    std::iota(column + column_start, column + s1len + 1, column_start);
    
    for (auto x = column_start; x <= s2len; x++) {
        column[0] = x;
        auto last_diagonal = x - column_start;
        for (auto y = column_start; y <= s1len; y++) {
            auto old_diagonal = column[y];
            auto possibilities = {
                column[y] + 1,
                column[y - 1] + 1,
                last_diagonal + (s1[y - 1] == s2[x - 1]? 0 : 1)
            };
            column[y] = std::min(possibilities);
            last_diagonal = old_diagonal;
        }
    }
    auto result = column[s1len];
    delete[] column;
    return result;
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

+ (NSInteger)levenshtein:(NSString *)strA anotherString:(NSString *)strB {
    const string str1 = [strA cStringUsingEncoding:NSUTF8StringEncoding];
    const string str2 = [strB cStringUsingEncoding:NSUTF8StringEncoding];
    return levenshtein_distance(str1, str2);
}

@end
