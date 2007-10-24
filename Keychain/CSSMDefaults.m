//
//  CSSMDefaults.m
//  Keychain
//
//  Created by Wade Tregaskis on Wed May 07 2003.
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "CSSMDefaults.h"

#import "CSSMUtils.h"
#import "Logging.h"


NSString *SecurityErrorDomain = @"Security Error Domain";


/* The init vector really should be unique per cryptographic operation which uses it.  It's presence is unfortunate and it is considered obsolete - it will be removed in a future version of the Keychain framework. */

uint8 keychainFrameworkInitVector[16]; /* = { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16 }; */
const CSSM_DATA keychainFrameworkInitVectorData = {16, keychainFrameworkInitVector};

const uint32 RAW_KEY_VERSION_1 = 1;
const uint32 KEYHEADER_VERSION_1_SIZE = 76;


CSSM_ENCRYPT_MODE defaultModeForAlgorithm(CSSM_ALGORITHMS algorithm) {
    switch(algorithm) {
        /* 8-byte block ciphers */
        case CSSM_ALGID_DES:
        case CSSM_ALGID_3DES_3KEY_EDE:
        case CSSM_ALGID_RC5:
        case CSSM_ALGID_RC2:
            return CSSM_ALGMODE_CBCPadIV8; break;
            /* 16-byte block ciphers */
        case CSSM_ALGID_AES:
            return CSSM_ALGMODE_CBCPadIV8; break;
            /* stream ciphers */
        case CSSM_ALGID_ASC:
        case CSSM_ALGID_RC4:
            return CSSM_ALGMODE_NONE; break;
            /* Unknown */
        default:
        	PDEBUG(@"Asked for the default mode for \"%@\" (%d), but don't know that algorithm.\n", nameOfAlgorithm(algorithm), algorithm);
            return CSSM_ALGMODE_NONE;
    }
}

CSSM_PADDING defaultPaddingForAlgorithm(CSSM_ALGORITHMS algorithm) {
    switch(algorithm) {
        /* 8-byte block ciphers */
        case CSSM_ALGID_DES:
        case CSSM_ALGID_3DES_3KEY_EDE:
        case CSSM_ALGID_RC5:
        case CSSM_ALGID_RC2:
            return CSSM_PADDING_PKCS5; break;
            /* 16-byte block ciphers */
        case CSSM_ALGID_AES:
            return CSSM_PADDING_PKCS7; break;
            /* stream ciphers */
        case CSSM_ALGID_ASC:
        case CSSM_ALGID_RC4:
            return CSSM_PADDING_NONE; break;
            /* RSA/DSA asymmetric */
        case CSSM_ALGID_DSA:
        case CSSM_ALGID_RSA:
            return CSSM_PADDING_PKCS1; break;
            /* Unknown */
        default:
        	PDEBUG(@"Asked for the default padding mode for \"%@\" (%d), but don't know that algorithm.\n", nameOfAlgorithm(algorithm), algorithm);
            return CSSM_PADDING_NONE;
    }
}

CSSM_ALGORITHMS defaultDigestForAlgorithm(CSSM_ALGORITHMS algorithm) {
    switch (algorithm) {
        case CSSM_ALGID_RSA:
            return CSSM_ALGID_SHA1WithRSA; break;
        case CSSM_ALGID_DSA:
            return CSSM_ALGID_SHA1WithDSA; break;
        case CSSM_ALGID_FEE:
            return CSSM_ALGID_FEE_SHA1; break;
        default:
 	      	PDEBUG(@"Asked for the default digest algorithm for \"%@\" (%d), but don't know that algorithm.\n", nameOfAlgorithm(algorithm), algorithm);
            return CSSM_ALGID_NONE;
    }
}
