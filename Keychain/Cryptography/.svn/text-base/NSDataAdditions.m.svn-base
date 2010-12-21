//
//  NSDataAdditions.m
//  Keychain
//
//  Created by Wade Tregaskis on Wed May 07 2003.
//
//  Copyright (c) 2003 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "NSDataAdditions.h"

#import "CDSA/CSSMDefaults.h"
#import "CDSA/CSSMControl.h"
#import "CDSA/CSSMUtils.h"
#import "CDSA/CSSMTypes.h"
#import "CDSA/CSSMModule.h"

#import "Utilities/UtilitySupport.h"
#import "Utilities/Logging.h"

// For pre-10.5 SDKs:
#ifndef NSINTEGER_DEFINED
typedef int NSInteger;
typedef unsigned int NSUInteger;
#define NSINTEGER_DEFINED
#endif
typedef size_t CSSM_SIZE;

@implementation NSData (KeychainFramework)

- (NSData*)encryptedDataUsingKey:(Key*)key mode:(CSSM_ENCRYPT_MODE)mode padding:(CSSM_PADDING)padding {
    CSSM_CC_HANDLE ccHandle;
    CSSM_DATA result = {0, NULL}, original;
    CSSM_SIZE outputLength;
    CSSM_RETURN err;
    NSData *finalResult = nil;
    CSSMModule *CSPModule = [key CSPModule];
    
    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }
    
    switch ([key keyClass]) {
        case CSSM_KEYCLASS_SESSION_KEY:
            // Symmetric encryption
            //PDEBUG(@"Symmetric.\n");
        
            err = CSSM_CSP_CreateSymmetricContext([CSPModule handle], [key algorithm], mode, keychainFrameworkDefaultCredentials(), [key CSSMKey], &keychainFrameworkInitVectorData, padding, NULL, &ccHandle);
            
            break;
        case CSSM_KEYCLASS_PUBLIC_KEY:
            // Asymmetric encryption
            //PDEBUG(@"Asymmetric, algorithm = %@.\n", nameOfAlgorithm([key algorithm]));
        
            err = CSSM_CSP_CreateAsymmetricContext([CSPModule handle], [key algorithm], keychainFrameworkDefaultCredentials(), [key CSSMKey], padding, &ccHandle);
            
            break;
        default:
            PSYSLOGND(LOG_ERR, @"Unable to create encryption context because an invalid key was provided.\n");
            PDEBUG(@"key keyClass = %d.\n", [key keyClass]);
        
            return nil;
    }
    
    if (err == CSSM_OK) {
        original.Length = [self length];
        original.Data = (uint8_t*)[self bytes];

        //PDEBUG(@"Original == %c%c%c%c%c%c%c...\n", original.Data[0], original.Data[1], original.Data[2], original.Data[3], original.Data[4], original.Data[5], original.Data[6]);
        
        if ((err = CSSM_EncryptData(ccHandle, &original, 1, &result, 1, &outputLength, &result)) == CSSM_OK) {
            //PDEBUG(@"Result == %c%c%c%c%c%c%c...\n", result.Data[0], result.Data[1], result.Data[2], result.Data[3], result.Data[4], result.Data[5], result.Data[6]);
            
            if (outputLength < original.Length) {
                PDEBUG(@"Warning - outputLength only %u bytes, versus original text of %u bytes.\n", outputLength, original.Length);
            }

            finalResult = NSDataFromDataNoCopy(&result, YES); // [NSData dataWithBytesNoCopy:result.Data length:result.Length];
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to encrypt data because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_EncryptData(%"PRIccHandle", %p, 1, %p, 1, %p [%d], %p) returned error %@.\n", ccHandle, &original, &result, &outputLength, outputLength, &result, CSSMErrorAsString(err));
        }

        if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
            PSYSLOGND(LOG_WARNING, @"Failed to destroy encryption context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
        }
    } else {
        switch ([key keyClass]) {
            case CSSM_KEYCLASS_SESSION_KEY:
                PSYSLOGND(LOG_ERR, @"Unable to create symmetric encryption context because of error %@.\n", CSSMErrorAsString(err));
                PDEBUG(@"CSSM_CSP_CreateSymmetricContext(X, %d, %d, Y, %p, %p, %p, NULL, %p [%"PRIccHandle"]) returned error %@.\n", [key algorithm], mode, [key CSSMKey], &keychainFrameworkInitVectorData, padding, &ccHandle, ccHandle, CSSMErrorAsString(err));
                
                break;
            case CSSM_KEYCLASS_PUBLIC_KEY:
                PSYSLOGND(LOG_ERR, @"Unable to create symmetric encryption context because of error %@.\n", CSSMErrorAsString(err));
                PDEBUG(@"CSSM_CSP_CreateAsymmetricContext(X, %d, Y, %p, %p, %p [%"PRIccHandle"]) returned error %@.\n", [key algorithm], [key CSSMKey], padding, &ccHandle, ccHandle, CSSMErrorAsString(err));
                
                break;
        }
    }

    return finalResult;
}

