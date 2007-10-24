//
//  AccessControlList.m
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

#import "AccessControlList.h"

#import "Access.h"


@implementation AccessControlList

+ (AccessControlList*)accessControlListNamed:(NSString*)name fromAccess:(Access*)acc forApplications:(NSArray*)applications requiringPassphrase:(BOOL)reqPass {
    return [[[[self class] alloc] initWithName:name fromAccess:acc forApplications:applications requiringPassphrase:reqPass] autorelease];
}

+ (AccessControlList*)accessControlListWithACLRef:(SecACLRef)AC {
    return [[[[self class] alloc] initWithACLRef:AC] autorelease];
}

- (AccessControlList*)initWithName:(NSString*)name fromAccess:(Access*)acc forApplications:(NSArray*)applications requiringPassphrase:(BOOL)reqPass {    
    if (acc && (self = [super init])) {
        CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR prompt;
        CFMutableArrayRef temp;
        NSEnumerator *enumerator = [applications objectEnumerator];
        id current;
        
        temp = CFArrayCreateMutable(NULL, [applications count], NULL);
        
        if (temp) {
            while (current = [enumerator nextObject]) {
                if ([current isKindOfClass:[TrustedApplication class]]) {
                    CFArrayAppendValue(temp, [current trustedApplicationRef]);
                }
            }
            
            prompt.version = CSSM_ACL_KEYCHAIN_PROMPT_CURRENT_VERSION;
            prompt.flags = (reqPass) ? CSSM_ACL_KEYCHAIN_PROMPT_REQUIRE_PASSPHRASE : 0;
            
            error = SecACLCreateFromSimpleContents((SecAccessRef)[acc accessRef], (CFArrayRef)applications, (CFStringRef)name, &prompt, &ACL);
            
            CFRelease(temp);
            
            if (error != 0) {
                [self release];
                self = nil;
            } else {
                CFRetain(acc);
            }
        }
    } else {
        [self release];
        self = nil;
    }
    
    return self;
}

- (AccessControlList*)initWithACLRef:(SecACLRef)AC {
    AccessControlList *existingObject;
    
    if (AC) {
        existingObject = [[self class] instanceWithKey:(id)AC from:@selector(ACLRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            return [existingObject retain];
        } else {
            if (self = [super init]) {
                CFRetain(AC);
                ACL = AC;
            }

            return self;
        }
    } else {
        [self release];
        
        return nil;
    }
}

- (AccessControlList*)init {
    [self release];
    return nil;
}

- (void)setApplications:(NSArray*)applications {
    CFArrayRef appList = NULL;
    CFStringRef desc = NULL;
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR woop;

    error = SecACLCopySimpleContents(ACL, &appList, &desc, &woop);

    if (error == 0) {
        error = SecACLSetSimpleContents(ACL, (CFArrayRef)applications, desc, &woop);
    }
    
    if (appList) {
        CFRelease(appList);
    }
    
    if (desc) {
        CFRelease(desc);
    }
}

- (void)setName:(NSString*)name {
    CFArrayRef appList = NULL;
    CFStringRef desc = NULL;
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR woop;

    error = SecACLCopySimpleContents(ACL, &appList, &desc, &woop);

    if (error == 0) {
        error = SecACLSetSimpleContents(ACL, appList, (CFStringRef)name, &woop);
    }
    
    if (appList) {
        CFRelease(appList);
    }
    
    if (desc) {
        CFRelease(desc);
    }
}

- (void)setRequiresPassphrase:(BOOL)reqPass {
    CFArrayRef appList = NULL;
    CFStringRef desc = NULL;
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR woop;

    error = SecACLCopySimpleContents(ACL, &appList, &desc, &woop);

    if ((error == 0) && (reqPass != (woop.flags & CSSM_ACL_KEYCHAIN_PROMPT_REQUIRE_PASSPHRASE))) {
        if (reqPass) {
            woop.flags |= CSSM_ACL_KEYCHAIN_PROMPT_REQUIRE_PASSPHRASE;
        } else {
            woop.flags &= !CSSM_ACL_KEYCHAIN_PROMPT_REQUIRE_PASSPHRASE;
        }
        
        error = SecACLSetSimpleContents(ACL, appList, desc, &woop);
    }
    
    if (appList) {
        CFRelease(appList);
    }
    
    if (desc) {
        CFRelease(desc);
    }
}

- (NSArray*)applications {
    CFArrayRef appList = NULL;
    CFStringRef desc = NULL;
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR woop;

    error = SecACLCopySimpleContents(ACL, &appList, &desc, &woop);

    if (desc) {
        CFRelease(desc);
    }
    
    if (error == 0) {
        return nil;
    } else {        
        return [(NSArray*)appList autorelease];
    }
}

- (NSString*)name {
    CFArrayRef appList = NULL;
    CFStringRef desc = NULL;
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR woop;

    error = SecACLCopySimpleContents(ACL, &appList, &desc, &woop);

    if (appList) {
        CFRelease(appList);
    }
    
    if (error != 0) {
        return nil;
    } else {        
        return [(NSString*)desc autorelease];
    }
}

- (BOOL)requiresPassphrase {
    CFArrayRef appList = NULL;
    CFStringRef desc = NULL;
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR woop;

    error = SecACLCopySimpleContents(ACL, &appList, &desc, &woop);

    if (appList) {
        CFRelease(appList);
    }
    
    if (desc) {
        CFRelease(desc);
    }
    
    if (error != 0) {
        return NO;
    } else {
        return (woop.flags & CSSM_ACL_KEYCHAIN_PROMPT_REQUIRE_PASSPHRASE);
    }
}

- (void)setAuthorizesAction:(CSSM_ACL_AUTHORIZATION_TAG)action to:(BOOL)value {
    UInt32 i, count, newCount = 0;
    CSSM_ACL_AUTHORIZATION_TAG *current = NULL, *changed = NULL;
    BOOL alreadySet = NO;

    error = SecACLGetAuthorizations(ACL, current, &count);

    if (error == 0) {
        for (i = 0; i < count; ++i) {
            if (current[i] == action) {
                alreadySet = YES;
                break;
            }
        }
        
        if (value && !alreadySet) {
            changed = malloc(sizeof(CSSM_ACL_AUTHORIZATION_TAG) * (count + 1));

            for (i = 0; i < count; ++i) {
                changed[i] = current[i];
            }

            changed[++i] = action;

            newCount = count + 1;
        } else if (!value && alreadySet) {
            changed = malloc(sizeof(CSSM_ACL_AUTHORIZATION_TAG) * (count - 1));

            for (i = 0; i < count; ++i) {
                if (current[i] != action) {
                    changed[newCount++] = current[i];
                }
            }
        } else {
            changed = current;
            newCount = count;
        }

        error = SecACLSetAuthorizations(ACL, changed, newCount);
    }
}

- (void)setAuthorizesEverything:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_ANY to:value];
}

