//
//  Keychain.m
//  Keychain
//
//  Created by Wade Tregaskis on Fri Jan 24 2003.
//  Modified by Wade Tregaskis & Mark Ackerman on Mon Sept 29 2003 [redone all the password-related methods].
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "Keychain.h"

#import <sys/param.h>

#import "UtilitySupport.h"
#import "CSSMUtils.h"
#import "CSSMTypes.h"
#import "MultiThreadingInternal.h"
#import "CompilerIndependence.h"

#import "Logging.h"


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
            PCONSOLE(@"Unable to install keychain events callback (error #%d); no keychain event notifications will be posted.\n", err);
            PDEBUG(@"SecKeychainAddCallback(%p, %x [kSecEveryMask], NULL) returned error #%d.\n", keychainEventCallback, kSecEveryEventMask, err);
        }
    }
}

+ (UInt32)keychainManagerVersion {
    UInt32 result;
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

+ (Keychain*)createNewKeychainAtPath:(NSString*)path withPassword:(NSString*)password {
    return [[[[self class] alloc] initNewAtPath:path withPassword:password] autorelease];
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
                keychain = keych;
                error = CSSM_OK;
            }
        }
    } else {
        [self release];
        self = nil;
    }
    
    return self;
}

- (Keychain*)initNewAtPath:(NSString*)path withPassword:(NSString*)password {
    if (path) {
        // FLAG - should the fourth argument below, Boolean promptUser, be hard wired to yes?
        error = SecKeychainCreate([path cString], [password cStringLength], [password cString], YES, NULL, &keychain);
        
        if (error != CSSM_OK) {
            [self release];
            self = nil;
        } else {
            if (self = [super init]) {
                error = CSSM_OK;
            }
        }
    } else {
        [self release];
        self = nil;
    }
    
    return self;
}

