//
//  Key.m
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

#import "Key.h"

#import "CSSMUtils.h"
#import "CSSMDefaults.h"
#import "CSSMControl.h"
#import "CSSMTypes.h"
#import "CSSMModule.h"

#import "UtilitySupport.h"
#import "Logging.h"


@implementation Key

+ (Key*)keyWithKeyRef:(SecKeyRef)ke {
    return [[[[self class] alloc] initWithKeyRef:ke] autorelease];
}

+ (Key*)keyWithCSSMKey:(const CSSM_KEY *)ke {
    return [[[[self class] alloc] initWithCSSMKey:ke] autorelease];
}

- (Key*)initWithKeyRef:(SecKeyRef)ke {
    Key *existingObject;
    
    if (ke) {
        existingObject = [[self class] instanceWithKey:(id)ke from:@selector(keyRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            self = [existingObject retain];
        } else {
            if (self = [super init]) {
                CFRetain(ke);
                
                key = ke;

                error = SecKeyGetCSSMKey(key, &CSSMKey);

                if (error != 0) {
                    [self release];
                    self = nil;
                }
            } else {
                [self release];
                self = nil;
            }
        }
    } else {
        [self release];
        self = nil;
    }
    
    return self;
}

- (Key*)initWithCSSMKey:(const CSSM_KEY *)ke {
    if (self = [super init]) {
        CSSMKey = ke;
        key = nil;
    }

    return self;
}

- (Key*)init {
    [self release];
    return nil;
}

- (CSSM_HEADERVERSION)version {
    return CSSMKey->KeyHeader.HeaderVersion;
}

- (CSSM_KEYBLOB_TYPE)blobType {
    return CSSMKey->KeyHeader.BlobType;
}

- (CSSM_KEYBLOB_FORMAT)format {
    return CSSMKey->KeyHeader.Format;
}

- (CSSM_ALGORITHMS)algorithm {
    return CSSMKey->KeyHeader.AlgorithmId;
}

- (CSSM_ALGORITHMS)wrapAlgorithm {
    return CSSMKey->KeyHeader.WrapAlgorithmId;
}

- (CSSM_KEYCLASS)keyClass {
    return CSSMKey->KeyHeader.KeyClass;
}

- (int)logicalSize {
    return CSSMKey->KeyHeader.LogicalKeySizeInBits;
}

- (CSSM_KEYATTR_FLAGS)attributes {
    return CSSMKey->KeyHeader.KeyAttr;
}

- (CSSM_KEYUSE)usage {
    return CSSMKey->KeyHeader.KeyUsage;
}

- (NSCalendarDate*)startDate {
    return calendarDateForCSSMDate(&(CSSMKey->KeyHeader.StartDate));
}

- (NSCalendarDate*)endDate {
    return calendarDateForCSSMDate(&(CSSMKey->KeyHeader.EndDate));
}

- (CSSM_ENCRYPT_MODE)wrapMode {
    return CSSMKey->KeyHeader.WrapMode;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Format: %@\nBlob Format: %@\nAlgorithm: %@\nWrap Algorithm: %@\nClass: %@\nLogical Size: %d\nAttributes: %@\nUsage: %@\nStart Date: %@\nEnd Date: %@\nWrap Mode: %@\n", nameOfTypedFormat([self format], [self blobType]), nameOfKeyBlob([self blobType]), nameOfAlgorithm([self algorithm]), nameOfAlgorithm([self wrapAlgorithm]), nameOfKeyClass([self keyClass]), [self logicalSize], namesOfAttributes([self attributes]), namesOfUsages([self usage]), [self startDate], [self endDate], nameOfAlgorithmMode([self wrapMode])];
}

- (Key*)wrappedKeyUnsafeWithDescription:(NSString*)description {
    CSSM_WRAP_KEY *result;
    CSSM_CC_HANDLE ccHandle;
    CSSM_RETURN err;
    CSSM_DATA desc;
    CSSM_DATA_PTR descPtr;
    Key *finalResult = nil;
    
    if (CSSMKey->KeyHeader.BlobType == CSSM_KEYBLOB_WRAPPED) {
        PDEBUG(@"Key is already wrapped.\n");
    } else if (!([self attributes] & CSSM_KEYATTR_EXTRACTABLE)) {
        PDEBUG(@"Key is not marked as extractable - cannot be wrapped.\n");
    } else if ([self attributes] & CSSM_KEYATTR_SENSITIVE) {
        PDEBUG(@"Key is marked as sensitive - cannot be unsafely wrapped.\n");
    } else {
        if (CSSMKey->KeyHeader.KeyClass != CSSM_KEYCLASS_PUBLIC_KEY) {
            PCONSOLE(@"Warning: Null wrapping a non-public key - this is a dangerous operation.\n");
        }
        
        if ((err = CSSM_CSP_CreateSymmetricContext([[CSSMModule defaultCSPModule] handle], CSSM_ALGID_NONE, CSSM_ALGMODE_WRAP, NULL, NULL, NULL, CSSM_PADDING_NONE, NULL, &ccHandle)) == CSSM_OK) {
            if (description) {
                descPtr = &desc;
                desc.Length = [description cStringLength];
                desc.Data = (uint8_t*)[description cString];
            } else {
                descPtr = NULL;
            }

            result = malloc(sizeof(CSSM_WRAP_KEY));
            
            if ((err = CSSM_WrapKey(ccHandle, keychainFrameworkDefaultCredentials(), CSSMKey, descPtr, result)) == CSSM_OK) {
                finalResult = [Key keyWithCSSMKey:result];
            } else {
                free(result);
                PCONSOLE(@"Unable to wrap key because of error #%u - %@.\n", err, CSSMErrorAsString(err));
                PDEBUG(@"CSSM_WrapKey(%"PRIccHandle", X, %p, %p, %p) returned error #%u (%@).\n", ccHandle, CSSMKey, descPtr, result, err, CSSMErrorAsString(err));
            }
        } else {
            PCONSOLE(@"Unable to create wrapping context because of error #%u - %@.\n", err, CSSMErrorAsString(err));
            PDEBUG(@"CSSM_CSP_CreateSymmetricContext(X, CSSM_ALGID_NONE, CSSM_ALGMODE_WRAP, NULL, NULL, NULL, CSSM_PADDING_NONE, NULL, %p [%"PRIccHandle"]) returned error #%u (%@).\n", &ccHandle, ccHandle, err, CSSMErrorAsString(err));
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
        CSSM_RETURN err;
        CSSM_DATA desc;
        CSSM_DATA_PTR descPtr;
        CSSM_ALGORITHMS wrapAlgorithm = [wrappingKey algorithm];
        static CSSM_CONTEXT_ATTRIBUTE contextAttribute;
        
        contextAttribute.AttributeType = CSSM_ATTRIBUTE_INIT_VECTOR;
        contextAttribute.AttributeLength = 16;
        contextAttribute.Attribute.Data = (CSSM_DATA*)&keychainFrameworkInitVectorData;
        
        if (CSSMKey->KeyHeader.BlobType == CSSM_KEYBLOB_WRAPPED) {
            PDEBUG(@"Key is already wrapped.\n");
        } else if (!([self attributes] & CSSM_KEYATTR_EXTRACTABLE)) {
            PDEBUG(@"Key is not marked as extractable - cannot be wrapped.\n");
        } else {
            switch ([wrappingKey keyClass]) {
                case CSSM_KEYCLASS_SESSION_KEY:
                    err = CSSM_CSP_CreateSymmetricContext([[CSSMModule defaultCSPModule] handle], wrapAlgorithm, defaultModeForAlgorithm(wrapAlgorithm), keychainFrameworkDefaultCredentials(), [wrappingKey CSSMKey], &keychainFrameworkInitVectorData, defaultPaddingForAlgorithm(wrapAlgorithm), NULL, &ccHandle);
                    
                    if (CSSM_OK != err) {
                        PCONSOLE(@"Unable to create symmetric encryption context for wrapping, error %#u - %@.\n", err, CSSMErrorAsString(err));
                        PDEBUG(@"CSSM_CSP_CreateSymmetricContext(X, %d, %d, Y, %p, %p, %d, NULL, %p [%"PRIccHandle"]) returned error #%u (%@).\n", wrapAlgorithm, defaultModeForAlgorithm(wrapAlgorithm), [wrappingKey CSSMKey], &keychainFrameworkInitVectorData, defaultPaddingForAlgorithm(wrapAlgorithm), &ccHandle, ccHandle, err, CSSMErrorAsString(err));
                        
                        return nil;
                    }
                        
                    break;
                case CSSM_KEYCLASS_PUBLIC_KEY:
                    err = CSSM_CSP_CreateAsymmetricContext([[CSSMModule defaultCSPModule] handle], wrapAlgorithm, keychainFrameworkDefaultCredentials(), [wrappingKey CSSMKey], defaultPaddingForAlgorithm(wrapAlgorithm), &ccHandle);
                
                    if (err == CSSM_OK) {
                        err = CSSM_UpdateContextAttributes(ccHandle, 1, &contextAttribute);
                        
                        if (CSSM_OK != err) {
                            PCONSOLE(@"Unable to correctly configure asymmetric encryption context, error #%u - %@.\n", err, CSSMErrorAsString(err));
                            PDEBUG(@"CSSM_UpdateContextAttributes(%"PRIccHandle", 1, %p) returned error #%u (%@).\n", ccHandle, &contextAttribute, err, CSSMErrorAsString(err));
                            
                            /* TODO - release context here */
                            
                            return nil;
                        }
                    } else {
                        PCONSOLE(@"Unable to create asymmetric encryption context for wrapping, error %#u - %@.\n", err, CSSMErrorAsString(err));
                        PDEBUG(@"CSSM_CSP_CreateAsymmetricContext(X, %d, Y, %p, %d, %p [%"PRIccHandle"]) returned error #%u (%@).\n", wrapAlgorithm, [wrappingKey CSSMKey], defaultPaddingForAlgorithm(wrapAlgorithm), &ccHandle, ccHandle, err, CSSMErrorAsString(err));
                        
                        return nil;
                    }
                        
                    break;
                default:
                    PCONSOLE(@"Unable to create wrapping context because an invalid key was provided (not a session or public key).\n");
                    PDEBUG(@"Invalid key type %d for wrapping.\n", [wrappingKey keyClass]);
                    return nil;
            }
            
            if (description) {
                descPtr = &desc;
                desc.Length = [description cStringLength];
                desc.Data = (uint8_t*)[description cString];
            } else {
                descPtr = NULL;
            }
            
            result = malloc(sizeof(CSSM_WRAP_KEY));
            
            if ((err = CSSM_WrapKey(ccHandle, keychainFrameworkDefaultCredentials(), CSSMKey, descPtr, result)) == CSSM_OK) {
                finalResult = [Key keyWithCSSMKey:result];
            } else {
                free(result);
                PCONSOLE(@"Unable to wrap key because of error #%u - %@.\n", err, CSSMErrorAsString(err));
                PDEBUG(@"CSSM_WrapKey(%"PRIccHandle", X, %p, %p, %p) returned error #%u (%@).\n", ccHandle, CSSMKey, descPtr, result, err, CSSMErrorAsString(err));
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
    CSSM_RETURN err;
    Key *finalResult = nil;
    CSSM_DATA output = {0, NULL};
    
    if ((CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_WRAPPED) && (CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_RAW)) {
        PDEBUG(@"Key is already unwrapped.\n");
    } else {
        if ((err = CSSM_CSP_CreateSymmetricContext([[CSSMModule defaultCSPModule] handle], CSSM_ALGID_NONE, CSSM_ALGMODE_WRAP, NULL, NULL, NULL, CSSM_PADDING_NONE, NULL, &ccHandle)) == CSSM_OK) {
            result = malloc(sizeof(CSSM_KEY));
            
            if ((err = CSSM_UnwrapKey(ccHandle, NULL, CSSMKey, CSSMKey->KeyHeader.KeyUsage, CSSMKey->KeyHeader.KeyAttr, NULL, NULL, result, &output)) == CSSM_OK) {
                finalResult = [Key keyWithCSSMKey:result];
            } else {
                free(result);
                PCONSOLE(@"Unable to unwrap key because of error #%u - %@.\n", err, CSSMErrorAsString(err));
                PDEBUG(@"CSSM_UnwrapKey(%"PRIccHandle", NULL, %p, %x, %x, NULL, NULL, %p, %p) returned error #%u (%@).\n", ccHandle, CSSMKey, CSSMKey->KeyHeader.KeyUsage, CSSMKey->KeyHeader.KeyAttr, result, &output, err, CSSMErrorAsString(err));
            }
        } else {
            PCONSOLE(@"Unable to create unwrapping context because of error #%u - %@.\n", err, CSSMErrorAsString(err));
            PDEBUG(@"CSSM_CSP_CreateSymmetricContext(X, CSSM_ALGID_NONE, CSSM_ALGMODE_WRAP, NULL, NULL, NULL, CSSM_PADDING_NONE, NULL, %p [%"PRIccHandle"]) returned error #%u (%@).\n", &ccHandle, ccHandle, err, CSSMErrorAsString(err));
        }
    }

    return finalResult;
}

- (Key*)unwrappedKeyUsingKey:(Key*)wrappingKey {
    Key *finalResult = nil;
    
    if (wrappingKey) {
        CSSM_KEY *result;
        CSSM_CC_HANDLE ccHandle;
        CSSM_RETURN err;
        CSSM_ALGORITHMS wrapAlgorithm = [wrappingKey algorithm];
        static CSSM_CONTEXT_ATTRIBUTE contextAttribute;
        CSSM_DATA output = {0, NULL};
        
        contextAttribute.AttributeType = CSSM_ATTRIBUTE_INIT_VECTOR;
        contextAttribute.AttributeLength = 16;
        contextAttribute.Attribute.Data = (CSSM_DATA*)&keychainFrameworkInitVectorData;
        
        if (CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_WRAPPED) {
            PDEBUG(@"Key is already unwrapped.\n");
        } else {
            switch ([wrappingKey keyClass]) {
                case CSSM_KEYCLASS_SESSION_KEY:
                    err = CSSM_CSP_CreateSymmetricContext([[CSSMModule defaultCSPModule] handle], wrapAlgorithm, defaultModeForAlgorithm(wrapAlgorithm), keychainFrameworkDefaultCredentials(), [wrappingKey CSSMKey], &keychainFrameworkInitVectorData, defaultPaddingForAlgorithm(wrapAlgorithm), NULL, &ccHandle);
                    
                    if (CSSM_OK != err) {
                        PCONSOLE(@"Unable to create symmetric encryption context for unwrapping, error #%u - %@.\n", err, CSSMErrorAsString(err));
                        PDEBUG(@"CSSM_CSP_CreateSymmetricContext(X, %d, %d, Y, %p, %p, %d, NULL, %p [%"PRIccHandle"]) returned error #%u (%@).\n", wrapAlgorithm, defaultModeForAlgorithm(wrapAlgorithm), [wrappingKey CSSMKey], &keychainFrameworkInitVectorData, defaultPaddingForAlgorithm(wrapAlgorithm), &ccHandle, ccHandle, err, CSSMErrorAsString(err));
                    }
                        
                    break;
                case CSSM_KEYCLASS_PRIVATE_KEY:
                    err = CSSM_CSP_CreateAsymmetricContext([[CSSMModule defaultCSPModule] handle], wrapAlgorithm, keychainFrameworkDefaultCredentials(), [wrappingKey CSSMKey], defaultPaddingForAlgorithm(wrapAlgorithm), &ccHandle);
                        
                    if (err == CSSM_OK) {
                        err = CSSM_UpdateContextAttributes(ccHandle, 1, &contextAttribute);
                        
                        if (CSSM_OK != err) {
                            PCONSOLE(@"Unable to correctly configure asymmetric encryption context, error #%u - %@.\n", err, CSSMErrorAsString(err));
                            PDEBUG(@"CSSM_UpdateContextAttributes(%"PRIccHandle", 1, %p) returned error #%u (%@).\n", ccHandle, &contextAttribute, err, CSSMErrorAsString(err));
                            
                            /* TODO - release context here */
                            
                            return nil;
                        }
                    } else {
                        PCONSOLE(@"Unable to create asymmetric encryption context for wrapping, error %#u - %@.\n", err, CSSMErrorAsString(err));
                        PDEBUG(@"CSSM_CSP_CreateAsymmetricContext(X, %d, Y, %p, %d, %p [%"PRIccHandle"]) returned error #%u (%@).\n", wrapAlgorithm, [wrappingKey CSSMKey], defaultPaddingForAlgorithm(wrapAlgorithm), &ccHandle, ccHandle, err, CSSMErrorAsString(err));
                        
                        return nil;
                    }
                        
                    break;
                default:
                    PCONSOLE(@"Unable to create wrapping context because an invalid key was provided (not a session or public key).\n");
                    PDEBUG(@"Invalid key type %d for wrapping.\n", [wrappingKey keyClass]);
                    return nil;
            }
            
            result = malloc(sizeof(CSSM_KEY));
                
            if ((err = CSSM_UnwrapKey(ccHandle, [wrappingKey CSSMKey], CSSMKey, CSSMKey->KeyHeader.KeyUsage, CSSMKey->KeyHeader.KeyAttr, NULL, NULL, result, &output)) == CSSM_OK) {
                finalResult = [Key keyWithCSSMKey:result];
            } else {
                free(result);
                PCONSOLE(@"Unable to wrap key because of error #%u - %@.\n", err, CSSMErrorAsString(err));
                PDEBUG(@"CSSM_UnwrapKey(%"PRIccHandle", %p, %p, %x, %x, NULL, NULL, %p, %p) returned error #%u (%@).\n", ccHandle, [wrappingKey CSSMKey], CSSMKey, CSSMKey->KeyHeader.KeyUsage, CSSMKey->KeyHeader.KeyAttr, result, &output, err, CSSMErrorAsString(err));                
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

    if ((error = CSSM_CSP_CreatePassThroughContext([[CSSMModule defaultCSPModule] handle], rawPubKey, &ccHand)) == CSSM_OK) {
        if ((error = CSSM_CSP_PassThrough(ccHand, CSSM_APPLECSP_KEYDIGEST, NULL, (void**)&keyDigest)) == CSSM_OK) {
            finalResult = NSDataFromDataNoCopy(keyDigest, YES);
        }
    }

    error = CSSM_DeleteContext(ccHand);

    return finalResult;
}

- (NSData*)rawData {
    if ((CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_RAW) && (CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_WRAPPED)) {
        PDEBUG(@"Called on an internal (non-raw) key instance; cannot [automatically] extract raw key data.\n");
        return nil;
    } else {
        return NSDataFromDataNoCopy(&(CSSMKey->KeyData), NO);
    }
}

- (NSData*)data {
    char *result;
    NSData *finalResult = nil;
    int dataLength;

    if ((CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_RAW) && (CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_WRAPPED)) {
        PDEBUG(@"Called on an internal (non-raw) key instance; cannot [automatically] extract raw key data.\n");
    } else {
        if (KEYHEADER_VERSION_CURRENT_SIZE != sizeof(CSSMKey->KeyHeader)) {
            PDEBUG(@"Newer version of Apple's CDSA detected (header size is %d, expected %d) - update required for the Keychain framework.\n", sizeof(CSSMKey->KeyHeader), KEYHEADER_VERSION_CURRENT_SIZE);
        } else {
            dataLength = KEYHEADER_VERSION_CURRENT_SIZE + 8 + CSSMKey->KeyData.Length;
            result = malloc(dataLength);

            memcpy(result, &RAW_KEY_VERSION_CURRENT, 4);

            // The simplest way to do this is to copy the whole header in one go.  However
            // this probably isn't going to make it very easy to port to other platforms.
            // So there's the version below, which could easily be altered to include any
            // necessary byte-swapping and so forth.

            memcpy(result + 4, &(CSSMKey->KeyHeader), KEYHEADER_VERSION_CURRENT_SIZE);

            /*memcpy(result + 4, &(CSSMKey->KeyHeader.HeaderVersion), 4);
            memcpy(result + 8, &(CSSMKey->KeyHeader.CspId), 12);
            memcpy(result + 20, &(CSSMKey->KeyHeader.BlobType), 4);
            memcpy(result + 24, &(CSSMKey->KeyHeader.Format), 4);
            memcpy(result + 28, &(CSSMKey->KeyHeader.AlgorithmId), 4);
            memcpy(result + 32, &(CSSMKey->KeyHeader.KeyClass), 4);
            memcpy(result + 36, &(CSSMKey->KeyHeader.LogicalKeySizeInBits), 4);
            memcpy(result + 40, &(CSSMKey->KeyHeader.KeyAttr), 4);
            memcpy(result + 44, &(CSSMKey->KeyHeader.KeyUsage), 4);
            memcpy(result + 48, &(CSSMKey->KeyHeader.StartDate), 8);
            memcpy(result + 56, &(CSSMKey->KeyHeader.EndDate), 8);
            memcpy(result + 64, &(CSSMKey->KeyHeader.WrapAlgorithmId), 4);
            memcpy(result + 68, &(CSSMKey->KeyHeader.WrapMode), 4);*/

            memcpy(result + KEYHEADER_VERSION_CURRENT_SIZE + 4, &(CSSMKey->KeyData.Length), 4);
            memcpy(result + KEYHEADER_VERSION_CURRENT_SIZE + 8, CSSMKey->KeyData.Data, CSSMKey->KeyData.Length);

            finalResult = [NSData dataWithBytesNoCopy:result length:dataLength freeWhenDone:YES];
        }
    }

    return finalResult;
}

- (BOOL)isEqualToKey:(Key*)otherKey {
    const CSSM_KEY *otherCSSMKey;

    if (otherKey) {
        otherCSSMKey = [otherKey CSSMKey];

        if ((CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_REFERENCE) && (otherCSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_REFERENCE)) {
            if ((self == otherKey) || (CSSMKey == otherCSSMKey)) {
                return YES;
            } else {
                return ((memcmp(&(CSSMKey->KeyHeader), &(otherCSSMKey->KeyHeader), sizeof(CSSM_KEYHEADER)) == 0) && (CSSMKey->KeyData.Length == otherCSSMKey->KeyData.Length) && (memcmp(CSSMKey->KeyData.Data, otherCSSMKey->KeyData.Data, CSSMKey->KeyData.Length) == 0));
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

        if ((CSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_REFERENCE) && (otherCSSMKey->KeyHeader.BlobType != CSSM_KEYBLOB_REFERENCE)) {
            if ((self == otherKey) || (CSSMKey == otherCSSMKey)) {
                return YES;
            } else {
                return ((CSSMKey->KeyData.Length == otherCSSMKey->KeyData.Length) && (memcmp(CSSMKey->KeyData.Data, otherCSSMKey->KeyData.Data, CSSMKey->KeyData.Length) == 0));
            }
        } else {
            PDEBUG(@"Called on a reference key, or with a reference key, or both.\n");
        }
    }
    
    return NO;
}

- (const CSSM_KEY *)CSSMKey {
    return CSSMKey;
}

- (int)lastError {
    return error;
}

- (SecKeyRef)keyRef {
    return key;
}

- (void)dealloc {
    if (key) {
        CFRelease(key);
    }
    
    [super dealloc];
}

@end
