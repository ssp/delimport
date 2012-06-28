//
//  DIBookmarksController.m
//  delimport
//
//  Created by Ian Henderson on 30.04.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import "DIBookmarksController.h"
#import "DIFileController.h"
#import "DILoginController.h"
#import <Keychain/Keychain.h>
#import <Keychain/KeychainSearch.h>
#import <Keychain/KeychainItem.h>

#define DIBookmarksPlistFileName @"Bookmarks.plist"



@implementation DIBookmarksController

// Shamelessly stolen from http://www.cocoadev.com/index.pl?AddingYourAppToLoginWindow
- (void)addToLoginItems {
	// First, get the login items from loginwindow pref
	NSMutableArray* loginItems = (NSMutableArray*) CFPreferencesCopyValue((CFStringRef) @"AutoLaunchedApplicationDictionary",
		(CFStringRef) @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	BOOL changed = NO, foundMyAppItem = NO;
	int myAppItemIndex = 0;
	NSString *kDTMyAppAppPath = [[NSBundle mainBundle] bundlePath]; 
	
	if (loginItems) {
		NSEnumerator *enumer;
		NSDictionary *itemDict;
		
		// Detirmine if myApp is in list
		enumer=[loginItems objectEnumerator];
		while ((itemDict=[enumer nextObject])) {
			if ([[itemDict objectForKey:@"Path"] isEqualToString:kDTMyAppAppPath]) {
				foundMyAppItem = YES;
				break;
			}
			myAppItemIndex++;
		}
	}
	if (!foundMyAppItem && ![[NSUserDefaults standardUserDefaults] boolForKey:DILoginAlertSuppressedKey]) {
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Automatically launch delimport on login?", @"Headline for add to login items dialogue") defaultButton:NSLocalizedString(@"Add", @"Add") alternateButton:NSLocalizedString(@"Don't Add", @"Don't Add") 
			otherButton:nil 
			informativeTextWithFormat:NSLocalizedString(@"delimport will be added to your login items. This will ensure delimport runs and downloads your del.icio.us bookmarks whenever you are using this account.", @"Explanatory text for add to login items dialogue")
			];
		[NSApp activateIgnoringOtherApps:YES];
		[[alert window] makeKeyAndOrderFront:self];
		[[alert window] center];
		[alert setShowsSuppressionButton:YES];
		
		if ([alert runModal] == NSAlertDefaultReturn) {
			// OK, Create item and add it - should work even if no pref existed
			NSDictionary	*myAppItem;
			FSRef			myFSRef;
			OSStatus		fsResult = FSPathMakeRef((const UInt8 *)[kDTMyAppAppPath fileSystemRepresentation], &myFSRef,NULL);
			
			if (loginItems) {
				loginItems = [loginItems mutableCopy];
			} else {
				loginItems = [[NSMutableArray alloc] init];	// didn't find this pref, make from scratch
			}
			// ref from path as NSString 
			if (fsResult == noErr) {
				AliasHandle myAliasHndl = NULL;
				
				//make alias record, a handle of variable length			
				fsResult = FSNewAlias(NULL, &myFSRef, &myAliasHndl);
				if (fsResult == noErr && myAliasHndl != NULL) {
					// Add the item
					myAppItem = [NSDictionary dictionaryWithObjectsAndKeys:
						[NSData dataWithBytes:*myAliasHndl length:GetHandleSize((Handle)myAliasHndl)],
						@"AliasData", [NSNumber numberWithBool:NO], @"Hide", kDTMyAppAppPath, @"Path", nil];
					[loginItems addObject:myAppItem];
					// release the new alias handle
					DisposeHandle((Handle)myAliasHndl);
					changed = YES;
				}
			}
		}
		
		if ([[alert suppressionButton] state] == NSOnState) {
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:DILoginAlertSuppressedKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	}
	
	if (changed) {
		// Set new value in pref
		CFPreferencesSetValue((CFStringRef) 
							  @"AutoLaunchedApplicationDictionary", loginItems, (CFStringRef) 
							  @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost); 
		CFPreferencesSynchronize((CFStringRef) @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost); 
	}
}



- (KeychainItem *) getKeychainUserAndPass {
	KeychainSearch * search = [[KeychainSearch alloc] init];
	[search setServer:[DIBookmarksController serverAddress]];

	NSArray *results = [search internetSearchResults];
	if ([results count] <= 0) {
		return nil;
	}

	KeychainItem *item = [results objectAtIndex:0];
	username = [item account];
	password = [item dataAsString];

	return item;
}



- (id) init {
	self = [super init];
	if (self != nil) {
		username = nil;
		password = nil;
		
		bookmarks = [[self loadBookmarksDictionary] mutableCopy];
		
		lastUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:DIDefaultsLastUpdateKey];
		if (!lastUpdate) {
			lastUpdate = [NSDate distantPast];
		} else if (![lastUpdate isKindOfClass:[NSDate class]]) {
			lastUpdate = [NSUnarchiver unarchiveObjectWithData:(NSData *)lastUpdate];
		}
		
		fileController = [[DIFileController alloc] init];
		loginController = [[DILoginController alloc] init];
		throttleTimepoint = [NSDate distantPast];
	}
	return self;
}



