//
//  AccessControlList.m
//  Keychain
//
//  Created by Wade Tregaskis on Fri Jan 24 2003.
//
//  Copyright (c) 2003 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Keychain/AccessControlList.h>

#import <Keychain/Access.h>
#import <Keychain/Logging.h>
#import <Keychain/SecurityUtils.h>

#import <Keychain/TrustedApplication.h>

#import <Security/Security.h>

// For pre-10.5 SDKs:
#ifndef NSINTEGER_DEFINED
typedef int NSInteger;
typedef unsigned int NSUInteger;
#define NSINTEGER_DEFINED
#endif

@interface AccessControlList (Internal)

+ (TrustedApplication*)_trustedApplicationFromObject:(id)object;
+ (NSArray*)_arrayOfSecTrustedApplicationRefsFromArray:(NSArray*)trustedApplications;
+ (NSArray*)_arrayOfTrustedApplicationsFromArray:(NSArray*)trustedApplications;

@end


@implementation AccessControlList

+ (AccessControlList*)accessControlListNamed:(NSString*)name fromAccess:(Access*)acc forApplications:(NSArray*)applications requiringPassphrase:(BOOL)reqPass {
    return [[[[self class] alloc] initWithName:name fromAccess:acc forApplications:applications requiringPassphrase:reqPass] autorelease];
}

+ (AccessControlList*)accessControlListWithACLRef:(SecACLRef)AC {
    return [[[[self class] alloc] initWithACLRef:AC] autorelease];
}

- (AccessControlList*)initWithName:(NSString*)name fromAccess:(Access*)acc forApplications:(NSArray*)applications requiringPassphrase:(BOOL)reqPass {    
    if (nil != acc) {
		if (self = [super init]) {
			NSArray *applicationsAsSecRefs = nil;
			
			if (nil != applications) {
				applicationsAsSecRefs = [[self class] _arrayOfSecTrustedApplicationRefsFromArray:applications];
				
				if (nil == applicationsAsSecRefs) {
					PSYSLOG(LOG_ERR, @"The given array of applications contains one or more objects which are not and cannot be converted to SecTrustedApplicationRefs.  Its contents are: %@\n", applications);
					[self release];
					self = nil;
				}
			}
			
			if (nil != self) {
				CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR prompt;
				SecAccessRef accessRef = [acc accessRef];
				
				prompt.version = CSSM_ACL_KEYCHAIN_PROMPT_CURRENT_VERSION;
				prompt.flags = (reqPass) ? CSSM_ACL_KEYCHAIN_PROMPT_REQUIRE_PASSPHRASE : 0;
				
				_error = SecACLCreateFromSimpleContents(accessRef, (CFArrayRef)applicationsAsSecRefs, (CFStringRef)name, &prompt, &_ACL);
				
				if (noErr == _error) {
					CFRetain(acc);
				} else {
					PSYSLOGND(LOG_ERR, @"Unable to create SecACLRef for new AccessControlList, error %@.\n", OSStatusAsString(_error));
					PDEBUG(@"SecACLCreateFromSimpleContents(%p, %p, \"%@\", %p [version = %"PRIu16", flags = %"PRIu16"], %p) returned error %@.\n", accessRef, applicationsAsSecRefs, name, &prompt, prompt.version, prompt.flags, &_ACL);
					
					[self release];
					self = nil;
				}
			}
		}
	} else {
		PSYSLOG(LOG_ERR, @"Cannot initialise an AccessControlList without an Access.\n");
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
                _ACL = AC;
            }

            return self;
        }
    } else {
		PSYSLOG(LOG_ERR, @"Missing 'AC' parameter.\n");
		
        [self release];
        
        return nil;
    }
}

- (AccessControlList*)init {
	PSYSLOG(LOG_ERR, @"'init' is not a valid initialiser for AccessControlList.\n");
	
    [self release];
    return nil;
}

