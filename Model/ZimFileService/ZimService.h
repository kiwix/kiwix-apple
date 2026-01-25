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
#import "ZimFileMetaData.h"
#import "zim/archive.h"
#import "SpellingsDBWrapper.h"

@interface ZimService : NSObject

@property (nonatomic, strong) NSString *_Nonnull libkiwixVersion;
@property (nonatomic, strong) NSString *_Nonnull libzimVersion;

- (instancetype _Nonnull)init NS_REFINED_FOR_SWIFT;
+ (nonnull ZimService *)sharedInstance NS_REFINED_FOR_SWIFT;

#pragma mark - Reader Management

- (void)store:(NSURL *_Nonnull)url with:(NSUUID *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;
- (NSUUID *_Nullable)open:(NSUUID *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;
- (void)close:(NSUUID *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;
- (NSArray *_Nonnull)getReaderIdentifiers NS_REFINED_FOR_SWIFT;
- (zim::Archive *_Nullable) archiveBy: (NSUUID *_Nonnull) zimFileID;
- (zim::Archive *_Nullable) findArchiveBy: (NSUUID *_Nonnull) zimFileID;
- (nonnull void *) getArchives;
- (SpellingsDBWrapper *_Nullable)spellingsDBFor:(NSUUID *_Nonnull)zimFileID cachePath:(NSString *_Nonnull)contentPath;

# pragma mark - Spelling
- (void) createSpellingIndex: (NSUUID *_Nonnull) zimFileID cachePath:(NSString *_Nonnull)contentPath NS_REFINED_FOR_SWIFT;

# pragma mark - Metadata

+ (nullable ZimFileMetaData *)getMetaDataWithFileURL:(nonnull NSURL *)url NS_REFINED_FOR_SWIFT;

# pragma mark - URL Handling

- (NSURL *_Nullable)getFileURL:(NSUUID *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;
- (NSString *_Nullable)getRedirectedPath:(NSUUID *_Nonnull)zimFileID contentPath:(NSString *_Nonnull)contentPath NS_REFINED_FOR_SWIFT;
- (NSString *_Nullable)getMainPagePath:(NSUUID *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;
- (NSString *_Nullable)getRandomPagePath:(NSUUID *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;
- (NSNumber *_Nullable)getContentSize:(NSUUID *_Nonnull)zimFileID contentPath:(NSString *_Nonnull)contentPath NS_REFINED_FOR_SWIFT;
- (NSDictionary *_Nullable)getContent:(NSUUID *_Nonnull)zimFileID contentPath:(NSString *_Nonnull)contentPath
                           start:(NSUInteger)start end:(NSUInteger)end NS_REFINED_FOR_SWIFT;
- (NSDictionary *_Nullable)getMetaData:(NSUUID *_Nonnull)zimFileID contentPath:(NSString *_Nonnull)contentPath  NS_REFINED_FOR_SWIFT;
- (NSDictionary *_Nullable)getDirectAccess: (NSUUID *_Nonnull)zimFileID contentPath:(NSString *_Nonnull)contentPath NS_REFINED_FOR_SWIFT;

# pragma mark - ZIM integrity check
- (Boolean) checkIntegrity: (NSUUID *_Nonnull)zimFileID NS_REFINED_FOR_SWIFT;

@end
