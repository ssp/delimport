//
//  DIFileController.m
//  delimport
//
//  Created by Ian Henderson on 28.04.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import "DIFileController.h"
#import "DIBookmarksController.h"
#import <WebKit/WebKit.h>
#import <sys/xattr.h>

#define DIInvalidURLStatus -1
#define DISaveWebArchiveDataFAILStatus -2
#define DINonHTTPResponseStatus 200 // dodgy?



@implementation DIFileController

- (id) init {
	self = [super init];
	if (self) {
		bookmarksToLoad = [[NSMutableArray alloc] init];
		running = NO;
	}
	
	return self;
}



- (void) dealloc {
	[webView release];
	[bookmarksToLoad release];
	
	[super dealloc];
}





#pragma mark -
#pragma mark Class Methods

/*
 Returns path to subfolder with the given name in the current user’s Library/Metadata folder.
 Create the folder if necessary.
*/
+ (NSString *) metadataPathForSubfolder: (NSString *) folderName {
	NSString *metadataPath = [[@"~/Library/Metadata/" stringByExpandingTildeInPath] stringByAppendingPathComponent: folderName];
	NSFileManager * fileManager = [[[NSFileManager alloc] init] autorelease];
	BOOL isDir;
	NSString * result = nil;
	NSError * myError;
	
	if ([fileManager fileExistsAtPath:metadataPath isDirectory:&isDir]) {
		if (isDir) {
			result = metadataPath;
		}
	} else if ([fileManager createDirectoryAtPath:metadataPath withIntermediateDirectories:YES attributes:nil error:&myError]) {
		result = metadataPath;
	}
	
	return result;
}



/*
 Returns path to file for a bookmark with the given hash.
 Use file name extension according to the bookmarking service we are using.
*/
+ (NSString *) bookmarkPathForHash: (NSString*) hash {
	NSString * fileName = [hash stringByAppendingPathExtension: [DIFileController filenameExtensionForPreferredService]];
	NSString * metadataPath = [[self class] metadataPathForSubfolder:@"delimport"];
	NSString * path = nil;
	if (metadataPath) {
		path = [metadataPath stringByAppendingPathComponent:fileName];
	}
	
	return path;
}



/*
 Returns path to file for a bookmark with the given hash.
 The file name includes the name of the bookmarking service we are using.
*/
+ (NSString *) webarchivePathForHash: (NSString*) hash {
	NSString * fileName = [hash stringByAppendingFormat:@"-%@", [DIBookmarksController serviceName]];
	fileName = [fileName stringByAppendingPathExtension: @"webarchive"];
	NSString * metadataWebarchivePath = [[self class] metadataPathForSubfolder:@"delimport-webarchives"];
	NSString * path = nil;
	if (metadataWebarchivePath) {
		path = [metadataWebarchivePath stringByAppendingPathComponent:fileName];
	}
	
	return path;
}



/*
 Helper returning the filename extension for bookmarks of the service we are using.
 Uses the service name for this, which works well for delicious/pinboard.
*/
+ (NSString *) filenameExtensionForPreferredService {
	return [DIBookmarksController serviceName];
}





#pragma mark -
#pragma mark Bookmark Dictionaries

- (NSDictionary*) readDictionaryForHash: (NSString*) hash {
	NSString * path = [[self class] bookmarkPathForHash: hash];
	NSMutableDictionary * fileBookmark = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	[fileBookmark setObject:hash forKey: DIHashKey];
	return fileBookmark;
}



- (void) saveDictionary: (NSDictionary *) dictionary {
	NSMutableDictionary *mutable = [[dictionary mutableCopy] autorelease];
	NSString *path = [[self class] bookmarkPathForHash: [mutable objectForKey: DIHashKey]];

	if ( path != nil ) {
		NSNumber *osType = [NSNumber numberWithUnsignedLong:'DELi'];
		[mutable removeObjectForKey: DIHashKey];
		[mutable writeToFile:path atomically:YES];
		NSFileManager * fM = [[[NSFileManager alloc] init] autorelease];
		
		[fM changeFileAttributes:[NSDictionary dictionaryWithObject:osType forKey:NSFileHFSTypeCode] atPath:path];

		/*  Set creation date do bookmark date.
			Setting the modification date might be more useful, but would be 'wrong' 
				as we don't know when the bookmark was last edited.
			Investigate setting the last used date as well? 
			This would put bookmarks in their correct order in Spotlight results.
		*/
		NSDate * date = [mutable objectForKey: DITimeKey];
		if (date) {
			[fM changeFileAttributes:[NSDictionary dictionaryWithObject:date forKey:NSFileCreationDate] atPath:path];
		}
	}
}



