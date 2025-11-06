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

NS_ASSUME_NONNULL_BEGIN

@interface OPDSParser : NSObject

- (nonnull instancetype)init;
- (BOOL)parseData:(nonnull NSData *)data using: (nonnull NSString *)urlHost NS_REFINED_FOR_SWIFT;
- (nonnull NSSet *)getZimFileIDs NS_REFINED_FOR_SWIFT;
- (nullable ZimFileMetaData *)getZimFileMetaData:(nonnull NSUUID *)identifier fetchFavicon: (BOOL) fetchFavicon NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
