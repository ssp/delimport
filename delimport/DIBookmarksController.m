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
		while (itemDict=[enumer nextObject]) {
			if ([[itemDict objectForKey:@"Path"] isEqualToString:kDTMyAppAppPath]) {
				foundMyAppItem = YES;
				break;
			}
			myAppItemIndex++;
		}
	}
	if (!foundMyAppItem) {
		NSAlert *alert = [NSAlert alertWithMessageText:@"Add delimport to Login Items?" defaultButton:@"Add" alternateButton:@"Don't Add" otherButton:nil informativeTextWithFormat:@"Delimport will start every time your computer boots to keep your bookmarks in sync."];
		[[alert window] makeKeyAndOrderFront:self];
		[[alert window] center];
		if ([alert runModal] == NSAlertDefaultReturn) {
			// OK, Create item and add it - should work even if no pref existed
			NSDictionary	*myAppItem;
			FSRef			myFSRef;
			OSStatus		fsResult = FSPathMakeRef([kDTMyAppAppPath fileSystemRepresentation], &myFSRef,NULL);
			
			if (loginItems) {
				loginItems = [[loginItems autorelease] mutableCopy]; // mutable copy we can work on, autorelease the original
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
	}
	
	if (changed) {
		// Set new value in pref
		CFPreferencesSetValue((CFStringRef) 
							  @"AutoLaunchedApplicationDictionary", loginItems, (CFStringRef) 
							  @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost); 
		CFPreferencesSynchronize((CFStringRef) @"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost); 
	}
	[loginItems release]; 
}

- (KeychainItem *)getKeychainUserAndPass
{
//	Keychain *keychain = [Keychain defaultKeychain];
//	KeychainSearch *search = [[KeychainSearch alloc] initWithKeychain:keychain];
	KeychainSearch * search = [[KeychainSearch alloc] init];
	
	[search setServer:@"del.icio.us"];

	NSArray *results = [search internetSearchResults];
	[search release];
	if ([results count] <= 0) {
		return nil;
	}
	KeychainItem *item = [results objectAtIndex:0];
	[username release];
	username = [[item account] retain];
	[password release];
	password = [[item dataAsString] retain];
	return item;
}

- init
{
	self = [super init];
	if (self != nil) {
		username = nil;
		password = nil;
		NSArray *bookmarkArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"DeliciousBookmarks"];
		if (!bookmarkArray) {
			bookmarks = [[NSSet alloc] init];
		} else {
			bookmarks = [[NSSet alloc] initWithArray:bookmarkArray];
		}
		lastUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:@"DeliciousLastUpdate"];
		if (!lastUpdate) {
			lastUpdate = [[NSDate distantPast] retain];
		} else if (![lastUpdate isKindOfClass:[NSDate class]]) {
			lastUpdate = [[NSUnarchiver unarchiveObjectWithData:(NSData *)lastUpdate] retain];
		}
		fileController = [[DIFileController alloc] init];
		loginController = [[DILoginController alloc] init];
	}
	return self;
}

- (NSXMLDocument *)deliciousAPIResponseToRequest:(NSString *)request
{
	NSString *apiPath = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/", username, password, nil];
	NSError *error;
	NSURL *requestURL = [NSURL URLWithString:[apiPath stringByAppendingString:request]];
	NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:requestURL];
	[URLRequest setValue: @"delimport/0.3" forHTTPHeaderField: @"User-Agent"];

	NSHTTPURLResponse *response;
	NSData * xmlData = [NSURLConnection sendSynchronousRequest:URLRequest returningResponse:&response error:&error];
	if (!xmlData) {
		if ([response statusCode] == 401) {
			[self logIn];
		}
		else {
			NSLog([NSString stringWithFormat:@"API Response Problem: %@", [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]], nil]);
		}
		return nil;
	}
	NSXMLDocument *document = [[[NSXMLDocument alloc] initWithData:xmlData options:NSXMLDocumentTidyXML error:&error] autorelease];
	if (document == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[[alert window] makeKeyAndOrderFront:self];
		[[alert window] center];
		[alert runModal];
		return nil;
	}
	return document;
}



- (void)logIn
{
	[username release];
	[password release];
	[loginController getUsername:&username password:&password];
	
	[username retain];
	[password retain];

	Keychain *keychain = [Keychain defaultKeychain];

	[keychain addInternetPassword:password onServer:@"del.icio.us" forAccount:username port:80 path:@"" inSecurityDomain:@"" protocol:kSecProtocolTypeHTTP auth:kSecAuthenticationTypeHTTPDigest replaceExisting:YES];

}