- (void) applicationDidFinishLaunching: (NSNotification *) notification {
	[self addToLoginItems];
	[self getKeychainUserAndPass];
	
	// Show login/preferences window in case the Option key is held on launch.
	CGEventRef event = CGEventCreate(NULL);
	CGEventFlags modifiers = CGEventGetFlags(event);
	if (modifiers & kCGEventFlagMaskAlternate) {
		[self logIn];
	}
	
	[self verifyMetadataCache];
	[self updateList:nil];
}



/*
 Check whether all our metadata files exist and are correct. 
 Make metadata consistent if they are not.
*/  
- (void) verifyMetadataCache {	
	NSFileManager * fM = [[NSFileManager alloc] init];
	NSMutableArray * bookmarksNeedingUpdate = [NSMutableArray array];
	
	for (NSString * hash in bookmarks) {
		NSDictionary *  bookmark = [bookmarks objectForKey:hash];
		// bookmark files
		NSDictionary * fileBookmark = [fileController readDictionaryForHash:hash];
		if (fileBookmark == nil || [bookmark isEqualToDictionary:fileBookmark] == NO) {
			// we don't have a bookmark or the bookmark ist not in sync with the cache
			// NSLog(@"replacing cache file %@", hash);
			[bookmarksNeedingUpdate addObject:bookmark];
		}
		else if (![fM fileExistsAtPath:[DIFileController webarchivePathForHash:hash]]) {
			[fileController fetchWebarchiveForDictionary:bookmark];
		}
	}

	[fileController saveDictionaries:bookmarksNeedingUpdate];
}



- (NSXMLDocument *) deliciousAPIResponseToRequest: (NSString *) request {
	NSString *URLString = [NSString stringWithFormat:@"https://%@:%@@%@/v1/%@", username, password, [DIBookmarksController serverAddress], request];
	NSURL *requestURL = [NSURL URLWithString:URLString];
	NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:requestURL];
	[URLRequest setValue:[DIBookmarksController userAgentName] forHTTPHeaderField: @"User-Agent"];
	
	NSError * error;
	NSHTTPURLResponse * response;
	NSData * xmlData = [NSURLConnection sendSynchronousRequest:URLRequest returningResponse:&response error:&error];
	// NSLog(@"API request: '%@', response: %i, d/l size: %i", request, [response statusCode], [xmlData length], nil);
	if ([response statusCode] == 401) {
		[self logIn];
		return nil;
	}
	else if ([response statusCode] == 503) {
		// we've been throttled
		[self setValue:[NSDate date] forKey:@"throttleTimepoint"];
		NSLog(@"503 http error: throttled");
		return nil;
	}
	
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:xmlData options:NSXMLDocumentTidyXML error:&error];

	if (document == nil) {
		// Display or log the problem (just sliently retrying seems preferable to me)
		[[NSUserDefaults standardUserDefaults] synchronize];
		if ([[NSUserDefaults standardUserDefaults] boolForKey:DIDisplayErrorMessages]) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[[alert window] makeKeyAndOrderFront:self];
			[[alert window] center];
			[alert runModal];
		}
		else {
			NSLog(@"Download failed: %@", [error localizedDescription]);
		}
	}
	return document;
}



- (void) logIn {
	[loginController getUsername:&username password:&password];

	Keychain *keychain = [Keychain defaultKeychain];

	[keychain addInternetPassword:password onServer:[DIBookmarksController serverAddress] forAccount:username port:80 path:@"" inSecurityDomain:@"" protocol:kSecProtocolTypeHTTP auth:kSecAuthenticationTypeHTTPDigest replaceExisting:YES];
}


- (NSDate*) dateFromXMLDateString: (NSString *) string {
	NSMutableString *dateString = [string mutableCopy];
	[dateString replaceOccurrencesOfString:@"T" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [dateString length])];
	[dateString replaceOccurrencesOfString:@"Z" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [dateString length])];
	[dateString appendString:@"+0000"];
	return [NSDate dateWithString:dateString];
}

