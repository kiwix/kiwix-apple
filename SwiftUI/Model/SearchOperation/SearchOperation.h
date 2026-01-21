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

NS_ASSUME_NONNULL_BEGIN

@interface SearchOperation : NSOperation

@property (nonatomic, strong) NSString *searchText;
@property (nonatomic, assign) BOOL extractMatchingSnippet;
@property (nonatomic, strong) NSMutableSet *foundURLs;
@property (nonatomic, nullable) NSURL *spellCacheDir;
@property (nonatomic, strong) NSSet *zimFileIDs;
@property (nonatomic, strong) NSMutableOrderedSet *results NS_REFINED_FOR_SWIFT;
@property (nonatomic, strong) NSMutableOrderedSet *corrections NS_REFINED_FOR_SWIFT;

- (id)initWithSearchText:(NSString *)searchText zimFileIDs:(NSSet *)zimFileIDs withSpellingCacheDir: (NSURL *_Nullable) spellCacheDir;
- (void)performSearch;

@end

NS_ASSUME_NONNULL_END