+ (TrustedApplication*)_trustedApplicationFromObject:(id)object {
	if ([object isKindOfClass:[TrustedApplication class]]) {
		return (TrustedApplication*)object;
	} else if ([object isKindOfClass:[NSString class]]) {
		return [TrustedApplication trustedApplicationWithPath:object];
	} else if (CFGetTypeID(object) == SecTrustedApplicationGetTypeID()) {
		return [TrustedApplication trustedApplicationWithTrustedApplicationRef:(SecTrustedApplicationRef)object];
	} else {
		PDEBUG(@"Don't know how to convert object of class %@ (0x%x) to TrustedApplication.\n", [object className], object);
		return nil;
	}
}

+ (NSArray*)_arrayOfSecTrustedApplicationRefsFromArray:(NSArray*)trustedApplications {
	NSMutableArray *result = nil;
	
	if (nil != trustedApplications) {
		NSEnumerator *enumerator = [trustedApplications objectEnumerator];
		id current;
		Class TrustedApplicationClass = [TrustedApplication class];
		Class NSStringClass = [NSString class];
		CFTypeID SecTrustedApplicationRefTypeID = SecTrustedApplicationGetTypeID();
		
		result = [NSMutableArray arrayWithCapacity:[trustedApplications count]];
		
		while (current = [enumerator nextObject]) {
			if ([current isKindOfClass:TrustedApplicationClass]) {
				[result addObject:(id)[(TrustedApplication*)current trustedApplicationRef]];
			} else if ([current isKindOfClass:NSStringClass]) {
				[result addObject:(id)[[TrustedApplication trustedApplicationWithPath:current] trustedApplicationRef]];
			} else if (CFGetTypeID(current) == SecTrustedApplicationRefTypeID) {
				[result addObject:current];
			} else {
				PDEBUG(@"Found object \"%@\" of class %@ in the given array - no idea what to do with it.\n", current, [current className]);
				result = nil;
				break;
			}
		}
	} else {
		PDEBUG(@"Provided array, 'trustedApplications', is nil.\n");
	}
	
	return result;
}

+ (NSArray*)_arrayOfTrustedApplicationsFromArray:(NSArray*)trustedApplications {
	NSMutableArray *result = nil;
	
	if (nil != trustedApplications) {
		NSEnumerator *enumerator = [trustedApplications objectEnumerator];
		id current;
		Class TrustedApplicationClass = [TrustedApplication class];
		Class NSStringClass = [NSString class];
		CFTypeID SecTrustedApplicationRefTypeID = SecTrustedApplicationGetTypeID();
		
		result = [NSMutableArray arrayWithCapacity:[trustedApplications count]];
		
		while (current = [enumerator nextObject]) {
			if ([current isKindOfClass:TrustedApplicationClass]) {
				[result addObject:current];
			} else if ([current isKindOfClass:NSStringClass]) {
				[result addObject:[TrustedApplication trustedApplicationWithPath:current]];
			} else if (CFGetTypeID(current) == SecTrustedApplicationRefTypeID) {
				[result addObject:[TrustedApplication trustedApplicationWithTrustedApplicationRef:(SecTrustedApplicationRef)current]];
			} else {
				PDEBUG(@"Found object \"%@\" of class %@ in the given array - no idea what to do with it.\n", current, [current className]);
				result = nil;
				break;
			}
		}
	} else {
		PDEBUG(@"Provided array, 'trustedApplications', is nil.\n");
	}
	
	return result;
}

- (BOOL)setApplications:(NSArray*)applications {
	NSArray *applicationsAsSecRefs = nil;
	
	if (nil != applications) {
		applicationsAsSecRefs = [[self class] _arrayOfSecTrustedApplicationRefsFromArray:applications];
	
		if (nil == applicationsAsSecRefs) {
			PSYSLOG(LOG_ERR, @"The given array of applications is invalid; it contains objects which cannot be converted to SecTrustedApplicationRefs.  It contains: %@\n", applications);
			_error = EINVAL;
			return NO;
		}
	}
	
	CFArrayRef appList = NULL;
	CFStringRef desc = NULL;
	CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR woop;

	// Unfortunately SetACLSetSimpleContents() treats NULL arguments as meaning 'reset' those attributes, so - given we want to preserve the other attributes - we need to get the existing values and carry them through.
	
	_error = SecACLCopySimpleContents(_ACL, &appList, &desc, &woop);

	if (noErr == _error) {
		_error = SecACLSetSimpleContents(_ACL, (CFArrayRef)applicationsAsSecRefs, desc, &woop);
		
		if (noErr != _error) {
			PSYSLOGND(LOG_ERR, @"Unable to modify applications list of ACL, error %@.\n", OSStatusAsString(_error));
			PDEBUG(@"SecACLSetSimpleContents(%p, %p, %p, %p) returned error %@.\n", _ACL, applicationsAsSecRefs, desc, &woop, OSStatusAsString(_error));
		}
	} else {
		PSYSLOGND(LOG_ERR, @"Unable to retrieve existing contents of ACL (in order to modify the applications list), error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecACLCopySimpleContents(%p, %p, %p, %p) returned error %@.\n", _ACL, &appList, &desc, &woop, OSStatusAsString(_error));
	}
	
	if (appList) {
		CFRelease(appList);
	}
	
	if (desc) {
		CFRelease(desc);
	}
	
	return (noErr == _error);
}

