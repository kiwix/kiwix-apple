//
//  SearchResult.m
//  Kiwix
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import "SearchResult.h"

@implementation SearchResult

- (instancetype)initWithZimFileID:(NSUUID *)zimFileID path:(NSString *)path title:(NSString *)title {
    self = [super init];
    if (self) {
        self.zimFileID = zimFileID;
        self.title = title;
        
        NSURLComponents *components = [[NSURLComponents alloc] init];
        components.scheme = @"kiwix";
        components.host = [zimFileID UUIDString];
        components.path = path;
        self.url = [components URL];
        
        if (self.zimFileID == nil || self.title == nil || self.url == nil) {
            return nil;
        }
    }
    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if ([other isKindOfClass:self.class]) {
        return [self.url isEqual:((SearchResult *)other).url];
    } else {
        return [super isEqual:other];
    }
}

- (NSUInteger)hash {
    return self.url.hash;
}

@end
