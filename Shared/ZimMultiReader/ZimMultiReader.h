//
//  ZimMultiReader.h
//  Kiwix
//
//  Created by Chris Li on 8/17/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZimMetaData.h"

@interface ZimMultiReader : NSObject

- (instancetype _Nonnull)init NS_REFINED_FOR_SWIFT;

- (NSArray *_Nonnull)getReaderIdentifiers NS_REFINED_FOR_SWIFT;
- (NSURL *_Nullable)getReaderFileURL:(NSString *_Nonnull)identifier NS_REFINED_FOR_SWIFT;

- (void)addReaderByURL:(NSURL *_Nonnull)url NS_REFINED_FOR_SWIFT;
- (void)removeReaderByID:(NSString *_Nonnull)bookID NS_REFINED_FOR_SWIFT;
- (void)removeStaleReaders;

- (BOOL)hasEmbeddedIndex:(NSString *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;
- (BOOL)hasExternalIndex:(NSString *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;

- (NSString *_Nullable)getRedirectedPath:(NSString *_Nonnull)zimFileID contentPath:(NSString *_Nonnull)contentPath NS_REFINED_FOR_SWIFT;

- (NSDictionary *_Nullable)getContent:(NSString *_Nonnull)zimFileID contentURL:(NSString *_Nonnull)contentURL NS_REFINED_FOR_SWIFT;
- (NSDictionary *_Nullable)getMetaData:(NSString *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;

- (NSString *_Nullable)getMainPageURL:(NSString *_Nonnull)bookID NS_REFINED_FOR_SWIFT;

- (void)startIndexSearch:(NSString *_Nonnull)searchText zimFileIDs:(NSSet *_Nonnull)zimFileIDs NS_REFINED_FOR_SWIFT;
- (NSDictionary *_Nullable)getNextIndexSearchResult NS_REFINED_FOR_SWIFT;
- (void)stopIndexSearch;
- (NSArray *_Nonnull)getTitleSearchResults:(NSString *_Nonnull)searchText zimFileID:(NSString *_Nullable)zimFileID count:(unsigned int)count NS_REFINED_FOR_SWIFT;

@end
