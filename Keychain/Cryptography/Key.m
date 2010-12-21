//
//  Key.m
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

#import "Key.h"

#import "CDSA/CSSMUtils.h"
#import "CDSA/CSSMDefaults.h"
#import "CDSA/CSSMControl.h"
#import "CDSA/CSSMTypes.h"
#import "CDSA/CSSMModule.h"
#import "CDSA/CSSMManagedModule.h"

#import "Utilities/UtilitySupport.h"
#import "Utilities/Logging.h"

// For pre-10.5 SDKs:
typedef size_t CSSM_SIZE;

@implementation Key

+ (Key*)keyWithKeyRef:(SecKeyRef)ke module:(CSSMModule*)CSPModule {
    return [[[[self class] alloc] initWithKeyRef:ke module:CSPModule] autorelease];
}

+ (Key*)keyWithCSSMKey:(const CSSM_KEY *)ke module:(CSSMModule*)CSPModule {
    return [[[[self class] alloc] initWithCSSMKey:ke module:CSPModule] autorelease];
}

- (Key*)initWithKeyRef:(SecKeyRef)ke module:(CSSMModule*)CSPModule {
    Key *existingObject;
    
    if (ke) {
        if (CSPModule) {
            existingObject = [[self class] instanceWithKey:(id)ke from:@selector(keyRef) simpleKey:NO];

            if (existingObject) {
                [self release];

                if (![CSPModule isEqual:[existingObject CSPModule]]) {
                    PDEBUG(@"Requested CSPModule (%p - %@) doesn't match that of the existing instance %p, who's CSPModule is %p - %@.\n", CSPModule, [CSPModule description], existingObject, [existingObject CSPModule], [[existingObject CSPModule] description]);
                    self = nil;
                } else {
                    self = [existingObject retain];
                }
            } else {
                if (self = [super init]) {
                    CFRetain(ke);
                    
                    _key = ke;

                    _error = SecKeyGetCSSMKey(_key, &_CSSMKey);

                    if (_error != 0) {
                        [self release];
                        self = nil;
                    }
		    
		    if (nil == CSPModule) {
			_CSPModule = [[CSSMManagedModule defaultCSPModule] retain];
		    } else {
			_CSPModule = [CSPModule retain];
		    }
                } else {
                    [self release];
                    self = nil;
                }
            }
        } else {
            PDEBUG(@"Invalid parameters - CSPModule is nil.\n");
            
            [self release];
            self = nil;
        }
    } else {
        PDEBUG(@"Invalid parameters - ke is NULL.\n");
        
        [self release];
        self = nil;
    }
    
    return self;
}

- (Key*)initWithCSSMKey:(const CSSM_KEY *)ke module:(CSSMModule*)CSPModule {
    if (NULL == ke) {
        PDEBUG(@"Invalid parameter - ke is NULL.\n");
        [self release];
        self = nil;
    } else if (self = [super init]) {
        _CSSMKey = ke;
        _key = nil;
	
	if (nil == CSPModule) {
	    _CSPModule = [[CSSMManagedModule defaultCSPModule] retain];
	} else {
	    _CSPModule = [CSPModule retain];
	}
    }

    return self;
}

- (Key*)init {
    [self release];
    return nil;
}

- (CSSMModule*)CSPModule {
    return _CSPModule;
}

- (CSSM_HEADERVERSION)version {
    return _CSSMKey->KeyHeader.HeaderVersion;
}

- (CSSM_KEYBLOB_TYPE)blobType {
    return _CSSMKey->KeyHeader.BlobType;
}

- (CSSM_KEYBLOB_FORMAT)format {
    return _CSSMKey->KeyHeader.Format;
}

- (CSSM_ALGORITHMS)algorithm {
    return _CSSMKey->KeyHeader.AlgorithmId;
}

- (CSSM_ALGORITHMS)wrapAlgorithm {
    return _CSSMKey->KeyHeader.WrapAlgorithmId;
}

- (CSSM_KEYCLASS)keyClass {
    return _CSSMKey->KeyHeader.KeyClass;
}

