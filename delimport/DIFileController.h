//
//  DIFileController.h
//  delimport
//
//  Created by Ian Henderson on 28.04.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define DIDeliciousFileNameExtension @"delicious"

#define DIURLKey @"URL"
#define DIDeliciousURLKey @"href"
#define DINameKey @"Name"
#define DIDeliciousNameKey @"description"
#define DIHashKey @"hash"
#define DITimeKey @"time"
#define DITagKey @"tag"

@class DIWebWindowController;

@interface DIFileController : NSObject {
	DIWebWindowController * webWindowController;
}


+ (NSString *) metadataPathForSubfolder: (NSString *) folderName;
+ (NSString *) bookmarkPathForHash: (NSString*) hash;
+ (NSString *) webarchivePathForHash: (NSString*) hash;

- (NSDictionary*) readDictionaryForHash:(NSString*) hash;
- (void) saveDictionary:(NSDictionary *)dictionary;
- (void) saveDictionaries:(NSArray *)dictionaries;
- (void) deleteDictionaries:(NSArray *)dictionaries;

- (BOOL)openFile:(NSString *)filename;

@end
