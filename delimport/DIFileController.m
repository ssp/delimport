//
//  DIFileController.m
//  delimport
//
//  Created by Ian Henderson on 28.04.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import "DIFileController.h"
#import "DIBookmarksController.h"
#import "DIQueue.h"
#import "DIWebarchiveDownload.h"
#import <sys/xattr.h>


@implementation DIFileController

- (id) init {
	self = [super init];
	if (self) {
		downloadQueue = [[DIQueue alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadFinishedWithStatus:) name:DIWebarchiveDownloadFinishedNotification object:nil];
	}
	
	return self;
}


- (void) finalize {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super finalize];
}





#pragma mark -
#pragma mark Notification

- (void) downloadFinishedWithStatus: (NSNotification*) notification {
	NSDictionary * statusDictionary = [notification userInfo];
	
	NSInteger status = [[statusDictionary objectForKey:DIStatusCodeKey] integerValue];
	if (status != 200) {
		NSString * hash = [statusDictionary objectForKey:DIStatusHashKey];
		NSString * defaultsKey = [NSString stringWithFormat:@"%@.%@", DIDefaultsFAILKey, hash];
		[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:statusDictionary forKeyPath:defaultsKey];
	}
	
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
	for (NSDictionary * dictionary in dictionaries) {
		[self saveDictionary: dictionary];
		[self fetchWebarchiveForDictionary: dictionary];
	}
}



- (void) deleteDictionaries: (NSArray *) dictionaries {
	for (NSDictionary * dictionary in dictionaries) {
		[self deleteDictionary:dictionary];
		// for the moment don’t delete web archives
	}
}





#pragma mark -
#pragma mark Webarchives

/*
 Queue download of the dictionary item if it hasn't been marked as problematic.
*/
- (void) fetchWebarchiveForDictionary: (NSDictionary *) dictionary {
	NSString * bookmarkFailKey = [NSString stringWithFormat:@"%@.%@", DIDefaultsFAILKey, [dictionary objectForKey:DIHashKey]];
	BOOL isProblematic = ([[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKeyPath:bookmarkFailKey] != nil);
	if (!isProblematic) {
		DIWebarchiveDownload * download = [[DIWebarchiveDownload alloc] init];
		NSURL * URL = [NSURL URLWithString:[dictionary objectForKey:DIURLKey]];
		download.URL = URL;
		download.webarchivePath = [DIFileController webarchivePathForHash:[dictionary objectForKey:DIHashKey]];
		download.hash = [dictionary objectForKey:DIHashKey];
		[downloadQueue addToQueue:download];
	}
}





#pragma mark -
#pragma mark Opening files

- (BOOL) openFile: (NSString *) filename {
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
