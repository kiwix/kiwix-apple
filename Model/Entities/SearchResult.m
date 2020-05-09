//
//  SearchResult.m
//  iOS
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import "SearchResult.h"

@implementation SearchResult

- (instancetype)initWithZimFileId:(NSString *)zimFileId path:(NSString *)path title:(NSString *)title {
    self = [super init];
    if (self) {
        self.zimFileID = zimFileId;
        self.title = title;
        
        NSURLComponents *components = [[NSURLComponents alloc] init];
        components.scheme = @"kiwix";
        components.host = zimFileId;
        components.path = path;
        self.url = [components URL];
        
        if (self.zimFileID == nil || self.title == nil || self.url == nil) {
            return nil;
        }
    }
    return self;;
}

@end
