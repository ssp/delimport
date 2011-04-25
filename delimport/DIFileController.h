//
//  DIFileController.h
//  delimport
//
//  Created by Ian Henderson on 28.04.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define DIURLKey @"URL"
#define DIDeliciousURLKey @"href"
#define DINameKey @"Name"
#define DIDeliciousNameKey @"description"
#define DIHashKey @"hash"
#define DITimeKey @"time"
#define DITagKey @"tag"

#define DIDownloadWebarchivesKey @"download web archives"
#define DIDefaultsFAILKey @"failed web page downloads"

@class DIQueue;


@interface DIFileController : NSObject {
	DIQueue * downloadQueue;
}

+ (NSString *) metadataPathForSubfolder: (NSString *) folderName;
+ (NSString *) bookmarkPathForHash: (NSString*) hash;
+ (NSString *) webarchivePathForHash: (NSString*) hash;
+ (NSString *) filenameExtensionForPreferredService;

- (NSDictionary*) readDictionaryForHash:(NSString*) hash;
- (void) saveDictionary:(NSDictionary *)dictionary;
- (void) saveDictionaries:(NSArray *)dictionaries;
- (void) deleteDictionaries:(NSArray *)dictionaries;

- (void) fetchWebarchiveForDictionary: (NSDictionary *) dictionary;

- (BOOL) openFile:(NSString *)filename;

@end