- (void) deleteDictionary: (NSDictionary *) dictionary {
	NSString *path = [[self class] bookmarkPathForHash: [dictionary objectForKey: DIHashKey]];
	if ( path != nil) {
		[[[[NSFileManager alloc] init] autorelease] removeFileAtPath:path handler:nil];
	}
}



- (void) saveDictionaries: (NSArray *) dictionaries {
	NSEnumerator *dictEnumerator = [dictionaries objectEnumerator];
	NSDictionary *dictionary;
	while (dictionary = [dictEnumerator nextObject]) {
		[self saveDictionary: dictionary];
		[self fetchWebArchiveForDictionary: dictionary];
	}
}



- (void) deleteDictionaries: (NSArray *) dictionaries {
	NSEnumerator *dictEnumerator = [dictionaries objectEnumerator];
	NSDictionary *dictionary;
	while (dictionary = [dictEnumerator nextObject]) {
		[self deleteDictionary:dictionary];
		// for the moment don’t delete web archives
	}
}





#pragma mark -
#pragma mark Webarchives

/*
 Used to add a dictionary to the queue.
 Adds the dictionary and kicks off saving process.
*/
- (void) fetchWebArchiveForDictionary: (NSDictionary *) dictionary {
	[bookmarksToLoad addObject: dictionary];
	[self saveNextWebArchive];
}



/*
 Kick off saving of the next web archive.
 Only run one of these at a time.
 If we’re already running, this method will be called again from -doneSavingWebArchiveWithStatus:
 after finishing.
*/
- (void) saveNextWebArchive {
	if (!running) {
		if ([bookmarksToLoad count] > 0) {
			NSDictionary * dictionary = [bookmarksToLoad objectAtIndex: 0];
			[self startSavingWebArchiveFor: dictionary];
		}
	}
}



/*
 Called for each web archive to be loaded.
 Only does its job if no webarchive is already present for this hash.
  (So we have an archiving nature.)
 Starts loading the web page in the webView. The rest is handled in the webView’s callback.
 Makes sure to call -doneSavingWebArchiveWithStatus: in case things go wrong, to ensure the next download can start.
*/
- (void) startSavingWebArchiveFor: (NSDictionary *) dictionary {
	running = YES;
	NSString * filePath = [DIFileController webarchivePathForHash:[dictionary objectForKey:DIHashKey]];
	
	// Only proceed if (1) the web archive doesn't exist yet and (2) loading the file didn't fail previously
	if (![[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:filePath]
		&& [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKeyPath:[NSString stringWithFormat:@"%@.%@", DIDefaultsFAILKey, [dictionary objectForKey:DIHashKey]]] == nil ) {
		NSURL * URL = [NSURL URLWithString: [dictionary objectForKey: DIURLKey]];

		if (URL) {
			NSLog(@"starting download of %@", [URL absoluteURL]);
			NSURLRequest * request = [NSURLRequest requestWithURL: URL];

			webView = [[WebView alloc] initWithFrame: NSMakeRect(.0, .0, 500., 500.)];
			[webView setFrameLoadDelegate:self];
			[webView setResourceLoadDelegate:self];
			[[webView mainFrame] loadRequest: request];
			return;
		}
	}

	[self doneSavingWebArchiveWithStatus: DIInvalidURLStatus];
}



/*
 WebFrameLoadDelegate callback.
 1. Check whether the right frame finished loading.
 2. Write the data of its dataSource to a webArchive.
 3. Add the URL to extended attributes (as Safari does).
*/
- (void) webView:(WebView *) sender didFinishLoadForFrame:(WebFrame *) frame {
	if ([sender mainFrame] == frame) {
		NSInteger status = DISaveWebArchiveDataFAILStatus;
		
		NSData * webData = [[[frame dataSource] webArchive] data];
		if (webData) {
			if ([bookmarksToLoad count] > 0) {
				NSString * hash = [[bookmarksToLoad objectAtIndex: 0] objectForKey:DIHashKey];
				if ([webData writeToFile:[DIFileController webarchivePathForHash:hash] atomically:YES]) {
					NSURLResponse * response = [[frame dataSource] response];
					if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
						status = [(NSHTTPURLResponse *) response statusCode];
					}
					else {
						status = DINonHTTPResponseStatus;
					}
					[self writeWhereFromsXattrForHash:hash];
				}
			}
			else {
				NSLog(@"Error: bookmarksToLoad array is empty: %@", [bookmarksToLoad description]);
			}
		}
		else {
			NSLog(@"Error: could not get webArchive data for frame %@", frame);
		}
		[self doneSavingWebArchiveWithStatus:status];
	}
}



