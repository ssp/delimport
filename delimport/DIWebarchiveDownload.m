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
#define DINonHTTPResponseStatus 200 // dodgy?


@interface DIWebarchiveDownload (Private)
- (void) finishedWithStatus: (NSNumber*) status;
- (void) writeWhereFromsXattr;
@end



@implementation DIWebarchiveDownload

@synthesize URL, webarchivePath, hash;

+ (void) initialize {
	WebPreferences * webPrefs = [WebPreferences standardPreferences];
	[webPrefs setJavaEnabled:NO];
	[webPrefs setPlugInsEnabled:NO];
	[webPrefs setJavaScriptCanOpenWindowsAutomatically:NO];
	[webPrefs setUsesPageCache:NO];
}

- (id) init {
	self = [super init];
	if (self) {
		started = NO;
	}
	return self;
}

- (void) start {
	if (!started && self.URL && self.webarchivePath
		&& ![[[NSFileManager alloc] init] fileExistsAtPath:self.webarchivePath] ) {
		NSURLRequest * request = [NSURLRequest requestWithURL:self.URL];
		
		webView = [[WebView alloc] initWithFrame:NSMakeRect(.0, .0, 500., 500.)];
		[webView setFrameLoadDelegate:self];
		[webView setResourceLoadDelegate:self];
		[[webView mainFrame] loadRequest:request];
		
		started = YES;
		NSLog(@"starting download of %@", [self.URL absoluteString]);
	}
	
	if (!started) {
		[self performSelector:@selector(finishedWithStatus:) withObject:[NSNumber numberWithInteger:DIDidNotStartStatus] afterDelay:0];
	}
	
}


- (void) finishedWithStatus: (NSNumber*) status {
	if (webView) {
		[webView close];
		webView = nil;
	}
	
	NSDictionary * result = [NSDictionary dictionaryWithObjectsAndKeys:
							self.URL, DIStatusURLKey,
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


#pragma mark WebView Delegate Callbacks

/*
 WebFrameLoadDelegate callback.
 1. Check whether the right frame finished loading.
 2. Write the data of its dataSource to a webarchive.
 3. Add the URL to extended attributes (as Safari does).
*/
- (void) webView: (WebView*) sender didFinishLoadForFrame: (WebFrame*) frame {
	if ([sender mainFrame] == frame) {
		NSInteger status = DISaveWebarchiveDataFAILStatus;
		
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
 WebFrameLoadDelegate callback.
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
 WebResourceLoadDelegate callback.
*/
- (void) webView: (WebView*) sender resource: (id) identifier didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge*) challenge fromDataSource: (WebDataSource*) dataSource {
	NSLog(@"didReceiveAuthenticationChallenge:");
	[[challenge sender] cancelAuthenticationChallenge:challenge]; 
}




/*
 WebFrameLoadDelegate callback.
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
