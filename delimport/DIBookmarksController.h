//
//  DIBookmarksController.h
//  delimport
//
//  Created by Ian Henderson on 30.04.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define DIMinutesBetweenChecks @"MinutesBetweenChecks"
#define DIDisplayErrorMessages @"DisplayErrorMessages"

@class DIFileController, DILoginController;

@interface DIBookmarksController : NSObject {
	DIFileController *fileController;
	DILoginController *loginController;
	
	NSString *username;
	NSString *password;

	NSSet *bookmarks;
	NSDate *lastUpdate;
	NSDate *throttleTimepoint;
}

- (void)logIn;
- (void)updateList:(NSTimer *)timer;
- (void)setBookmarks:(NSSet *)newMarks;

- (void) setupTimer:(NSTimer*) timer;
- (NSTimeInterval) currentUpdateInterval;

@end
