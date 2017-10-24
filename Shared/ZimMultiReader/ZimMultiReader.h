//
//  ZimMultiReader.h
//  Kiwix
//
//  Created by Chris Li on 8/17/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZimMultiReader : NSObject
- (instancetype _Nonnull)init NS_REFINED_FOR_SWIFT;

- (void)addBookByURL:(NSURL *_Nonnull)url NS_REFINED_FOR_SWIFT;
- (void)removeBookByID:(NSString *_Nonnull)bookID NS_REFINED_FOR_SWIFT;
- (void)removeBookByURL:(NSURL *_Nonnull)url NS_REFINED_FOR_SWIFT;

- (NSArray *_Nonnull)getReaderIdentifiers NS_REFINED_FOR_SWIFT;
- (NSArray *_Nonnull)getReaderURLs NS_REFINED_FOR_SWIFT;

- (NSDictionary *)getContent:(NSString *)bookID contentURL:(NSString *)contentURL NS_REFINED_FOR_SWIFT;

- (NSString *)getMainPageURL:(NSString *)bookID NS_REFINED_FOR_SWIFT;

- (void)startSearch:(NSString *)searchTerm NS_REFINED_FOR_SWIFT;
- (NSDictionary *)getNextSearchResult NS_REFINED_FOR_SWIFT;
- (void)stopSearch;

- (NSArray *)getSearchSuggestions:(NSString *)searchTerm NS_REFINED_FOR_SWIFT;

@end