- (NSDate *) remoteLastUpdate {
	NSXMLDocument *updateDoc = [self deliciousAPIResponseToRequest:@"posts/update"];
	if (!updateDoc) {
		return [NSDate distantFuture];
	}
	NSXMLElement *updateElement = [updateDoc rootElement];
	return [self dateFromXMLDateString:[[updateElement attributeForName: DITimeKey] stringValue]];
}



- (void) updateList: (NSTimer *) timer {
	[self setupTimer:timer];

	if (!username) {
		[self logIn];
	}
	NSDate * remoteUpdateTime = [self remoteLastUpdate];
	NSTimeInterval interval = [lastUpdate timeIntervalSinceDate:remoteUpdateTime];
	if (interval >= 0) {
		return;
	}
	
	// the work gets done here and data could be lost, so disable sudden termination
	[DIBookmarksController disableSuddenTermination];
	NSXMLDocument *allPostsDoc = [self deliciousAPIResponseToRequest:@"posts/all"];
	if (allPostsDoc != nil) {
		NSXMLElement *root = [allPostsDoc rootElement];
		//	NSLog([NSString stringWithFormat:@"-updateList, downloaded %@", [root description],nil]);
		if (![[root name] isEqualTo:@"html"]) {
			// it seems that error pages may come through without the right status code but an error message HTML page
			// avoid reading those as they'll destroy our metadata cache
			NSMutableDictionary *updatedPosts = [NSMutableDictionary dictionary];

			for (NSXMLElement * post in [root children]) {
				NSMutableDictionary * postDictionary = [NSMutableDictionary dictionary];
				NSString * hash = nil;
		
				for (NSXMLNode * attribute in [post attributes]) {
					if ([[attribute name] isEqualToString: DITimeKey]) {
						[postDictionary setObject:[self dateFromXMLDateString:[attribute stringValue]] forKey:[attribute name]];
					} else if ([[attribute name] isEqualToString: DITagKey]) {
						[postDictionary setObject:[[attribute stringValue] componentsSeparatedByString:@" "] forKey:[attribute name]];
					} else if ([[attribute name] isEqualToString: DIDeliciousURLKey]) {
						// use Safari-style key for URL
						[postDictionary setObject:[attribute stringValue] forKey:DIURLKey];
					} else if ([[attribute name] isEqualToString: DIDeliciousNameKey]) {
						// use Safari-style key for Name
						[postDictionary setObject:[attribute stringValue] forKey:DINameKey];
					} else if ([[attribute name] isEqualToString: DIHashKey]) {
						hash = [attribute stringValue];
						[postDictionary setObject:hash forKey: DIHashKey];
					} else {
						[postDictionary setObject:[attribute stringValue] forKey:[attribute name]];
					}
				}
				
				if (hash) {
					[updatedPosts setObject:[NSDictionary dictionaryWithDictionary:postDictionary] forKey:hash];
				}
			}
		[self setBookmarks:updatedPosts];
		}
	}
	[DIBookmarksController enableSuddenTermination];
}



- (void) setBookmarks: (NSDictionary *) newMarks {
	NSMutableDictionary * postsToWrite = [NSMutableDictionary dictionary];
	NSMutableDictionary * postsToDelete = [bookmarks mutableCopy];
	
	for (NSString * hash in newMarks) {
		NSDictionary * newMark = [newMarks objectForKey:hash];
		NSDictionary * oldMark = [bookmarks objectForKey:hash];
		
		if (oldMark) {
			if (![newMark isEqualToDictionary:oldMark]) {
				[postsToWrite setObject:newMark forKey:hash];
			}
			[postsToDelete removeObjectForKey:hash];
		}
		else {
			[postsToWrite setObject:newMark forKey:hash];
		}
	}
	
	NSLog(@"Deleting %lu entries, then adding %lu...", [postsToDelete count], [postsToWrite count]);

	[fileController deleteDictionaries:[postsToDelete allValues]];
	[fileController saveDictionaries:[postsToWrite allValues]];

	[bookmarks removeObjectsForKeys:[postsToDelete allKeys]];
	[bookmarks addEntriesFromDictionary:postsToWrite];
	
	[self saveBookmarksDictionary:bookmarks];
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate new] forKey:DIDefaultsLastUpdateKey];
}



- (NSDictionary *) loadBookmarksDictionary {
	NSString * DIApplicationSupportPath = [DIBookmarksController DIApplicationSupportFolderPath];
	NSString * dictionaryPath = [DIApplicationSupportPath stringByAppendingPathComponent:DIBookmarksPlistFileName];

	NSDictionary * bookmarksList = [NSMutableDictionary dictionaryWithContentsOfFile:dictionaryPath];

	if (!bookmarksList) {
		NSLog(@"Could not find stored bookmarks at %@, starting with an empty list.", dictionaryPath);
		bookmarksList = [NSMutableDictionary dictionary];
	}
	
	return bookmarksList;
}



