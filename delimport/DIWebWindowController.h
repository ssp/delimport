/*
 DIWebWindowController.h
 delimport
 
 Created by Sven-S. Porst <ssp-web@earthlingsoft.net> on 2011-01-03.
 Copyright 2011 earthlingsoft. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

@class WebView;


@interface DIWebWindowController : NSWindowController {
	NSMutableArray * bookmarksToLoad;
	BOOL running;
	
	IBOutlet WebView * webView;
}

- (void) fetchWebArchiveForDictionary: (NSDictionary *) dictionary;

- (void) saveNextWebArchive;
- (void) startSavingWebArchiveFor: (NSDictionary *) dictionary;
- (void) doneSavingWebArchive;

@end