- (BOOL)addApplication:(id)application {
	if (nil != application) {
		NSArray *currentApplications = [self applications];
		OSStatus err = [self lastError];
		
		if (noErr == err) {
			if (nil == currentApplications) {
				// We already trust everything; just return YES.
				return YES;
			} else {
				TrustedApplication *newApp = [[self class] _trustedApplicationFromObject:application];
				
				if (nil != newApp) {
					if ([currentApplications containsObject:newApp]) {
						return YES;
					} else {
						return [self setApplications:[currentApplications arrayByAddingObject:newApp]];
					}
				} else {
					_error = errSecInvalidItemRef;
					return NO;
				}
			}
		} else {
			return NO;
		}
	} else {
		PDEBUG(@"'application' is nil.\n");
		_error = errSecInvalidItemRef;
		return NO;
	}
}

- (BOOL)_removeApplication:(id)application explicitOnly:(BOOL)explicitOnly {
	if (nil != application) {
		NSArray *currentApplications = [self applications];
		OSStatus err = [self lastError];
		
		if (noErr == err) {
			if (nil == currentApplications) {
				// We trust all applications implicitly...
				
				if (explicitOnly) {
					// ...and this method is only expected to remove *explicit* access, not the implicit access the missing list implies.  So, we do nothing and pretend we were successful.
					return YES;
				} else {
					// ...but we're being told to remove even implicit access such as this.  So, we have to disallow access by *all* applications... brutal, but hey, we document this behaviour, so I can only pray whoever's calling us knows what they're doing.
					return [self setApplications:[NSArray array]];
				}
			} else {
				TrustedApplication *targetApp = [[self class] _trustedApplicationFromObject:application];
				
				if (nil != targetApp) {
					if ([currentApplications containsObject:targetApp]) {
						NSMutableArray *newApplications = [currentApplications mutableCopy];
						
						[newApplications removeObject:targetApp];
						
						return [self setApplications:[newApplications autorelease]];
					} else {
						// The given app's not in our application list anyway.
						return YES;
					}
				} else {
					_error = errSecInvalidItemRef;
					return NO;
				}
			}
		} else {
			return NO;
		}
	} else {
		PDEBUG(@"'application' is nil.\n");
		_error = errSecInvalidItemRef;
		return NO;
	}
}

- (BOOL)removeApplication:(id)application {
	return [self _removeApplication:application explicitOnly:NO];
}

- (BOOL)removeApplicationIfPresent:(id)application {
	return [self _removeApplication:application explicitOnly:YES];
}

- (BOOL)setName:(NSString*)name {
    CFArrayRef appList = NULL;
    CFStringRef desc = NULL;
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR woop;

    _error = SecACLCopySimpleContents(_ACL, &appList, &desc, &woop);

    if (noErr == _error) {
        _error = SecACLSetSimpleContents(_ACL, appList, (CFStringRef)name, &woop);
		
		if (noErr != _error) {
			PSYSLOGND(LOG_ERR, @"Unable to modify name of ACL, error %@.\n", OSStatusAsString(_error));
			PDEBUG(@"SecACLSetSimpleContents(%p, %p, %p [\"%@\"], %p) returned error %@.\n", _ACL, appList, name, name, &woop, OSStatusAsString(_error));
		}
    } else {
		PSYSLOGND(LOG_ERR, @"Unable to retrieve existing contents of ACL (in order to modify the name), error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecACLCopySimpleContents(%p, %p, %p, %p) returned error %@.\n", _ACL, &appList, &desc, &woop, OSStatusAsString(_error));
	}
    
    if (appList) {
        CFRelease(appList);
    }
    
    if (desc) {
        CFRelease(desc);
    }
	
	return (noErr == _error);
}