- (Keychain*)initFromDefault {
    Keychain *existingObject;
    
    error = SecKeychainCopyDefault(&keychain);

    if (error != CSSM_OK) {
        [self release];
        self = nil;
    } else {
        existingObject = [[self class] instanceWithKey:(id)keychain from:@selector(keychainRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            self = [existingObject retain];
        } else {
            if (self = [super init]) {
                error = CSSM_OK;
            }
        }
    }
    
    return self;
}

- (Keychain*)initFromPath:(NSString*)path {
    Keychain *existingObject;
    
    error = SecKeychainOpen([path cString], &keychain);

    if (error != CSSM_OK) {
        [self release];
        self = nil;
    } else {
        existingObject = [[self class] instanceWithKey:(id)keychain from:@selector(keychainRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            self = [existingObject retain];
        } else {
            if (self = [super init]) {
                error = CSSM_OK;
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
    UInt32 length = MAXPATHLEN;

    error = SecKeychainGetPath(keychain, &length, buffer);

    if ((error == 0) && (length > 0)) {
        return [NSString stringWithCString:buffer length:length];
    } else {
        return nil;
    }
}

- (BOOL)lock {
    error = SecKeychainLock(keychain);

    return (error == 0);
}

- (BOOL)unlock {
    error = SecKeychainUnlock(keychain, 0, NULL, NO);

    return (error == 0);
}

- (BOOL)unlockWithPassword:(NSString*)password {
    if (password) {
        error = SecKeychainUnlock(keychain, [password cStringLength], (void*)[password cString], YES);
    } else {
        error = SecKeychainUnlock(keychain, 0, NULL, YES);
    }

    return (error == 0);
}

- (void)makeDefault {
    error = SecKeychainSetDefault(keychain);
}

- (BOOL)isUnlocked {
    SecKeychainStatus result;

    error = SecKeychainGetStatus(keychain, &result);

    return ((error == 0) && (result & kSecUnlockStateStatus));
}

- (BOOL)isReadOnly {
    SecKeychainStatus result;

    error = SecKeychainGetStatus(keychain, &result);

    return ((error == 0) && (result & kSecReadPermStatus));
}

- (BOOL)isWritable {
    SecKeychainStatus result;

    error = SecKeychainGetStatus(keychain, &result);

    return ((error == 0) && (result & kSecWritePermStatus));
}

- (void)setVersion:(UInt32)version {
    SecKeychainSettings settings;

    error = SecKeychainCopySettings(keychain, &settings);

    if (error == 0) {
        settings.version = version;

        error = SecKeychainSetSettings(keychain, &settings);
    }
}

- (UInt32)version {
    SecKeychainSettings settings;

    error = SecKeychainCopySettings(keychain, &settings);

    if (error == 0) {
        return settings.version;
    } else {
        return -1;
    }
}

- (void)setLockOnSleep:(BOOL)lockOnSleep {
    SecKeychainSettings settings;

    error = SecKeychainCopySettings(keychain, &settings);

    if (error == 0) {
        settings.lockOnSleep = lockOnSleep;

        error = SecKeychainSetSettings(keychain, &settings);
    }
}

- (BOOL)willLockOnSleep {
    SecKeychainSettings settings;

    error = SecKeychainCopySettings(keychain, &settings);

    if (error == 0) {
        return settings.lockOnSleep;
    } else {
        return NO;
    }
}

- (void)setLockAfterInterval:(BOOL)lockAfterInterval {
    SecKeychainSettings settings;

    error = SecKeychainCopySettings(keychain, &settings);

    if (error == 0) {
        settings.useLockInterval = lockAfterInterval;

        error = SecKeychainSetSettings(keychain, &settings);
    }
}

- (BOOL)willLockAfterInterval {
    SecKeychainSettings settings;

    error = SecKeychainCopySettings(keychain, &settings);

    if (error == 0) {
        return settings.useLockInterval;
    } else {
        return NO;
    }
}

- (void)setInterval:(UInt32)interval {
    SecKeychainSettings settings;

    error = SecKeychainCopySettings(keychain, &settings);

    if (error == 0) {
        settings.lockInterval = interval;

        error = SecKeychainSetSettings(keychain, &settings);
    }
}

- (UInt32)interval {
    SecKeychainSettings settings;

    error = SecKeychainCopySettings(keychain, &settings);

    if (error == 0) {
        return settings.lockInterval;
    } else {
        return -1;
    }
}

- (void)addItem:(KeychainItem*)item {
    if (item) {
        SecKeychainItemRef result = NULL;
        
        error = SecKeychainItemCreateCopy([item keychainItemRef], keychain, [[item access] accessRef], &result);
        
        if ((error == 0) && result) {
            CFRelease(result);
        }
    }
}

- (KeychainItem*)addNewItemWithClass:(SecItemClass)itemClass access:(Access*)initialAccess {
    SecKeychainItemRef keychainItem;
    SecKeychainAttributeList attributes = {0, nil};
    
    error = SecKeychainItemCreateFromContent(itemClass, &attributes, 0, nil, keychain, [initialAccess accessRef], &keychainItem);
    
    return error ? nil : [KeychainItem keychainItemWithKeychainItemRef:keychainItem];
}

/*- (void)importCertificateBundle:(CertificateBundle*)bundle {
    error = SecCertificateBundleImport(keychain, [bundle bundle], [bundle type], [bundle encoding], nil);
}*/

- (void)addCertificate:(Certificate*)certificate withName:(NSString*)name {
    CSSM_DB_ATTRIBUTE_DATA attrs[6];
    CSSM_DB_RECORD_ATTRIBUTE_DATA recordAttrs;
    CSSM_DB_ATTRIBUTE_DATA_PTR attr = &attrs[0];
    CSSM_DATA certTypeData = {0, NULL}, certEncData = {0, NULL}, printNameData = {0, NULL}, rawCertData = {0, NULL}, pubKeyHash = {0, NULL};
    CSSM_DL_DB_HANDLE DLDBHandle;
    CSSM_DB_UNIQUE_RECORD_PTR recordPtr;
    CSSM_DATA *issuer = [certificate rawValueOfField:&CSSMOID_X509V1IssuerNameCStruct];
    CSSM_DATA *serial = [certificate rawValueOfField:&CSSMOID_X509V1SerialNumber];
    NSData *publicKeyHash, *rawData;
    CSSM_CERT_TYPE certType = [certificate type];
    CSSM_CERT_ENCODING certEncoding = [certificate encoding];

    if (SecKeychainGetDLDBHandle(keychain, &DLDBHandle) == 0) {
        [certificate retain];

        rawData = [[certificate data] retain];
        copyNSDataToDataNoCopy(rawData, &rawCertData);

        certTypeData.Data = (uint8*)&certType;
        certTypeData.Length = sizeof(CSSM_CERT_TYPE);

        certEncData.Data = (uint8*)&certEncoding;
        certEncData.Length = sizeof(CSSM_CERT_ENCODING);

        printNameData.Data = (uint8*)[name cString];
        printNameData.Length = [name cStringLength];

        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "CertType";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = &certTypeData;

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "CertEncoding";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = &certEncData;

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "PrintName";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;
        attr->Value = &printNameData;

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "PublicKeyHash";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;

        publicKeyHash = [[[certificate publicKey] keyHash] retain];
        copyNSDataToDataNoCopy(publicKeyHash, &pubKeyHash);
        attr->Value = &pubKeyHash;

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "Issuer";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;
        attr->Value = issuer;

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "SerialNumber";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;
        attr->Value = serial;

        recordAttrs.DataRecordType = CSSM_DL_DB_RECORD_X509_CERTIFICATE;
        recordAttrs.SemanticInformation = 0;
        recordAttrs.NumberOfAttributes = 6;
        recordAttrs.AttributeData = attrs;

        if ((error = CSSM_DL_DataInsert(DLDBHandle, CSSM_DL_DB_RECORD_X509_CERTIFICATE, &recordAttrs, &rawCertData, &recordPtr)) == CSSM_OK) {
            error = CSSM_DL_FreeUniqueRecord(DLDBHandle, recordPtr);
        }

        [rawData release];
        [publicKeyHash release];
        [certificate release];
    }
}

- (void)addKey:(Key*)key withName:(NSString*)name isPermanent:(BOOL)isPermanent isPrivate:(BOOL)isPrivate publicKeyHash:(NSData*)publicKeyHash {
    CSSM_DB_RECORDTYPE recType;
    int attributeCount = 26;
    uint32 keySize;
    CSSM_DB_ATTRIBUTE_DATA attrs[27];
    CSSM_DB_RECORD_ATTRIBUTE_DATA recordAttrs;
    CSSM_DB_ATTRIBUTE_DATA_PTR attr = &attrs[0];
    CSSM_DL_DB_HANDLE DLDBHandle;
    CSSM_DB_UNIQUE_RECORD_PTR recordPtr;
    CSSM_BOOL boolFalse = CSSM_FALSE, boolTrue = CSSM_TRUE;
    CSSM_DATA cssmFalse = {sizeof(CSSM_BOOL), (uint8_t*)&boolFalse},
              cssmTrue = {sizeof(CSSM_BOOL), (uint8*)&boolTrue},
              printNameData = {0, NULL},
              recTypeData = {sizeof(CSSM_DB_RECORDTYPE), NULL},
              cspIdData = {sizeof(CSSM_GUID), NULL},
              algIdData = {sizeof(CSSM_ALGORITHMS), NULL},
              logicalKeySizeData = {sizeof(uint32), NULL},
              startDateData = {sizeof(CSSM_DATE), NULL},
              endDateData = {sizeof(CSSM_DATE), NULL},
              pubKeyHash = {0, NULL},
              keySizeData = {sizeof(uint32), NULL},
              appTag = {19, (uint8_t*)"Keychain Framework"};
    const CSSM_KEYHEADER *keyHeader = NULL;
    
    if (SecKeychainGetDLDBHandle(keychain, &DLDBHandle) == 0) {
        [key retain];
        [publicKeyHash retain];
        [name retain];
        
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

        keyHeader = &([key CSSMKey]->KeyHeader);

        recTypeData.Data = (uint8*)&recType;
        cspIdData.Data = (uint8*)&keyHeader->CspId;
        algIdData.Data = (uint8*)&keyHeader->AlgorithmId;
        logicalKeySizeData.Data = (uint8*)&keyHeader->LogicalKeySizeInBits;
        startDateData.Data = (uint8*)&keyHeader->StartDate;
        endDateData.Data = (uint8*)&keyHeader->EndDate;
        
        printNameData.Data = (uint8*)[name cString];
        printNameData.Length = [name cStringLength];

        keySize = [key CSSMKey]->KeyData.Length * 8;
        keySizeData.Data = (uint8*)&keySize;
        
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
        
        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "KeyCreator";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;
        attr->Value = &cspIdData;
        
        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "KeyType";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = &algIdData;

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "KeySizeInBits";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        //attr->Value = &keySizeData; // The logical key size is taken from this KeySizeInBits property, not the EffectiveKeySize.  Makes you wonder what the EffectiveKeySize is then.
        attr->Value = &logicalKeySizeData;
        
        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "EffectiveKeySize";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_UINT32;
        attr->NumberOfValues = 1;
        attr->Value = &logicalKeySizeData;

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "StartDate";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;
        attr->Value = &startDateData;

        ++attr;
        attr->Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
        attr->Info.Label.AttributeName = "EndDate";
        attr->Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
        attr->NumberOfValues = 1;
        attr->Value = &endDateData;

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

        if ((error = CSSM_DL_DataInsert(DLDBHandle, recType, &recordAttrs, &([key CSSMKey]->KeyData), &recordPtr)) == CSSM_OK) {
            error = CSSM_DL_FreeUniqueRecord(DLDBHandle, recordPtr);
        }

        [publicKeyHash release];
        [key release];
    }
}

- (void)addCertificate:(Certificate*)certificate privateKey:(Key*)privateKey withName:(NSString*)name {    
    if (certificate && privateKey) {
        [self addCertificate:certificate withName:name];

        if (error == CSSM_OK) {
            [self addKey:privateKey withName:name isPermanent:YES isPrivate:NO publicKeyHash:[[certificate publicKey] keyHash]];
        }
    } else {
        PDEBUG(@"Invalid arguments (certificate:%p privateKey:%p withName:%p).\n", certificate, privateKey, name);
    }
}

- (void)addCertificate:(Certificate*)cert {
    NameListEnumerator *nameEnumerator;
    DistinguishedNameEnumerator *fieldEnumerator;
    NameList *subject = [[cert subject] retain];
    DistinguishedName *currentName;
    TypeValuePair *currentPair;
    NSString *name = nil;

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
    
    [self addCertificate:cert withName:name];
    [name release];

    // Yes, so the following single line is simpler.  But if the above way works, it should generate much nicer results, and remove another important dependency on the Sec* library.
    //error = SecCertificateAddToKeychain([cert certificateRef], keychain);
}

// The following addGenericPassword: method was contributed by Mark Ackerman.  addInternetPassword: was derived [in simplest terms] from it by Wade Tregaskis.

//  Basic logic;
//     1.  First try to add keychain item with attributes given in method
//         arguments,
//     2.  If an item with same account and service is found in the keychain,
//         check that the passwords are not the same and, if they are not,
//     3.
//        a.  Modify the password data, or
//        b.  Delete the existing item from the keychain then add a new item
//            with the attributes given in the method arguments

- (void)addGenericPassword:(NSString*)password onService:(NSString*)service forAccount:(NSString*)account replaceExisting:(BOOL)replace {
    // SecKeychainAddGenericPassword() will enter new item into keychain, if item with attributes service and account don't already exist in keychain;  returns errSecDuplicateItem if the item already exists;  uses strlen() and UTF8String in place of cStringLength and cString;  passes NULL for &itemRef since SecKeychainItemRef isn't needed, and SecKeychainItemRef won't be returned in &itemRef if errSecDuplicateItem is returned (at least that's been my experience;  couldn't find this behavio(u)r documented)
    
    error = SecKeychainAddGenericPassword(keychain, (service ? strlen([service UTF8String]) : 0), [service UTF8String], (account ? strlen([account UTF8String]) : 0), [account UTF8String], (password ? strlen([password UTF8String]) : 0), [password UTF8String], NULL);
    
    // if we have a duplicate item error and user indicates that password should be replaced...
    if(error == errSecDuplicateItem && replace == YES) {
        UInt32 existingPasswordLength;
        char* existingPasswordData ;
        SecKeychainItemRef existingItem;
        
        // ...get the existing password and a reference to the existing keychain item, then...
        error = SecKeychainFindGenericPassword(keychain, (service ? strlen([service UTF8String]) : 0), [service UTF8String], (account ? strlen([account UTF8String]) : 0), [account UTF8String], &existingPasswordLength, (void **)&existingPasswordData, &existingItem);
        
        // ...check to see that the passwords are not the same (no reason to muck around in the keychain if we don't need to;  this check may not be required, depending on whether it is anticipated that this method would be called with the same password as the password for an existing keychain item)  and if the passwords are not the same...
        if(![password isEqualToString:[NSString stringWithCString:existingPasswordData length:existingPasswordLength]]) {
            
            // ...modify the password for the existing keychain item;  (I'll admit to being mystified as to how this function works;  how does it know that it's the password data that's being modified??;  anyway, it seems to work); and finally...
            // Answer: the data of a keychain item is what is being modified.  In the case of internet or generic passwords, the data is the password.  For a certificate, for example, the data is the certificate itself.
            
            error = SecKeychainItemModifyContent(existingItem, NULL, (password ? strlen([password UTF8String]) : 0), (void *)[password UTF8String]);
        }

        // ...free the memory allocated in call to SecKeychainFindGenericPassword() above
        SecKeychainItemFreeContent(NULL, existingPasswordData);
        
        if (existingItem) {
            CFRelease(existingItem);
        }
    }
}

- (void)addInternetPassword:(NSString*)password onServer:(NSString*)server forAccount:(NSString*)account port:(UInt16)port path:(NSString*)path inSecurityDomain:(NSString*)domain protocol:(SecProtocolType)protocol auth:(SecAuthenticationType)authType replaceExisting:(BOOL)replace {
    KeychainItem *existingItem;
    
    error = SecKeychainAddInternetPassword(keychain, (server ? strlen([server UTF8String]) : 0), [server UTF8String], (domain ? strlen([domain UTF8String]) : 0), [domain UTF8String], (account ? strlen([account UTF8String]) : 0), [account UTF8String], (path ? strlen([path UTF8String]) : 0), [path UTF8String], port, protocol, authType, (password ? strlen([password UTF8String]) : 0), [password UTF8String], NULL);

    // I prefer the following approach to that used in addGenericPassword:, simply because it reuses the existing code to retrieve an existing item, recurring only a little extra overhead.
    
    if ((error == errSecDuplicateItem) && (replace == YES)) {
        existingItem = [self internetServer:server forAccount:account port:port path:path inSecurityDomain:domain protocol:protocol auth:authType];

        if (nil == existingItem) {
            error = -1;
        } else {
            [existingItem setDataString:password];
        }
    }
}

- (NSArray*)items {
    CSSM_DL_DB_HANDLE dbHandle;
    CSSM_HANDLE resultsHandle;
    NSMutableArray *results = nil;
    CSSM_DB_RECORD_ATTRIBUTE_DATA attr = {CSSM_DL_DB_RECORD_ANY, 0, 0, NULL};
    CSSM_DB_UNIQUE_RECORD *recordID;
    CSSM_QUERY query = {CSSM_DL_DB_RECORD_ANY, CSSM_DB_NONE, 0, NULL, {CSSM_QUERY_TIMELIMIT_NONE, CSSM_QUERY_SIZELIMIT_NONE}, 0};
    CSSM_DATA data = {0, NULL};
    
    if ((error = SecKeychainGetDLDBHandle(keychain, &dbHandle)) == CSSM_OK) {
        if ((error = CSSM_DL_DataGetFirst(dbHandle, &query, &resultsHandle, &attr, &data, &recordID)) == CSSM_OK) {
            do {
                switch (attr.DataRecordType) {
                    case CSSM_DL_DB_RECORD_CERT:
                        PDEBUG(@"Found certificat.\ne");
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
                
                error = CSSM_DL_DataGetNext(dbHandle, resultsHandle, &attr, &data, &recordID);
            } while (error == CSSM_OK);

            if ((CSSM_OK != error) && (CSSMERR_DL_ENDOFDATA != error)) {
                PCONSOLE(@"Unable to list items in keychain because of error #%u - %@.\n", error, CSSMErrorAsString(error));
                PDEBUG(@"CSSM_DL_DataGetFirst(%"PRIdbHandle", %p, %p, %p, %p, %p) returned error #%u (%@).\n", dbHandle, &query, &resultsHandle, &attr, &data, &recordID, error, CSSMErrorAsString(error));
            }
        }
    }

    return results;
}

// The following methods for passwordForGenericService: and genericService: were contributed by Mark Ackerman.  The passwordForInternetServer: and internetServer: methods were derived directly from them by Wade Tregaskis.

- (NSString*)passwordForGenericService:(NSString*)service forAccount:(NSString*)account {
    char *passData;
    UInt32 passLength;

    error = SecKeychainFindGenericPassword(keychain, (service ? strlen([service UTF8String]) : 0), [service UTF8String], (account ? strlen([account UTF8String]) : 0), [account UTF8String], &passLength, (void**)&passData, NULL);

    if (error == CSSM_OK) {
        return [[[NSString alloc] initWithCStringNoCopy:passData length:passLength freeWhenDone:YES] autorelease];
    } else {
        return nil;
    }
}

- (NSString*)passwordForInternetServer:(NSString*)server forAccount:(NSString*)account port:(UInt16)port path:(NSString*)path inSecurityDomain:(NSString*)domain protocol:(SecProtocolType)protocol auth:(SecAuthenticationType)authType {
    char *passData;
    UInt32 passLength;

    error = SecKeychainFindInternetPassword(keychain, (server ? strlen([server UTF8String]) : 0), [server UTF8String], (domain ? strlen([domain UTF8String]) : 0), [domain UTF8String], (account ? strlen([account UTF8String]) : 0), [account UTF8String], (path ? strlen([path UTF8String]) : 0), [path UTF8String], port, protocol, authType, &passLength, (void**)&passData, NULL);
    
    if (error == CSSM_OK) {
        return [[[NSString alloc] initWithCStringNoCopy:passData length:passLength freeWhenDone:YES] autorelease];
    } else {
        return nil;
    }
}

- (KeychainItem*)genericService:(NSString*)service forAccount:(NSString*)account {
    KeychainItem *keychainItem = nil;
    SecKeychainItemRef result = NULL;

    error = SecKeychainFindGenericPassword(keychain, (service ? strlen([service UTF8String]) : 0), [service UTF8String], (account ? strlen([account UTF8String]) : 0), [account UTF8String], NULL, NULL, &result);

    if ((error == CSSM_OK) && result) {
        keychainItem = [KeychainItem keychainItemWithKeychainItemRef:result];
        CFRelease(result);
    }
    
    return keychainItem;
}

- (KeychainItem*)internetServer:(NSString*)server forAccount:(NSString*)account port:(UInt16)port path:(NSString*)path inSecurityDomain:(NSString*)domain protocol:(SecProtocolType)protocol auth:(SecAuthenticationType)authType {
    KeychainItem *keychainItem = nil;
    SecKeychainItemRef result = NULL;

    error = SecKeychainFindInternetPassword(keychain, (server ? strlen([server UTF8String]) : 0), [server UTF8String], (domain ? strlen([domain UTF8String]) : 0), [domain UTF8String], (account ? strlen([account UTF8String]) : 0), [account UTF8String], (path ? strlen([path UTF8String]) : 0), [path UTF8String], port, protocol, authType, NULL, NULL, &result);

    if ((error == CSSM_OK) && result) {
        keychainItem = [KeychainItem keychainItemWithKeychainItemRef:result];
        CFRelease(result);
    }

    return keychainItem;
}

- (NSArray*)identitiesForUse:(CSSM_KEYUSE)use {
    SecIdentitySearchRef search = NULL;
    SecIdentityRef result = NULL;
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:5];

    error = SecIdentitySearchCreate(keychain, use, &search);

    if ((error == CSSM_OK) && search) {
        while (((error = SecIdentitySearchCopyNext(search, &result)) == CSSM_OK) && result) {
            [results addObject:[Identity identityWithIdentityRef:result]];
            CFRelease(result);
        }

        CFRelease(search);

        return results;
    } else {
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

- (NSArray*)createAndAddKeyPairWithAlgorithm:(CSSM_ALGORITHMS)alg bitSize:(UInt32)size publicUse:(CSSM_KEYUSE)pubUse publicAttributes:(UInt32)pubAttr privateUse:(CSSM_KEYUSE)privUse privateAttributes:(UInt32)privAttr access:(Access*)acc {
    SecKeyRef pubResult = NULL, privResult = NULL;
    NSArray *res;
    
    error = SecKeyCreatePair(keychain, alg, size, nil, pubUse, pubAttr, privUse, privAttr, [acc accessRef], &pubResult, &privResult);

    if ((error == CSSM_OK) && pubResult && privResult) {
        res = [NSArray arrayWithObjects:[Key keyWithKeyRef:pubResult], [Key keyWithKeyRef:privResult], nil];

        CFRelease(pubResult);
        CFRelease(privResult);

        return res;
    } else {
        return nil;
    }
}

- (void)setAccess:(Access*)access {
    error = SecKeychainSetAccess(keychain, [access accessRef]);
}

- (Access*)access {
    SecAccessRef result = NULL;
    Access *res;
    
    error = SecKeychainCopyAccess(keychain, &result);

    if ((error == CSSM_OK) && result) {
        res = [Access accessWithAccessRef:result];
        CFRelease(result);

        return res;
    } else {
        return nil;
    }
}

- (void)deleteCompletely {
    // WARNING - THIS REALLY DOES DELETE THE KEYCHAIN, COMPLETELY AND IRREVERSIBLY, INCLUDING ALL ITS CONTENTS
    // BOTH IN MEMORY AND ON DISK
    
    // I'm hesitant to even include this code...
    // I'm sure someone's going to call it at least once by accident.
    // You have been warned.

    // Btw, this definitely does work, don't test it - I did (don't ask)
    
    error = SecKeychainDelete(keychain);

    if (error == CSSM_OK) {
        keychain = NULL;
    }
}

- (int)lastError {
    return error;
}

- (SecKeychainRef)keychainRef {
    return keychain;
}

- (void)dealloc {
    if (keychain) {
        CFRelease(keychain);
    }
    
    [super dealloc];
}

@end


NSArray* defaultSetOfKeychains(void) {
    CFArrayRef result = NULL;
    CFIndex i, c;
    NSMutableArray *finalResult = nil;
    int error;

    error = SecKeychainCopySearchList(&result);

    if ((error == 0) && result) {
        c = CFArrayGetCount(result);
        finalResult = [[NSMutableArray alloc] initWithCapacity:c];
        
        for (i = 0; i < c; ++i) {
            [finalResult addObject:[Keychain keychainWithKeychainRef:(SecKeychainRef)CFArrayGetValueAtIndex(result, i)]];
        }

        CFRelease(result);
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
