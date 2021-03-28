//
//  ZimFileMetaData.h
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZimFileMetaData : NSObject

// nonnull attributes
@property (nonatomic, strong, nonnull) NSString *identifier;
@property (nonatomic, strong, nonnull) NSString *groupIdentifier;
@property (nonatomic, strong, nonnull) NSString *title;
@property (nonatomic, strong, nonnull) NSString *fileDescription;
@property (nonatomic, strong, nonnull) NSString *languageCode;
@property (nonatomic, strong, nonnull) NSString *category;

// nullable attributes
@property (nonatomic, strong, nullable) NSString *creator;
@property (nonatomic, strong, nullable) NSString *publisher;
@property (nonatomic, strong, nullable) NSDate *creationDate;
@property (nonatomic, strong, nullable) NSURL *downloadURL;
@property (nonatomic, strong, nullable) NSURL *faviconURL;
@property (nonatomic, strong, nullable) NSData *faviconData;
@property (nonatomic, strong, nullable) NSNumber *size;
@property (nonatomic, strong, nullable) NSNumber *articleCount;
@property (nonatomic, strong, nullable) NSNumber *mediaCount;

// assigned attributes
@property (nonatomic, assign) BOOL hasDetails;
@property (nonatomic, assign) BOOL hasIndex;
@property (nonatomic, assign) BOOL hasPictures;
@property (nonatomic, assign) BOOL hasVideos;
@property (nonatomic, assign) BOOL requiresServiceWorker;

- (nullable instancetype)initWithBook:(nonnull void *)book;

@end
