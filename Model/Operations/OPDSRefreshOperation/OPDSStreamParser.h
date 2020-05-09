//
//  OPDSStreamParser.h
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZimFileMetaData.h"

NS_ASSUME_NONNULL_BEGIN

@interface OPDSStreamParser : NSObject

- (nonnull instancetype)init;
- (BOOL)parseData:(nonnull NSData *)data error:(NSError **)error NS_REFINED_FOR_SWIFT;
- (nonnull NSArray *)getZimFileIDs NS_REFINED_FOR_SWIFT;
- (nullable ZimFileMetaData *)getZimFileMetaData:(nonnull NSString *)identifier NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
