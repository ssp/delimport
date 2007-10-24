//
//  DigestOutputStream.m
//  Keychain
//
//  Created by Wade Tregaskis on 23/5/2005.
//
//  Copyright (c) 2005, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "DigestOutputStream.h"

#import "CSSMDefaults.h"
#import "CSSMControl.h"
#import "CSSMUtils.h"
#import "CSSMTypes.h"
#import "CSSMModule.h"

#import "UtilitySupport.h"
#import "Logging.h"


NSString *DigestOutputStreamAlgorithm = @"algorithm";
NSString *DigestOutputStreamCurrentDigestValue = @"currentDigestValue";


@implementation DigestOutputStream

/* Inherited from NSStream. */

- (void)open {
    if (CSSM_INVALID_HANDLE == ccHandle) {
        err = CSSM_CSP_CreateDigestContext([[CSSMModule defaultCSPModule] handle], algorithm, &ccHandle);
         
        if (CSSM_OK == err) {
            err = CSSM_DigestDataInit(ccHandle);
            
            if (CSSM_OK == err) {
                [super open];
            } else {
                PCONSOLE(@"Unable to initialise digest context [for continuous operation] because of error #%u - %@.\n", err, CSSMErrorAsString(err));
                PDEBUG(@"CSSM_DigestDataInit(%"PRIccHandle") returned error #%u (%@).\n", ccHandle, err, CSSMErrorAsString(err));
                
                [self close];
            }
        } else {
            PCONSOLE(@"Unable to create digest context because of error #%u - %@.\n", err, CSSMErrorAsString(err));
            PDEBUG(@"CSSM_CSP_CreateDigestContext(X, %d, %p [%"PRIccHandle"]) returned error #%u (%@).\n", algorithm, &ccHandle, ccHandle, err, CSSMErrorAsString(err));
        }
    } else {
        PDEBUG(@"Stream is already open.\n");
    }
}

- (void)close {    
    if (CSSM_INVALID_HANDLE == ccHandle) {
        PDEBUG(@"Stream is not open.\n");
    } else {        
        if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
            PCONSOLE(@"Warning: Failed to destroy digest context because of error #%u - %@.\n", err, CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error #%u (%@).\n", ccHandle, err, CSSMErrorAsString(err));
        }
        
        ccHandle = CSSM_INVALID_HANDLE;
        
        [super close];
    }
}

- (id)propertyForKey:(NSString*)key {
    if ([key isEqualToString:DigestOutputStreamAlgorithm]) {
        return [NSNumber numberWithUnsignedInt:algorithm];
    } else if ([key isEqualToString:DigestOutputStreamCurrentDigestValue]) {
        return [self currentDigestValue];
    } else {
        return [super propertyForKey:key];
    }
}

- (BOOL)setProperty:(id)property forKey:(NSString*)key {
    if ([key isEqualToString:DigestOutputStreamAlgorithm]) {
        if (CSSM_INVALID_HANDLE == ccHandle) {
            if ([property isKindOfClass:[NSNumber class]]) {
                algorithm = [(NSNumber*)property unsignedIntValue];
                return YES;
            } else {
                return NO;
            }
        } else {
            return NO;
        }
    } else if ([key isEqualToString:DigestOutputStreamCurrentDigestValue]) {
        return NO;
    } else {
        return [super setProperty:property forKey:key];
    }
}

- (NSError*)streamError {
    if (0 != err) {
        return [NSError errorWithDomain:SecurityErrorDomain code:err userInfo:[NSDictionary dictionaryWithObject:CSSMErrorAsString(err) forKey:NSLocalizedDescriptionKey]];
    } else {
        return [super streamError];
    }
}

/* Inherited from NSOutputStream. */

- (id)initToMemory {
    if (self = [super initToMemory]) {
        ccHandle = CSSM_INVALID_HANDLE;
        algorithm = CSSM_ALGID_SHA1;
    }
    
    return self;
}

- (id)initToBuffer:(uint8_t*)buffer capacity:(unsigned int)capacity {
    if (self = [super initToBuffer:buffer capacity:capacity]) {
        ccHandle = CSSM_INVALID_HANDLE;
        algorithm = CSSM_ALGID_SHA1;
    }
    
    return self;
}