/*
 WebFrameLoadDelegate callback.
 1. Log that there was an error.
 2. Go to next round of loading.
*/
- (void) webView: (WebView *) sender didFailLoadWithError: (NSError *) error forFrame: (WebFrame *) frame {
	NSLog(@"-webView:didFailLoadWithError: (%lx) %@", [error code], (long)[error localizedDescription]);
	[self doneSavingWebArchiveWithStatus:[error code]];
}



/*
 WebFrameLoadDelegate callback.
 1. Log that there was an error.
 2. Go to next round of loading.
*/
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	NSLog(@"-webView:didFailProvisionalLoadWithError: (%lx) %@", [error code], (long)[error localizedDescription]);
	[self doneSavingWebArchiveWithStatus:[error code]];
}



/*
 Helper function to write "com.apple.metadata:kMDItemWhereFroms" extended attribute for a given hash.
 Assumes the that the hash exists in our data and that its webarchive file exists.
*/
- (void) writeWhereFromsXattrForHash: (NSString*) hash {
	NSString * errorDescription = nil;
	NSData * xAttrPlistData = [NSPropertyListSerialization dataFromPropertyList:[webView mainFrameURL] format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorDescription];
	if (errorDescription != nil) {
		NSLog(@"Could not convert URL for extended attributes when saving web archive: %@", errorDescription);
		[errorDescription release];
	}
	
	setxattr([[DIFileController webarchivePathForHash:hash] fileSystemRepresentation],
			 "com.apple.metadata:kMDItemWhereFroms",
			 [xAttrPlistData bytes], [xAttrPlistData length], 0, 0);
}



/*
 Called at the end of all web loading cycles.
 If the the status information is not 200, save it, along with the current date to the FAIL dictionary in user defaults.
 This way we can avoid reloading broken pages over and over again (which can be lengthy if the sites don't exist anymore).
 Removes the current bookmark from the list and kicks off the next save.
*/
- (void) doneSavingWebArchiveWithStatus: (long) status {
	if ([bookmarksToLoad count] > 0) {
		NSString * hash = [[bookmarksToLoad objectAtIndex: 0] objectForKey:DIHashKey];
		
		if (status != 200) {
			NSDictionary * failState = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithInteger: status], DIFAILStateNumberKey,
										[NSDate date], DIFAILDateKey, nil];
			
			[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:failState forKeyPath:[NSString stringWithFormat:@"%@.%@", DIDefaultsFAILKey, hash]];

			[webView stopLoading:self];
		}
		
		[bookmarksToLoad removeObjectAtIndex: 0];
	}
	[webView setFrameLoadDelegate:nil];
	[webView setResourceLoadDelegate:nil];
	[webView release];
	running = NO;
	[self saveNextWebArchive];
}




#pragma mark -
#pragma mark Opening files

- (BOOL)openFile:(NSString *)filename
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filename];
	if (!dict) {
		return NO;
	}
	NSString * URLString = [dict objectForKey: DIURLKey];
	if (URLString == nil) {
		// try old-style key first
		URLString = [dict objectForKey: DIDeliciousURLKey];
		if (URLString == nil) { // fail
			return NO;
		}
	}
	
	return [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URLString]];
}

@end
