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
#import <QuartzCore/QuartzCore.h>

#if DEBUG

@interface PerformanceObjC : NSObject

@property (nonatomic, strong, readonly) NSUUID *id;
@property (nonatomic, assign) CFTimeInterval start;

- (instancetype)initWithId:(NSUUID *)id;
- (void)measure:(NSString *)msg;
- (void)reset;

@end

@implementation PerformanceObjC

- (instancetype)init {
    return [self initWithId:[NSUUID UUID]];
}

- (instancetype)initWithId:(NSUUID *)id {
    self = [super init];
    if (self) {
        _id = id;
        _start = CACurrentMediaTime();
    }
    return self;
}

- (void)measure:(NSString *)msg {
    CFTimeInterval elapsedTime = (CACurrentMediaTime() - _start) * 1000;
    NSLog(@"%@ %@: %.2f ms", msg, _id.UUIDString, elapsedTime);
}

- (void)reset {
    _start = CACurrentMediaTime();
}

@end

#endif
