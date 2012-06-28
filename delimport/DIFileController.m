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

#define DIFAILPlistFileName @"Failed Downloads.plist"


@interface DIFileController (Callback)
- (void) downloadFinishedWithStatus: (NSNotification*) notification;
@end


@implementation DIFileController

- (id) init {
	self = [super init];
	if (self) {
		downloadQueue = [[DIQueue alloc] init];
		failDict = [NSMutableDictionary dictionaryWithContentsOfFile:[DIFileController failDictPath]];
		if (!failDict) {
			failDict = [NSMutableDictionary dictionary];
		}
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadFinishedWithStatus:) name:DIWebarchiveDownloadFinishedNotification object:nil];
	}
	
	return self;
}



- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}





#pragma mark -
#pragma mark Notification

- (void) downloadFinishedWithStatus: (NSNotification*) notification {
	NSDictionary * statusDictionary = [notification userInfo];
	
	NSInteger status = [[statusDictionary objectForKey:DIStatusCodeKey] integerValue];
	if (status != 200) {
		NSString * hash = [statusDictionary objectForKey:DIStatusHashKey];
		[failDict setObject:statusDictionary forKey:hash];
		if (![failDict writeToFile:[DIFileController failDictPath] atomically:YES]) {
			NSLog(@"Could not write Failure Dictionary at %@", [DIFileController failDictPath]);
		}
	}
}





#pragma mark -
#pragma mark Class Methods

/*
 Returns path to subfolder with the given name in our container’s Documents folder.
 Create the folder if necessary.
*/
+ (NSString *) pathForName: (NSString *) fileName
			   inSubfolder: (NSString *) subfolderName
			   withExtension: (NSString *) filenameExtension {
	NSString * result = nil;
	NSError * error;
	
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSURL * documentsFolderURL = [fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:NULL create:YES error:&error];
	NSString * documentsFolderPath = [documentsFolderURL path];
	
	if (documentsFolderURL) {
		// Subfolder name.
		NSString * subfolderPath = [documentsFolderPath stringByAppendingPathComponent:subfolderName];
		
		// Create 256 subfolders with names given by the beginning of fileName (the hash) to avoid overcrowded folders.
		if ([fileName length] >= 2) {
			subfolderPath = [subfolderPath stringByAppendingPathComponent:[fileName substringWithRange:NSMakeRange(0, 2)]];
		}

		// Add the file name and extension to the path.
		if (subfolderPath) {
			NSString * filePath = [subfolderPath stringByAppendingPathComponent:fileName];
			if (filenameExtension) {
			   result = [filePath stringByAppendingPathExtension:filenameExtension];
			}
		}
	}
	else {
		if (error) {
			NSLog(@"Could not get URL for documents folder: %@", [error localizedDescription]);
		}
	}
	
	return result;
}



// Determine whether the folders containing the path exist and try to create it if necessary.
// Return YES if the containing folder exists and NO otherwise.
+ (BOOL) createSubfoldersForFilePath: (NSString*) filePath {
	BOOL success = NO;

	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSString * folderPath = [filePath stringByDeletingLastPathComponent];
	
	NSError * error;
	BOOL isDir;
	if ([fileManager fileExistsAtPath:folderPath isDirectory:&isDir]) {
		if (isDir) {
			success = YES;
		}
		else {
			NSLog(@"%@ exists but is not a folder: we need to store files inside it.", folderPath);
		}
	}
	else {
		if ([fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			success = YES;
		}
		else if (error) {
			NSLog(@"Could not create folder %@: %@", folderPath, [error localizedDescription]);
		}
	}

	return success;
}



/*
 Returns path to file for a bookmark with the given hash.
 Use file name extension according to the bookmarking service we are using.
*/
+ (NSString *) bookmarkPathForHash: (NSString*) hash {
	NSString * path = [[self class] pathForName:hash
									inSubfolder:@"delimport-bookmarks"
									withExtension:[DIFileController filenameExtensionForPreferredService]
					   ];

	return path;
}



/*
 Returns path to file for a bookmark with the given hash.
 The file name includes the name of the bookmarking service we are using.
*/
+ (NSString *) webarchivePathForHash: (NSString*) hash {
	NSString * fileName = [hash stringByAppendingFormat:@"-%@", [DIBookmarksController serviceName]];
	NSString * path = [[self class] pathForName:fileName
									inSubfolder:@"delimport-webarchives"
									withExtension:@"webarchive"
					   ];
	
	return path;
}



/*
 Helper returning the path to the property list file containing information about download failures.
*/
+ (NSString *) failDictPath {
	return [[DIBookmarksController DIApplicationSupportFolderPath] stringByAppendingPathComponent:DIFAILPlistFileName];
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
	NSMutableDictionary * mutable = [dictionary mutableCopy];
	NSString * path = [[self class] bookmarkPathForHash: [mutable objectForKey: DIHashKey]];
	
	if ([[self class] createSubfoldersForFilePath:path]) {
		NSNumber * osType = [NSNumber numberWithUnsignedLong:'DELi'];
		[mutable removeObjectForKey: DIHashKey];
		[mutable writeToFile:path atomically:YES];

		NSFileManager * fM = [[NSFileManager alloc] init];
		NSError * error;
		
		if (![fM setAttributes:[NSDictionary dictionaryWithObject:osType forKey:NSFileHFSTypeCode] ofItemAtPath:path error:&error]) {
			if (error) {
				NSLog(@"Failed to set HFS Type Code for file %@ (%@)", path, [error localizedDescription]);
			}
		}
		

		/*  Set creation date to bookmark date.
			Setting the modification date might be more useful, but would be 'wrong' 
				as we don't know when the bookmark was last edited.
			Investigate setting the last used date as well? 
			This would put bookmarks in their correct order in Spotlight results.
		*/
		NSDate * date = [mutable objectForKey: DITimeKey];
		if (date) {
			if (![fM setAttributes:[NSDictionary dictionaryWithObject:date forKey:NSFileCreationDate] ofItemAtPath:path error:&error]) {
				if (error) {
					NSLog(@"Failed to set creation date for file %@ (%@)", path, [error localizedDescription]);
				}
			}
		}
	}
}



- (void) deleteDictionary: (NSDictionary *) dictionary {
	NSString * path = [[self class] bookmarkPathForHash: [dictionary objectForKey: DIHashKey]];
	NSURL * pathURL = [NSURL fileURLWithPath:path];
	if (pathURL != nil) {
		NSError * error;
		if (![[NSFileManager defaultManager] removeItemAtURL:pathURL error:&error]) {
			if (error != nil) {
				NSLog(@"Error deleting file %@: %@", path, [error localizedDescription]);
			}
		}
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
	if (![failDict objectForKey:[dictionary objectForKey:DIHashKey]]) {
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
