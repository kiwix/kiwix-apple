// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

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
@property (nonatomic, strong, nullable) NSData *faviconData;
@property (nonatomic, strong, nullable) NSString *flavor;

// assigned attributes
@property (nonatomic, assign) BOOL hasDetails;
@property (nonatomic, assign) BOOL hasPictures;
@property (nonatomic, assign) BOOL hasVideos;
@property (nonatomic, assign) BOOL requiresServiceWorkers;

// methods
- (nullable instancetype)initWithBook:(nonnull void *)book fetchFavicon: (BOOL) fetchFavicon;

- (nonnull instancetype)initWithFileID:(NSUUID * _Nonnull)fileID
                        groupIdentifier:(NSString * _Nonnull)groupIdentifier
                                  title:(NSString * _Nonnull)title
                        fileDescription:(NSString * _Nonnull)fileDescription
                          languageCodes:(NSString * _Nonnull)languageCodes
                               category:(NSString * _Nonnull)category
                           creationDate:(NSDate * _Nonnull)creationDate
                                   size:(NSNumber * _Nonnull)size
                           articleCount:(NSNumber * _Nonnull)articleCount
                             mediaCount:(NSNumber * _Nonnull)mediaCount
                                creator:(NSString * _Nonnull)creator
                              publisher:(NSString * _Nonnull)publisher
                            downloadURL:(NSURL * _Nullable)downloadURL
                             faviconURL:(NSURL * _Nullable)faviconURL
                            faviconData:(NSData * _Nullable)faviconData
                                 flavor:(NSString * _Nullable)flavor
                             hasDetails:(BOOL)hasDetails
                            hasPictures:(BOOL)hasPictures
                              hasVideos:(BOOL)hasVideos
                 requiresServiceWorkers:(BOOL)requiresServiceWorkers;

@end
