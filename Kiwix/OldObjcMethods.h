//
//  OldObjcMethods.h
//  Kiwix
//
//  Created by Chris Li on 8/3/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OldObjcMethods : NSObject

+ (NSString *)abbreviateNumber:(int)num;

+ (uint64_t)getFreeDiskspaceInBytes;

@end