- (NSDate *)dateFromXMLDateString:(NSString *)string
{
	NSMutableString *dateString = [[string mutableCopy] autorelease];
	[dateString replaceOccurrencesOfString:@"T" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [dateString length])];
	[dateString replaceOccurrencesOfString:@"Z" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [dateString length])];
	[dateString appendString:@"+0000"];
	return [NSDate dateWithString:dateString];
}

- (NSDate *)remoteLastUpdate
{
	NSXMLDocument *updateDoc = [self deliciousAPIResponseToRequest:@"posts/update"];
	if (!updateDoc) {
		return [NSDate distantFuture];
	}
	NSXMLElement *updateElement = [updateDoc rootElement];
	return [self dateFromXMLDateString:[[updateElement attributeForName:@"time"] stringValue]];
}

- (void)updateList:(NSTimer *)timer
{
	if (!username) {
		[self logIn];
	}
	NSDate * remoteUpdateTime = [self remoteLastUpdate];
	NSTimeInterval interval = [lastUpdate timeIntervalSinceDate:remoteUpdateTime];
	if (interval >= 0) {
		return;
	}
	
	NSXMLDocument *allPostsDoc = [self deliciousAPIResponseToRequest:@"posts/all"];
	if (allPostsDoc == nil) {
		return;
	}
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSXMLElement *root = [allPostsDoc rootElement];
	if (![[root name] isEqualTo:@"html"]) {
		// it seems that error pages may come through without the right status code but an error message HTML page
		// avoid reading those as they'll destroy our metadata cache
		NSMutableSet *updatedPosts = [NSMutableSet set];
		NSEnumerator *postEnumerator = [[root children] objectEnumerator], *attributeEnumerator;
		NSXMLElement *post;
		NSXMLNode *attribute;
		NSMutableDictionary *postDictionary;
		while (post = [postEnumerator nextObject]) {
			postDictionary = [[NSMutableDictionary alloc] init];
			attributeEnumerator = [[post attributes] objectEnumerator];
			while (attribute = [attributeEnumerator nextObject]) {
			if ([[attribute name] isEqualToString:@"time"]) {
				[postDictionary setObject:[self dateFromXMLDateString:[attribute stringValue]] forKey:[attribute name]];
			} else if ([[attribute name] isEqualToString:@"tag"]) {
				[postDictionary setObject:[[attribute stringValue] componentsSeparatedByString:@" "] forKey:[attribute name]];
			} else {
				[postDictionary setObject:[attribute stringValue] forKey:[attribute name]];
			}
			}
			
			[updatedPosts addObject:[NSDictionary dictionaryWithDictionary:postDictionary]];
			[postDictionary release];
		}
	[self setBookmarks:updatedPosts];
	}
	[pool release];
}

- (void)setBookmarks:(NSSet *)newMarks
{
	NSMutableSet *postsToAdd = [[newMarks mutableCopy] autorelease];
	NSMutableSet *postsToDelete = [[bookmarks mutableCopy] autorelease];
	[postsToAdd minusSet:bookmarks];
	[postsToDelete minusSet:newMarks];
	NSLog(@"Deleting %d entries, then adding %d...", [postsToDelete count], [postsToAdd count]);
	[fileController deleteDictionaries:postsToDelete];
	[fileController saveDictionaries:postsToAdd];

	[bookmarks release];
	bookmarks = [[NSSet alloc] initWithSet:newMarks];
	[lastUpdate release];
	lastUpdate = [NSDate new];
	NSData *archivedDate = [NSArchiver archivedDataWithRootObject:lastUpdate];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[bookmarks allObjects] forKey:@"DeliciousBookmarks"];
	[defaults setObject:archivedDate forKey:@"DeliciousLastUpdate"];
	[defaults synchronize];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[self addToLoginItems];
	[self getKeychainUserAndPass];
	[self updateList:nil];
	updateTimer = [NSTimer scheduledTimerWithTimeInterval:30*60 target:self selector:@selector(updateList:) userInfo:nil repeats:YES];
}

- (void)dealloc
{
	[username release];
	[password release];
	[bookmarks release];
	[lastUpdate release];
	[fileController release];
	[loginController release];
	
	[updateTimer invalidate];
	[super dealloc];
}
- (void)applicationWillTerminate:(NSNotification *)notification
{
}
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	return [fileController openFile:filename];
}

@end