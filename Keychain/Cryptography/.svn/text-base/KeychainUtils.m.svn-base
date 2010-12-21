//
//  KeychainUtils.m
//  Keychain
//
//  Created by Wade Tregaskis on Wed May 14 2003.
//
//  Copyright (c) 2003 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "KeychainUtils.h"

#import "CDSA/CSSMControl.h"
#import "CDSA/CSSMUtils.h"
#import "CDSA/CSSMTypes.h"
#import "CDSA/CSSMModule.h"

#import "Utilities/Logging.h"


char* generateRandomData(uint32_t lengthInBytes, CSSM_ALGORITHMS algorithm, const char *seed, NSUInteger seedLength, CSSMModule *CSPModule) {
    CSSM_CC_HANDLE ccHandle;
    static CSSM_CRYPTO_DATA rawSeed;
    static CSSM_CRYPTO_DATA_PTR rawSeedPtr;
    static CSSM_DATA result;
    CSSM_RETURN err;
    char *finalResult = NULL;
    
    if (seed && (seedLength > 0)) {
        rawSeedPtr = &rawSeed;
        rawSeed.Callback = NULL;
        rawSeed.CallerCtx = NULL;
        rawSeed.Param.Length = seedLength;
        rawSeed.Param.Data = (uint8_t*)seed;
    } else {
        rawSeedPtr = NULL;
    }
    
    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }
    
    if ((err = CSSM_CSP_CreateRandomGenContext([CSPModule handle], algorithm, rawSeedPtr, lengthInBytes, &ccHandle)) == CSSM_OK) {
        result.Length = 0;
        result.Data = NULL;
        
        if ((err = CSSM_GenerateRandom(ccHandle, &result)) == CSSM_OK) {
            if (result.Length != lengthInBytes) {
                PDEBUG(@"CSSM_GenerateRandom(%"PRIccHandle", %p) succeeded but returned a result of length %d, not %d.\n", ccHandle, &result, result.Length, lengthInBytes);
            } else {
                finalResult = (char*)(result.Data);
            }
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to generate random data because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_GenerateRandom(%"PRIccHandle", %p) returned error %@.\n", ccHandle, &result, CSSMErrorAsString(err));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create random data generation context because of error %@.\n", CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateRandomGenContext(X, %d, %p, %d, %p [%"PRIccHandle"]) returned error %@.\n", algorithm, rawSeedPtr, lengthInBytes, &ccHandle, ccHandle, CSSMErrorAsString(err));
    }
    
    return finalResult;
}

NSData* generateRandomNSData(uint32_t lengthInBytes, CSSM_ALGORITHMS algorithm, NSData *seed, CSSMModule *CSPModule) {
    char *temp = generateRandomData(lengthInBytes, algorithm, (seed ? [seed bytes] : NULL), (seed ? [seed length] : 0), CSPModule);
    
    if (temp) {
        return [NSData dataWithBytesNoCopy:temp length:lengthInBytes];
    } else {
        return nil;
    }
}
