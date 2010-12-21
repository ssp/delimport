//
//  MutableKey.m
//  Keychain
//
//  Created by Wade Tregaskis on Sat Mar 15 2003.
//
//  Copyright (c) 2003 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "MutableKey.h"

#import "CDSA/CSSMControl.h"
#import "CDSA/CSSMUtils.h"
#import "CDSA/CSSMModule.h"
#import "CDSA/CSSMTypes.h"

#import "Utilities/UtilitySupport.h"
#import "Utilities/Logging.h"


@implementation MutableKey

+ (MutableKey*)generateKey:(CSSM_ALGORITHMS)algorithm size:(uint32_t)keySizeInBits validFrom:(NSCalendarDate*)validFrom validTo:(NSCalendarDate*)validTo usage:(uint32_t)keyUsage mutable:(BOOL)keyIsMutable extractable:(BOOL)keyIsExtractable sensitive:(BOOL)keyIsSensitive label:(NSString*)label module:(CSSMModule*)CSPModule {
    CSSM_KEY *keyResult;
    CSSM_CC_HANDLE cryptoContext;
    CSSM_DATA *keyLabel;
    MutableKey *result = nil;
    CSSM_RETURN err;
    CSSM_DATE from = CSSMDateForCalendarDate(validFrom), to = CSSMDateForCalendarDate(validTo);

    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }
    
    //PDEBUG(@"from == %c%c/%c%c/%c%c%c%c\n", from->Day[0], from->Day[1], from->Month[0], from->Month[1], from->Year[0], from->Year[1], from->Year[2], from->Year[3]);
    
    if (CSSM_OK == (err = CSSM_CSP_CreateKeyGenContext([CSPModule handle], algorithm, keySizeInBits, NULL, NULL, &from, &to, NULL, &cryptoContext))) {
        uint32_t keyAttributes = CSSM_KEYATTR_RETURN_REF;
        
        if (keyIsMutable) {
            keyAttributes |= CSSM_KEYATTR_MODIFIABLE;
        }
        
        if (keyIsSensitive) {
            keyAttributes |= CSSM_KEYATTR_SENSITIVE;
        } else if (keyIsExtractable) {
            keyAttributes |= CSSM_KEYATTR_EXTRACTABLE;
        }
        
        //PDEBUG(@"Generated date for %@ resulting in %@.\n", validFrom, calendarDateForCSSMDate(CSSMDateForCalendarDate(validFrom)));
        
        keyLabel = dataFromNSString(label);
        keyResult = malloc(sizeof(CSSM_KEY));
        
        if ((err = CSSM_GenerateKey(cryptoContext, keyUsage, keyAttributes, keyLabel, NULL, keyResult)) == CSSM_OK) {

            result = [MutableKey keyWithCSSMKey:keyResult freeWhenDone:YES module:CSPModule];
        } else {
            free(keyResult);
            PSYSLOGND(LOG_ERR, @"Unable to generate key because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_GenerateKey(%"PRIccHandle", %x, %x, %p, NULL, %p) returned error %@.\n", cryptoContext, keyUsage, keyAttributes, keyLabel, keyResult, CSSMErrorAsString(err));
        }

        CSSM_DeleteContext(cryptoContext);
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create key generation context because of error %@.\n", CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateKeyGenContext(X, %d, %d, NULL, NULL, %p, %p, NULL, %p [%"PRIccHandle"]) returned error %@.\n", algorithm, keySizeInBits, &from, &to, &cryptoContext, cryptoContext, CSSMErrorAsString(err));
    }

    return result;
}

+ (MutableKey*)keyWithKeyRef:(SecKeyRef)ke module:(CSSMModule*)CSPModule {
#pragma unused (ke, CSPModule) // These will never be used, since we're actually a placeholder implementation to ensure no-one calls us.
    PDEBUG(@"It is not possible to create a MutableKey instance from existing SecKeyRef.\n");
    return nil;
}

+ (MutableKey*)keyWithCSSMKey:(CSSM_KEY*)ke module:(CSSMModule*)CSPModule {
    return [self keyWithCSSMKey:ke freeWhenDone:NO module:CSPModule];
}