- (id)initToFileAtPath:(NSString*)path append:(BOOL)shouldAppend {
    if (self = [super initToFileAtPath:path append:shouldAppend]) {
        ccHandle = CSSM_INVALID_HANDLE;
        algorithm = CSSM_ALGID_SHA1;
    }
    
    return self;
}

- (id)initToOutputStream:(NSOutputStream*)otherStream {
    if (self = [super initToOutputStream:otherStream]) {
        ccHandle = CSSM_INVALID_HANDLE;
        algorithm = CSSM_ALGID_SHA1;
    }
            
    return self;
}

- (int)write:(const uint8_t*)buffer maxLength:(unsigned int)len {
    if (CSSM_INVALID_HANDLE == ccHandle) {
        PDEBUG(@"Attempted to write to stream before opening it.\n");
        return -1;
    } else {
        int result = [super write:buffer maxLength:len];
        
        if (0 < result) {
            CSSM_DATA data = {result, (uint8_t*)buffer};
            
            err = CSSM_DigestDataUpdate(ccHandle, &data, 1);
            
            if (CSSM_OK != err) {
                PCONSOLE(@"Unable to calculate [part of] digest because of error #%u - %@.\n", err, CSSMErrorAsString(err));
                PDEBUG(@"CSSM_DigestDataUpdate(%"PRIccHandle", %p, 1) returned error #%u (%@).\n", ccHandle, &data, err, CSSMErrorAsString(err));
                return -1;
            }
        }
        
        return result;
    }
}

- (BOOL)hasSpaceAvailable {
    if (CSSM_INVALID_HANDLE == ccHandle) {
        return NO;
    } else {
        return [super hasSpaceAvailable];
    }
}

/* Our additions. */

- (void)dealloc {
    if (CSSM_INVALID_HANDLE != ccHandle) {
        [self close];
    }
    
    [super dealloc];
}

- (NSData*)currentDigestValue {
    if (CSSM_INVALID_HANDLE == ccHandle) {
        PDEBUG(@"Stream is not open - digest not available.\n");
        return nil;
    } else {
        CSSM_CC_HANDLE tempHandle;
        
        err = CSSM_DigestDataClone(ccHandle, &tempHandle);
        
        if (CSSM_OK != err) {
            PCONSOLE(@"Unable to clone digest context because of error #%u - %@.\n", err, CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DigestDataClone(%"PRIccHandle", %p) returned error #%u (%@).\n", ccHandle, &tempHandle, err, CSSMErrorAsString(err));
            return nil;
        } else {
            CSSM_DATA result = {0, NULL};
            NSData *finalResult = nil;
            int otherErr;
            
            err = CSSM_DigestDataFinal(tempHandle, &result);
                
            if (CSSM_OK == err) {
                finalResult = NSDataFromDataNoCopy(&result, YES);
            }
            
            otherErr = CSSM_DeleteContext(tempHandle);
            
            if (CSSM_OK != otherErr) {
                PCONSOLE(@"Warning: Failed to destroy [cloned] digest context because of error #%u - %@.\n", err, CSSMErrorAsString(err));
                PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error #%u (%@).\n", tempHandle, err, CSSMErrorAsString(err));
                
                if (CSSM_OK == err) {
                    err = otherErr;
                }
            }
            
            return finalResult;
        }
    }
}

- (CSSM_ALGORITHMS)algorithm {
    return algorithm;
}

- (BOOL)setAlgorithm:(CSSM_ALGORITHMS)newAlgorithm {
    if (CSSM_INVALID_HANDLE == ccHandle) {
        algorithm = newAlgorithm;
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)validateAlgorithm:(id*)ioValue error:(NSError**)outError {
    if (CSSM_INVALID_HANDLE == ccHandle) {
        return YES;
    } else {
        if (outError) {
            *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:EPERM userInfo:[NSDictionary dictionaryWithObject:@"Cannot change the algorithm of an open DigestOutputStream." forKey:NSLocalizedDescriptionKey]];
        }
        
        return NO;
    }
}

@end
