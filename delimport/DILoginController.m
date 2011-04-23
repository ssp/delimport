//
//  DILoginController.m
//  delimport
//
//  Created by Ian Henderson on 01.05.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import "DILoginController.h"


@implementation DILoginController


- init
{
	return [super initWithWindowNibName:@"LogIn"];
}

- (void)getUsername:(NSString **)username password:(NSString **)password
{
	[self showWindow:self];
	[[self window] makeKeyAndOrderFront:self];
	[[self window] center];
	[NSApp runModalForWindow:[self window]];
	*username = [userField stringValue];
	*password = [passField stringValue];
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