- (int)logicalSize {
    return _CSSMKey->KeyHeader.LogicalKeySizeInBits;
}

- (CSSM_KEYATTR_FLAGS)attributes {
    return _CSSMKey->KeyHeader.KeyAttr;
}

- (CSSM_KEYUSE)usage {
    return _CSSMKey->KeyHeader.KeyUsage;
}

- (NSCalendarDate*)startDate {
    return calendarDateForCSSMDate(&(_CSSMKey->KeyHeader.StartDate));
}

- (NSCalendarDate*)endDate {
    return calendarDateForCSSMDate(&(_CSSMKey->KeyHeader.EndDate));
}

- (CSSM_ENCRYPT_MODE)wrapMode {
    return _CSSMKey->KeyHeader.WrapMode;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Format: %@\nBlob Format: %@\nAlgorithm: %@\nWrap Algorithm: %@\nClass: %@\nLogical Size: %d\nAttributes: %@\nUsage: %@\nStart Date: %@\nEnd Date: %@\nWrap Mode: %@\n", nameOfTypedFormat([self format], [self blobType]), nameOfKeyblobType([self blobType]), nameOfAlgorithm([self algorithm]), nameOfAlgorithm([self wrapAlgorithm]), nameOfKeyClass([self keyClass]), [self logicalSize], descriptionOfKeyAttributes([self attributes]), descriptionOfKeyUsage([self usage]), [self startDate], [self endDate], nameOfAlgorithmMode([self wrapMode])];
}

- (Key*)wrappedKeyUnsafeWithDescription:(NSString*)description {
    CSSM_WRAP_KEY *result;
    CSSM_CC_HANDLE ccHandle;
    CSSM_DATA desc;
    CSSM_DATA_PTR descPtr;
    Key *finalResult = nil;
    
    if (_CSSMKey->KeyHeader.BlobType == CSSM_KEYBLOB_WRAPPED) {
        PDEBUG(@"Key is already wrapped.\n");
    } else if (!([self attributes] & CSSM_KEYATTR_EXTRACTABLE)) {
        PDEBUG(@"Key is not marked as extractable - cannot be wrapped.\n");
    } else if ([self attributes] & CSSM_KEYATTR_SENSITIVE) {
        PDEBUG(@"Key is marked as sensitive - cannot be unsafely wrapped.\n");
    } else {
        if (_CSSMKey->KeyHeader.KeyClass != CSSM_KEYCLASS_PUBLIC_KEY) {
            PSYSLOG(LOG_CRIT, @"Warning: Null wrapping a non-public key - this is a dangerous operation.\n");
        }
        
        if ((_error = CSSM_CSP_CreateSymmetricContext([_CSPModule handle], CSSM_ALGID_NONE, CSSM_ALGMODE_WRAP, NULL, NULL, NULL, CSSM_PADDING_NONE, NULL, &ccHandle)) == CSSM_OK) {
            if (description) {
				const char *descriptionCStr = [description UTF8String];
				
                descPtr = &desc;
                desc.Length = strlen(descriptionCStr);
                desc.Data = (uint8_t *)descriptionCStr;
            } else {
                descPtr = NULL;
            }

            result = malloc(sizeof(CSSM_WRAP_KEY));
            
            if ((_error = CSSM_WrapKey(ccHandle, keychainFrameworkDefaultCredentials(), _CSSMKey, descPtr, result)) == CSSM_OK) {
                finalResult = [Key keyWithCSSMKey:result module:_CSPModule];
            } else {
                free(result);
                PSYSLOGND(LOG_ERR, @"Unable to wrap key because of error %@.\n", CSSMErrorAsString(_error));
                PDEBUG(@"CSSM_WrapKey(%"PRIccHandle", X, %p, %p, %p) returned error %@.\n", ccHandle, _CSSMKey, descPtr, result, CSSMErrorAsString(_error));
            }
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to create wrapping context because of error %@.\n", CSSMErrorAsString(_error));
            PDEBUG(@"CSSM_CSP_CreateSymmetricContext(X, CSSM_ALGID_NONE, CSSM_ALGMODE_WRAP, NULL, NULL, NULL, CSSM_PADDING_NONE, NULL, %p [%"PRIccHandle"]) returned error %@.\n", &ccHandle, ccHandle, CSSMErrorAsString(_error));
        }
    }
    
    return finalResult;
}

