/*
  DIWebarchiveDownload.h
  delimport

  Created by Sven-S. Porst <ssp-web@earthlingsoft.net> on 23.04.11.
  Copyright 2011 earthlingsoft. All rights reserved.
*/

#import <Cocoa/Cocoa.h>
#import "DIQueueItem.h"

#define DIStatusURLKey @"URL"
#define DIStatusCodeKey @"error code"
#define DIStatusDateKey @"date"
#define DIStatusHashKey @"hash"
#define DIWebarchiveDownloadFinishedNotification @"download finished"

@class WebView;


@interface DIWebarchiveDownload : DIQueueItem {
	NSURL * URL;
	NSString * webarchivePath;
	NSString * hash;
	
	BOOL started;
	NSTimer * timer;
	WebView * webView;
}

@property  NSURL * URL;
@property  NSString * webarchivePath;
@property  NSString * hash;

@end