+ (MutableKey*)keyWithCSSMKey:(CSSM_KEY*)ke freeWhenDone:(BOOL)freeWhenDo module:(CSSMModule*)CSPModule {
    return [[[[self class] alloc] initWithCSSMKey:ke freeWhenDone:freeWhenDo module:CSPModule] autorelease];
}

- (MutableKey*)initWithKeyRef:(SecKeyRef)ke module:(CSSMModule*)CSPModule {
#pragma unused (ke, CSPModule) // These will never be used, since we're actually a placeholder implementation to ensure no-one calls us.

    PDEBUG(@"It is not possible to initialise a MutableKey instance with an existing SecKeyRef.\n");
    
    [self release];
    
    return nil;
}

- (MutableKey*)initWithCSSMKey:(CSSM_KEY*)ke freeWhenDone:(BOOL)freeWhenDo module:(CSSMModule*)CSPModule {
    if (nil == CSPModule) {
        PDEBUG(@"Invalid parameter - CSPModule is nil.\n");
        [self release];
        return nil;
    }
    
    _CSPModule = [CSPModule retain];
    _CSSMKey = _MutableCSSMKey = ke;
    _key = nil;
    _freeWhenDone = freeWhenDo;

    return self;
}

- (MutableKey*)init {
    [self release];
    return nil;
}

- (void)setFreeWhenDone:(BOOL)freeWhenDo {
    _freeWhenDone = freeWhenDo;
}

- (BOOL)freeWhenDone {
    return _freeWhenDone;
}

- (void)setVersion:(CSSM_HEADERVERSION)version {
    _MutableCSSMKey->KeyHeader.HeaderVersion = version;
}

- (void)setBlobType:(CSSM_KEYBLOB_TYPE)blobType {
    _MutableCSSMKey->KeyHeader.BlobType = blobType;
}

- (void)setFormat:(CSSM_KEYBLOB_FORMAT)format {
    _MutableCSSMKey->KeyHeader.Format = format;
}

- (void)setAlgorithm:(CSSM_ALGORITHMS)algorithm {
    _MutableCSSMKey->KeyHeader.AlgorithmId = algorithm;
}

- (void)setWrapAlgorithm:(CSSM_ALGORITHMS)wrapAlgorithm {
    _MutableCSSMKey->KeyHeader.WrapAlgorithmId = wrapAlgorithm;
}

- (void)setKeyClass:(CSSM_KEYCLASS)keyClass {
    _MutableCSSMKey->KeyHeader.KeyClass = keyClass;
}

- (void)setLogicalSize:(int)size {
    _MutableCSSMKey->KeyHeader.LogicalKeySizeInBits = size;
}

- (void)setAttributes:(CSSM_KEYATTR_FLAGS)attributes {
    _MutableCSSMKey->KeyHeader.KeyAttr = attributes;
}

- (void)setUsage:(CSSM_KEYUSE)usage {
    _MutableCSSMKey->KeyHeader.KeyUsage = usage;
}

- (void)setStartDate:(NSCalendarDate*)date {
    _MutableCSSMKey->KeyHeader.StartDate = CSSMDateForCalendarDate(date);
}

- (void)setEndDate:(NSCalendarDate*)date {
    _MutableCSSMKey->KeyHeader.EndDate = CSSMDateForCalendarDate(date);
}

- (void)setWrapMode:(CSSM_ENCRYPT_MODE)wrapMode {
    _MutableCSSMKey->KeyHeader.WrapMode = wrapMode;
}

- (void)setData:(NSData*)data {
    copyNSDataToData(data, &(_MutableCSSMKey->KeyData));
}

- (CSSM_KEY*)CSSMKey {
    return _MutableCSSMKey;
}

- (void)dealloc {
    if (_MutableCSSMKey && _freeWhenDone) {
        CSSM_FreeKey([_CSPModule handle], NULL, _MutableCSSMKey, 0);
    }

    [super dealloc];
}

@end