- (BOOL)setRequiresPassphrase:(BOOL)reqPass {
    CFArrayRef appList = NULL;
    CFStringRef desc = NULL;
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR woop;

    _error = SecACLCopySimpleContents(_ACL, &appList, &desc, &woop);

    if (noErr == _error) {
		if (reqPass != (woop.flags & CSSM_ACL_KEYCHAIN_PROMPT_REQUIRE_PASSPHRASE)) {
			if (reqPass) {
				woop.flags |= CSSM_ACL_KEYCHAIN_PROMPT_REQUIRE_PASSPHRASE;
			} else {
				woop.flags &= !CSSM_ACL_KEYCHAIN_PROMPT_REQUIRE_PASSPHRASE;
			}
			
			_error = SecACLSetSimpleContents(_ACL, appList, desc, &woop);
			
			if (noErr != _error) {
				PSYSLOGND(LOG_ERR, @"Unable to modify requires-passphrase flag of ACL, error %@.\n", OSStatusAsString(_error));
				PDEBUG(@"SecACLSetSimpleContents(%p, %p, %p, %p) returned error %@.\n", _ACL, appList, desc, &woop, OSStatusAsString(_error));
			}
		}
    } else {
		PSYSLOGND(LOG_ERR, @"Unable to retrieve existing contents of ACL (in order to modify the requires-passphrase flag), error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecACLCopySimpleContents(%p, %p, %p, %p) returned error %@.\n", _ACL, &appList, &desc, &woop, OSStatusAsString(_error));
	}
    
    if (appList) {
        CFRelease(appList);
    }
    
    if (desc) {
        CFRelease(desc);
    }
	
	return (noErr == _error);
}

- (NSArray*)applications {
    CFArrayRef appList = NULL;
    CFStringRef desc = NULL;
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR woop;
	NSArray *result = nil;
	
	// Unfortunately we must provide non-NULL arguments for all parameters; required by the Security API.
    _error = SecACLCopySimpleContents(_ACL, &appList, &desc, &woop);
    
    if (noErr == _error) {     
		result = ((NULL != appList) ? [[self class] _arrayOfTrustedApplicationsFromArray:(NSArray*)appList] : nil);
	} else {
		PSYSLOGND(LOG_ERR, @"Unable to retrieve applications list of ACL, error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecACLCopySimpleContents(%p, %p, %p, %p) returned error %@.\n", _ACL, &appList, &desc, &woop, OSStatusAsString(_error));
	}
	
	if (appList) {
		CFRelease(appList);
	}
	
	if (desc) {
        CFRelease(desc);
    }
	
	return result;
}

- (BOOL)allowsAnyApplication {
	return ((nil != [self applications]) && (noErr == [self lastError]));
}

- (NSString*)name {
    CFArrayRef appList = NULL;
    CFStringRef desc = NULL;
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR woop;
	NSString *result = nil;
	
	// Unfortunately we must provide non-NULL arguments for all parameters; required by the Security API.
    _error = SecACLCopySimpleContents(_ACL, &appList, &desc, &woop);

	if (noErr == _error) {
		result = [(NSString*)desc autorelease];
	} else {
		PSYSLOGND(LOG_ERR, @"Unable to retrieve name of ACL, error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecACLCopySimpleContents(%p, %p, %p, %p) returned error %@.\n", _ACL, &appList, &desc, &woop, OSStatusAsString(_error));
	}
	
    if (appList) {
        CFRelease(appList);
    }
    
    return result;
}

