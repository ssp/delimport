//
//  DILoginController.m
//  delimport
//
//  Created by Ian Henderson on 01.05.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import "DILoginController.h"


@implementation DILoginController


- (IBAction)quit:sender
{
	[NSApp terminate:self];
}

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

- (IBAction)logIn:sender
{
	[NSApp stopModal];
}

@end