- (NSData*)encryptedDataUsingKey:(Key*)key {
    CSSM_ALGORITHMS algorithm = [key algorithm];

    return [self encryptedDataUsingKey:key mode:defaultModeForAlgorithm(algorithm) padding:defaultPaddingForAlgorithm(algorithm)];
}

- (NSData*)decryptedDataUsingKey:(Key*)key mode:(CSSM_ENCRYPT_MODE)mode padding:(CSSM_PADDING)padding {
    CSSM_CC_HANDLE ccHandle;
    CSSM_DATA result = {0, NULL}, original;
    CSSM_SIZE outputLength;
    CSSM_RETURN err;
    NSData *finalResult = nil;
    CSSMModule *CSPModule = [key CSPModule];

    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }
    
    switch ([key keyClass]) {
        case CSSM_KEYCLASS_SESSION_KEY:
            // Symmetric encryption
            //PDEBUG(@"Symmetric.\n");

            err = CSSM_CSP_CreateSymmetricContext([CSPModule handle], [key algorithm], mode, keychainFrameworkDefaultCredentials(), [key CSSMKey], &keychainFrameworkInitVectorData, padding, NULL, &ccHandle);
            
            break;
        case CSSM_KEYCLASS_PRIVATE_KEY:
            // Asymmetric encryption
            //PDEBUG(@"Asymmetric, algorithm = %@.\n", nameOfAlgorithm([key algorithm]));

            err = CSSM_CSP_CreateAsymmetricContext([CSPModule handle], [key algorithm], keychainFrameworkDefaultCredentials(), [key CSSMKey], padding, &ccHandle);
            
            break;
        default:
            PSYSLOG(LOG_ERR, @"Unable to create decryption context because an invalid key (class %d) was provided.\n", [key keyClass]);
            return nil;
    }
    
    if (err == CSSM_OK) {
        original.Length = [self length];
        original.Data = (uint8_t*)[self bytes];

        if ((err = CSSM_DecryptData(ccHandle, &original, 1, &result, 1, &outputLength, &result)) == CSSM_OK) {
            //PDEBUG(@"outputLength == %u, versus input of %u.\n", outputLength, original.Length);
            finalResult = [NSData dataWithBytesNoCopy:result.Data length:outputLength];
            // Note that the length given in to the NSData is not that of the result struct - we want to clip away the junk that results from the padding
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to decrypt data because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DecryptData(%"PRIccHandle", %p, 1, %p, 1, %p [%d], %p) returned error %@.\n", ccHandle, &original, &result, &outputLength, outputLength, &result, CSSMErrorAsString(err));
        }

        if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
            PSYSLOGND(LOG_WARNING, @"Failed to destroy decryption context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
        }
    } else {
        switch ([key keyClass]) {
            case CSSM_KEYCLASS_SESSION_KEY:                
                PSYSLOGND(LOG_ERR, @"Unable to create symmetric decryption context because of error %@.\n", CSSMErrorAsString(err));
                PDEBUG(@"CSSM_CSP_CreateSymmetricContext(X, %d, %d, Y, %p, %p, %p, NULL, %p [%"PRIccHandle"]) returned error %@.\n", [key algorithm], mode, [key CSSMKey], &keychainFrameworkInitVectorData, padding, &ccHandle, ccHandle, CSSMErrorAsString(err));

                break;
            case CSSM_KEYCLASS_PRIVATE_KEY:
                err = CSSM_CSP_CreateAsymmetricContext([CSPModule handle], [key algorithm], keychainFrameworkDefaultCredentials(), [key CSSMKey], padding, &ccHandle);

                PSYSLOGND(LOG_ERR, @"Unable to create asymmetric decryption context because of error %@.\n", CSSMErrorAsString(err));
                PDEBUG(@"CSSM_CSP_CreateSymmetricContext(X, %d, Y, %p, %p, %p [%"PRIccHandle"]) returned error %@.\n", [key algorithm], [key CSSMKey], padding, &ccHandle, ccHandle, CSSMErrorAsString(err));

                break;
        }
        
    }

    return finalResult;
}

