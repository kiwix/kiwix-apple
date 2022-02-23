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

@property (nonatomic, strong) NSString *searchText;
@property (nonatomic, assign) BOOL includeSnippet;

@property (nonatomic, strong) NSMutableSet *results NS_REFINED_FOR_SWIFT;

- (id)initWithSearchText:(NSString *)searchText zimFileIDs:(NSSet *)identifiers;
- (void)performSearch;

@end

NS_ASSUME_NONNULL_END