- (BOOL)requiresPassphrase {
    CFArrayRef appList = NULL;
    CFStringRef desc = NULL;
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR woop;
	BOOL result = NO;
	
	// Unfortunately we must provide non-NULL arguments for all parameters; required by the Security API.
    _error = SecACLCopySimpleContents(_ACL, &appList, &desc, &woop);

	if (noErr == _error) {
		result = (0 != (woop.flags & CSSM_ACL_KEYCHAIN_PROMPT_REQUIRE_PASSPHRASE));
	} else {
		PSYSLOGND(LOG_ERR, @"Unable to retrieve requires-passphrase flag of ACL, error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecACLCopySimpleContents(%p, %p, %p, %p) returned error %@.\n", _ACL, &appList, &desc, &woop, OSStatusAsString(_error));
	}
	
    if (appList) {
        CFRelease(appList);
    }
    
    if (desc) {
        CFRelease(desc);
    }
    
    return result;
}

- (BOOL)setAuthorizations:(NSArray*)authorizations {
	NSUInteger authorizationsCount = [authorizations count];
	CSSM_ACL_AUTHORIZATION_TAG *auths = ((0 < authorizationsCount) ? malloc(sizeof(CSSM_ACL_AUTHORIZATION_TAG) * authorizationsCount) : NULL);
	uint32_t i;
	
	for (i = 0; i < authorizationsCount; ++i) {
		auths[i] = [[authorizations objectAtIndex:i] intValue];
	}
	
	_error = SecACLSetAuthorizations(_ACL, auths, (uint32_t)authorizationsCount);
	
	if (NULL != auths) {
		free(auths);
	}
	
	if (noErr != _error) {
		PSYSLOGND(LOG_ERR, @"Unable to set new authorisations, error %@.", OSStatusAsString(_error));
		PDEBUG(@"SecACLSetAuthorizations(%p, %p, %"PRIu32") returned error %@.", _ACL, auths, authorizationsCount, OSStatusAsString(_error));
	}
	
	return (noErr == _error);
}

- (BOOL)setAuthorizesAction:(CSSM_ACL_AUTHORIZATION_TAG)action to:(BOOL)value {
    uint32 i, capacity = 10, count, newCount = 0;
    CSSM_ACL_AUTHORIZATION_TAG *currentAuths = NULL, *newAuths = NULL;
    BOOL alreadySet = NO;

	do {
		capacity *= 2;
		count = capacity;
		currentAuths = reallocf(currentAuths, sizeof(CSSM_ACL_AUTHORIZATION_TAG) * count);
		
		_error = SecACLGetAuthorizations(_ACL, currentAuths, &count);
	} while (errSecBufferTooSmall == _error);

    if (noErr == _error) {
        for (i = 0; i < count; ++i) {
            if (currentAuths[i] == action) {
                alreadySet = YES;
                break;
            }
        }
        
        if (value && !alreadySet) {
            newAuths = malloc(sizeof(CSSM_ACL_AUTHORIZATION_TAG) * (count + 1));

			memcpy(newAuths, currentAuths, sizeof(CSSM_ACL_AUTHORIZATION_TAG) * count);

            newAuths[count] = action;

            newCount = count + 1;
        } else if (!value && alreadySet) {
            newAuths = malloc(sizeof(CSSM_ACL_AUTHORIZATION_TAG) * (count - 1));

            for (i = 0; i < count; ++i) {
                if (currentAuths[i] != action) {
                    newAuths[newCount++] = currentAuths[i];
                }
            }
        } else {
            newAuths = currentAuths;
            newCount = count;
        }

        _error = SecACLSetAuthorizations(_ACL, newAuths, newCount);
		
		if (noErr != _error) {
			PSYSLOGND(LOG_ERR, @"Unable to apply changed authorisations, error %@.", OSStatusAsString(_error));
			PDEBUG(@"SecACLSetAuthorizations(%p, %p, %"PRIu32") returned error %@.", _ACL, newAuths, newCount, OSStatusAsString(_error));
		}
		
		if ((NULL != newAuths) && (newAuths != currentAuths)) {
			free(newAuths);
		}
    } else {
		PSYSLOGND(LOG_ERR, @"Unable to get existing authorisations [in order to modify them], error %@.", OSStatusAsString(_error));
		PDEBUG(@"SecACLGetAuthorizations(%p, %p, %p [%u->%u]) returned error %@.", _ACL, currentAuths, &count, capacity, count, OSStatusAsString(_error));
	}
	
	if (NULL != currentAuths) {
		free(currentAuths);
	}
	
	return (noErr == _error);
}