CSSM_RETURN generateKeyPair(CSSM_ALGORITHMS algorithm, uint32_t keySizeInBits, NSCalendarDate *validFrom, NSCalendarDate *validTo, uint32_t publicKeyUsage, uint32_t privateKeyUsage, NSString *publicKeyLabel, NSString *privateKeyLabel, CSSMModule *CSPModule, MutableKey **publicKey, MutableKey **privateKey) {
    if ((nil == validFrom) || (nil == validTo) || (nil == publicKeyLabel)) {
        PSYSLOGND(LOG_ERR, @"Missing parameter(s) to generateKeyPair().\n");
        PDEBUG(@"Invalid parameter(s) - validFrom = %p, validTo = %p, publicKeyLabel = %p.\n", validFrom, validTo, publicKeyLabel);
        return CSSMERR_CSSM_INVALID_INPUT_POINTER;
    } else if ((nil == publicKey) || (nil == privateKey)) {
        PSYSLOGND(LOG_ERR, @"Missing parameter(s) to generateKeyPair().\n");
        PDEBUG(@"Invalid parameter(s) - publicKey = %p, privateKey = %p.\n", publicKey, privateKey);
        return CSSMERR_CSSM_INVALID_OUTPUT_POINTER;
    }
    
    CSSM_CC_HANDLE cryptoContext;
    CSSM_KEY *pubKey, *privKey;
    CSSM_DATA *pubKeyLabel, *privKeyLabel;
    CSSM_DATE from = CSSMDateForCalendarDate(validFrom), to = CSSMDateForCalendarDate(validTo);
    CSSM_RETURN err = CSSM_OK;
    CSSM_KEYATTR_FLAGS pubAttributes, privAttributes;
    
    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }
    
    if ((err = CSSM_CSP_CreateKeyGenContext([CSPModule handle], algorithm, keySizeInBits, NULL, NULL, &from, &to, NULL, &cryptoContext)) == CSSM_OK) {
        pubKeyLabel = dataFromNSString(publicKeyLabel);
        privKeyLabel = dataFromNSString(privateKeyLabel);

        pubKey = malloc(sizeof(CSSM_KEY));
        privKey = malloc(sizeof(CSSM_KEY));

        // Note that public and private keys must be marked CSSM_KEYATTR_EXTRACTABLE.
        // They cannot be CSSM_KEYATTR_MODIFIABLE and/or CSSM_KEYATTR_SENSITIVE.
        // Presumably they cannot be securely wrapped (?!?)
        
        pubAttributes = privAttributes = CSSM_KEYATTR_RETURN_REF | CSSM_KEYATTR_EXTRACTABLE;
        privAttributes |= CSSM_KEYATTR_SENSITIVE;
        
        //PDEBUG(@"Public key attributes: %@\n", descriptionOfKeyAttributesUsingConstants(pubAttributes));
        //PDEBUG(@"Private key attributes: %@\n", descriptionOfKeyAttributesUsingConstants(privAttributes));
        
        if ((err = CSSM_GenerateKeyPair(cryptoContext, publicKeyUsage, pubAttributes, pubKeyLabel, pubKey, privateKeyUsage, privAttributes, privKeyLabel, NULL, privKey)) == CSSM_OK) {
            *publicKey = [MutableKey keyWithCSSMKey:pubKey freeWhenDone:YES module:CSPModule];
            *privateKey = [MutableKey keyWithCSSMKey:privKey freeWhenDone:YES module:CSPModule];
        } else {
            free(pubKey);
            free(privKey);
            
            PSYSLOGND(LOG_ERR, @"Unable to generate key pair because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_GenerateKeyPair(%"PRIccHandle", %x, %x, %p, %p, %x, %x, %p, NULL, %p) returned error %@.\n", cryptoContext, publicKeyUsage, pubAttributes, pubKeyLabel, pubKey, privateKeyUsage, privAttributes, privKeyLabel, privKey, CSSMErrorAsString(err));
        }

        CSSM_DeleteContext(cryptoContext);
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create key gen context because of error %@.\n", CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateKeyGenContext(X, %d, %d, NULL, NULL, %p, %p, NULL, %p [%"PRIccHandle"]) returned error %@.\n", algorithm, keySizeInBits, &from, &to, &cryptoContext, cryptoContext, CSSMErrorAsString(err));
    }
    
    return err;
}
