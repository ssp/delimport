//
//  MutableKey.m
//  Keychain
//
//  Created by Wade Tregaskis on Sat Mar 15 2003.
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "MutableKey.h"

#import "CSSMControl.h"
#import "CSSMUtils.h"
#import "CSSMModule.h"
#import "CSSMTypes.h"

#import "UtilitySupport.h"
#import "Logging.h"


@implementation MutableKey

+ (MutableKey*)generateKey:(CSSM_ALGORITHMS)algorithm size:(uint32)keySizeInBits validFrom:(NSCalendarDate*)validFrom validTo:(NSCalendarDate*)validTo usage:(uint32)keyUsage mutable:(BOOL)keyIsMutable extractable:(BOOL)keyIsExtractable sensitive:(BOOL)keyIsSensitive label:(NSString*)label {
    CSSM_KEY *keyResult;
    CSSM_CC_HANDLE cryptoContext;
    CSSM_DATA *keyLabel;
    MutableKey *result = nil;
    CSSM_RETURN err;
    CSSM_DATE from = CSSMDateForCalendarDate(validFrom), to = CSSMDateForCalendarDate(validTo);

    //PDEBUG(@"from == %c%c/%c%c/%c%c%c%c\n", from->Day[0], from->Day[1], from->Month[0], from->Month[1], from->Year[0], from->Year[1], from->Year[2], from->Year[3]);
    
    if (CSSM_OK == (err = CSSM_CSP_CreateKeyGenContext([[CSSMModule defaultCSPModule] handle], algorithm, keySizeInBits, NULL, NULL, &from, &to, NULL, &cryptoContext))) {
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

            result = [MutableKey keyWithCSSMKey:keyResult freeWhenDone:YES];
        } else {
            free(keyResult);
            PCONSOLE(@"Unable to generate key because of error #%u - %@.\n", err, CSSMErrorAsString(err));
            PDEBUG(@"CSSM_GenerateKey(%"PRIccHandle", %x, %x, %p, NULL, %p) returned error #%u (%@).\n", cryptoContext, keyUsage, keyAttributes, keyLabel, keyResult, err, CSSMErrorAsString(err));
        }

        CSSM_DeleteContext(cryptoContext);
    } else {
        PCONSOLE(@"Unable to create key generation context because of error #%u - %@.\n", err, CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateKeyGenContext(X, %d, %d, NULL, NULL, %p, %p, NULL, %p [%"PRIccHandle"]) returned error #%u (%@).\n", algorithm, keySizeInBits, &from, &to, &cryptoContext, cryptoContext, err, CSSMErrorAsString(err));
    }

    return result;
}

+ (MutableKey*)keyWithKeyRef:(SecKeyRef)ke {
    return nil;
}

+ (MutableKey*)keyWithCSSMKey:(CSSM_KEY*)ke {
    return [[self class] keyWithCSSMKey:ke freeWhenDone:NO];
}

+ (MutableKey*)keyWithCSSMKey:(CSSM_KEY*)ke freeWhenDone:(BOOL)freeWhenDo {
    return [[[[self class] alloc] initWithCSSMKey:ke freeWhenDone:freeWhenDo] autorelease];
}

- (MutableKey*)initWithKeyRef:(SecKeyRef)ke {
    [self release];
    
    return nil;
}

- (MutableKey*)initWithCSSMKey:(CSSM_KEY*)ke freeWhenDone:(BOOL)freeWhenDo {
    CSSMKey = MutableCSSMKey = ke;
    key = nil;
    freeWhenDone = freeWhenDo;

    return self;
}

- (MutableKey*)init {
    [self release];
    return nil;
}

- (void)setFreeWhenDone:(BOOL)freeWhenDo {
    freeWhenDone = freeWhenDo;
}

- (BOOL)freeWhenDone {
    return freeWhenDone;
}

- (void)setVersion:(CSSM_HEADERVERSION)version {
    MutableCSSMKey->KeyHeader.HeaderVersion = version;
}

- (void)setBlobType:(CSSM_KEYBLOB_TYPE)blobType {
    MutableCSSMKey->KeyHeader.BlobType = blobType;
}

- (void)setFormat:(CSSM_KEYBLOB_FORMAT)format {
    MutableCSSMKey->KeyHeader.Format = format;
}

- (void)setAlgorithm:(CSSM_ALGORITHMS)algorithm {
    MutableCSSMKey->KeyHeader.AlgorithmId = algorithm;
}

- (void)setWrapAlgorithm:(CSSM_ALGORITHMS)wrapAlgorithm {
    MutableCSSMKey->KeyHeader.WrapAlgorithmId = wrapAlgorithm;
}

- (void)setKeyClass:(CSSM_KEYCLASS)keyClass {
    MutableCSSMKey->KeyHeader.KeyClass = keyClass;
}

