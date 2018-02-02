//
//  ZimMetaData.m
//  Kiwix
//
//  Created by Chris Li on 10/24/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

#include "reader.h"
#import "ZimMetaData.h"

@implementation ZimMetaData {
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

- (NSString *)getID {
    return [NSString stringWithCString:identifier->c_str() encoding:NSUTF8StringEncoding];
}

- (NSString *)getMainPageURL {
    return [NSString stringWithCString:(reader->getMainPageUrl()).c_str() encoding:NSUTF8StringEncoding];
}

- (NSString *)getTitle {
    return [NSString stringWithCString:(reader->getTitle()).c_str() encoding:NSUTF8StringEncoding];
}

- (NSString *)getDescription {
    return [NSString stringWithCString:(reader->getDescription()).c_str() encoding:NSUTF8StringEncoding];
}

- (NSString *)getLanguage {
    return [NSString stringWithCString:(reader->getLanguage()).c_str() encoding:NSUTF8StringEncoding];
}

- (NSString *)getName {
    return [NSString stringWithCString:(reader->getName()).c_str() encoding:NSUTF8StringEncoding];
}

- (NSString *)getTags {
    return [NSString stringWithCString:(reader->getTags()).c_str() encoding:NSUTF8StringEncoding];
}

- (NSString *)getDate {
    return [NSString stringWithCString:(reader->getDate()).c_str() encoding:NSUTF8StringEncoding];
}

- (NSString *)getCreator {
    return [NSString stringWithCString:(reader->getCreator()).c_str() encoding:NSUTF8StringEncoding];
}

- (NSString *)getPublisher {
    return [NSString stringWithCString:(reader->getOrigId()).c_str() encoding:NSUTF8StringEncoding];
}

- (NSData *)getFavicon {
    string content;
    string mimeType;
    if (reader->getFavicon(content, mimeType)) {
        return [NSData dataWithBytes:content.c_str() length:content.length()];
    } else {
        return [[NSData alloc] init];
    }
}

- (unsigned int)getFileSize {
    return reader->getFileSize() * 1024;
}

- (unsigned int)getArticleCount {
    return reader->getArticleCount();
}

- (unsigned int)getMediaCount {
    return reader->getMediaCount();
}

- (unsigned int)getGlobalCount {
    return reader->getGlobalCount();
}

@end
