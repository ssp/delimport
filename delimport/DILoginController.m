//
//  DILoginController.m
//  delimport
//
//  Created by Ian Henderson on 01.05.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import "DILoginController.h"
#import "DIBookmarksController.h"


@implementation DILoginController


- init {
	return [super initWithWindowNibName:@"LogIn"];
}

- (void) run {
	[self showWindow:self];
	[[self window] makeKeyAndOrderFront:self];
	[[self window] center];

	NSString * username;
	username = [DIBookmarksController username];
	if (username) {
		[userField setStringValue:username];
	}
	
	NSString * password = [DIBookmarksController password];
	if (password) {
		[passField setStringValue:password];
	}
	
	[NSApp runModalForWindow:[self window]];

	[DIBookmarksController setUsername:[userField stringValue]];
	[DIBookmarksController setPassword:[passField stringValue]];

	[self close];
	
}


- (IBAction) logIn: (id) sender {
	[NSApp stopModal];
}


- (IBAction) quit: (id) sender {
	[NSApp terminate:self];
}


- (IBAction) showWebPage: (id) sender {
	NSURL * delimportURL = [NSURL URLWithString:@"https://github.com/ssp/delimport/wiki"];
	[[NSWorkspace sharedWorkspace] openURL:delimportURL];
}


@end