- (void)setLogicalSize:(int)size {
    MutableCSSMKey->KeyHeader.LogicalKeySizeInBits = size;
}

- (void)setAttributes:(CSSM_KEYATTR_FLAGS)attributes {
    MutableCSSMKey->KeyHeader.KeyAttr = attributes;
}

- (void)setUsage:(CSSM_KEYUSE)usage {
    MutableCSSMKey->KeyHeader.KeyUsage = usage;
}

- (void)setStartDate:(NSCalendarDate*)date {
    MutableCSSMKey->KeyHeader.StartDate = CSSMDateForCalendarDate(date);
}

- (void)setEndDate:(NSCalendarDate*)date {
    MutableCSSMKey->KeyHeader.EndDate = CSSMDateForCalendarDate(date);
}

- (void)setWrapMode:(CSSM_ENCRYPT_MODE)wrapMode {
    MutableCSSMKey->KeyHeader.WrapMode = wrapMode;
}

- (void)setData:(NSData*)data {
    copyNSDataToData(data, &(MutableCSSMKey->KeyData));
}

- (CSSM_KEY*)CSSMKey {
    return MutableCSSMKey;
}

- (void)dealloc {
    if (MutableCSSMKey && freeWhenDone) {
        CSSM_FreeKey([[CSSMModule defaultCSPModule] handle], NULL, MutableCSSMKey, 0);
    }

    [super dealloc];
}

@end

NSArray* generateKeyPair(CSSM_ALGORITHMS algorithm, uint32 keySizeInBits, NSCalendarDate *validFrom, NSCalendarDate *validTo, uint32 publicKeyUsage, uint32 privateKeyUsage, NSString *publicKeyLabel, NSString *privateKeyLabel) {
    CSSM_CC_HANDLE cryptoContext;
    CSSM_KEY *pubKey, *privKey;
    CSSM_DATA *pubKeyLabel, *privKeyLabel;
    CSSM_DATE from = CSSMDateForCalendarDate(validFrom), to = CSSMDateForCalendarDate(validTo);
    NSArray *result = nil;
    CSSM_RETURN err;
    CSSM_KEYATTR_FLAGS pubAttributes, privAttributes;
    
    if ((err = CSSM_CSP_CreateKeyGenContext([[CSSMModule defaultCSPModule] handle], algorithm, keySizeInBits, NULL, NULL, &from, &to, NULL, &cryptoContext)) == CSSM_OK) {
        pubKeyLabel = dataFromNSString(publicKeyLabel);
        privKeyLabel = dataFromNSString(privateKeyLabel);

        pubKey = malloc(sizeof(CSSM_KEY));
        privKey = malloc(sizeof(CSSM_KEY));

        // Note that public and private keys must be marked CSSM_KEYATTR_EXTRACTABLE.
        // They cannot be CSSM_KEYATTR_MODIFIABLE and/or CSSM_KEYATTR_SENSITIVE.
        // Presumably they cannot be securely wrapped (?!?)
        
        pubAttributes = privAttributes = CSSM_KEYATTR_RETURN_REF | CSSM_KEYATTR_EXTRACTABLE;
        privAttributes |= CSSM_KEYATTR_SENSITIVE;
        
        //PDEBUG(@"Public key attributes: %@\n", namesOfAttributes(pubAttributes));
        //PDEBUG(@"Private key attributes: %@\n", namesOfAttributes(privAttributes));
        
        if ((err = CSSM_GenerateKeyPair(cryptoContext, publicKeyUsage, pubAttributes, pubKeyLabel, pubKey, privateKeyUsage, privAttributes, privKeyLabel, NULL, privKey)) == CSSM_OK) {
            result = [NSArray arrayWithObjects:[MutableKey keyWithCSSMKey:pubKey freeWhenDone:YES], [MutableKey keyWithCSSMKey:privKey freeWhenDone:YES], nil];
        } else {
            free(pubKey);
            free(privKey);
            
            PCONSOLE(@"Unable to generate key pair because of error #%u - %@.\n", err, CSSMErrorAsString(err));
            PDEBUG(@"CSSM_GenerateKeyPair(%"PRIccHandle", %x, %x, %p, %p, %x, %x, %p, NULL, %p) returned error #%u (%@).\n", cryptoContext, publicKeyUsage, pubAttributes, pubKeyLabel, pubKey, privateKeyUsage, privAttributes, privKeyLabel, privKey, err, CSSMErrorAsString(err));
        }

        CSSM_DeleteContext(cryptoContext);
    } else {
        PCONSOLE(@"Unable to create key gen context because of error #%u - %@.\n", err, CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateKeyGenContext(X, %d, %d, NULL, NULL, %p, %p, NULL, %p [%"PRIccHandle"]) returned error #%u (%@).\n", algorithm, keySizeInBits, &from, &to, &cryptoContext, cryptoContext, err, CSSMErrorAsString(err));
    }
    
    return result;
}