- (NSData*)decryptedDataUsingKey:(Key*)key {
    CSSM_ALGORITHMS algorithm = [key algorithm];

    return [self decryptedDataUsingKey:key mode:defaultModeForAlgorithm(algorithm) padding:defaultPaddingForAlgorithm(algorithm)];
}

- (NSData*)MACUsingKey:(Key*)key {
    CSSM_CC_HANDLE ccHandle;
    CSSM_RETURN err;
    CSSM_DATA result = {0, NULL}, original;
    NSData *finalResult = nil;
    CSSMModule *CSPModule = [key CSPModule];

    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }
    
    if ((err = CSSM_CSP_CreateMacContext([CSPModule handle], [key algorithm], [key CSSMKey], &ccHandle)) == CSSM_OK) {
        original.Length = [self length];
        original.Data = (uint8_t*)[self bytes];
        
        if ((err = CSSM_GenerateMac(ccHandle, &original, 1, &result)) == CSSM_OK) {
            finalResult = NSDataFromDataNoCopy(&result, YES); // [NSData dataWithBytesNoCopy:result.Data length:result.Length];
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to generate MAC because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_GenerateMac(%"PRIccHandle", %p, 1, %p) returned error %@.\n", ccHandle, &original, &result, CSSMErrorAsString(err));
        }

        if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
            PSYSLOGND(LOG_WARNING, @"Failed to destroy MAC context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create MAC context because of error %@.\n", CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateMacContext(X, %d, %p, %p [%"PRIccHandle"]) returned error %@.\n", [key algorithm], [key CSSMKey], &ccHandle, ccHandle, CSSMErrorAsString(err));
    }

    return finalResult;
}

- (BOOL)verifyUsingKey:(Key*)key MAC:(NSData*)MAC {
    CSSM_CC_HANDLE ccHandle;
    CSSM_RETURN err;
    CSSM_DATA original, originalMAC;
    BOOL finalResult = NO;
    CSSMModule *CSPModule = [key CSPModule];

    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }
    
    if ((err = CSSM_CSP_CreateMacContext([CSPModule handle], [key algorithm], [key CSSMKey], &ccHandle)) == CSSM_OK) {
        original.Length = [self length];
        original.Data = (uint8_t*)[self bytes];

        originalMAC.Length = [MAC length];
        originalMAC.Data = (uint8_t*)[MAC bytes];

        if ((err = CSSM_VerifyMac(ccHandle, &original, 1, &originalMAC)) == CSSM_OK) {
            finalResult = YES;
        } else {
            if ((err != CSSMERR_CSP_VERIFY_FAILED) && (err != CSSMERR_CSP_INVALID_SIGNATURE)) {
                PSYSLOGND(LOG_ERR, @"Unable to verify MAC because of error %@.\n", CSSMErrorAsString(err));
                PDEBUG(@"CSSM_VerifyMac(%"PRIccHandle", %p, 1, %p) returned error %@.\n", ccHandle, &original, &originalMAC, CSSMErrorAsString(err));
            }
        }

        if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
            PSYSLOGND(LOG_WARNING, @"Failed to destroy MAC context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create MAC context because of error %@.\n", CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateMacContext(X, %d, %p, %p [%"PRIccHandle"]) returned error %@.\n", [key algorithm], [key CSSMKey], &ccHandle, ccHandle, CSSMErrorAsString(err));
    }

    return finalResult;
}