- (void) saveBookmarksDictionary: (NSDictionary *) list {
	if (list) {
		NSString * DIApplicationSupportPath = [DIBookmarksController DIApplicationSupportFolderPath]; 
		NSFileManager * fM = [[NSFileManager alloc] init];
		
		if (![fM fileExistsAtPath:DIApplicationSupportPath]) {
			NSError * error;
			if (![fM createDirectoryAtPath:DIApplicationSupportPath withIntermediateDirectories:YES attributes:nil error:&error]) {
				NSLog(@"Could not create Application Support subfolder %@: %@", DIApplicationSupportPath, [error localizedDescription]);
			}
		}

		if ([fM fileExistsAtPath:DIApplicationSupportPath]) {
			NSString * plistPath = [DIApplicationSupportPath stringByAppendingPathComponent:DIBookmarksPlistFileName];
			if (![list writeToFile:plistPath atomically:YES]) {
				NSLog(@"Failed to write the bookmarks dictionary at %@.", plistPath);
			}
		}
		else {
			NSLog(@"Could not store bookmarks because delimport’s Application support subfolder %@ does not exist.", DIApplicationSupportPath);
		}
	}
}



- (void) setupTimer: (NSTimer *) timer {
	// get rid of the old timer
	[timer invalidate];
	// set up a new timer, potentially using an updated time interval
	[NSTimer scheduledTimerWithTimeInterval:[self currentUpdateInterval] target:self selector:@selector(updateList:) userInfo:nil repeats:NO];
	// NSLog(@"-setupTimer: Timer set to trigger in %fs", [self currentUpdateInterval]);
}	



- (NSTimeInterval) currentUpdateInterval {
	[[NSUserDefaults standardUserDefaults] synchronize];
	NSNumber * delta = [[NSUserDefaults standardUserDefaults] objectForKey:DIMinutesBetweenChecks];
	NSTimeInterval minutes;
		// Might be better to not go beneath 30min because of throttling.
	if ((delta != nil) && ([throttleTimepoint timeIntervalSinceNow] < -30.0*60.0)) {
		// if a time is stored and throttling is more than 30min ago, use the stored time, otherwise go for a 30min interval
		minutes = [delta doubleValue];
		if (minutes < 1.0) {
			minutes = 1.0;
		}
	}
	else {
		minutes = 30.0;
	}
	
	return (minutes * 60.0);
}



+ (NSString *) serverAddress {
	NSString * address = @"api.del.icio.us";
	
	NSNumber * serviceTypeValue = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:DIDefaultsServiceTypeKey];
	
	if (serviceTypeValue && [serviceTypeValue intValue] == DIServiceTypePinboard) {
		address = @"api.pinboard.in";
	}
	
	return address;
}



+ (NSString *) serviceName {
	NSString * name = @"delicious";
	
	NSNumber * serviceTypeValue = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:DIDefaultsServiceTypeKey];
	
	if (serviceTypeValue && [serviceTypeValue intValue] == DIServiceTypePinboard) {
		name = @"pinboard";
	}
	
	return name;
}


+ (NSString *) versionString {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}


+ (NSString *) userAgentName {
	return [NSString stringWithFormat:@"delimport/%@", [DIBookmarksController versionString]];
}


+ (NSString *) DIApplicationSupportFolderPath {
	return [@"~/Library/Application Support/delimport/" stringByExpandingTildeInPath];
}


- (BOOL) application: (NSApplication *) theApplication openFile: (NSString *) filename {
	return [fileController openFile:filename];
}


/*
 uglyuglyugly but sudden termination seems worth the hassle
*/
+ (void) enableSuddenTermination {
	NSProcessInfo * pI = [NSProcessInfo processInfo];
	SEL enableSuddenTerminationSelector = @selector(enableSuddenTermination);
	if ([pI respondsToSelector:enableSuddenTerminationSelector]) { // we're running X.6 or higher
		[pI performSelector:enableSuddenTerminationSelector];
	}
}

+ (void) disableSuddenTermination {
	NSProcessInfo * pI = [NSProcessInfo processInfo];
	SEL enableSuddenTerminationSelector = @selector(disableSuddenTermination);
	if ([pI respondsToSelector:enableSuddenTerminationSelector]) { // we're running X.6 or higher
		[pI performSelector:enableSuddenTerminationSelector];
	}
}

@end
