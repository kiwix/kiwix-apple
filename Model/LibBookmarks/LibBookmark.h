//
//  LibBookmark.h
//  Kiwix

#import <Foundation/Foundation.h>

@interface LibBookmark : NSObject

@property std::string zimFileID_c;
@property std::string url_c;
@property std::string title_c;

- (nonnull instancetype) init: (nonnull NSURL *) url inZIM: (nonnull NSUUID *) zimFileID withTitle: (nonnull NSString *) title;

- (const kiwix::Bookmark&) bridged;

@end
