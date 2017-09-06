//
//  ZimMetaData.h
//  Kiwix
//
//  Created by Chris Li on 10/24/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZimMetaData : NSObject

- (instancetype _Nullable)initWithZimFileURL:(NSURL *_Nonnull)url NS_REFINED_FOR_SWIFT;

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
- (NSData *_Nonnull)getFavicon NS_REFINED_FOR_SWIFT;
- (unsigned int)getFileSize NS_REFINED_FOR_SWIFT;
- (unsigned int)getArticleCount NS_REFINED_FOR_SWIFT;
- (unsigned int)getMediaCount NS_REFINED_FOR_SWIFT;
- (unsigned int)getGlobalCount NS_REFINED_FOR_SWIFT;

@end