- (Key*)wrappedKeyUnsafe {
    return [self wrappedKeyUnsafeWithDescription:nil];
}

- (Key*)wrappedKeyUsingKey:(Key*)wrappingKey description:(NSString*)description {
    Key *finalResult = nil;

    if (wrappingKey) {
        CSSM_WRAP_KEY *result;
        CSSM_CC_HANDLE ccHandle;
        CSSM_DATA desc;
        CSSM_DATA_PTR descPtr;
        CSSM_ALGORITHMS wrapAlgorithm = [wrappingKey algorithm];
        static CSSM_CONTEXT_ATTRIBUTE contextAttribute;
        
        contextAttribute.AttributeType = CSSM_ATTRIBUTE_INIT_VECTOR;
        contextAttribute.AttributeLength = 16;
        contextAttribute.Attribute.Data = (CSSM_DATA*)&keychainFrameworkInitVectorData;
        
        if (_CSSMKey->KeyHeader.BlobType == CSSM_KEYBLOB_WRAPPED) {
            PDEBUG(@"Key is already wrapped.\n");
        } else if (!([self attributes] & CSSM_KEYATTR_EXTRACTABLE)) {
            PDEBUG(@"Key is not marked as extractable - cannot be wrapped.\n");
        } else {
            switch ([wrappingKey keyClass]) {
                case CSSM_KEYCLASS_SESSION_KEY:
                    _error = CSSM_CSP_CreateSymmetricContext([_CSPModule handle], wrapAlgorithm, defaultModeForAlgorithm(wrapAlgorithm), keychainFrameworkDefaultCredentials(), [wrappingKey CSSMKey], &keychainFrameworkInitVectorData, defaultPaddingForAlgorithm(wrapAlgorithm), NULL, &ccHandle);
                    
                    if (CSSM_OK != _error) {
                        PSYSLOGND(LOG_ERR, @"Unable to create symmetric encryption context for wrapping, error %@.\n", CSSMErrorAsString(_error));
                        PDEBUG(@"CSSM_CSP_CreateSymmetricContext(X, %d, %d, Y, %p, %p, %d, NULL, %p [%"PRIccHandle"]) returned error %@.\n", wrapAlgorithm, defaultModeForAlgorithm(wrapAlgorithm), [wrappingKey CSSMKey], &keychainFrameworkInitVectorData, defaultPaddingForAlgorithm(wrapAlgorithm), &ccHandle, ccHandle, CSSMErrorAsString(_error));
                        
                        return nil;
                    }
                        
                    break;
                case CSSM_KEYCLASS_PUBLIC_KEY:
                    _error = CSSM_CSP_CreateAsymmetricContext([_CSPModule handle], wrapAlgorithm, keychainFrameworkDefaultCredentials(), [wrappingKey CSSMKey], defaultPaddingForAlgorithm(wrapAlgorithm), &ccHandle);
                
                    if (_error == CSSM_OK) {
                        _error = CSSM_UpdateContextAttributes(ccHandle, 1, &contextAttribute);
                        
                        if (CSSM_OK != _error) {
                            PSYSLOGND(LOG_ERR, @"Unable to correctly configure asymmetric encryption context, error %@.\n", CSSMErrorAsString(_error));
                            PDEBUG(@"CSSM_UpdateContextAttributes(%"PRIccHandle", 1, %p) returned error %@.\n", ccHandle, &contextAttribute, CSSMErrorAsString(_error));
                            
                            /* TODO - release context here */
                            
                            return nil;
                        }
                    } else {
                        PSYSLOGND(LOG_ERR, @"Unable to create asymmetric encryption context for wrapping, error %@.\n", CSSMErrorAsString(_error));
                        PDEBUG(@"CSSM_CSP_CreateAsymmetricContext(X, %d, Y, %p, %d, %p [%"PRIccHandle"]) returned error %@.\n", wrapAlgorithm, [wrappingKey CSSMKey], defaultPaddingForAlgorithm(wrapAlgorithm), &ccHandle, ccHandle, CSSMErrorAsString(_error));
                        
                        return nil;
                    }
                        
                    break;
                default:
                    PSYSLOGND(LOG_ERR, @"Unable to create wrapping context because an invalid key was provided (not a session or public key).\n");
                    PDEBUG(@"Invalid key type %d for wrapping.\n", [wrappingKey keyClass]);
                    return nil;
            }
            
            if (description) {
				const char *descriptionCStr = [description UTF8String];
				
                descPtr = &desc;
                desc.Length = strlen(descriptionCStr);
                desc.Data = (uint8_t *)descriptionCStr;
            } else {
                descPtr = NULL;
            }
            
            result = malloc(sizeof(CSSM_WRAP_KEY));
            
            if ((_error = CSSM_WrapKey(ccHandle, keychainFrameworkDefaultCredentials(), _CSSMKey, descPtr, result)) == CSSM_OK) {
                finalResult = [Key keyWithCSSMKey:result module:_CSPModule];
            } else {
                free(result);
                PSYSLOGND(LOG_ERR, @"Unable to wrap key because of error %@.\n", CSSMErrorAsString(_error));
                PDEBUG(@"CSSM_WrapKey(%"PRIccHandle", X, %p, %p, %p) returned error %@.\n", ccHandle, _CSSMKey, descPtr, result, CSSMErrorAsString(_error));
            }
        }
    }
    
    return finalResult;
}

