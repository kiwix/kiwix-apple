/*
 * This file is part of Kiwix for iOS & macOS.
 *
 * Kiwix is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * Kiwix is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Kiwix; If not, see https://www.gnu.org/licenses/.
*/

#import <Foundation/Foundation.h>

@interface SearchResult : NSObject

@property (nonatomic, strong, nonnull) NSUUID *zimFileID;
@property (nonatomic, strong, nonnull) NSURL *url;
@property (nonatomic, strong, nonnull) NSString *title;
@property (nonatomic, strong, nullable) NSString *htmlSnippet;
@property (nonatomic, strong, nullable) NSAttributedString *snippet;
@property (nonatomic, strong, nullable) NSNumber *probability;
@property (nonatomic, strong, nullable) NSNumber *score;

- (nullable instancetype)initWithZimFileID:(nonnull NSUUID *)zimFileID
                                      path:(nonnull NSString *)path
                                     title:(nonnull NSString *)title;
- (BOOL)isEqual:(nullable id)other;
- (NSUInteger)hash;

@end
