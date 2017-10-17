//
//  ZimReader.h
//  Kiwix
//
//  Created by Chris Li on 8/1/14.
//  Copyright (c) 2014 Chris. All rights reserved.
//
//  This is the wrapper class that converts all C++ functions in reader.h to Objective-C methods

#import <Foundation/Foundation.h>

@interface ZimReader : NSObject

- (instancetype _Nullable)initWithZimFileURL:(NSURL *_Nonnull)url NS_REFINED_FOR_SWIFT;

- (NSDictionary *_Nullable)getContent:(NSString *_Nonnull)contentURL NS_REFINED_FOR_SWIFT;

- (NSString *_Nonnull)getID NS_REFINED_FOR_SWIFT;
- (NSString *_Nonnull)getMainPageURL NS_REFINED_FOR_SWIFT;
- (NSString *_Nonnull)getTitle NS_REFINED_FOR_SWIFT;
- (NSString *_Nonnull)getDescription NS_REFINED_FOR_SWIFT;
- (NSString *_Nonnull)getLanguage NS_REFINED_FOR_SWIFT;
- (NSString *_Nonnull)getName NS_REFINED_FOR_SWIFT;
- (NSString *_Nonnull)getTags NS_REFINED_FOR_SWIFT;
- (NSString *_Nonnull)getDate NS_REFINED_FOR_SWIFT;
- (NSString *_Nonnull)getCreator NS_REFINED_FOR_SWIFT;
- (NSString *_Nonnull)getPublisher NS_REFINED_FOR_SWIFT;
- (NSData *_Nullable)getFavicon NS_REFINED_FOR_SWIFT;
- (unsigned int)getArticleCount NS_REFINED_FOR_SWIFT;
- (unsigned int)getMediaCount NS_REFINED_FOR_SWIFT;
- (unsigned int)getGlobalCount NS_REFINED_FOR_SWIFT;


//#pragma mark - getData
//
//#pragma mark - getURLs
//- (NSString *)pageURLFromTitle:(NSString *)title;//Will return nil if there is no such page with the specific title
//- (NSString *)mainPageURL;//Will return nil if the zim file have no main page, not sure if this will ever happen(Does every zim file have a main page?)
//- (NSString *)getRandomPageUrl;
//
//#pragma mark - search
//- (NSArray *)searchSuggestionsSmart:(NSString *)searchTerm;
//- (NSArray *)searchUsingIndex:(NSString *)searchTerm;
//
//#pragma mark - get meta data
//- (NSString *)getArticleCount;
//- (NSString *)getMediaCount;
//- (NSString *)getGlobalCount;
//
//- (NSString *)getID;
//- (NSString *)getTitle;
//- (NSString *)getDesc;
//- (NSString *)getLanguage;
//- (NSString *)getName;
//- (NSString *)getTags;
//- (NSString *)getDate;
//- (NSString *)getCreator;
//- (NSString *)getPublisher;
//- (NSString *)getOriginID;
//- (NSString *)getFileSize;
//- (NSString *)getFavicon;
//
//- (NSString *)parseURL:(NSString *)urlPath;
//
//
//
//- (NSURL *)fileURL;
//
//+ (NSInteger)levenshtein:(NSString *)string anotherString:(NSString *)anotherString;

@end