- (Key*)wrappedKeyUsingKey:(Key*)wrappingKey {
    return [self wrappedKeyUsingKey:wrappingKey description:nil];
}

- (Key*)unwrappedKeyUnsafe {
    CSSM_KEY *result;
    CSSM_CC_HANDLE ccHandle;
    Key *finalResult = nil;
    CSSM_DATA output = {0, NULL};
    
    if ((_CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_WRAPPED) && (_CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_RAW)) {
        PDEBUG(@"Key is already unwrapped.\n");
    } else {
        if ((_error = CSSM_CSP_CreateSymmetricContext([_CSPModule handle], CSSM_ALGID_NONE, CSSM_ALGMODE_WRAP, NULL, NULL, NULL, CSSM_PADDING_NONE, NULL, &ccHandle)) == CSSM_OK) {
            result = malloc(sizeof(CSSM_KEY));
            
            if ((_error = CSSM_UnwrapKey(ccHandle, NULL, _CSSMKey, _CSSMKey->KeyHeader.KeyUsage, _CSSMKey->KeyHeader.KeyAttr, NULL, NULL, result, &output)) == CSSM_OK) {
                finalResult = [Key keyWithCSSMKey:result module:_CSPModule];
            } else {
                free(result);
                PSYSLOGND(LOG_ERR, @"Unable to unwrap key because of error %@.\n", CSSMErrorAsString(_error));
                PDEBUG(@"CSSM_UnwrapKey(%"PRIccHandle", NULL, %p, %x, %x, NULL, NULL, %p, %p) returned error %@.\n", ccHandle, _CSSMKey, _CSSMKey->KeyHeader.KeyUsage, _CSSMKey->KeyHeader.KeyAttr, result, &output, CSSMErrorAsString(_error));
            }
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to create unwrapping context because of error %@.\n", CSSMErrorAsString(_error));
            PDEBUG(@"CSSM_CSP_CreateSymmetricContext(X, CSSM_ALGID_NONE, CSSM_ALGMODE_WRAP, NULL, NULL, NULL, CSSM_PADDING_NONE, NULL, %p [%"PRIccHandle"]) returned error %@.\n", &ccHandle, ccHandle, CSSMErrorAsString(_error));
        }
    }

    return finalResult;
}

