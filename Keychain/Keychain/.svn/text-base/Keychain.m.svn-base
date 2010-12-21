//
//  Keychain.m
//  Keychain
//
//  Created by Wade Tregaskis on Fri Jan 24 2003.
//  Modified by Wade Tregaskis & Mark Ackerman on Mon Sept 29 2003 [redone all the password-related methods].
//
//  Copyright (c) 2003 - 2007, Wade Tregaskis & Mark Ackerman.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Keychain/Keychain.h>

#import <sys/param.h>

#import "Utilities/UtilitySupport.h"
#import "CDSA/CSSMUtils.h"
#import "Utilities/SecurityUtils.h"
#import "CDSA/CSSMTypes.h"
#import "Utilities/MultiThreadingInternal.h"
#import "Utilities/CompilerIndependence.h"

#import "Utilities/Logging.h"

// For pre-10.5 SDKs:
#ifndef NSINTEGER_DEFINED
typedef int NSInteger;
typedef unsigned int NSUInteger;
#define NSINTEGER_DEFINED
#endif
typedef size_t CSSM_SIZE;

NSString *KeychainKeychainKey = @"Keychain Keychain Key";
NSString *KeychainItemKey = @"Keychain Item Key";
NSString *KeychainVersionKey = @"Keychain Version Key";
NSString *KeychainProcessIDKey = @"Keychain PID Key";

NSString *DefaultKeychainChangedNotification = @"Default keychain changed notification";
NSString *KeychainLockedNotification = @"Keychain locked notification";
NSString *KeychainUnlockedNotification = @"Keychain unlocked notification";
NSString *KeychainItemAddedNotification = @"KeychainItem added notification";
NSString *KeychainItemRemovedNotification = @"KeychainItem removed notification";
NSString *KeychainItemUpdatedNotification = @"KeychainItem updated notification";
NSString *KeychainPasswordChangedNotification = @"Keychain password changed notification";
NSString *KeychainItemAccessedNotification = @"KeychainItem accessed notification";
NSString *KeychainListChangedNotification = @"Keychain list changed notification";


@implementation Keychain

OSStatus keychainEventCallback(SecKeychainEvent keychainEvent, SecKeychainCallbackInfo *info, void *context __unused) {
    Keychain *theKeychain;
    KeychainItem *theItem;
    NSMutableDictionary *eventDictionary;
    NSString *notificationName;
    id destination;

    // The commented out version doesn't create a new Keychain instance if one doesn't already exist.  This is a good idea if you are only interested in events for keychains you've created/used, but of course isn't so good if you want all events, regardless of which keychain they occur in (as my Keychain Logger does).
    // I'm trying to come up with a better way to receive all events, without simply using my own callback directly.  If I can find a better way, I'll be able to revert back to the more efficient version.
    
    if (info->keychain) {
        destination = theKeychain = [Keychain keychainWithKeychainRef:info->keychain];
        //theKeychain = [[Keychain alloc] initWithKeychainRef:info->keychain];
        //theKeychain = [Keychain instanceWithKey:(id)info->keychain from:@selector(keychainRef) simpleKey:NO];
    } else {
        destination = theKeychain = nil;
    }
    
    eventDictionary = [NSMutableDictionary dictionaryWithCapacity:5];

    if (theKeychain) {
        [eventDictionary setObject:theKeychain forKey:KeychainKeychainKey];
    }
    
    [eventDictionary setObject:[NSNumber numberWithUnsignedInt:info->version] forKey:KeychainVersionKey];

    if (info->item) {
        theItem = [KeychainItem keychainItemWithKeychainItemRef:info->item];
        [eventDictionary setObject:theItem forKey:KeychainItemKey];
    } else {
        theItem = nil;
    }

    if (info->pid) { // It may or may not be physically possible that the init process could modify the keychain, but I think it's safe to say it won't
        [eventDictionary setObject:[NSNumber numberWithUnsignedInt:info->pid] forKey:KeychainProcessIDKey];
    }

    
    switch (keychainEvent) {
        case kSecLockEvent: // The keychain was locked
            notificationName = KeychainLockedNotification; break;
        case kSecUnlockEvent: // The keychain was unlocked
            notificationName = KeychainUnlockedNotification; break;
        case kSecAddEvent: // An item was added (item included)
            notificationName = KeychainItemAddedNotification;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:theItem userInfo:eventDictionary];

            break;
        case kSecDeleteEvent: // An item was deleted (item included)
            notificationName = KeychainItemRemovedNotification;
            
            // Is the item still valid at this point?  Probably not...
            
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:theItem userInfo:eventDictionary];

            break;
        case kSecUpdateEvent: // An item was changed (item included)
            notificationName = KeychainItemUpdatedNotification;

            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:theItem userInfo:eventDictionary];

            break;
        case kSecPasswordChangedEvent: // The keychain password was changed
            notificationName = KeychainPasswordChangedNotification; break;
        case kSecDefaultChangedEvent: // The default keychain was changed
            notificationName = KeychainUnlockedNotification; break;
        case kSecDataAccessEvent: // Data accessed in keychain item
            notificationName = KeychainItemAccessedNotification;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:theItem userInfo:eventDictionary];
            
            break;
        case kSecKeychainListChangedEvent: // The list of keychains was changed
            notificationName = KeychainListChangedNotification; break;
        default:
            PDEBUG(@"Unknown keychain event - id #%u (0x%x).\n", keychainEvent, keychainEvent);
            notificationName = nil;
    }

    if (notificationName) {
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:theKeychain userInfo:eventDictionary];
    }

    return 0;
}

+ (void)initialize { // Is it really necessary to do this once-assurancing... can initialize even be called more than once, aside from manually, in which case do we really care?
    static BOOL haveAddedCallbacks;
    int err;
    
    if (!haveAddedCallbacks) {
        //PDEBUG(@"Attempting to add callbacks.\n");
        
        err = SecKeychainAddCallback(keychainEventCallback, kSecEveryEventMask, NULL);
        
        if (0 == err) {
            //PDEBUG(@"Successfully added callbacks.\n");
            haveAddedCallbacks = YES;
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to install keychain events callback (error %@); no keychain event notifications will be posted.\n", OSStatusAsString(err));
            PDEBUG(@"SecKeychainAddCallback(%p, %x [kSecEveryMask], NULL) returned error %@.\n", keychainEventCallback, kSecEveryEventMask, OSStatusAsString(err));
        }
    }
}

+ (uint32_t)keychainManagerVersion {
    uint32 result;
    int err;
    
    err = SecKeychainGetVersion(&result);

    if (err == 0) {
        return result;
    } else {
        return -1;
    }
}

+ (void)setUserInteractionAllowed:(BOOL)allowed {
    SecKeychainSetUserInteractionAllowed(allowed);
}
    
+ (BOOL)userInteractionAllowed {
    BOOL result;

    SecKeychainGetUserInteractionAllowed((Boolean*)&result);

    return result;
}

+ (BOOL)lockAll {
    return (SecKeychainLockAll() == 0);
}

+ (Keychain*)keychainWithKeychainRef:(SecKeychainRef)keych {
    return [[[[self class] alloc] initWithKeychainRef:keych] autorelease];
}

+ (Keychain*)createNewKeychainAtPath:(NSString*)path withPassword:(NSString*)password access:(Access*)access {
    return [[[[self class] alloc] initNewAtPath:path withPassword:password access:access] autorelease];
}

+ (Keychain*)defaultKeychain {
    static Keychain *defaultKeychain = nil;

    if (nil == defaultKeychain) {
        [keychainSingletonLock lock];
        
        if (nil == defaultKeychain) {
            defaultKeychain = [[Keychain alloc] initFromDefault];
        }
        
        [keychainSingletonLock unlock];
    }

    return defaultKeychain;
}

+ (Keychain*)defaultKeychainForUser:(NSString*)username {
    NSString *userHomeDirectory;
    
    if (username) {
        userHomeDirectory = NSHomeDirectoryForUser(username);

        if (userHomeDirectory) {
            return [[[[self class] alloc] initFromPath:[[userHomeDirectory stringByAppendingPathComponent:@"Library/Keychains/"] stringByAppendingPathComponent:[userHomeDirectory lastPathComponent]]] autorelease];
        } else {
            return nil;
        }
    } else {
        return [Keychain defaultKeychain];
    }
}

+ (Keychain*)keychainAtPath:(NSString*)path {
    return [[[[self class] alloc] initFromPath:path] autorelease];
}