- (void)setAuthorizesLogin:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_LOGIN to:value];
}

- (void)setAuthorizesGeneratingKeys:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_GENKEY to:value];
}

- (void)setAuthorizesDeletion:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_DELETE to:value];
}

- (void)setAuthorizesExportingWrapped:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_EXPORT_WRAPPED to:value];
}

- (void)setAuthorizesExportingClear:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_EXPORT_CLEAR to:value];
}

- (void)setAuthorizesImportingWrapped:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_IMPORT_WRAPPED to:value];
}

- (void)setAuthorizesImportingClear:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_IMPORT_CLEAR to:value];
}

- (void)setAuthorizesSigning:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_SIGN to:value];
}

- (void)setAuthorizesEncrypting:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_ENCRYPT to:value];
}

- (void)setAuthorizesDecrypting:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_DECRYPT to:value];
}

- (void)setAuthorizesMACGeneration:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_MAC to:value];
}

- (void)setAuthorizesDerivingKeys:(BOOL)value {
    [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_DERIVE to:value];
}

- (BOOL)authorizesAction:(CSSM_ACL_AUTHORIZATION_TAG)action {
    UInt32 i, count;
    CSSM_ACL_AUTHORIZATION_TAG *results = NULL;

    error = SecACLGetAuthorizations(ACL, results, &count);

    if (error == 0) {
        for (i = 0; i < count; ++i) {
            if (results[i] == action) {
                return YES;
            }
        }
    }

    return NO;
}

- (BOOL)authorizesEverything {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_ANY];
}

- (BOOL)authorizesLogin {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_LOGIN];
}

- (BOOL)authorizesGeneratingKeys {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_GENKEY];
}

- (BOOL)authorizesDeletion {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_DELETE];
}

- (BOOL)authorizesExportingWrapped {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_EXPORT_WRAPPED];
}

- (BOOL)authorizesExportingClear {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_EXPORT_CLEAR];
}

- (BOOL)authorizesImportingWrapped {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_IMPORT_WRAPPED];
}

- (BOOL)authorizesImportingClear {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_IMPORT_CLEAR];
}

- (BOOL)authorizesSigning {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_SIGN];
}

- (BOOL)authorizesEncrypting {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_ENCRYPT];
}

- (BOOL)authorizesDecrypting {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_DECRYPT];
}

- (BOOL)authorizesMACGeneration {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_MAC];
}

- (BOOL)authorizesDerivingKeys {
    return [self authorizesAction:CSSM_ACL_AUTHORIZATION_DERIVE];
}

- (void)deleteAccessControlList {
    error = SecACLRemove(ACL);
}

- (int)lastError {
    return error;
}

- (SecACLRef)ACLRef {
    return ACL;
}

- (void)dealloc {
    if (ACL) {
        CFRelease(ACL);
    }
    
    [super dealloc];
}

@end
