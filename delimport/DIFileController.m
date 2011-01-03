//
//  DIFileController.m
//  delimport
//
//  Created by Ian Henderson on 28.04.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import "DIFileController.h"
#import "DIWebWindowController.h"

@implementation DIFileController

- (id) init {
	self = [super init];
	if (self) {
		webWindowController = [[DIWebWindowController alloc] initWithWindowNibName:@"FileWindow"];
	}

	return self;
}

- (void) dealloc {
	[webWindowController dealloc];
	[super dealloc];
}


+ (NSString *) metadataPathForSubfolder: (NSString *) folderName {
	NSString *metadataPath = [[@"~/Library/Metadata/" stringByExpandingTildeInPath] stringByAppendingPathComponent: folderName];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDir;
	NSString * result = nil;
	
	if ([fileManager fileExistsAtPath:metadataPath isDirectory:&isDir]) {
		if (isDir) {
			result = metadataPath;
		}
	} else if ([fileManager createDirectoryAtPath:metadataPath attributes:nil]) {
		result = metadataPath;
	}
	
	return result;
}


+ (NSString *) bookmarkPathForHash: (NSString*) hash {
	NSString * fileName = [hash stringByAppendingPathExtension: DIDeliciousFileNameExtension];
	NSString * metadataPath = [[self class] metadataPathForSubfolder:@"delimport"];
	NSString * path = nil;
	if (metadataPath) {
		path = [metadataPath stringByAppendingPathComponent:fileName];
	}
	
	return path;
}


+ (NSString *) webarchivePathForHash: (NSString*) hash {
	NSString * fileName = [hash stringByAppendingPathExtension: @"webarchive"];
	NSString * metadataWebarchivePath = [[self class] metadataPathForSubfolder:@"delimport-webarchives"];
	NSString * path = nil;
	if (metadataWebarchivePath) {
		path = [metadataWebarchivePath stringByAppendingPathComponent:fileName];
	}
	
	return path;
}


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
		
		[[NSFileManager defaultManager] changeFileAttributes:[NSDictionary dictionaryWithObject:osType forKey:NSFileHFSTypeCode] atPath:path];

		/*  set creation date do delicious date
			setting the modification date might be more useful, but would be 'wrong' as we don't know when the bookmark was last edited.
			investigate setting the last used date as well? This would put bookmarks in their correct order in Spotlight results.
		 */
		NSDate * date = [mutable objectForKey: DITimeKey];
		if (date) {
			[[NSFileManager defaultManager] changeFileAttributes:[NSDictionary dictionaryWithObject:date forKey:NSFileCreationDate] atPath:path];
		}
	}
}



- (void) deleteDictionary: (NSDictionary *) dictionary {
	NSString *path = [[self class] bookmarkPathForHash: [dictionary objectForKey: DIHashKey]];
	if ( path != nil) {
		[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
	}
}



- (void) saveDictionaries: (NSArray *) dictionaries {
	NSEnumerator *dictEnumerator = [dictionaries objectEnumerator];
	NSDictionary *dictionary;
	while (dictionary = [dictEnumerator nextObject]) {
		[self saveDictionary: dictionary];
		[webWindowController fetchWebArchiveForDictionary: dictionary];
	}
}



- (void)deleteDictionaries:(NSArray *)dictionaries
{
	NSEnumerator *dictEnumerator = [dictionaries objectEnumerator];
	NSDictionary *dictionary;
	while (dictionary = [dictEnumerator nextObject]) {
		[self deleteDictionary:dictionary];
	}
}



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