- (Key*)unwrappedKeyUsingKey:(Key*)wrappingKey {
    Key *finalResult = nil;
    
    if (wrappingKey) {
        CSSM_KEY *result;
        CSSM_CC_HANDLE ccHandle;
        CSSM_ALGORITHMS wrapAlgorithm = [wrappingKey algorithm];
        static CSSM_CONTEXT_ATTRIBUTE contextAttribute;
        CSSM_DATA output = {0, NULL};
        
        contextAttribute.AttributeType = CSSM_ATTRIBUTE_INIT_VECTOR;
        contextAttribute.AttributeLength = 16;
        contextAttribute.Attribute.Data = (CSSM_DATA*)&keychainFrameworkInitVectorData;
        
        if (_CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_WRAPPED) {
            PDEBUG(@"Key is already unwrapped.\n");
        } else {
            switch ([wrappingKey keyClass]) {
                case CSSM_KEYCLASS_SESSION_KEY:
                    _error = CSSM_CSP_CreateSymmetricContext([_CSPModule handle], wrapAlgorithm, defaultModeForAlgorithm(wrapAlgorithm), keychainFrameworkDefaultCredentials(), [wrappingKey CSSMKey], &keychainFrameworkInitVectorData, defaultPaddingForAlgorithm(wrapAlgorithm), NULL, &ccHandle);
                    
                    if (CSSM_OK != _error) {
                        PSYSLOGND(LOG_ERR, @"Unable to create symmetric encryption context for unwrapping, error %@.\n", CSSMErrorAsString(_error));
                        PDEBUG(@"CSSM_CSP_CreateSymmetricContext(X, %d, %d, Y, %p, %p, %d, NULL, %p [%"PRIccHandle"]) returned error %@.\n", wrapAlgorithm, defaultModeForAlgorithm(wrapAlgorithm), [wrappingKey CSSMKey], &keychainFrameworkInitVectorData, defaultPaddingForAlgorithm(wrapAlgorithm), &ccHandle, ccHandle, CSSMErrorAsString(_error));
                    }
                        
                    break;
                case CSSM_KEYCLASS_PRIVATE_KEY:
                    _error = CSSM_CSP_CreateAsymmetricContext([_CSPModule handle], wrapAlgorithm, keychainFrameworkDefaultCredentials(), [wrappingKey CSSMKey], defaultPaddingForAlgorithm(wrapAlgorithm), &ccHandle);
                        
                    if (_error == CSSM_OK) {
                        _error = CSSM_UpdateContextAttributes(ccHandle, 1, &contextAttribute);
                        
                        if (CSSM_OK != _error) {
                            PSYSLOGND(LOG_ERR, @"Unable to correctly configure asymmetric encryption context, error %@.\n", CSSMErrorAsString(_error));
                            PDEBUG(@"CSSM_UpdateContextAttributes(%"PRIccHandle", 1, %p) returned error %@.\n", ccHandle, &contextAttribute, CSSMErrorAsString(_error));
                            
                            /* TODO - release context here */
                            
                            return nil;
                        }
                    } else {
                        PSYSLOGND(LOG_ERR, @"Unable to create asymmetric encryption context for wrapping, error %@.\n", CSSMErrorAsString(_error));
                        PDEBUG(@"CSSM_CSP_CreateAsymmetricContext(X, %d, Y, %p, %d, %p [%"PRIccHandle"]) returned error %@.\n", wrapAlgorithm, [wrappingKey CSSMKey], defaultPaddingForAlgorithm(wrapAlgorithm), &ccHandle, ccHandle, CSSMErrorAsString(_error));
                        
                        return nil;
                    }
                        
                    break;
                default:
                    PSYSLOGND(LOG_ERR, @"Unable to create wrapping context because an invalid key was provided (not a session or public key).\n");
                    PDEBUG(@"Invalid key type %d for wrapping.\n", [wrappingKey keyClass]);
                    return nil;
            }
            
            result = malloc(sizeof(CSSM_KEY));
                
            if ((_error = CSSM_UnwrapKey(ccHandle, [wrappingKey CSSMKey], _CSSMKey, _CSSMKey->KeyHeader.KeyUsage, _CSSMKey->KeyHeader.KeyAttr, NULL, NULL, result, &output)) == CSSM_OK) {
                finalResult = [Key keyWithCSSMKey:result module:_CSPModule];
            } else {
                free(result);
                PSYSLOGND(LOG_ERR, @"Unable to wrap key because of error %@.\n", CSSMErrorAsString(_error));
                PDEBUG(@"CSSM_UnwrapKey(%"PRIccHandle", %p, %p, %x, %x, NULL, NULL, %p, %p) returned error %@.\n", ccHandle, [wrappingKey CSSMKey], _CSSMKey, _CSSMKey->KeyHeader.KeyUsage, _CSSMKey->KeyHeader.KeyAttr, result, &output, CSSMErrorAsString(_error));                
            }
        }
    }
    
    return finalResult;
}

