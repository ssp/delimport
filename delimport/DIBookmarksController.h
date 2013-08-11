//
//  DIBookmarksController.h
//  delimport
//
//  Created by Ian Henderson on 30.04.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define DIDefaultsMinutesBetweenChecks @"MinutesBetweenChecks"
#define DIDefaultsDisplayErrorMessages @"DisplayErrorMessages"
#define DIDefaultsLoginAlertSuppressedKey @"suppressAddToLoginItemsAlert"
#define DIDefaultsLastUpdateKey @"lastUpdate"
#define DIDefaultsServiceTypeKey @"serviceType"
#define DIDefaultsUserNameKey @"userName"

@class DIFileController, DILoginController;

@interface DIBookmarksController : NSObject {
	DIFileController *fileController;

	NSMutableDictionary *bookmarks;
	NSDate *lastUpdate;
	NSDate *throttleTimepoint;
}

- (void) logIn;

- (NSDictionary *) loadBookmarksDictionary;
- (void) saveBookmarksDictionary: (NSDictionary *) list;

- (void) verifyMetadataCache;
- (void) updateList: (NSTimer *) timer;
- (NSDictionary *) postDictionaryForXML: (NSXMLElement *) postXML;
- (void) setBookmarks: (NSDictionary *) newMarks;

- (void) setupTimer: (NSTimer *) timer;
- (NSTimeInterval) currentUpdateInterval;

+ (NSString *) username;
+ (void) setUsername:(NSString *) newUsername;
+ (NSString *) keychainPasswordKey;
+ (NSString *) password;
+ (void) setPassword:(NSString *) newPassword;

+ (NSString *) serverAddress;
+ (NSString *) serviceName;
+ (NSString *) versionString;
+ (NSString *) userAgentName;
+ (NSString *) DIApplicationSupportFolderPath;

@end
