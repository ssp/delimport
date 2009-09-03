//
//  DIFileController.m
//  delimport
//
//  Created by Ian Henderson on 28.04.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import "DIFileController.h"


@implementation DIFileController


- (NSString *) cachePath
{
	NSString *cachePath = [@"~/Library/Caches/Metadata/delimport" stringByExpandingTildeInPath];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDir;
	
	if ([fileManager fileExistsAtPath:cachePath isDirectory:&isDir]) {
		if (isDir) {
			return cachePath;
		}
	} else if ([fileManager createDirectoryAtPath:cachePath attributes:nil]) {
		return cachePath;
	}
	
	return nil;
}


- (NSString *) pathForHash: (NSString*) hash {
	NSString * fileName = [hash stringByAppendingPathExtension: DIDeliciousFileNameExtension];
	NSString * cachePath = [self cachePath];
	NSString * path = nil;
	if (cachePath) {
		path = [cachePath stringByAppendingPathComponent:fileName];
	}
	
	return path;
}



- (NSDictionary*) readDictionaryForHash:(NSString*) hash {
	NSString * path = [self pathForHash: hash];
	NSMutableDictionary * fileBookmark = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	[fileBookmark setObject:hash forKey: DIHashKey];
	return fileBookmark;
}



- (void)saveDictionary:(NSDictionary *)dictionary
{
	NSMutableDictionary *mutable = [[dictionary mutableCopy] autorelease];
	NSString *path = [self pathForHash: [mutable objectForKey: DIHashKey]];

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



- (void)deleteDictionary:(NSDictionary *)dictionary
{
	NSString *path = [self pathForHash: [dictionary objectForKey: DIHashKey]];
	if ( path != nil) {
		[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
	}
}



- (void)saveDictionaries:(NSSet *)dictionaries
{
	NSEnumerator *dictEnumerator = [dictionaries objectEnumerator];
	NSDictionary *dictionary;
	while (dictionary = [dictEnumerator nextObject]) {
		[self saveDictionary:dictionary];
	}
}

- (void)deleteDictionaries:(NSSet *)dictionaries
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
