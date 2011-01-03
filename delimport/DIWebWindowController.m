/*
 DIWebWindowController.m
 delimport
 
 Created by Sven-S. Porst <ssp-web@earthlingsoft.net> on 2011-01-03.
 Copyright 2011 earthlingsoft. All rights reserved.
*/

#import "DIWebWindowController.h"
#import "DIFileController.h"
#import <WebKit/WebKit.h>

@implementation DIWebWindowController

- (id) initWithWindowNibName: (NSString*) nibName {
	self = [super initWithWindowNibName:nibName];
	if (self) {
		bookmarksToLoad = [[NSMutableArray alloc] init];
		running = NO;
	}
	
	return self;
}



- (void) dealloc {
	[bookmarksToLoad dealloc];
	[super dealloc];
}



- (void) fetchWebArchiveForDictionary: (NSDictionary *) dictionary {
	[bookmarksToLoad addObject: dictionary];
	[self saveNextWebArchive];
}


- (void) saveNextWebArchive {
	[[self window] orderFront: self];
	
	if (!running) {
		if ([bookmarksToLoad count] > 0) {
			NSDictionary * dictionary = [bookmarksToLoad objectAtIndex: 0];
			[self startSavingWebArchiveFor: dictionary];
		}
	}
}


- (void) startSavingWebArchiveFor: (NSDictionary *) dictionary {
	running = YES;
	NSURL * URL = [NSURL URLWithString: [dictionary objectForKey: DIURLKey]];

	if (URL) {
		NSURLRequest * request = [NSURLRequest requestWithURL: URL];
		[[webView mainFrame] loadRequest: request];
	}
	else {
		[self doneSavingWebArchive];
	}
}



- (void) webView:(WebView *) sender didFinishLoadForFrame:(WebFrame *) frame {
	if ([sender mainFrame] == frame) {
		NSData * webData = [[[frame dataSource] webArchive] data];
		if (webData) {
			if ([bookmarksToLoad count] > 0) {
				NSString * hash = [[bookmarksToLoad objectAtIndex: 0] objectForKey: DIHashKey]; 
				[webData writeToFile: [DIFileController webarchivePathForHash: hash] atomically: YES];
				[self doneSavingWebArchive];
			}
			else {
				NSLog(@"Error: bookmarksToLoad array is empty: %@", [bookmarksToLoad description]);
			}
		}
		else {
			NSLog(@"Error: could not get webArchive data for frame %@", frame);
		}
	}
}


- (void) doneSavingWebArchive {
	if ([bookmarksToLoad count] > 0) {
		[bookmarksToLoad removeObjectAtIndex: 0];
	}
	running = NO;
	[self saveNextWebArchive];
}

	
@end