- (NSData*)keyHash {
    CSSM_KEY *rawPubKey = (CSSM_KEY*)[self CSSMKey];
    CSSM_DATA *keyDigest = NULL;
    CSSM_CC_HANDLE ccHand;
    NSData *finalResult = nil;
    
    if ((_error = CSSM_CSP_CreatePassThroughContext([_CSPModule handle], rawPubKey, &ccHand)) == CSSM_OK) {
        if ((_error = CSSM_CSP_PassThrough(ccHand, CSSM_APPLECSP_KEYDIGEST, NULL, (void**)&keyDigest)) == CSSM_OK) {
            finalResult = NSDataFromDataNoCopy(keyDigest, YES);
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to retrieve public key digest, error %@.\n", CSSMErrorAsString(_error));
            PDEBUG(@"CSSM_CSP_PassThrough(%"PRIccHandle", CSSM_APPLECSP_KEYDIGEST [%u], NULL, %p) returned error %@.\n", ccHand, CSSM_APPLECSP_KEYDIGEST, &keyDigest, CSSMErrorAsString(_error));
        }
        
        _error = CSSM_DeleteContext(ccHand);
        
        if (CSSM_OK != _error) {
            PSYSLOGND(LOG_WARNING, @"Unable to delete pass through context (used for retrieving public key digest), error %@.\n", CSSMErrorAsString(_error));
            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHand, CSSMErrorAsString(_error));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create pass through context for retrieving public key digest, error %@.\n", CSSMErrorAsString(_error));
        PDEBUG(@"CSSM_CSP_CreatePassThroughContext(%"PRImoduleHandle", %p, %p) returned error %@.\n", [_CSPModule handle], rawPubKey, &ccHand, CSSMErrorAsString(_error));
    }
    
    return finalResult;
}

- (NSData*)rawData {
    if ((_CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_RAW) && (_CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_WRAPPED)) {
        PDEBUG(@"Called on an internal (non-raw) key instance; cannot [automatically] extract raw key data.\n");
        return nil;
    } else {
        return NSDataFromDataNoCopy(&(_CSSMKey->KeyData), NO);
    }
}

