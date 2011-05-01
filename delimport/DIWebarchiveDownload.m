/*
  DIWebarchiveDownload.m
  delimport

  Created by Sven-S. Porst <ssp-web@earthlingsoft.net> on 23.04.11.
  Copyright 2011 earthlingsoft. All rights reserved.
*/

#import "DIWebarchiveDownload.h"
#import <WebKit/WebKit.h>
#import <sys/xattr.h>

#define DIInvalidURLStatus -1
#define DISaveWebarchiveDataFAILStatus -2
#define DIDidNotStartStatus -3
#define DITimeoutStatus -4
#define DINonHTTPResponseStatus 200 // dodgy?
#define DIWebarchiveDownloadTimeout 120 // allow two minutes for the download

@interface DIWebarchiveDownload (Private)
- (void) finishedWithStatus: (NSNumber*) status;
- (void) reallyFinishedWithStatus: (NSNumber*) status;
- (void) writeWhereFromsXattr;
- (void) timeout;
@end



@implementation DIWebarchiveDownload

@synthesize URL, webarchivePath, hash;

+ (void) initialize {
	WebPreferences * webPrefs = [WebPreferences standardPreferences];
	[webPrefs setJavaEnabled:NO];
	[webPrefs setPlugInsEnabled:NO];
	[webPrefs setJavaScriptCanOpenWindowsAutomatically:NO];
	[webPrefs setUsesPageCache:NO];
	[webPrefs setCacheModel:WebCacheModelDocumentViewer];
}

- (id) init {
	self = [super init];
	if (self) {
		started = NO;
	}
	return self;
}

- (void) start {
	timer = [NSTimer scheduledTimerWithTimeInterval:DIWebarchiveDownloadTimeout target:self selector:@selector(timeout) userInfo:nil repeats:NO];
	
	if (!started && self.URL && self.webarchivePath
		&& ![[[NSFileManager alloc] init] fileExistsAtPath:self.webarchivePath] ) {
		webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)];
		[webView setMaintainsBackForwardList:NO];
		[webView setFrameLoadDelegate:self];
		[webView setResourceLoadDelegate:self];
		[webView setMainFrameURL:[self.URL absoluteString]];
		
		started = YES;
		NSLog(@"starting download of %@", [self.URL absoluteString]);
	}
	
	if (!started) {
		[self performSelector:@selector(finishedWithStatus:) withObject:[NSNumber numberWithInteger:DIDidNotStartStatus] afterDelay:0];
	}
}


- (void) timeout {
	NSLog(@"timeout");
	[self finishedWithStatus:[NSNumber numberWithInteger:DITimeoutStatus]];
}



- (void) finishedWithStatus: (NSNumber*) status {
	[self performSelector:@selector(reallyFinishedWithStatus:) withObject:status afterDelay:0];
}	
	
- (void) reallyFinishedWithStatus: (NSNumber*) status {
	[timer invalidate];
	
	if (webView) {
		[webView setFrameLoadDelegate:nil];
		[webView setResourceLoadDelegate:nil];
		[webView close];
		webView = nil;
	}
	
	NSDictionary * result = [NSDictionary dictionaryWithObjectsAndKeys:
							[self.URL absoluteString], DIStatusURLKey,
							self.hash, DIStatusHashKey,
							status, DIStatusCodeKey,
							[NSDate date], DIStatusDateKey,
							nil];

	[[NSNotificationCenter defaultCenter] postNotificationName:DIWebarchiveDownloadFinishedNotification
														object:self
													  userInfo:result];
	
	[self finished];
}



- (void) finished {
	[super finished];
}




#pragma mark WebFrameLoadDelegate Delegate Callbacks

