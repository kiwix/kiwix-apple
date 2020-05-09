//
//  SearchResult.h
//  Kiwix
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SearchResult : NSObject

@property (nonatomic, strong, nonnull) NSString *zimFileID;
@property (nonatomic, strong, nonnull) NSString *path;
@property (nonatomic, strong, nonnull) NSString *title;
@property (nonatomic, strong, nullable) NSString *snippet;

@end
