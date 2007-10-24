//
//  DIFileController.m
//  delimport
//
//  Created by Ian Henderson on 28.04.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import "DIFileController.h"


@implementation DIFileController

- (NSString *)cachePath
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

- (void)saveDictionary:(NSDictionary *)dictionary
{
	NSMutableDictionary *mutable = [dictionary mutableCopy];
	NSNumber *osType = [NSNumber numberWithUnsignedLong:'DELi'];
	NSString *path = [[[self cachePath] stringByAppendingPathComponent:[mutable objectForKey:@"hash"]] stringByAppendingPathExtension:@"delicious"];
	if (!path) {
		return;
	}
	[mutable removeObjectForKey:@"hash"];
	[mutable writeToFile:path atomically:YES];
	[[NSFileManager defaultManager] changeFileAttributes:[NSDictionary dictionaryWithObject:osType forKey:NSFileHFSTypeCode] atPath:path];
	[mutable release];
}

- (void)deleteDictionary:(NSDictionary *)dictionary
{
	NSString *path = [[[self cachePath] stringByAppendingPathComponent:[dictionary objectForKey:@"hash"]] stringByAppendingPathExtension:@"delicious"];
	if (!path) {
		return;
	}
	[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
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
	NSString *href = [dict objectForKey:@"href"];
	if (!href) {
		return NO;
	}
	return [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:href]];
}

@end
