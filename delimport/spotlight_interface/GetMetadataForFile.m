#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#include <Foundation/Foundation.h> 

#include "DIFileController.h"
#include "DIBookmarksController.h"

/* -----------------------------------------------------------------------------
   Step 1
   Set the UTI types the importer supports
  
   Modify the CFBundleDocumentTypes entry in Info.plist to contain
   an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
   that your importer can handle
  
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 2 
   Implement the GetMetadataForFile function
  
   Implement the GetMetadataForFile function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update the schema.xml file
  
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attrs, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
	NSDictionary *dictionary;
	NSMutableDictionary *attributes = (__bridge NSMutableDictionary*) attrs;
	NSAutoreleasePool *pool;
	pool = [[NSAutoreleasePool alloc] init];
	BOOL result = NO;
	
	dictionary = [[[NSDictionary alloc] initWithContentsOfFile:(__bridge NSString *)pathToFile] autorelease];
	if (dictionary != nil) {
		NSString * displayName = [dictionary objectForKey: DINameKey];
		if ( displayName == nil ) { // try old-style key if no name is found
			displayName = [dictionary objectForKey: DIDeliciousNameKey];
		}
		[attributes setObject: displayName forKey:(NSString *)kMDItemDisplayName];			

		NSString * URLString = [dictionary objectForKey: DIURLKey ];
		if ( URLString == nil ) { // try old-style key if no URL is found
			URLString = [dictionary objectForKey: DIDeliciousURLKey ];
		}
		[attributes setObject: URLString forKey:@"kMDItemURL"];			
		
		NSString * description = [dictionary objectForKey:@"extended"];
		if ( description != nil) {
			[attributes setObject:description forKey:(NSString *)kMDItemDescription];
		} else {
			[attributes setObject:@"" forKey:(NSString *)kMDItemDescription];
		}
		
		[attributes setObject:[dictionary objectForKey: DITagKey ] forKey:(NSString *)kMDItemKeywords];
		[attributes setObject:[dictionary objectForKey: DITimeKey ] forKey:(NSString *)kMDItemContentCreationDate];
		[attributes setObject:[dictionary objectForKey: DITimeKey ] forKey:(NSString *)kMDItemContentModificationDate];

		result = YES;
	}	
	[pool release];
    return result;
}