- (NSData*)signatureUsingKey:(Key*)key digest:(CSSM_ALGORITHMS)algorithm {
    CSSM_RETURN err;
    CSSM_CC_HANDLE ccHandle;
    NSData *finalResult = nil;
    CSSM_DATA original, result;
    CSSMModule *CSPModule = [key CSPModule];

    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }
    
    if ((err = CSSM_CSP_CreateSignatureContext([CSPModule handle], algorithm, keychainFrameworkDefaultCredentials(), [key CSSMKey], &ccHandle)) == CSSM_OK) {
        original.Length = [self length];
        original.Data = (uint8_t*)[self bytes];

        result.Length = 0;
        result.Data = NULL;
        
        if ((err = CSSM_SignData(ccHandle, &original, 1, CSSM_ALGID_NONE, &result)) == CSSM_OK) {
            finalResult = NSDataFromDataNoCopy(&result, YES); // [NSData dataWithBytesNoCopy:result.Data length:result.Length];
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to generate digest and/or signature because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_SignData(%"PRIccHandle", %p, 1, CSSM_ALGID_NONE, %p) returned error %@.\n", ccHandle, &original, &result, CSSMErrorAsString(err));
        }

        if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
            PSYSLOGND(LOG_WARNING, @"Failed to destroy digest & signing context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create digest & signing context because of error %@.\n", CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateSignatureContext(X, %d, Y, %p, %p [%"PRIccHandle"]) returned error %@.\n", algorithm, [key CSSMKey], &ccHandle, ccHandle, CSSMErrorAsString(err));
    }

    return finalResult;
}

- (NSData*)signatureUsingKey:(Key*)key {
    return [self signatureUsingKey:key digest:defaultDigestForAlgorithm([key algorithm])];
}

- (NSData*)digestSignatureUsingKey:(Key*)key digest:(CSSM_ALGORITHMS)algorithm {
    CSSM_RETURN err;
    CSSM_CC_HANDLE ccHandle;
    NSData *finalResult = nil;
    CSSM_DATA original, result;
    CSSMModule *CSPModule = [key CSPModule];

    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }
    
    if ((err = CSSM_CSP_CreateSignatureContext([CSPModule handle], [key algorithm], keychainFrameworkDefaultCredentials(), [key CSSMKey], &ccHandle)) == CSSM_OK) {
        original.Length = [self length];
        original.Data = (uint8_t*)[self bytes];

        result.Length = 0;
        result.Data = NULL;

        if ((err = CSSM_SignData(ccHandle, &original, 1, algorithm, &result)) == CSSM_OK) {
            finalResult = NSDataFromDataNoCopy(&result, YES); // [NSData dataWithBytesNoCopy:result.Data length:result.Length];
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to generate signature because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_SignData(%"PRIccHandle", %p, 1, %d, %p) returned error %@.\n", ccHandle, &original, algorithm, &result, CSSMErrorAsString(err));
        }

        if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
            PSYSLOGND(LOG_WARNING, @"Failed to destroy signing context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create signing context because of error %@.\n", CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateSignatureContext(X, %d, Y, %p, %p [%"PRIccHandle"]) returned error %@.\n", [key algorithm], [key CSSMKey], &ccHandle, ccHandle, CSSMErrorAsString(err));
    }

    return finalResult;
}

