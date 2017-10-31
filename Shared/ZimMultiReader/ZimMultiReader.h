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

- (NSDictionary *_Nullable)getContent:(NSString *_Nonnull)zimFileID contentURL:(NSString *_Nonnull)contentURL NS_REFINED_FOR_SWIFT;
- (ZimMetaData *_Nullable)getMetaData:(NSString *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;

- (NSString *_Nullable)getMainPageURL:(NSString *_Nonnull)bookID NS_REFINED_FOR_SWIFT;

- (void)startSearch:(NSString *_Nonnull)searchTerm NS_REFINED_FOR_SWIFT;
- (NSDictionary *_Nullable)getNextSearchResult NS_REFINED_FOR_SWIFT;
- (void)stopSearch;
- (NSArray *_Nonnull)getSearchSuggestions:(NSString *_Nonnull)searchTerm NS_REFINED_FOR_SWIFT;

@end
