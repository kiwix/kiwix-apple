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

#import "SearchResult.h"

@implementation SearchResult

- (instancetype)initWithZimFileID:(NSUUID *)zimFileID path:(NSString *)path title:(NSString *)title {
    self = [super init];
    if (self) {
        self.zimFileID = zimFileID;
        self.title = title;
        
        // HACK: assuming path is always absolute, which is required to construct a url using NSURLComponents
        if (![path hasPrefix:@"/"]) { path = [@"/" stringByAppendingString:path]; }
        
        NSURLComponents *components = [[NSURLComponents alloc] init];
        components.scheme = @"zim";
        components.host = [zimFileID UUIDString];
        components.path = path;
        NSURL *_Nullable finalURL = [components URL];
        if (finalURL == nil) {
            return nil;
        }
        self.url = finalURL;
        
        if (self.zimFileID == nil || self.title == nil || self.url == nil) {
            return nil;
        }
    }
    return self;
}

@end
