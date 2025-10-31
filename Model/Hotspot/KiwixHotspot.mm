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

- (KiwixHotspot *_Nonnull) init {
    self = [super init];
    self.library = kiwix::Library::create();
    self.server = std::make_shared<kiwix::Server>(self.library);
    return self;
}

- (Boolean) startFor: (nonnull NSSet *) zimFileIDs onPort: (int) port {
    self.server->stop();
    [self removeAllBooksFromLibrary];
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
        self.server->setPort(port);
        return self.server->start(); // this returns false if the port is occupied
    } else {
        NSLog(@"no point in starting the hotspot with no zim files");
        self.server->stop();
        return false;
    }
}

- (NSString *_Nullable) address {
    //return the first serverAccessUrl
    return [NSString stringWithUTF8String:self.server->getServerAccessUrls()[0].c_str()];
}

- (void) stop {
    self.server->stop();
    [self removeAllBooksFromLibrary];
}

- (void) removeAllBooksFromLibrary {
    for (std::string identifierC: self.library->getBooksIds()) {
        self.library->removeBookById(identifierC);
    }
}

@end
