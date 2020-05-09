//
//  SearchOperation.h
//  Kiwix
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchOperation : NSOperation

@property (nonatomic, strong, nonnull) NSArray *results NS_REFINED_FOR_SWIFT;
@property (nonatomic, assign) BOOL extractSnippet;

- (id)initWithSearchText:(NSString *)searchText zimFileIDs:(NSSet *)identifiers;

@end

NS_ASSUME_NONNULL_END