- (NSData*)data {
    char *result;
    NSData *finalResult = nil;
    CSSM_SIZE dataLength;

    if ((_CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_RAW) && (_CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_WRAPPED)) {
        PDEBUG(@"Called on an internal (non-raw) key instance; cannot [automatically] extract raw key data.\n");
    } else {
        if (KEYHEADER_VERSION_CURRENT_SIZE != sizeof(_CSSMKey->KeyHeader)) {
            PDEBUG(@"Newer version of Apple's CDSA detected (header size is %d, expected %d) - update required for the Keychain framework.\n", sizeof(_CSSMKey->KeyHeader), KEYHEADER_VERSION_CURRENT_SIZE);
        } else {
            dataLength = KEYHEADER_VERSION_CURRENT_SIZE + 8 + _CSSMKey->KeyData.Length;
            result = malloc(dataLength);

            memcpy(result, &RAW_KEY_VERSION_CURRENT, 4);

            // The simplest way to do this is to copy the whole header in one go.  However
            // this probably isn't going to make it very easy to port to other platforms.
            // So there's the version below, which could easily be altered to include any
            // necessary byte-swapping and so forth.

            memcpy(result + 4, &(_CSSMKey->KeyHeader), KEYHEADER_VERSION_CURRENT_SIZE);

            /*memcpy(result + 4, &(_CSSMKey->KeyHeader.HeaderVersion), 4);
            memcpy(result + 8, &(_CSSMKey->KeyHeader.CspId), 12);
            memcpy(result + 20, &(_CSSMKey->KeyHeader.BlobType), 4);
            memcpy(result + 24, &(_CSSMKey->KeyHeader.Format), 4);
            memcpy(result + 28, &(_CSSMKey->KeyHeader.AlgorithmId), 4);
            memcpy(result + 32, &(_CSSMKey->KeyHeader.KeyClass), 4);
            memcpy(result + 36, &(_CSSMKey->KeyHeader.LogicalKeySizeInBits), 4);
            memcpy(result + 40, &(_CSSMKey->KeyHeader.KeyAttr), 4);
            memcpy(result + 44, &(_CSSMKey->KeyHeader.KeyUsage), 4);
            memcpy(result + 48, &(_CSSMKey->KeyHeader.StartDate), 8);
            memcpy(result + 56, &(_CSSMKey->KeyHeader.EndDate), 8);
            memcpy(result + 64, &(_CSSMKey->KeyHeader.WrapAlgorithmId), 4);
            memcpy(result + 68, &(_CSSMKey->KeyHeader.WrapMode), 4);*/

            memcpy(result + KEYHEADER_VERSION_CURRENT_SIZE + 4, &(_CSSMKey->KeyData.Length), 4);
            memcpy(result + KEYHEADER_VERSION_CURRENT_SIZE + 8, _CSSMKey->KeyData.Data, _CSSMKey->KeyData.Length);

            finalResult = [NSData dataWithBytesNoCopy:result length:dataLength freeWhenDone:YES];
        }
    }

    return finalResult;
}

- (BOOL)isEqualToKey:(Key*)otherKey {
    const CSSM_KEY *otherCSSMKey;

    if (otherKey) {
        otherCSSMKey = [otherKey CSSMKey];

        if ((_CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_REFERENCE) && (otherCSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_REFERENCE)) {
            if ((self == otherKey) || (_CSSMKey == otherCSSMKey)) {
                return YES;
            } else {
                return ((memcmp(&(_CSSMKey->KeyHeader), &(otherCSSMKey->KeyHeader), sizeof(CSSM_KEYHEADER)) == 0) && (_CSSMKey->KeyData.Length == otherCSSMKey->KeyData.Length) && (memcmp(_CSSMKey->KeyData.Data, otherCSSMKey->KeyData.Data, _CSSMKey->KeyData.Length) == 0));
            }
        } else {
            PDEBUG(@"Called on a reference key, or with a reference key, or both.\n");
        }
    }

    return NO;
}

- (BOOL)isSimilarToKey:(Key*)otherKey {
    const CSSM_KEY *otherCSSMKey;

    if (otherKey) {
        otherCSSMKey = [otherKey CSSMKey];

        if ((_CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_REFERENCE) && (otherCSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_REFERENCE)) {
            if ((self == otherKey) || (_CSSMKey == otherCSSMKey)) {
                return YES;
            } else {
                return ((_CSSMKey->KeyData.Length == otherCSSMKey->KeyData.Length) && (memcmp(_CSSMKey->KeyData.Data, otherCSSMKey->KeyData.Data, _CSSMKey->KeyData.Length) == 0));
            }
        } else {
            PDEBUG(@"Called on a reference key, or with a reference key, or both.\n");
        }
    }
    
    return NO;
}

- (const CSSM_KEY *)CSSMKey {
    return _CSSMKey;
}

- (int)lastError {
    return _error;
}

- (SecKeyRef)keyRef {
    return _key;
}

- (void)dealloc {
    if (nil != _CSPModule) {
        [_CSPModule release];
        _CSPModule = nil;
    }
    
    if (NULL != _key) {
        CFRelease(_key);
        _key = NULL;
    }
    
    [super dealloc];
}

@end