- (BOOL)setAuthorizesEverything:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_ANY to:value];
}

- (BOOL)setAuthorizesLogin:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_LOGIN to:value];
}

- (BOOL)setAuthorizesGeneratingKeys:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_GENKEY to:value];
}

- (BOOL)setAuthorizesDeletion:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_DELETE to:value];
}

- (BOOL)setAuthorizesExportingWrapped:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_EXPORT_WRAPPED to:value];
}

- (BOOL)setAuthorizesExportingClear:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_EXPORT_CLEAR to:value];
}

- (BOOL)setAuthorizesImportingWrapped:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_IMPORT_WRAPPED to:value];
}

- (BOOL)setAuthorizesImportingClear:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_IMPORT_CLEAR to:value];
}

- (BOOL)setAuthorizesSigning:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_SIGN to:value];
}

- (BOOL)setAuthorizesEncrypting:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_ENCRYPT to:value];
}

- (BOOL)setAuthorizesDecrypting:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_DECRYPT to:value];
}

- (BOOL)setAuthorizesMACGeneration:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_MAC to:value];
}

- (BOOL)setAuthorizesDerivingKeys:(BOOL)value {
    return [self setAuthorizesAction:CSSM_ACL_AUTHORIZATION_DERIVE to:value];
}

- (NSArray*)authorizations {
    uint32 i, capacity = 10, count;
    CSSM_ACL_AUTHORIZATION_TAG *auths = NULL;
	NSMutableArray *result = nil;
	
	do {
		capacity *= 2;
		count = capacity;
		auths = reallocf(auths, sizeof(CSSM_ACL_AUTHORIZATION_TAG) * count);
		
		_error = SecACLGetAuthorizations(_ACL, auths, &count);
	} while (errSecBufferTooSmall == _error);
	
    if (noErr == _error) {
		result = [NSMutableArray arrayWithCapacity:count];
		
        for (i = 0; i < count; ++i) {
            [result addObject:[NSNumber numberWithInt:auths[i]]];
        }
	} else {
		PSYSLOGND(LOG_ERR, @"Unable to get authorisations, error %@.", OSStatusAsString(_error));
		PDEBUG(@"SecACLGetAuthorizations(%p, %p, %p [%u->%u]) returned error %@.", _ACL, auths, &count, capacity, count, OSStatusAsString(_error));
	}
	
	return result;
}

- (BOOL)authorizesAction:(CSSM_ACL_AUTHORIZATION_TAG)action {
    uint32 i, capacity = 10, count;
    CSSM_ACL_AUTHORIZATION_TAG *auths = NULL;
	BOOL result = NO;
	
	do {
		capacity *= 2;
		count = capacity;
		auths = reallocf(auths, sizeof(CSSM_ACL_AUTHORIZATION_TAG) * count);
		
		_error = SecACLGetAuthorizations(_ACL, auths, &count);
	} while (errSecBufferTooSmall == _error);
	
    if (noErr == _error) {
        for (i = 0; i < count; ++i) {
            if (auths[i] == action) {
                result = YES;
				break;
            }
        }
    } else {
		PSYSLOGND(LOG_ERR, @"Unable to get authorisations, error %@.", OSStatusAsString(_error));
		PDEBUG(@"SecACLGetAuthorizations(%p, %p, %p [%u->%u]) returned error %@.", _ACL, auths, &count, capacity, count, OSStatusAsString(_error));
	}

	if (NULL != auths) {
		free(auths);
	}
	
    return result;
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
    _error = SecACLRemove(_ACL);
	
	if (noErr != _error) {
		PSYSLOG(LOG_ERR, @"Unable to get delete ACL %p, error %@.", self, OSStatusAsString(_error));
	}
}

- (OSStatus)lastError {
    return _error;
}

- (SecACLRef)ACLRef {
    return _ACL;
}

- (void)dealloc {
    if (_ACL) {
        CFRelease(_ACL);
		_ACL = NULL;
    }
    
    [super dealloc];
}

@end
