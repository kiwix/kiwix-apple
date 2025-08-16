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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#pragma clang diagnostic pop

#import <Foundation/Foundation.h>
#import "KiwixHotspot.h"
#import "zim/archive.h"
#import "kiwix/library.h"
#import "kiwix/book.h"
#import "kiwix/server.h"
#import "ZimFileService.h"


@interface KiwixHotspot ()

@property kiwix::LibraryPtr library;
@property std::shared_ptr<kiwix::Server> server;

@end

@implementation KiwixHotspot

- (KiwixHotspot *_Nullable)initWithZimFileIds:(nonnull NSSet *)zimFileIDs onPort: (int) port {
    self = [super init];
    if (self) {
        self.library = kiwix::Library::create();
        if(self.library != nullptr) {
            if([self startFor:zimFileIDs onPort: port] == false) {
                return nil;
            }
        } else {
            NSLog(@"couldn't create kiwix::Library for Hotspot!");
        }
    }
    return self;
}

-(Boolean) startFor: (nonnull NSSet *) zimFileIDs onPort: (int) port {
    if (self.server != nullptr) {
        self.server = nil;
    }
    
    for (NSUUID *zimFileID in zimFileIDs) {
        try {
            zim::Archive * _Nullable archive = [[ZimFileService sharedInstance] archiveBy: zimFileID];
            if(archive != nullptr) {
                kiwix::Book book = kiwix::Book();
                book.update(*archive);
                self.library->addBook(book);
            } else {
                NSLog(@"couldn't add to hotspot zimFileID: %@", zimFileID);
            }
        } catch (std::exception &e) {
            NSLog(@"couldn't add zimFile to Hotspot: %@ because: %s", zimFileID, e.what());
        }
    }
    if(self.library->getBooksIds().size() > 0) {
        self.server = std::make_shared<kiwix::Server>(self.library);
        self.server->setPort(port);
        self.server->start();
        return true;
    } else {
        NSLog(@"no point in starting the hotspot with no zim files");
        return false;
    }
}

- (NSString *)address {
    if(self.server == nullptr) {
        return nil;
    }
    NSString *ipAddress = [NSString stringWithUTF8String: self.server->getAddress().addr.c_str()];
    return [NSString stringWithFormat:@"http://%@%@/", ipAddress, [self portNumberSuffix]];
}

- (NSString *) portNumberSuffix {
    int portNumber = self.server->getPort();
    if(portNumber == 80) {
        return @"";
    } else {
        return [NSString stringWithFormat: @":%i", portNumber];
    }
}

- (void)stop {
    if(self.server != nullptr) {
        self.server->stop();
    }
}

@end