- (BOOL)verifySignature:(NSData*)signature usingKey:(Key*)key digest:(CSSM_ALGORITHMS)algorithm {
    CSSM_RETURN err;
    CSSM_CC_HANDLE ccHandle;
    BOOL finalResult = NO;
    CSSM_DATA original, sig;
    CSSMModule *CSPModule = [key CSPModule];

    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }

    if ((err = CSSM_CSP_CreateSignatureContext([CSPModule handle], algorithm, keychainFrameworkDefaultCredentials(), [key CSSMKey], &ccHandle)) == CSSM_OK) {
        original.Length = [self length];
        original.Data = (uint8_t*)[self bytes];

        sig.Length = [signature length];
        sig.Data = (uint8_t*)[signature bytes];

        if ((err = CSSM_VerifyData(ccHandle, &original, 1, CSSM_ALGID_NONE, &sig)) == CSSM_OK) {
            finalResult = YES;
        } else {
            if (err != CSSMERR_CSP_VERIFY_FAILED) {
                PSYSLOGND(LOG_ERR, @"Unable to generate signature because of error %@.\n", CSSMErrorAsString(err));
                PDEBUG(@"CSSM_VerifyData(%"PRIccHandle", %p, 1, CSSM_ALGID_NONE, %p) returned error %@.\n", ccHandle, &original, &sig, CSSMErrorAsString(err));
            }
        }

        if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
            PSYSLOGND(LOG_WARNING, @"Failed to destroy signing context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create signing context because of error %@.\n", CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateSignatureContext(X, %d, Y, %p, %p [%"PRIccHandle"]) returned error %@.\n", algorithm, [key CSSMKey], &ccHandle, ccHandle, CSSMErrorAsString(err));
    }

    return finalResult;
}

- (BOOL)verifySignature:(NSData*)signature usingKey:(Key*)key {
    return [self verifySignature:signature usingKey:key digest:defaultDigestForAlgorithm([key algorithm])];
}

- (BOOL)verifyDigestSignature:(NSData*)signature usingKey:(Key*)key digest:(CSSM_ALGORITHMS)algorithm {
    CSSM_RETURN err;
    CSSM_CC_HANDLE ccHandle;
    BOOL finalResult = NO;
    CSSM_DATA original, sig;
    CSSMModule *CSPModule = [key CSPModule];

    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }

    if ((err = CSSM_CSP_CreateSignatureContext([CSPModule handle], [key algorithm], keychainFrameworkDefaultCredentials(), [key CSSMKey], &ccHandle)) == CSSM_OK) {
        original.Length = [self length];
        original.Data = (uint8_t*)[self bytes];

        sig.Length = [signature length];
        sig.Data = (uint8_t*)[signature bytes];

        if ((err = CSSM_VerifyData(ccHandle, &original, 1, algorithm, &sig)) == CSSM_OK) {
            finalResult = YES;
        } else {
            if (err != CSSMERR_CSP_VERIFY_FAILED) {
                PSYSLOGND(LOG_ERR, @"Unable to generate signature because of error %@.\n", CSSMErrorAsString(err));
                PDEBUG(@"CSSM_VerifyData(%"PRIccHandle", %p, 1, %d, %p) returned error %@.\n", ccHandle, &original, algorithm, &sig, CSSMErrorAsString(err));
            }
        }

        if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
            PSYSLOGND(LOG_WARNING, @"Failed to destroy signing context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create signing context because of error %@.\n", CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateSignatureContext(X, %d, Y, %p, %p [%"PRIccHandle"]) returned error %@.\n", [key algorithm], [key CSSMKey], &ccHandle, ccHandle, CSSMErrorAsString(err));
    }

    return finalResult;
}