- (Keychain*)initWithKeychainRef:(SecKeychainRef)keych {
    Keychain *existingObject;
    
    if (keych) {
        existingObject = [[self class] instanceWithKey:(id)keych from:@selector(keychainRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            self = [existingObject retain];
        } else {
            if (self = [super init]) {
                CFRetain(keych);
                _keychain = keych;
                _error = noErr;
            }
        }
    } else {
        [self release];
        self = nil;
    }
    
    return self;
}

- (Keychain*)initNewAtPath:(NSString*)path withPassword:(NSString*)password access:(Access*)access {
    if (path) {
        // FLAG - should the fourth argument below, Boolean promptUser, be hard wired to yes?
		const char *passwordUTF8String = ((nil != password) ? [password UTF8String] : NULL);
		SecAccessRef accessRef = ((nil != access) ? [access accessRef] : NULL);
		
        _error = SecKeychainCreate([path fileSystemRepresentation], ((NULL != passwordUTF8String) ? (uint32_t)strlen(passwordUTF8String) : 0), passwordUTF8String, (NULL == passwordUTF8String), accessRef, &_keychain);
        
        if (noErr != _error) {
            PSYSLOGND(LOG_ERR, @"Unable to initialise keychain at path \"%@\", error %@.\n", path, OSStatusAsString(_error));
            PDEBUG(@"SecKeychainCreate(\"%@\", <hidden>, <hidden>, %@, %p, %p) returned error %@.\n", path, ((NULL == passwordUTF8String) ? @"YES" : @"NO"), accessRef, &_keychain, OSStatusAsString(_error));
            
            [self release];
            self = nil;
        } else {
            if (self = [super init]) {
                _error = noErr;
            }
        }
    } else {
		PSYSLOG(LOG_ERR, @"Cannot create a new keychain without a path.\n");
        [self release];
        self = nil;
    }
    
    return self;
}

- (Keychain*)initFromDefault {
    Keychain *existingObject;
    
    _error = SecKeychainCopyDefault(&_keychain);

    if (_error != CSSM_OK) {
        PSYSLOGND(LOG_ERR, @"Unable to initialise with default keychain, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainCopyDefault(%p) returned error %@.\n", &_keychain, OSStatusAsString(_error));
        
        [self release];
        self = nil;
    } else {
        existingObject = [[self class] instanceWithKey:(id)_keychain from:@selector(keychainRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            self = [existingObject retain];
        } else {
            if (self = [super init]) {
                _error = noErr;
            }
        }
    }
    
    return self;
}

- (Keychain*)initFromPath:(NSString*)path {
    Keychain *existingObject;
    
    _error = SecKeychainOpen([path fileSystemRepresentation], &_keychain);

    if (_error != CSSM_OK) {
        PSYSLOGND(LOG_ERR, @"Unable to initialise keychain from path \"%@\", error %@.\n", path, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainOpen(\"%@\", %p) returned error %@.\n", path, OSStatusAsString(_error));
        
        [self release];
        self = nil;
    } else {
        existingObject = [[self class] instanceWithKey:(id)_keychain from:@selector(keychainRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            self = [existingObject retain];
        } else {
            if (self = [super init]) {
                _error = noErr;
            }
        }        
    }

    return self;
}

- (Keychain*)init {
    [self release];
    return nil;
}

- (NSString*)path {
    char buffer[MAXPATHLEN + 1];
    uint32 length = MAXPATHLEN;

    _error = SecKeychainGetPath(_keychain, &length, buffer);

    if ((noErr == _error) && (length > 0)) {
        return [NSString stringWithCString:buffer length:length];
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to retrieve keychain %p's path, error %@.\n", self, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainGetPath(%p, %p [%"PRIu32"], %p) returned error %@.\n", _keychain, &length, length, buffer, OSStatusAsString(_error));
        
        return nil;
    }
}

- (BOOL)lock {
    _error = SecKeychainLock(_keychain);

    if (CSSM_OK != _error) {
        PSYSLOGND(LOG_ERR, @"Unable to lock keychain, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainLock(%p) returned error %@.\n", _keychain, OSStatusAsString(_error));
        
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)unlock {
    _error = SecKeychainUnlock(_keychain, 0, NULL, NO);

    if (CSSM_OK != _error) {
        PSYSLOGND(LOG_ERR, @"Unable to unlock keychain, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainUnlock(%p, 0, NULL, NO) returned error %@.\n", _keychain, OSStatusAsString(_error));
        
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)unlockWithPassword:(NSString*)password {
    if (password) {
		const char *cPassword = [password UTF8String];
        _error = SecKeychainUnlock(_keychain, (uint32_t)strlen(cPassword), cPassword, YES);
        
        if (CSSM_OK != _error) {
            PDEBUG(@"SecKeychainUnlock(%p, <hidden>, <hidden>, YES) returned error %@.\n", _keychain, OSStatusAsString(_error));
        }
    } else {
        _error = SecKeychainUnlock(_keychain, 0, NULL, YES);
        
        if (CSSM_OK != _error) {
            PDEBUG(@"SecKeychainUnlock(%p, 0, NULL, YES) returned error %@.\n", _keychain, OSStatusAsString(_error));
        }
    }
    
    if (noErr != _error) {
        PSYSLOG(LOG_ERR, @"Unable to unlock keychain with password, error %@.\n", OSStatusAsString(_error));
        
        return NO;
    } else {
        return YES;
    }
}

- (void)makeDefault {
    _error = SecKeychainSetDefault(_keychain);
    
    if (CSSM_OK != _error) {
        PSYSLOGND(LOG_ERR, @"Unable to make keychain %p the default, error %@.\n", self, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainSetDefault(%p) returned error %@.\n", _keychain, OSStatusAsString(_error));
    }
}

- (BOOL)isUnlocked {
    SecKeychainStatus result;

    _error = SecKeychainGetStatus(_keychain, &result);

    if (noErr != _error) {
        PSYSLOGND(LOG_ERR, @"Unable to determine if keychain %p is unlocked, error %@.\n", self, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainGetStatus(%p, %p) returned error %@.\n", _keychain, &result, OSStatusAsString(_error));
        
        return NO;
    } else {
        return (result & kSecUnlockStateStatus);
    }
}

- (BOOL)isReadOnly {
    SecKeychainStatus result;

    _error = SecKeychainGetStatus(_keychain, &result);

    if (noErr != _error) {
        PSYSLOGND(LOG_ERR, @"Unable to determine if keychain %p is read-only, error %@.\n", self, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainGetStatus(%p, %p) returned error %@.\n", _keychain, &result, OSStatusAsString(_error));
        
        return NO;
    } else {
        return (result & kSecReadPermStatus);
    }
}

- (BOOL)isWritable {
    SecKeychainStatus result;

    _error = SecKeychainGetStatus(_keychain, &result);

    if (noErr != _error) {
        PSYSLOGND(LOG_ERR, @"Unable to determine if keychain %p is writable, error %@.\n", self, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainGetStatus(%p, %p) returned error %@.\n", _keychain, &result, OSStatusAsString(_error));
        
        return NO;
    } else {
        return (result & kSecWritePermStatus);
    }
}

- (void)setLockOnSleep:(BOOL)lockOnSleep {
    SecKeychainSettings settings = {
		.version = SEC_KEYCHAIN_SETTINGS_VERS1
	};

    _error = SecKeychainCopySettings(_keychain, &settings);

    if (noErr == _error) {
        settings.lockOnSleep = lockOnSleep;

        _error = SecKeychainSetSettings(_keychain, &settings);
        
        if (CSSM_OK != _error) {
            PSYSLOGND(LOG_ERR, @"Unable to set lock-on-sleep for keychain %p, error %@.\n", self, OSStatusAsString(_error));
            PDEBUG(@"SecKeychainSetSettings(%p, %p) returned error %@.\n", _keychain, &settings, OSStatusAsString(_error));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to set lock-on-sleep for keychain %p, error %@.\n", self, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainCopySettings(%p, %p) returned error %@.\n", _keychain, &settings, OSStatusAsString(_error));
    }
}

- (BOOL)willLockOnSleep {
    SecKeychainSettings settings = {
		.version = SEC_KEYCHAIN_SETTINGS_VERS1
	};

    _error = SecKeychainCopySettings(_keychain, &settings);

    if (noErr == _error) {
        return settings.lockOnSleep;
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to determine lock-on-sleep setting of keychain %p, error %@.\n", self, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainCopySettings(%p, %p) returned error %@.\n", _keychain, &settings, OSStatusAsString(_error));
        
        return NO;
    }
}

- (void)setLockInterval:(uint32_t)interval {
    SecKeychainSettings settings = {
		.version = SEC_KEYCHAIN_SETTINGS_VERS1
	};

    _error = SecKeychainCopySettings(_keychain, &settings);

    if (noErr == _error) {
        settings.lockInterval = interval;

        _error = SecKeychainSetSettings(_keychain, &settings);
    
        if (CSSM_OK != _error) {
            PSYSLOGND(LOG_ERR, @"Unable to set interval for keychain %p, error %@.\n", self, OSStatusAsString(_error));
            PDEBUG(@"SecKeychainSetSettings(%p, %p) returned error %@.\n", _keychain, &settings, OSStatusAsString(_error));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to set interval for keychain %p, error %@.\n", self, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainCopySettings(%p, %p) returned error %@.\n", _keychain, &settings, OSStatusAsString(_error));
    }
}

- (uint32_t)lockInterval {
    SecKeychainSettings settings = {
		SEC_KEYCHAIN_SETTINGS_VERS1
	};

    _error = SecKeychainCopySettings(_keychain, &settings);

    if (noErr == _error) {
        return settings.lockInterval;
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to determine interval of keychain %p, error %@.\n", self, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainCopySettings(%p, %p) returned error %@.\n", _keychain, &settings, OSStatusAsString(_error));
        
        return -1;
    }
}

- (BOOL)addItem:(KeychainItem*)item {
    if (item) {
        SecKeychainItemRef result = NULL;
        
        _error = SecKeychainItemCreateCopy([item keychainItemRef], _keychain, [[item access] accessRef], &result);
        
        if ((noErr == _error) && result) {
            CFRelease(result);
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to add item %p to keychain %p, error %@.\n", item, self, OSStatusAsString(_error));
            PDEBUG(@"SecKeychainItemCreateCopy(%p, %p, %p, %p) returned error %@.\n", [item keychainItemRef], _keychain, [[item access] accessRef], &result, OSStatusAsString(_error));
        }
    } else {
        PSYSLOG(LOG_ERR, @"Invalid argument - item is nil.\n");
        _error = EINVAL;
    }
    
    return (noErr == _error);
}

- (KeychainItem*)addNewItemWithClass:(SecItemClass)itemClass access:(Access*)initialAccess {
    SecKeychainItemRef keychainItem;
    SecKeychainAttributeList attributes = {0, nil};
    SecAccessRef accessRef = [initialAccess accessRef];
	KeychainItem *result = nil;
	
    _error = SecKeychainItemCreateFromContent(itemClass, &attributes, 0, nil, _keychain, accessRef, &keychainItem);
    
    if (noErr == _error) {
		result = [KeychainItem keychainItemWithKeychainItemRef:keychainItem];
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to add new item of class %@, error %@.\n", nameOfKeychainItemClassConstant(itemClass), OSStatusAsString(_error));
        PDEBUG(@"SecKeychainItemCreateFromContent(%@, %p, 0, nil, %p, %p, %p) returned error %@.\n",
			   nameOfKeychainItemClassConstant(itemClass),
			   &attributes,
			   _keychain,
			   accessRef,
			   &keychainItem,
			   OSStatusAsString(_error));
    }
	
	if (nil != result) {
		CFBundleRef mainBundle = CFBundleGetMainBundle();
		FourCharCode creatorCode = 0;
		
		if (NULL != mainBundle) {
			CFBundleGetPackageInfo(mainBundle, NULL, &creatorCode);
			
			if ('????' == creatorCode) {
				creatorCode = 0;
			}
		}
		
		[result setCreator:creatorCode];
	}
	
	return result;
}

/*- (void)importCertificateBundle:(CertificateBundle*)bundle {
    _error = SecCertificateBundleImport(_keychain, [bundle bundle], [bundle type], [bundle encoding], nil);
}*/

- (KeychainItem*)addCertificate:(Certificate*)certificate withName:(NSString*)name {
    KeychainItem *result = nil;
    SecExternalFormat format = kSecFormatUnknown;
    SecExternalItemType type = kSecItemTypeCertificate;
    CFArrayRef resultRawArray = NULL;// = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    SecKeychainRef keychain = [self keychainRef];
    NSData *certificateData = [certificate data];
	
    _error = SecKeychainItemImport((CFDataRef)certificateData,
                                   NULL,
                                   &format,
                                   &type,
                                   0,
                                   NULL,
                                   keychain,
                                   &resultRawArray);
    
    if (noErr == _error) {
        NSArray *resultArray = (NSArray*)resultRawArray;
        NSUInteger numberOfResults = [resultArray count];
		
        if (0 < numberOfResults) {
			if (1 < numberOfResults) {
				PSYSLOGND(LOG_WARNING, @"More than one keychain item created during import of certificate - attempting to handle as best as possible, but this is not a well supported case.\n");
				PDEBUG(@"SecKeychainItemImport(%p, NULL, %p [%@], %p [%@], 0, NULL, %p, %p) returned more than one item: %@\n", certificateData, &format, nameOfExternalFormatConstant(format), &type, nameOfExternalItemTypeConstant(type), keychain, &resultRawArray, [resultArray description]);
			}
			
			NSEnumerator *resultEnumerator = [resultArray objectEnumerator];
            SecKeychainItemRef itemRef;
			CFBundleRef mainBundle = CFBundleGetMainBundle();
			FourCharCode creatorCode = 0;
			
			if (NULL != mainBundle) {
				CFBundleGetPackageInfo(mainBundle, NULL, &creatorCode);
				
				if ('????' == creatorCode) {
					creatorCode = 0;
				}
			}
			
			while (itemRef = (SecKeychainItemRef)[resultEnumerator nextObject]) {
				result = [KeychainItem keychainItemWithKeychainItemRef:itemRef];
				
				[result setLabel:name];
				[result setCreator:creatorCode];
			}
        } else {
            PSYSLOGND(LOG_ERR, @"No keychain items created by import of certificate.\n");
			PDEBUG(@"SecKeychainItemImport(%p, NULL, %p [%@], %p [%@], 0, NULL, %p, %p) returned nil or empty array: %@\n", certificateData, &format, nameOfExternalFormatConstant(format), &type, nameOfExternalItemTypeConstant(type), keychain, &resultRawArray, [resultArray description]);
        }
        
        CFRelease(resultRawArray);
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to insert certificate into keychain, error %@.\n", CSSMErrorAsString(_error));
        PDEBUG(@"SecKeychainItemImport(<data>, NULL, %p, %p, 0, NULL, %p, %p) returned error %@.\n", &format, &type, keychain, &resultRawArray, CSSMErrorAsString(_error));
    }
    
    return result;
}

#if 0
- (KeychainItem*)addKey:(Key*)key withName:(NSString*)name isPermanent:(BOOL)isPermanent isPrivate:(BOOL)isPrivate publicKeyHash:(NSData*)publicKeyHash {
	SecKeyImportExportParameters importExportParameters;
	
	importExportParameters.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
	importExportParameters.flags = 0;
	importExportParameters.passphrase = CFSTR("TODO: replace this with random data");
	importExportParameters.alertTitle = CFSTR("This should never be shown.");
	importExportParameters.alertPrompt = CFSTR("Something clearly went very wrong.");
	
	importExportParameters.accessRef = NULL;
	importExportParameters.keyUsage = [key usage];
	importExportParameters.keyAttributes =    ((   [key attributes]
												 | (CSSM_KEYATTR_FLAGS)(isPermanent ? CSSM_KEYATTR_PERMANENT : 0)
												 | (CSSM_KEYATTR_FLAGS)(isPrivate ? CSSM_KEYATTR_PRIVATE : 0))
											& (isPermanent ? UINT32_MAX : (CSSM_KEYATTR_FLAGS)~CSSM_KEYATTR_PERMANENT)
											& (isPrivate ? UINT32_MAX : (CSSM_KEYATTR_FLAGS)~CSSM_KEYATTR_PRIVATE));
	
	CFDataRef exportedForm;
	
	// [key keyRef] won't work in all cases because it only applies to Keys we initialised using SecKeyRefs, not those from raw CSSM_KEYs.
	_error = SecKeychainItemExport([key keyRef], kSecFormatUnknown, 0, NULL /* &importExportParameters */, &exportedForm);
	
	if (noErr == _error) {
		SecExternalFormat format = kSecFormatUnknown;
		SecExternalItemType itemType = kSecItemTypeUnknown;
		CFArrayRef results = NULL;
		
		_error = SecKeychainItemImport(exportedForm, NULL, &format, &itemType, 0, &importExportParameters, [self keychainRef], &results);
		
		if (noErr == _error) {
			NSLog(@"Shit on me, it worked.  Result is: %@", (NSArray*)results);
		} else {
			PSYSLOGND(LOG_ERR, @"Couldn't import key, error %@.\n", OSStatusAsString(_error));
			PDEBUG(@"SecKeychainItemImport(%p, NULL, %p, %p, 0, %p, %p, %p) returned error %@.\n", exportedForm, &format, &itemType, &importExportParameters, [self keychainRef], results, OSStatusAsString(_error));
		}
	} else {
		PSYSLOGND(LOG_ERR, @"Couldn't [temporarily] export key, error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecKeychainItemExport(%p, kSecFormatUnknown, 0, %p, %p) returned error %@.\n", [key keyRef], &importExportParameters, &exportedForm, OSStatusAsString(_error));
	}
}
#else
- (KeychainItem*)addKey:(Key*)key withName:(NSString*)name isPermanent:(BOOL)isPermanent isPrivate:(BOOL)isPrivate publicKeyHash:(NSData*)publicKeyHash {
    CSSM_DB_RECORDTYPE recType;
    int attributeCount = 26;
    CSSM_SIZE keySize;
    CSSM_DB_ATTRIBUTE_DATA attrs[27];
    CSSM_DB_RECORD_ATTRIBUTE_DATA recordAttrs;
    CSSM_DB_ATTRIBUTE_DATA_PTR attr = &attrs[0];
    CSSM_DL_DB_HANDLE DLDBHandle;
    CSSM_DB_UNIQUE_RECORD_PTR recordPtr;
    CSSM_BOOL boolFalse = CSSM_FALSE, boolTrue = CSSM_TRUE;
    CSSM_DATA cssmFalse = {sizeof(CSSM_BOOL), (uint8_t*)&boolFalse},
              cssmTrue = {sizeof(CSSM_BOOL), (uint8_t*)&boolTrue},
              printNameData = {0, NULL},
              recTypeData = {sizeof(CSSM_DB_RECORDTYPE), NULL},
              cspIdData = {sizeof(CSSM_GUID), NULL},
              algIdData = {sizeof(CSSM_ALGORITHMS), NULL},
              logicalKeySizeData = {sizeof(uint32_t), NULL},
              startDateData = {sizeof(CSSM_DATE), NULL},
              endDateData = {sizeof(CSSM_DATE), NULL},
              pubKeyHash = {0, NULL},
              keySizeData = {sizeof(uint32_t), NULL},
              appTag = {19, (uint8_t*)"Keychain Framework"};
    const CSSM_KEYHEADER *keyHeader = NULL;
    KeychainItem *result = nil;
    
	_error = SecKeychainGetDLDBHandle(_keychain, &DLDBHandle);
	
    if (noErr == _error) {
        SecKeychainAttributeList attributeList;
        SecKeychainAttribute attribute[8];
        const CSSM_KEY *rawKey = [key CSSMKey];
		const char *cName = [name UTF8String];
		
        attributeList.count = 8;
        attributeList.attr = attribute;
        
        /* Key schema:
        
            startClass(Key)
            attribute(`  Ss', KeyClass, kKeyClass, "KeyClass", 0, NULL, UINT32)
            attribute(`  Ss', PrintName, kPrintName, "PrintName", 0, NULL, BLOB)
            attribute(`  Ss', Alias, kAlias, "Alias", 0, NULL, BLOB)
            attribute(`  Ss', Permanent, kPermanent, "Permanent", 0, NULL, UINT32)
            attribute(`  Ss', Private, kPrivate, "Private", 0, NULL, UINT32)
            attribute(`  Ss', Modifiable, kModifiable, "Modifiable", 0, NULL, UINT32)
                attribute(`UISs', Label, kLabel, "Label", 0, NULL, BLOB)
                attribute(`U Ss', ApplicationTag, kApplicationTag, "ApplicationTag", 0, NULL, BLOB)
                attribute(`U Ss', KeyCreator, kKeyCreator, "KeyCreator", 0, NULL, BLOB)
                attribute(`U Ss', KeyType, kKeyType, "KeyType", 0, NULL, UINT32)
                attribute(`U Ss', KeySizeInBits, kKeySizeInBits, "KeySizeInBits", 0, NULL, UINT32)
                attribute(`U Ss', EffectiveKeySize, kEffectiveKeySize, "EffectiveKeySize", 0, NULL, UINT32)
                attribute(`U Ss', StartDate, kStartDate, "StartDate", 0, NULL, BLOB)
                attribute(`U Ss', EndDate, kEndDate, "EndDate", 0, NULL, BLOB)
            attribute(`  Ss', Sensitive, kSensitive, "Sensitive", 0, NULL, UINT32)
            attribute(`  Ss', AlwaysSensitive, kAlwaysSensitive, "AlwaysSensitive", 0, NULL, UINT32)
            attribute(`  Ss', Extractable, kExtractable, "Extractable", 0, NULL, UINT32)
            attribute(`  Ss', NeverExtractable, kNeverExtractable, "NeverExtractable", 0, NULL, UINT32)
            attribute(` ISs', Encrypt, kEncrypt, "Encrypt", 0, NULL, UINT32)
            attribute(` ISs', Decrypt, kDecrypt, "Decrypt", 0, NULL, UINT32)
            attribute(` ISs', Derive, kDerive, "Derive", 0, NULL, UINT32)
            attribute(` ISs', Sign, kSign, "Sign", 0, NULL, UINT32)
            attribute(` ISs', Verify, kVerify, "Verify", 0, NULL, UINT32)
            attribute(` ISs', SignRecover, kSignRecover, "SignRecover", 0, NULL, UINT32)
            attribute(` ISs', VerifyRecover, kVerifyRecover, "VerifyRecover", 0, NULL, UINT32)
            attribute(` ISs', Wrap, kWrap, "Wrap", 0, NULL, UINT32)
            attribute(` ISs', Unwrap, kUnwrap, "Unwrap", 0, NULL, UINT32)
            endClass() */
        
        switch ([key keyClass]) {
            case CSSM_KEYCLASS_PUBLIC_KEY:
                recType = CSSM_DL_DB_RECORD_PUBLIC_KEY; break;
            case CSSM_KEYCLASS_PRIVATE_KEY:
                recType = CSSM_DL_DB_RECORD_PRIVATE_KEY; break;
            case CSSM_KEYCLASS_SESSION_KEY:
                recType = CSSM_DL_DB_RECORD_SYMMETRIC_KEY; break;
            default:
                recType = CSSM_DL_DB_RECORD_ALL_KEYS;
        }

        keyHeader = &(rawKey->KeyHeader);

        recTypeData.Data = (uint8_t*)&recType;
        cspIdData.Data = (uint8_t*)&keyHeader->CspId;
        algIdData.Data = (uint8_t*)&keyHeader->AlgorithmId;
        logicalKeySizeData.Data = (uint8_t*)&keyHeader->LogicalKeySizeInBits;
        startDateData.Data = (uint8_t*)&keyHeader->StartDate;
        endDateData.Data = (uint8_t*)&keyHeader->EndDate;
        
        printNameData.Data = (uint8_t *)cName;
        printNameData.Length = (uint32_t)strlen(cName);

        keySize = rawKey->KeyData.Length * 8;
        keySizeData.Data = (uint8_t*)&keySize;
        
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "KeyClass";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = &recTypeData;

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "PrintName";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;
        attr->Value = &printNameData;

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Label";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;
        
        if (publicKeyHash != nil) {
            copyNSDataToDataNoCopy(publicKeyHash, &pubKeyHash);
            attr->Value = &pubKeyHash;
        } else {
            attr->Value = &printNameData;
        }
        
        attribute[0].tag = kSecKeyLabel;
        attribute[0].data = attr->Value->Data;
        attribute[0].length = (uint32)(attr->Value->Length);
        
        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Permanent";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = (isPermanent ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Private";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = (isPrivate ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Modifiable";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyAttr & CSSM_KEYATTR_MODIFIABLE) ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "ApplicationTag";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;
        attr->Value = &appTag;
        
        attribute[1].tag = kSecKeyApplicationTag;
        attribute[1].data = attr->Value->Data;
        attribute[1].length = (uint32)(attr->Value->Length);
        
        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "KeyCreator";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;
        attr->Value = &cspIdData;
        
        attribute[2].tag = kSecKeyKeyCreator;
        attribute[2].data = attr->Value->Data;
        attribute[2].length = (uint32)(attr->Value->Length);
            
        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "KeyType";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = &algIdData;

        attribute[3].tag = kSecKeyKeyType;
        attribute[3].data = attr->Value->Data;
        attribute[3].length = (uint32)(attr->Value->Length);
        
        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "KeySizeInBits";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        //attr->Value = &keySizeData; // The logical key size is taken from this KeySizeInBits property, not the EffectiveKeySize.  Makes you wonder what the EffectiveKeySize is then.
        attr->Value = &logicalKeySizeData;
        
        attribute[4].tag = kSecKeyKeySizeInBits;
        attribute[4].data = attr->Value->Data;
        attribute[4].length = (uint32)(attr->Value->Length);
        
        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "EffectiveKeySize";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = &logicalKeySizeData;

        attribute[5].tag = kSecKeyEffectiveKeySize;
        attribute[5].data = attr->Value->Data;
        attribute[5].length = (uint32)(attr->Value->Length);
        
        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "StartDate";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;
        attr->Value = &startDateData;

        attribute[6].tag = kSecKeyStartDate;
        attribute[6].data = attr->Value->Data;
        attribute[6].length = (uint32)(attr->Value->Length);
        
        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "EndDate";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;
        attr->Value = &endDateData;

        attribute[7].tag = kSecKeyEndDate;
        attribute[7].data = attr->Value->Data;
        attribute[7].length = (uint32)(attr->Value->Length);
        
        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Sensitive";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyAttr & CSSM_KEYATTR_SENSITIVE) ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "AlwaysSensitive";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyAttr & CSSM_KEYATTR_ALWAYS_SENSITIVE) ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Extractable";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyAttr & CSSM_KEYATTR_EXTRACTABLE) ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "NeverExtractable";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyAttr & CSSM_KEYATTR_NEVER_EXTRACTABLE) ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Encrypt";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyUsage & CSSM_KEYUSE_ENCRYPT) || (keyHeader->KeyUsage & CSSM_KEYUSE_ANY) ? &cssmTrue : &cssmFalse);
        
        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Decrypt";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyUsage & CSSM_KEYUSE_DECRYPT) || (keyHeader->KeyUsage & CSSM_KEYUSE_ANY) ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Derive";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyUsage & CSSM_KEYUSE_DERIVE) || (keyHeader->KeyUsage & CSSM_KEYUSE_ANY) ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Sign";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyUsage & CSSM_KEYUSE_SIGN) || (keyHeader->KeyUsage & CSSM_KEYUSE_ANY) ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Verify";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyUsage & CSSM_KEYUSE_VERIFY) || (keyHeader->KeyUsage & CSSM_KEYUSE_ANY) ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "SignRecover";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyUsage & CSSM_KEYUSE_SIGN_RECOVER) || (keyHeader->KeyUsage & CSSM_KEYUSE_ANY) ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "VerifyRecover";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyUsage & CSSM_KEYUSE_VERIFY_RECOVER) || (keyHeader->KeyUsage & CSSM_KEYUSE_ANY) ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Wrap";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyUsage & CSSM_KEYUSE_WRAP) || (keyHeader->KeyUsage & CSSM_KEYUSE_ANY) ? &cssmTrue : &cssmFalse);

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Unwrap";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = ((keyHeader->KeyUsage & CSSM_KEYUSE_UNWRAP) || (keyHeader->KeyUsage & CSSM_KEYUSE_ANY) ? &cssmTrue : &cssmFalse);

        /*if (publicKeyHash != nil) {
            //copyNSDataToDataNoCopy(publicKeyHash, &pubKeyHash);

            ++attributeCount;
            ++attr;
            attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
            attr->Info.Label.AttributeName = "PublicKeyHash";
            attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
            attr->NumberOfValues = 1;
            attr->Value = &pubKeyHash;
        }*/
        
        recordAttrs.DataRecordType = recType;
        recordAttrs.SemanticInformation = 0;
        recordAttrs.NumberOfAttributes = attributeCount;
        recordAttrs.AttributeData = attrs;

        _error = CSSM_DL_DataInsert(DLDBHandle, recType, &recordAttrs, &(rawKey->KeyData), &recordPtr);
        
        if (CSSM_OK == _error) {
            //const CSSM_DB_UNIQUE_RECORD *currentUniqueID;
            SecKeychainSearchRef searchRef = NULL;
            SecKeychainItemRef refoundKey = NULL, extraResult = NULL;
            
            _error = SecKeychainSearchCreateFromAttributes(_keychain, recType, &attributeList, &searchRef);
            
            if (noErr == _error) {
                _error = SecKeychainSearchCopyNext(searchRef, &refoundKey);
                
                if (noErr == _error) {
                    _error = SecKeychainSearchCopyNext(searchRef, &extraResult);
                    
                    if (errSecItemNotFound != _error) {
                        PDEBUG(@"Found more (_error = %@) than one key with the supposedly uniquely identifying attributes; aborting.\n", OSStatusAsString(_error));
                        
                        if (NULL != extraResult) {
                            CFRelease(extraResult);
                        }
                    } else {
                        result = [KeychainItem keychainItemWithKeychainItemRef:refoundKey];
                    }
                    
                    CFRelease(refoundKey);
                } else {
                    PSYSLOGND(LOG_ERR, @"Unable to find newly inserted key, error %@.\n", CSSMErrorAsString(_error));
                    PDEBUG(@"SecKeychainSearchCreateFromAttributes(%p, %u, %p, %p) returned error %@.\n", _keychain, recType, &attributeList, &searchRef, CSSMErrorAsString(_error));
                }
                
                CFRelease(searchRef);
            }
            
            CSSM_RETURN _freeError = CSSM_DL_FreeUniqueRecord(DLDBHandle, recordPtr);
            
            if (CSSM_OK != _freeError) {
                PDEBUG(@"CSSM_DL_FreeUniqueRecord(%"PRIdldbHandle", %p) returned error %@.\n", DLDBHandle, recordPtr, CSSMErrorAsString(_freeError));
            }
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to insert key into keychain, error %@.\n", CSSMErrorAsString(_error));
            PDEBUG(@"CSSM_DL_DataInsert(%"PRIdldbHandle", %"PRIu32", %p, %p, %p) returned error %@.\n", DLDBHandle, recType, &recordAttrs, &(rawKey->KeyData), &recordPtr, CSSMErrorAsString(_error));
        }
    } else {
		PSYSLOGND(LOG_ERR, @"Unable to get DLDB handle in order to add key, error %@.\n", CSSMErrorAsString(_error));
		PDEBUG(@"SecKeychainGetDLDBHandle(%p, %p [%"PRIdldbHandle"]) returned error %@.\n", _keychain, &DLDBHandle, DLDBHandle, CSSMErrorAsString(_error));
	}
    
	if (nil != result) {
		CFBundleRef mainBundle = CFBundleGetMainBundle();
		FourCharCode creatorCode = 0;
		
		if (NULL != mainBundle) {
			CFBundleGetPackageInfo(mainBundle, NULL, &creatorCode);
			
			if ('????' == creatorCode) {
				creatorCode = 0;
			}
		}
		
		[result setCreator:creatorCode];
	}
	
    return result;
}
#endif

- (NSArray*)addCertificate:(Certificate*)certificate privateKey:(Key*)privateKey withName:(NSString*)name {
    NSArray *result = nil;
    
    if (certificate && privateKey) {
        KeychainItem *certItem;
        
        certItem = [self addCertificate:certificate withName:name];

        if (nil != certItem) {
            KeychainItem *keyItem;
            
            keyItem = [self addKey:privateKey withName:name isPermanent:YES isPrivate:NO publicKeyHash:[[certificate publicKey] keyHash]];
            
            if (nil != keyItem) {
                result = [NSArray arrayWithObjects:certItem, keyItem, nil];
            }
        }
    } else {
        PDEBUG(@"Invalid arguments (certificate:%p privateKey:%p withName:%p).\n", certificate, privateKey, name);
        _error = EINVAL;
    }
    
    return result;
}

- (KeychainItem*)addCertificate:(Certificate*)cert {
    NameListEnumerator *nameEnumerator;
    DistinguishedNameEnumerator *fieldEnumerator;
    NameList *subject = [[cert subject] retain];
    DistinguishedName *currentName;
    TypeValuePair *currentPair;
    NSString *name = nil;
    KeychainItem *result;
    
    // The purpose of the following is to [eventually] return a brief but succinct name for the item.  At present, it doesn't really do this; the common name is not likely enough to uniquely identify this certificate amongst the others in the receiver.
    
    nameEnumerator = (NameListEnumerator*)[subject nameEnumerator];

    while (currentName = [nameEnumerator nextObject]) {
        fieldEnumerator = (DistinguishedNameEnumerator*)[currentName fieldEnumerator];

        while (currentPair = [fieldEnumerator nextObject]) {
            if ([currentPair isCommonName]) {
                name = [NSStringFromNSData([currentPair value]) retain];
                break;
            }
        }
    }

    if (!name) {
        // Eek, we haven't got a common name.  Shit.
        name = @"Unnamed";
    }
    
    result = [self addCertificate:cert withName:name];
    [name release];

    return result;
    
    // Yes, so the following single line is simpler.  But if the above way works, it should generate much nicer results, and remove another important dependency on the Sec* library.  Also, it's not clear whether you can just cast the input cert to a KeychainItem and return that, and in any case that's semantically invalid, so we'd have to do annoying tricks to get the KeychainItem after adding the cert.
    //_error = SecCertificateAddToKeychain([cert certificateRef], _keychain);
}

// The following addGenericPassword: method was originally contributed by Mark Ackerman, now heavily modified by Wade Tregaskis.

//  Basic logic;
//     1.  First try to add keychain item with attributes given in method
//         arguments,
//     2.  If an item with same account and service is found in the keychain,
//        a.  Modify the password data, or
//        b.  Fail, if "replace" is NO

- (KeychainItem*)addGenericPassword:(NSString*)password onService:(NSString*)service forAccount:(NSString*)account replaceExisting:(BOOL)replace {
    const char *serviceString, *accountString, *passwordString;
    size_t serviceStringLength, accountStringLength, passwordStringLength;
    SecKeychainItemRef newItem;
    KeychainItem *result = nil;
    
    passwordString = ((nil != password) ? [password UTF8String] : NULL);
    accountString = ((nil != account) ? [account UTF8String] : NULL);
    serviceString = ((nil != service) ? [service UTF8String] : NULL);
    
    passwordStringLength = ((NULL != passwordString) ? strlen(passwordString) : 0);
    accountStringLength = ((NULL != accountString) ? strlen(accountString) : 0);
    serviceStringLength = ((NULL != serviceString) ? strlen(serviceString) : 0);

    _error = SecKeychainAddGenericPassword(_keychain, (uint32_t)serviceStringLength, serviceString, (uint32_t)accountStringLength, accountString, (uint32_t)passwordStringLength, passwordString, &newItem);
    
    if (noErr == _error) {
        result = [KeychainItem keychainItemWithKeychainItemRef:newItem];
    } else if ((errSecDuplicateItem == _error) && replace) {
        SecKeychainItemRef existingItem;
        
        _error = SecKeychainFindGenericPassword(_keychain, (uint32_t)serviceStringLength, serviceString, (uint32_t)accountStringLength, accountString, NULL, NULL, &existingItem);
        
        if (noErr == _error) {
            _error = SecKeychainItemModifyContent(existingItem, NULL, (uint32_t)passwordStringLength, (void*)passwordString);
            
            if (noErr == _error) {
                result = [KeychainItem keychainItemWithKeychainItemRef:existingItem];
            } else {
                PSYSLOGND(LOG_ERR, @"Unable to modify existing entry, error %@.\n", OSStatusAsString(_error));
                PDEBUG(@"SecKeychainItemModifyContent(%p, NULL, <hidden>, <hidden>) returned error %@.\n", existingItem, OSStatusAsString(_error));
            }
            
            if (NULL != existingItem) {
                CFRelease(existingItem);
            }
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to retrieve existing item to update, error %@.\n", OSStatusAsString(_error));
            PDEBUG(@"SecKeychainFindGenericPassword(%p, %u, \"%@\", %u, \"%@\", NULL, NULL, %p) returned error %@.\n", _keychain, serviceStringLength, service, accountStringLength, account, &existingItem, OSStatusAsString(_error));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to add password to keychain, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainAddGenericPassword(%p, %u, \"%@\", %u, \"%@\", <hidden>, <hidden>, NULL) returned error %@.\n", _keychain, serviceStringLength, service, accountStringLength, account, OSStatusAsString(_error));
    }
    
	if (nil != result) {
		// 1) Set the creator code, if possible.
		
		CFBundleRef mainBundle = CFBundleGetMainBundle();
		FourCharCode creatorCode = 0;
		
		if (NULL != mainBundle) {
			CFBundleGetPackageInfo(mainBundle, NULL, &creatorCode);
			
			if ('????' == creatorCode) {
				creatorCode = 0;
			}
		}
		
		[result setCreator:creatorCode];
		
		
		// 2) Mark the password as invalid (and invisible) if it was given as nil.
		
		if (nil == password) {
			[result setPasswordIsValid:NO];
			[result setIsVisible:NO];
		}
	}
	
    return result;
}

- (KeychainItem*)addInternetPassword:(NSString*)password onServer:(NSString*)server forAccount:(NSString*)account port:(uint32_t)port path:(NSString*)path inSecurityDomain:(NSString*)securityDomain protocol:(SecProtocolType)protocol auth:(SecAuthenticationType)authType replaceExisting:(BOOL)replace {
    const char *serverString, *accountString, *passwordString, *pathString, *securityDomainString;
    size_t serverStringLength, accountStringLength, passwordStringLength, pathStringLength, securityDomainStringLength;
    SecKeychainItemRef newItem;
    KeychainItem *result = nil;
    
    passwordString = ((nil != password) ? [password UTF8String] : NULL);
    accountString = ((nil != account) ? [account UTF8String] : NULL);
    serverString = ((nil != server) ? [server UTF8String] : NULL);
    pathString = ((nil != path) ? [path UTF8String] : NULL);
    securityDomainString = ((nil != securityDomain) ? [securityDomain UTF8String] : NULL);

    passwordStringLength = ((NULL != passwordString) ? strlen(passwordString) : 0);
    accountStringLength = ((NULL != accountString) ? strlen(accountString) : 0);
    serverStringLength = ((NULL != serverString) ? strlen(serverString) : 0);
    pathStringLength = ((NULL != pathString) ? strlen(pathString) : 0);
    securityDomainStringLength = ((NULL != securityDomainString) ? strlen(securityDomainString) : 0);

    _error = SecKeychainAddInternetPassword(_keychain, (uint32_t)serverStringLength, serverString, (uint32_t)securityDomainStringLength, securityDomainString, (uint32_t)accountStringLength, accountString, (uint32_t)pathStringLength, pathString, port, protocol, authType, (uint32_t)passwordStringLength, passwordString, &newItem);

    if (noErr == _error) {
        result = [KeychainItem keychainItemWithKeychainItemRef:newItem];
    } else if ((_error == errSecDuplicateItem) && replace) {
        SecKeychainItemRef existingItem;

        _error = SecKeychainFindInternetPassword(_keychain, (uint32_t)serverStringLength, serverString, (uint32_t)securityDomainStringLength, securityDomainString, (uint32_t)accountStringLength, accountString, (uint32_t)pathStringLength, pathString, port, protocol, authType, NULL, NULL, &existingItem);
        
        if (noErr == _error) {
            _error = SecKeychainItemModifyAttributesAndData(existingItem, NULL, (uint32_t)passwordStringLength, passwordString);
            
            if (noErr == _error) {
                result = [KeychainItem keychainItemWithKeychainItemRef:existingItem];
            } else {
                PSYSLOGND(LOG_ERR, @"Unable to modify existing entry, error %@.\n", OSStatusAsString(_error));
                PDEBUG(@"SecKeychainItemModifyAttributesAndData(%p, NULL, <hidden>, <hidden>) returned error %@.\n", existingItem, OSStatusAsString(_error));
            }
            
            if (NULL != existingItem) {
                CFRelease(existingItem);
            }
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to retrieve existing item to update, error %@.\n", OSStatusAsString(_error));
            PDEBUG(@"SecKeychainFindInternetPassword(%p, %"PRIu32", \"%@\", %"PRIu32", \"%@\", %"PRIu32", \"%@\", %"PRIu32", \"%@\", %"PRIu16", %@, %@, NULL, NULL, %p) returned error %@.\n",
				   _keychain,
				   
				   serverStringLength,
				   serverString,
				   securityDomainStringLength,
				   securityDomainString,
				   accountStringLength,
				   accountString,
				   pathStringLength,
				   pathString,
				   
				   port,
				   nameOfProtocolConstant(protocol),
				   nameOfAuthenticationType(authType),
				   
				   &existingItem,
				   OSStatusAsString(_error));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to add internet password, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainAddInternetPassword(%p, %"PRIu32", \"%@\", %"PRIu32", \"%@\", %"PRIu32", \"%@\", %"PRIu32", \"%@\", %"PRIu16", %@, %@, <hidden>, <hidden>, NULL) returned error %@.\n",
			   _keychain,
			   
			   serverStringLength,
			   server,
			   securityDomainStringLength,
			   securityDomain,
			   accountStringLength,
			   account,
			   pathStringLength,
			   path,
			   
			   port,
			   nameOfProtocolConstant(protocol),
			   nameOfAuthenticationType(authType),
			   
			   OSStatusAsString(_error));
    }
    
	if (nil != result) {
		// 1) Set the creator code, if possible.
		
		CFBundleRef mainBundle = CFBundleGetMainBundle();
		FourCharCode creatorCode = 0;
		
		if (NULL != mainBundle) {
			CFBundleGetPackageInfo(mainBundle, NULL, &creatorCode);
			
			if ('????' == creatorCode) {
				creatorCode = 0;
			}
		}
		
		[result setCreator:creatorCode];
		
		
		// 2) Fix up the port, if it's too large to fit in the 16-bit version that SecKeychainAddInternetPassword accepts.
		
		if (port > 0xffff) {
			[result setPort:port];
		}
		
		
		// 3) Mark the password as invalid (and invisible) if it was given as nil.
		
		if (nil == password) {
			[result setPasswordIsValid:NO];
			[result setIsVisible:NO];
		}
	}
	
    return result;
}

- (NSArray*)items {
    CSSM_DL_DB_HANDLE dbHandle;
    CSSM_HANDLE resultsHandle;
    NSMutableArray *results = nil;
    CSSM_DB_RECORD_ATTRIBUTE_DATA attr = {CSSM_DL_DB_RECORD_ANY, 0, 0, NULL};
    CSSM_DB_UNIQUE_RECORD *recordID;
    CSSM_QUERY query = {CSSM_DL_DB_RECORD_ANY, CSSM_DB_NONE, 0, NULL, {CSSM_QUERY_TIMELIMIT_NONE, CSSM_QUERY_SIZELIMIT_NONE}, 0};
    CSSM_DATA data = {0, NULL};
    
	_error = SecKeychainGetDLDBHandle(_keychain, &dbHandle);
	
    if (noErr == _error) {
		_error = CSSM_DL_DataGetFirst(dbHandle, &query, &resultsHandle, &attr, &data, &recordID);
		
        if (CSSM_OK == _error) {
            do {
                switch (attr.DataRecordType) {
                    case CSSM_DL_DB_RECORD_CERT:
                        PDEBUG(@"Found certificate.\n");
                        // Need to create a Certificate instance using this
                        break;
                    case CSSM_DL_DB_RECORD_CRL:
                        PDEBUG(@"Found CRL.\n");
                        // There is no real CRL facility as yet, except in the x509 stuff, so this needs a lot of work
                        break;
                    case CSSM_DL_DB_RECORD_POLICY:
                        PDEBUG(@"Found policy.\n");
                        // Need to create a Policy instance using this
                        break;
                    case CSSM_DL_DB_RECORD_GENERIC:
                        PDEBUG(@"Found generic.\n");
                        // Need to create a generic KeychainItem instance using this
                        break;
                    case CSSM_DL_DB_RECORD_PUBLIC_KEY:
                        PDEBUG(@"Found public key.\n");
                        // Need to create a Key instance using this
                        break;
                    case CSSM_DL_DB_RECORD_PRIVATE_KEY:
                        PDEBUG(@"Found private key.\n");
                        // Need to create a Key instance using this
                        break;
                    case CSSM_DL_DB_RECORD_SYMMETRIC_KEY:
                        PDEBUG(@"Found symmetric key.\n");
                        // Need to create a Key instance using this
                        break;
                    case CSSM_DL_DB_RECORD_GENERIC_PASSWORD:
                        PDEBUG(@"Found generic password.\n");
                        // Need to create a KeychainItem instance using this
                        break;
                    case CSSM_DL_DB_RECORD_INTERNET_PASSWORD:
                        PDEBUG(@"Found internet password.\n");
                        // Need to create a KeychainItem instance using this
                        break;
                    case CSSM_DL_DB_RECORD_APPLESHARE_PASSWORD:
                        PDEBUG(@"Found AppleShare password.\n");
                        // Need to create a KeychainItem instance using this
                        break;
                    case CSSM_DL_DB_RECORD_X509_CERTIFICATE:
                        PDEBUG(@"Found x509 certificate.\n");
                        // Need to create a Certificate instance using this
                        break;
                    case CSSM_DL_DB_RECORD_USER_TRUST:
                        PDEBUG(@"Found user trust.\n");
                        // Does this translate directly to a Trust instance?
                        break;
                    case CSSM_DL_DB_RECORD_METADATA:
                        PDEBUG(@"Found metadata.\n");
                        // Presumably this metadata has some good purpose for existing; need to figure out what
                        break;
                    default:
                        PDEBUG(@"Warning - unknown record type %d in Keychain.\n", attr.DataRecordType);
                }

                /*attr.DataRecordType = CSSM_DL_DB_RECORD_ANY;
                attr.SemanticInformation = 0;
                attr.NumberOfAttributes = 0;
                attr.AttributeData = NULL;*/ // This may cause a memory leak; the existing attributes should probably be released first
                
                _error = CSSM_DL_DataGetNext(dbHandle, resultsHandle, &attr, &data, &recordID);
            } while (_error == CSSM_OK);

            if ((CSSM_OK != _error) && (CSSMERR_DL_ENDOFDATA != _error)) {
                PSYSLOGND(LOG_ERR, @"Unable to list items in keychain because of _error %@.\n", CSSMErrorAsString(_error));
                PDEBUG(@"CSSM_DL_DataGetFirst(%"PRIdbHandle", %p, %p, %p, %p, %p) returned error %@.\n", dbHandle, &query, &resultsHandle, &attr, &data, &recordID, CSSMErrorAsString(_error));
            }
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to retrieve keychain %p's items, error %@.\n", CSSMErrorAsString(_error));
            PDEBUG(@"CSSM_DL_DataGetFirst(%"PRIdldbHandle", %p, %p, %p, %p, %p) returned error %@.\n", dbHandle, &query, &resultsHandle, &attr, &data, &recordID, CSSMErrorAsString(_error));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to retrieve keychain %p's items, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainGetDLDBHandle(%p, %p) returned error %@.\n", _keychain, &dbHandle, OSStatusAsString(_error));
    }

    return results;
}

// The following methods for passwordForGenericService: and genericService: were contributed by Mark Ackerman.  The passwordForInternetServer: and internetServer: methods were derived directly from them by Wade Tregaskis.

- (NSString*)passwordForGenericService:(NSString*)service forAccount:(NSString*)account {
    char *passData;
    uint32 passLength;
	
	const char *serviceString = [service UTF8String];
	const char *accountString = [account UTF8String];
	
	size_t serviceStringLength = ((nil != service) ? strlen(serviceString) : 0);
	size_t accountStringLength = ((nil != account) ? strlen(accountString) : 0);

    _error = SecKeychainFindGenericPassword(_keychain, (uint32_t)serviceStringLength, serviceString, (uint32_t)accountStringLength, accountString, &passLength, (void**)&passData, NULL);

    if (noErr == _error) {
        return [[[NSString alloc] initWithCStringNoCopy:passData length:passLength freeWhenDone:YES] autorelease];
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to find generic password, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainFindGenericPassword(%p, %u, \"%@\", %u, \"%@\", %p, %p, NULL) returned error %@.\n", _keychain, serviceStringLength, service, accountStringLength, account, &passLength, &passData, OSStatusAsString(_error));
        
        return nil;
    }
}

- (NSString*)passwordForInternetServer:(NSString*)server forAccount:(NSString*)account port:(uint16_t)port path:(NSString*)path inSecurityDomain:(NSString*)securityDomain protocol:(SecProtocolType)protocol auth:(SecAuthenticationType)authType {
    char *passData;
    uint32 passLength;
	
	const char *serverString, *accountString, *pathString, *securityDomainString;
    size_t serverStringLength, accountStringLength, pathStringLength, securityDomainStringLength;
    
    accountString = ((nil != account) ? [account UTF8String] : NULL);
    serverString = ((nil != server) ? [server UTF8String] : NULL);
    pathString = ((nil != path) ? [path UTF8String] : NULL);
    securityDomainString = ((nil != securityDomain) ? [securityDomain UTF8String] : NULL);
	
    accountStringLength = ((NULL != accountString) ? strlen(accountString) : 0);
    serverStringLength = ((NULL != serverString) ? strlen(serverString) : 0);
    pathStringLength = ((NULL != pathString) ? strlen(pathString) : 0);
    securityDomainStringLength = ((NULL != securityDomainString) ? strlen(securityDomainString) : 0);
	
    _error = SecKeychainFindInternetPassword(_keychain,
											 (uint32_t)serverStringLength,
											 serverString,
											 (uint32_t)securityDomainStringLength,
											 securityDomainString,
											 (uint32_t)accountStringLength,
											 accountString,
											 (uint32_t)pathStringLength,
											 pathString,
											 port,
											 protocol,
											 authType,
											 &passLength,
											 (void**)&passData,
											 NULL);
    
    if (noErr == _error) {
        return [[[NSString alloc] initWithCStringNoCopy:passData length:passLength freeWhenDone:YES] autorelease];
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to find internet password, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainFindInternetPassword(%p, %"PRIu32", \"%@\", %"PRIu32", \"%@\", %"PRIu32", \"%@\", %"PRIu32", \"%@\", %"PRIu16", %@, %@, %p, %p, NULL) returned error %@.\n",
			   _keychain,
			   
			   serverStringLength,
			   server,
			   securityDomainStringLength,
			   securityDomain,
			   accountStringLength,
			   account,
			   pathStringLength,
			   path,
			   
			   port,
			   nameOfProtocolConstant(protocol),
			   nameOfAuthenticationTypeConstant(authType),
			   
			   &passLength,
			   &passData,
			   
			   OSStatusAsString(_error));
        
        return nil;
    }
}

- (KeychainItem*)genericService:(NSString*)service forAccount:(NSString*)account {
    KeychainItem *keychainItem = nil;
    SecKeychainItemRef result = NULL;

    _error = SecKeychainFindGenericPassword(_keychain, (service ? (uint32_t)strlen([service UTF8String]) : 0), [service UTF8String], (account ? (uint32_t)strlen([account UTF8String]) : 0), [account UTF8String], NULL, NULL, &result);

    if ((noErr == _error) && result) {
        keychainItem = [KeychainItem keychainItemWithKeychainItemRef:result];
        CFRelease(result);
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to retrieve generic keychain item, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainFindGenericPassword(%p, %u, \"%@\", %u, \"%@\", NULL, NULL, %p) returned error %@.\n", _keychain, (service ? strlen([service UTF8String]) : 0), service, (account ? strlen([account UTF8String]) : 0), account, &result, OSStatusAsString(_error));
    }
    
    return keychainItem;
}

- (KeychainItem*)internetServer:(NSString*)server forAccount:(NSString*)account port:(uint16_t)port path:(NSString*)path inSecurityDomain:(NSString*)securityDomain protocol:(SecProtocolType)protocol auth:(SecAuthenticationType)authType {
    KeychainItem *keychainItem = nil;
    SecKeychainItemRef result = NULL;
	
	const char *serverString, *accountString, *pathString, *securityDomainString;
    size_t serverStringLength, accountStringLength, pathStringLength, securityDomainStringLength;
    
    accountString = ((nil != account) ? [account UTF8String] : NULL);
    serverString = ((nil != server) ? [server UTF8String] : NULL);
    pathString = ((nil != path) ? [path UTF8String] : NULL);
    securityDomainString = ((nil != securityDomain) ? [securityDomain UTF8String] : NULL);
	
    accountStringLength = ((NULL != accountString) ? strlen(accountString) : 0);
    serverStringLength = ((NULL != serverString) ? strlen(serverString) : 0);
    pathStringLength = ((NULL != pathString) ? strlen(pathString) : 0);
    securityDomainStringLength = ((NULL != securityDomainString) ? strlen(securityDomainString) : 0);
	
    _error = SecKeychainFindInternetPassword(_keychain,
											 (uint32_t)serverStringLength,
											 serverString,
											 (uint32_t)securityDomainStringLength,
											 securityDomainString,
											 (uint32_t)accountStringLength,
											 accountString,
											 (uint32_t)pathStringLength,
											 pathString,
											 port,
											 protocol,
											 authType,
											 NULL,
											 NULL,
											 &result);

    if ((noErr == _error) && result) {
        keychainItem = [KeychainItem keychainItemWithKeychainItemRef:result];
        CFRelease(result);
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to find internet keychain item, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainFindInternetPassword(%p, %"PRIu32", \"%@\", %"PRIu32", \"%@\", %"PRIu32", \"%@\", %"PRIu32", \"%@\", %"PRIu16", %@, %@, NULL, NULL, %p) returned error %@.\n",
			   _keychain,
			   
			   serverStringLength,
			   server,
			   securityDomainStringLength,
			   securityDomain,
			   accountStringLength,
			   account,
			   pathStringLength,
			   path,
			   
			   port,
			   nameOfProtocolConstant(protocol),
			   nameOfAuthenticationTypeConstant(authType),
			   
			   &result,
			   OSStatusAsString(_error));
    }

    return keychainItem;
}

- (NSArray*)identitiesForUse:(CSSM_KEYUSE)use {
    SecIdentitySearchRef search = NULL;
    SecIdentityRef result = NULL;
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:5];

    _error = SecIdentitySearchCreate(_keychain, use, &search);

    if ((noErr == _error) && search) {
        while ((noErr == (_error = SecIdentitySearchCopyNext(search, &result))) && result) {
            [results addObject:[Identity identityWithIdentityRef:result]];
            CFRelease(result);
        }

        if ((noErr != _error) && (errSecItemNotFound != _error)) {
            PSYSLOGND(LOG_ERR, @"Unable to search for identities for use %@, error %@.\n", descriptionOfKeyUsage(use), OSStatusAsString(_error));
            PDEBUG(@"SecIdentitySearchCopyNext(%p, %p) returned error %@.\n", _keychain, &search, OSStatusAsString(_error));
        }
        
        CFRelease(search);

        return results;
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to search for identities for use %@, error %@.\n", descriptionOfKeyUsage(use), OSStatusAsString(_error));
        PDEBUG(@"SecIdentitySearchCreate(%p, %"PRIu32" [%@], %p) returned error %@.\n", _keychain, use, descriptionOfKeyUsageUsingConstants(use), &search, OSStatusAsString(_error));
        
        return nil;
    }
}

- (NSArray*)identities {
    return [self identitiesForUse:0];
}

- (NSArray*)identitiesForAnyUse {
    return [self identitiesForUse:CSSM_KEYUSE_ANY];
}

- (NSArray*)identitiesForEncryption {
    return [self identitiesForUse:CSSM_KEYUSE_ENCRYPT];
}

- (NSArray*)identitiesForDecryption {
    return [self identitiesForUse:CSSM_KEYUSE_DECRYPT];
}

- (NSArray*)identitiesForSigning {
    return [self identitiesForUse:CSSM_KEYUSE_SIGN];
}

- (NSArray*)identitiesForVerifying {
    return [self identitiesForUse:CSSM_KEYUSE_VERIFY];
}

- (NSArray*)identitiesForSignRecovery {
    return [self identitiesForUse:CSSM_KEYUSE_SIGN_RECOVER];
}

- (NSArray*)identitiesForVerifyRecovery {
    return [self identitiesForUse:CSSM_KEYUSE_VERIFY_RECOVER];
}

- (NSArray*)identitiesForWrapping {
    return [self identitiesForUse:CSSM_KEYUSE_WRAP];
}

- (NSArray*)identitiesForUnwrapping {
    return [self identitiesForUse:CSSM_KEYUSE_UNWRAP];
}

- (NSArray*)identitiesForDeriving {
    return [self identitiesForUse:CSSM_KEYUSE_DERIVE];
}

- (NSArray*)createAndAddKeyPairWithAlgorithm:(CSSM_ALGORITHMS)alg bitSize:(uint32_t)size publicUse:(CSSM_KEYUSE)pubUse publicAttributes:(uint32_t)pubAttr privateUse:(CSSM_KEYUSE)privUse privateAttributes:(uint32_t)privAttr access:(Access*)acc {
    SecKeyRef pubResult = NULL, privResult = NULL;
    NSArray *res;
    
    _error = SecKeyCreatePair(_keychain, alg, size, 0LL, pubUse, pubAttr, privUse, privAttr, [acc accessRef], &pubResult, &privResult);

    if ((noErr == _error) && pubResult && privResult) {
        res = [NSArray arrayWithObjects:[Key keyWithKeyRef:pubResult module:[self CSPModule]], [Key keyWithKeyRef:privResult module:[self CSPModule]], nil];

        CFRelease(pubResult);
        CFRelease(privResult);

        return res;
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create key pair, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeyCreatePair(%p, %"PRIu32" [%@], %"PRIu32", %"PRIu32" [%@], %"PRIu32", %"PRIu32" [%@], %"PRIu32", %p, %p, %p) returned error %@.\n", _keychain, alg, size, nil, pubUse, descriptionOfKeyUsageUsingConstants(pubUse), pubAttr, privUse, descriptionOfKeyUsageUsingConstants(privUse), privAttr, [acc accessRef], &pubResult, &privResult, OSStatusAsString(_error));
        
        return nil;
    }
}

- (void)setAccess:(Access*)access {
    _error = SecKeychainSetAccess(_keychain, [access accessRef]);
    
    if (noErr != _error) {
        PSYSLOGND(LOG_ERR, @"Unable to set keychain %p's access to %p, error %@.\n", self, access, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainSetAccess(%p, %p) returned error %@.\n", _keychain, [access accessRef], OSStatusAsString(_error));
    }
}

- (Access*)access {
    SecAccessRef result = NULL;
    Access *res;
    
    _error = SecKeychainCopyAccess(_keychain, &result);

    if ((noErr == _error) && result) {
        res = [Access accessWithAccessRef:result];
        CFRelease(result);

        return res;
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to retrieve access of keychain %p, error %@.\n", self, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainCopyAccess(%p, %p) returned error %@.\n", _keychain, &result, OSStatusAsString(_error));
        
        return nil;
    }
}

- (CSSMModule*)CSPModule {
    CSSM_CSP_HANDLE cspHandle;
    
    _error = SecKeychainGetCSPHandle(_keychain, &cspHandle);
    
    if (noErr != _error) {
        PSYSLOGND(LOG_ERR, @"Unable to retrieve keychain's CSP handle, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainGetCSPHandle(%p, %p) returned error %@.\n", _keychain, &cspHandle, OSStatusAsString(_error));
        
        return nil;
    } else {
        return [CSSMModule moduleWithHandle:cspHandle];
    }
}

- (CSSMModule*)DLModule {
    CSSM_DL_DB_HANDLE dldbHandle;
    
    _error = SecKeychainGetDLDBHandle(_keychain, &dldbHandle);
    
    if (noErr != _error) {
        PSYSLOGND(LOG_ERR, @"Unable to retrieve keychain's DLDB handle, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainGetDLDBHandle(%p, %p) returned error %@.\n", _keychain, &dldbHandle, OSStatusAsString(_error));
        
        return nil;
    } else {
        return [CSSMModule moduleWithHandle:dldbHandle.DLHandle];
    }
}

- (void)deleteCompletely {
    // WARNING - THIS REALLY DOES DELETE THE KEYCHAIN, COMPLETELY AND IRREVERSIBLY, INCLUDING ALL ITS CONTENTS
    // BOTH IN MEMORY AND ON DISK
    
    // I'm hesitant to even include this code...
    // I'm sure someone's going to call it at least once by accident.
    // You have been warned.

    // Btw, this definitely does work, don't test it - I did (don't ask)
    
    _error = SecKeychainDelete(_keychain);

    if (noErr == _error) {
        _keychain = NULL;
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to delete keychain %p, error %@.\n", self, OSStatusAsString(_error));
        PDEBUG(@"SecKeychainDelete(%p) returned error %@.\n", OSStatusAsString(_error));
    }
}

- (OSStatus)lastError {
    return _error;
}

- (SecKeychainRef)keychainRef {
    return _keychain;
}

- (void)dealloc {
    if (_keychain) {
        CFRelease(_keychain);
        _keychain = NULL;
    }
    
    [super dealloc];
}

@end


NSArray* defaultSetOfKeychains(void) {
    CFArrayRef result = NULL;
    CFIndex i, c;
    NSMutableArray *finalResult = nil;
    int _error;

    _error = SecKeychainCopySearchList(&result);

    if ((_error == 0) && result) {
        c = CFArrayGetCount(result);
        finalResult = [[NSMutableArray alloc] initWithCapacity:c];
        
        for (i = 0; i < c; ++i) {
            [finalResult addObject:[Keychain keychainWithKeychainRef:(SecKeychainRef)CFArrayGetValueAtIndex(result, i)]];
        }

        CFRelease(result);
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create keychain search, error %@.\n", OSStatusAsString(_error));
        PDEBUG(@"SecKeychainCopySearchList(%p) returned error %@.\n", &result, OSStatusAsString(_error));
    }

    return [finalResult autorelease];
}


NSArray* completeSetOfKeychains(void) {
    // We want to browse the Keychain folders at the following locations:
    //
    // /System/Library/
    // /Users/<username>/Library/
    //
    // This does not guarantee to include all keychains on a system, but given
    // that these are the only real places you should find (and put) useful
    // keychains, it should be sufficient in most cases.

    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:5];
    Keychain *temp;
    BOOL wantFolders = YES, dontWantFolders = NO;
    NSEnumerator *folderEnumerator, *userEnumerator;
    NSString *currentPath, *currentKeychainFile;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    static NSString *rootKeychains = @"/System/Library/Keychains/", *usersDirectory = @"/Users/";
    folderEnumerator = [[fileManager directoryContentsAtPath:rootKeychains] objectEnumerator];
    
    while (currentKeychainFile = [folderEnumerator nextObject]) {
        currentKeychainFile = [rootKeychains stringByAppendingPathComponent:currentKeychainFile];

        if ([fileManager fileExistsAtPath:currentKeychainFile isDirectory:&dontWantFolders]) {
            temp = [[Keychain alloc] initFromPath:currentKeychainFile];

            if (temp) {
                //PDEBUG(@"Found valid keychain at: %@\n", currentKeychainFile);
                
                [result addObject:temp];
                [temp release];
            }
        }
    }

    userEnumerator = [[fileManager directoryContentsAtPath:usersDirectory] objectEnumerator];

    while (currentPath = [userEnumerator nextObject]) {
        currentPath = [[usersDirectory stringByAppendingPathComponent:currentPath] stringByAppendingPathComponent:@"Library/Keychains"];

        if ([fileManager fileExistsAtPath:currentPath isDirectory:&wantFolders]) {
            folderEnumerator = [[fileManager directoryContentsAtPath:currentPath] objectEnumerator];

            while (currentKeychainFile = [folderEnumerator nextObject]) {
                currentKeychainFile = [currentPath stringByAppendingPathComponent:currentKeychainFile];
                
                if ([fileManager fileExistsAtPath:currentKeychainFile isDirectory:&dontWantFolders]) {
                    temp = [[Keychain alloc] initFromPath:currentKeychainFile];

                    if (temp) {
                        //PDEBUG(@"Found valid keychain at: %@\n", currentKeychainFile);

                        [result addObject:temp];
                        [temp release];
                    }
                }
            }
        }
    }

    return [result autorelease];
}

NSArray* keychainsForUser(NSString *username) {
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:5];
    Keychain *temp;
    BOOL dontWantFolders = NO;
    NSEnumerator *folderEnumerator;
    NSString *currentKeychainFile;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *specificUserDirectory;
    
    if (username) {
        specificUserDirectory = NSHomeDirectoryForUser(username);
    } else {
        specificUserDirectory = NSHomeDirectory();
    }

    //PDEBUG(@"Home directory for %@ is %@.\n", username, specificUserDirectory);

    specificUserDirectory = [specificUserDirectory stringByAppendingPathComponent:@"Library/Keychains"];
    
    folderEnumerator = [[fileManager directoryContentsAtPath:specificUserDirectory] objectEnumerator];

    while (currentKeychainFile = [folderEnumerator nextObject]) {
        currentKeychainFile = [specificUserDirectory stringByAppendingPathComponent:currentKeychainFile];

        if ([fileManager fileExistsAtPath:currentKeychainFile isDirectory:&dontWantFolders]) {
            temp = [[Keychain alloc] initFromPath:currentKeychainFile];

            if (temp) {
                //PDEBUG(@"Found valid keychain at: %@\n", currentKeychainFile);

                [result addObject:temp];
                [temp release];
            }
        }
    }
    
    return [result autorelease];
}
