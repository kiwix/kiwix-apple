//
//  ZimIndexer.h
//  Kiwix
//
//  Created by Chris Li on 6/3/16.
//  Copyright © 2016 Chris. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZimIndexerDelegate <NSObject>
@optional

- (void)didProcessArticle:(NSUInteger)processedArticleCount totalArticleCount:(NSUInteger)totalArticleCount;

@end

@interface ZimIndexer : NSObject

@property (nonatomic, weak) id <ZimIndexerDelegate> delegate;
- (void)start:(NSURL *)zimFileURL indexFolderURL:(NSURL *)indexFolderURL;

@end