- (MutableKey*)keyForModule:(CSSMModule*)CSPModule {
    CSSM_KEY *result;
    const char *bytes = [self bytes];
    NSUInteger version = 0, myLength = [self length];
    MutableKey *finalResult = nil;
    
    if (myLength < 4) {
        PDEBUG(@"Too little data (not enough for version marker).\n");
    } else {
        memcpy(&version, bytes, 4);

        if (version == RAW_KEY_VERSION_1) {
            if (myLength < KEYHEADER_VERSION_1_SIZE) {
                PDEBUG(@"Not enough data to be a version %u key header.\n", RAW_KEY_VERSION_1);
            } else {
                result = malloc(sizeof(CSSM_KEY));
                
                // The simplest way to do this is to copy the whole header in one go.  However
                // this probably isn't going to make it very easy to port to other platforms.
                // So there's the version below, which could easily be altered to include any
                // necessary byte-swapping and so forth.

                memcpy(&(result->KeyHeader), bytes + 4, KEYHEADER_VERSION_1_SIZE);
                
                /*memcpy(&(result->KeyHeader.HeaderVersion), bytes + 4, 4);
                memcpy(&(result->KeyHeader.CspId), bytes + 8, 12);
                memcpy(&(result->KeyHeader.BlobType), bytes + 20, 4);
                memcpy(&(result->KeyHeader.Format), bytes + 24, 4);
                memcpy(&(result->KeyHeader.AlgorithmId), bytes + 28, 4);
                memcpy(&(result->KeyHeader.KeyClass), bytes + 32, 4);
                memcpy(&(result->KeyHeader.LogicalKeySizeInBits), bytes + 36, 4);
                memcpy(&(result->KeyHeader.KeyAttr), bytes + 40, 4);
                memcpy(&(result->KeyHeader.KeyUsage), bytes + 44, 4);
                memcpy(&(result->KeyHeader.StartDate), bytes + 48, 8);
                memcpy(&(result->KeyHeader.EndDate), bytes + 56, 8);
                memcpy(&(result->KeyHeader.WrapAlgorithmId), bytes + 64, 4);
                memcpy(&(result->KeyHeader.WrapMode), bytes + 68, 4);*/

                memcpy(&(result->KeyData.Length), bytes + KEYHEADER_VERSION_1_SIZE + 4, 4);

                if ((myLength - KEYHEADER_VERSION_1_SIZE) < result->KeyData.Length) {
                    free(result);
                    PDEBUG(@"Not enough key data included after header.\n");
                } else {
                    result->KeyData.Data = malloc(result->KeyData.Length);
                    memcpy(result->KeyData.Data, bytes + KEYHEADER_VERSION_1_SIZE + 8, result->KeyData.Length);

                    if (nil == CSPModule) {
                        CSPModule = [CSSMModule defaultCSPModule];
                    }
                    
                    finalResult = [MutableKey keyWithCSSMKey:result freeWhenDone:YES module:CSPModule];
                }
            }
        } else {
            PDEBUG(@"Data is invalid or in an unknown format (version %u?).\n", version);
        }
    }

    return finalResult;
}

- (NSData*)digestUsingAlgorithm:(CSSM_ALGORITHMS)algorithm module:(CSSMModule*)CSPModule {
    CSSM_RETURN err;
    CSSM_CC_HANDLE ccHandle;
    CSSM_DATA result, original;
    NSData *finalResult = nil;
    
    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }
    
    if ((err = CSSM_CSP_CreateDigestContext([CSPModule handle], algorithm, &ccHandle)) == CSSM_OK) {
        original.Length = [self length];
        original.Data = (uint8_t*)[self bytes];

        result.Length = 0;
        result.Data = NULL;

        if ((err = CSSM_DigestData(ccHandle, &original, 1, &result)) == CSSM_OK) {
            finalResult = NSDataFromDataNoCopy(&result, YES);
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to generate digest because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DigestData(%"PRIccHandle", %p, 1, %p) returned error %@.\n", ccHandle, &original, &result, CSSMErrorAsString(err));
        }

        if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
            PSYSLOGND(LOG_WARNING, @"Failed to destroy digest context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create digest context because of error %@.\n", CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateDigestContext(X, %d, %p [%"PRIccHandle"]) returned error %@.\n", algorithm, &ccHandle, ccHandle, CSSMErrorAsString(err));
    }

    return finalResult;
}

@end