/*
 1. Check whether the right frame finished loading.
 2. Write the data of its dataSource to a webarchive.
 3. Add the URL to extended attributes (as Safari does).
*/
- (void) webView: (WebView*) sender didFinishLoadForFrame: (WebFrame*) frame {
	if ([sender mainFrame] == frame) {
		NSInteger status = DISaveWebarchiveDataFAILStatus;
		
		/*
		 There are two ways to get hold of a web archive:
		 1) Using the dataSource and 2) using the DOMDocument of the main frame.
		 According to comments in the webarchiver project the latter is less prone to unexpected
		 crashing (a statement I couldn't confirm). In addition, the web archives provided by the
		 dataSource seem to be more complete and contain more of the external resources (those loaded by
		 JavaScript) which are missing in the DOMDocument provided ones.
		 (Interestingly these two kinds of web archives also end up providing files with slightly
		 differing markup, e.g. in the quotation mark style or, occasionally, linebreaks.
		*/
		// NSData * webData = [[[frame DOMDocument] webArchive] data];
		NSData * webData = [[[frame dataSource] webArchive] data];
		if (webData) {
			if ([webData writeToFile:self.webarchivePath atomically:YES]) {
				NSURLResponse * response = [[frame dataSource] response];
				if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
					status = [(NSHTTPURLResponse *) response statusCode];
				}
				else {
					status = DINonHTTPResponseStatus;
				}
				[self writeWhereFromsXattr];
			}
		}
		else {
			NSLog(@"Error: could not get webarchive data for frame %@", frame);
		}
		[self finishedWithStatus:[NSNumber numberWithInteger:status]];
	}
}



/*
 1. Log that there was an error.
 2. If we are on the main frame proceed to next round of loading.
*/
- (void) webView: (WebView*) sender didFailLoadWithError: (NSError*) error forFrame: (WebFrame*) frame {
	NSLog(@"-webView:didFailLoadWithError: (%ld) %@", [error code], (long)[error localizedDescription]);
	if ([sender mainFrame] == frame) {
		NSLog(@"-webView:didFailLoadWithError: error occured on the main frame: cancel");
		[self finishedWithStatus:[NSNumber numberWithInteger:[error code]]];
	}
}



/*
 1. Log that there was an error.
 2. If we are on the main frame proceed to next round of loading.
*/
- (void) webView:(WebView*)sender didFailProvisionalLoadWithError:(NSError*)error forFrame:(WebFrame*)frame {
	NSLog(@"-webView:didFailProvisionalLoadWithError: (%ld) %@", [error code], (long)[error localizedDescription]);
	if ([sender mainFrame] == frame) {
		NSLog(@"-webView:didFailProvisionalLoadWithError: error occured on the main frame: cancel");
		[self finishedWithStatus:[NSNumber numberWithInteger:[error code]]];
	}
}




#pragma mark WebResourceLoadDelegate Delegate Callbacks

/*
 1. Cancel authentication (so no authentication dialogues pop up)
 TODO: Consider using the keychain here.
*/
- (void) webView: (WebView*) sender resource: (id) identifier didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge*) challenge fromDataSource: (WebDataSource*) dataSource {
	NSLog(@"didReceiveAuthenticationChallenge:");
	[[challenge sender] cancelAuthenticationChallenge:challenge];
}



/*
 Prevent caching of requests.
*/
- (NSURLRequest*) webView: (WebView*) sender resource: (id) identifier willSendRequest: (NSURLRequest*) request redirectResponse: (NSURLResponse*) redirectResponse fromDataSource: (WebDataSource*) dataSource {
	NSMutableURLRequest * myRequest = [request mutableCopy];
	[myRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	return myRequest;
}





#pragma mark Utiliy method

/*
 Helper function to write "com.apple.metadata:kMDItemWhereFroms" extended attribute for a given hash.
 Assumes the that the hash exists in our data and that its web archive file exists.
*/
- (void) writeWhereFromsXattr {
	NSString * errorDescription = nil;
	NSData * xAttrPlistData = [NSPropertyListSerialization dataFromPropertyList:[self.URL absoluteString]
																		 format:NSPropertyListBinaryFormat_v1_0
															   errorDescription:&errorDescription ];
	if (errorDescription != nil) {
		NSLog(@"Could not convert URL %@ for extended attributes when saving web archive: %@", [self.URL absoluteString], errorDescription);
	}
	
	setxattr([self.webarchivePath fileSystemRepresentation], "com.apple.metadata:kMDItemWhereFroms",
			 [xAttrPlistData bytes], [xAttrPlistData length], 0, 0);
}


@end
