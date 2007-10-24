//
//  DIBookmarksController.h
//  delimport
//
//  Created by Ian Henderson on 30.04.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DIFileController, DILoginController;

@interface DIBookmarksController : NSObject {
	DIFileController *fileController;
	DILoginController *loginController;
	
	NSString *username;
	NSString *password;

	NSSet *bookmarks;
	NSDate *lastUpdate;
	
	NSTimer *updateTimer;
}

- (void)logIn;
- (void)updateList:(NSTimer *)timer;
- (void)setBookmarks:(NSSet *)newMarks;

@end
