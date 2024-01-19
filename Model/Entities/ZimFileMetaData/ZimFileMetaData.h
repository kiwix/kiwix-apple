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
@property (nonatomic, strong, nonnull) NSUUID *fileID;
@property (nonatomic, strong, nonnull) NSString *groupIdentifier;
@property (nonatomic, strong, nonnull) NSString *title;
@property (nonatomic, strong, nonnull) NSString *fileDescription;
@property (nonatomic, strong, nonnull) NSString *languageCodes;
@property (nonatomic, strong, nonnull) NSString *category;
@property (nonatomic, strong, nonnull) NSDate *creationDate;
@property (nonatomic, strong, nonnull) NSNumber *size;
@property (nonatomic, strong, nonnull) NSNumber *articleCount;
@property (nonatomic, strong, nonnull) NSNumber *mediaCount;
@property (nonatomic, strong, nonnull) NSString *creator;
@property (nonatomic, strong, nonnull) NSString *publisher;

// nullable attributes
@property (nonatomic, strong, nullable) NSURL *downloadURL;
@property (nonatomic, strong, nullable) NSURL *faviconURL;
@property (nonatomic, strong, nullable) NSString *flavor;

// assigned attributes
@property (nonatomic, assign) BOOL hasDetails;
@property (nonatomic, assign) BOOL hasPictures;
@property (nonatomic, assign) BOOL hasVideos;
@property (nonatomic, assign) BOOL requiresServiceWorkers;

// methods
- (nullable instancetype)initWithBook:(nonnull void *)book;

@end
