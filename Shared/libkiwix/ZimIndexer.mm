//
//  ZimIndexer.m
//  Kiwix
//
//  Created by Chris Li on 6/3/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

#include "xapianIndexer.h"
#import "ZimIndexer.h"

@interface ZimIndexer () {
    kiwix::XapianIndexer *_indexer;
}
@end

@implementation ZimIndexer

static id staticInstance = nil;

- (instancetype)init {
    self = [super init];
    if (self) {
        _indexer = new kiwix::XapianIndexer();
        _indexer->setVerboseFlag(true);
    }
    staticInstance = self;
    return self;
}

- (void)start:(NSURL *)zimFileURL indexFolderURL:(NSURL *)indexFolderURL {
    _indexer->start([zimFileURL fileSystemRepresentation], [indexFolderURL fileSystemRepresentation], ProgressCallback);
}

void ProgressCallback(const UInt processedArticleCount, const UInt totalArticleCount) {
    [staticInstance progressUpdate: processedArticleCount totalArticleCount: totalArticleCount];
}

- (void)progressUpdate:(UInt)processedArticleCount totalArticleCount:(UInt)totalArticleCount {
    if ([self.delegate respondsToSelector:@selector(didProcessArticle:totalArticleCount:)]) {
        [self.delegate didProcessArticle:processedArticleCount totalArticleCount:totalArticleCount];
    }
}

@end
