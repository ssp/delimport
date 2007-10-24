//
//  Access.m
//  Keychain
//
//  Created by Wade Tregaskis on Fri Jan 24 2003.
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "Access.h"


@implementation Access

+ (Access*)accessWithName:(NSString*)name {
    return [[[[self class] alloc] initWithName:name applications:nil] autorelease];
}

+ (Access*)accessWithName:(NSString*)name applications:(NSArray*)apps {
    return [[[[self class] alloc] initWithName:name applications:apps] autorelease];
}

+ (Access*)accessWithAccessRef:(SecAccessRef)acc {
    return [[[[self class] alloc] initWithAccessRef:acc] autorelease];
}

- (Access*)initWithName:(NSString*)name applications:(NSArray*)apps {
    if (self = [super init]) {
        CFMutableArrayRef convertedArray = NULL;
        CFTypeID trustedApplicationType = SecTrustedApplicationGetTypeID();
        
        if (apps) {
            convertedArray = CFArrayCreateMutable(NULL, 0, NULL);
            
            if (convertedArray) {
                NSEnumerator *enumerator = [apps objectEnumerator];
                id current;
                
                while (current = [enumerator nextObject]) {
                    if ([current isKindOfClass:[TrustedApplication class]]) {
                        CFArrayAppendValue(convertedArray, [current trustedApplicationRef]);
                    } else if (CFGetTypeID(current) == trustedApplicationType) {
                        CFArrayAppendValue(convertedArray, current);
                    }
                }
            } else {
                return nil;
            }
        }
        
        error = SecAccessCreate((CFStringRef)name, convertedArray, &access); // Don't know whether name is permitted to be NULL, so make no assumptions
        
        if (convertedArray) {
            CFRelease(convertedArray);
        }
        
        return self;
    } else {
        [self release];
        
        return nil;
    }
}

- (Access*)initWithAccessRef:(SecAccessRef)acc {
    if (acc && (self = [super init])) {
        Access *existingObject;
        
        existingObject = [[self class] instanceWithKey:(id)acc from:@selector(accessRef) simpleKey:NO];
        
        if (existingObject) {
            [self release];
            
            return [existingObject retain];
        } else {
            CFRetain(acc);
            access = acc;
            
            return self;
        }
    } else {
        [self release];

        return nil;
    }
}

- (Access*)init {
    return [self initWithName:@"Unnamed" applications:NULL];
}

- (NSArray*)accessControlLists {
    CFArrayRef results;
    NSMutableArray *finalResults = nil;
    NSEnumerator *enumerator;
    SecACLRef current;
    
    error = SecAccessCopyACLList(access, &results);

    if ((error == 0) && results) {
        enumerator = [(NSArray*)results objectEnumerator];
        finalResults = [NSMutableArray arrayWithCapacity:CFArrayGetCount(results)];
        
        while (current = (SecACLRef)[enumerator nextObject]) {
            [finalResults addObject:[AccessControlList accessControlListWithACLRef:current]];
        }
        
        CFRelease(results);
    }
    
    return finalResults;
}

- (NSArray*)accessControlListsForAction:(CSSM_ACL_AUTHORIZATION_TAG)action {
    CFArrayRef results;
    NSMutableArray *finalResults = nil;
    NSEnumerator *enumerator;
    SecACLRef current;
    
    error = SecAccessCopySelectedACLList(access, action, &results);
    
    if ((error == 0) && results) {
        enumerator = [(NSArray*)results objectEnumerator];
        finalResults = [NSMutableArray arrayWithCapacity:CFArrayGetCount(results)];
        
        while (current = (SecACLRef)[enumerator nextObject]) {
            [finalResults addObject:[AccessControlList accessControlListWithACLRef:current]];
        }
        
        CFRelease(results);
    }
    
    return finalResults;
}

- (NSArray*)accessControlListsForEverything {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_ANY];
}

- (NSArray*)accessControlListsForLogin {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_LOGIN];
}

- (NSArray*)accessControlListsForGeneratingKeys {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_GENKEY];
}

- (NSArray*)accessControlListsForDeletion {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_DELETE];
}

- (NSArray*)accessControlListsForExportingWrapped {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_EXPORT_WRAPPED];
}

- (NSArray*)accessControlListsForExportingClear {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_EXPORT_CLEAR];
}

- (NSArray*)accessControlListsForImportingWrapped {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_IMPORT_WRAPPED];
}

- (NSArray*)accessControlListsForImportingClear {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_IMPORT_CLEAR];
}

- (NSArray*)accessControlListsForSigning {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_SIGN];
}

- (NSArray*)accessControlListsForEncrypting {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_ENCRYPT];
}

- (NSArray*)accessControlListsForDecrypting {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_DECRYPT];
}

- (NSArray*)accessControlListsForMACGeneration {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_MAC];
}

- (NSArray*)accessControlListsForDerivingKeys {
    return [self accessControlListsForAction:CSSM_ACL_AUTHORIZATION_DERIVE];
}

- (int)lastError {
    return error;
}

- (SecAccessRef)accessRef {
    return access;
}

- (void)dealloc {
    if (access) {
        CFRelease(access);
    }
    
    [super dealloc];
}

@end
