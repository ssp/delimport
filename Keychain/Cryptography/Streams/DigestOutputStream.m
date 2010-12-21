//
//  DigestOutputStream.m
//  Keychain
//
//  Created by Wade Tregaskis on Mon May 23 2005.
//
//  Copyright (c) 2005 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "DigestOutputStream.h"

#import "CDSA/CSSMDefaults.h"
#import "CDSA/CSSMControl.h"
#import "CDSA/CSSMUtils.h"
#import "CDSA/CSSMTypes.h"
#import "CDSA/CSSMModule.h"

#import "Utilities/UtilitySupport.h"
#import "Utilities/Logging.h"


NSString *DigestOutputStreamAlgorithm = @"algorithm";
NSString *DigestOutputStreamCurrentDigestValue = @"currentDigestValue";


@implementation DigestOutputStream

/* Inherited from NSStream. */

- (void)open {
    if (CSSM_INVALID_HANDLE == ccHandle) {
        err = CSSM_CSP_CreateDigestContext([_CSPModule handle], algorithm, &ccHandle);
         
        if (CSSM_OK == err) {
            err = CSSM_DigestDataInit(ccHandle);
            
            if (CSSM_OK == err) {
                [super open];
            } else {
                PSYSLOGND(LOG_ERR, @"Unable to initialise digest context [for continuous operation] because of error %@.\n", CSSMErrorAsString(err));
                PDEBUG(@"CSSM_DigestDataInit(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
                
                [self close];
            }
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to create digest context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_CSP_CreateDigestContext(X, %d, %p [%"PRIccHandle"]) returned error %@.\n", algorithm, &ccHandle, ccHandle, CSSMErrorAsString(err));
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
            PSYSLOGND(LOG_ERR, @"Failed to destroy digest context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
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
        _CSPModule = [[CSSMModule defaultCSPModule] retain];
    }
    
    return self;
}

- (id)initToBuffer:(uint8_t*)buffer capacity:(unsigned int)capacity {
    if (self = [super initToBuffer:buffer capacity:capacity]) {
        ccHandle = CSSM_INVALID_HANDLE;
        algorithm = CSSM_ALGID_SHA1;
        _CSPModule = [[CSSMModule defaultCSPModule] retain];
    }
    
    return self;
}

- (id)initToFileAtPath:(NSString*)path append:(BOOL)shouldAppend {
    if (self = [super initToFileAtPath:path append:shouldAppend]) {
        ccHandle = CSSM_INVALID_HANDLE;
        algorithm = CSSM_ALGID_SHA1;
        _CSPModule = [[CSSMModule defaultCSPModule] retain];
    }
    
    return self;
}

- (id)initToOutputStream:(NSOutputStream*)otherStream {
    if (self = [super initToOutputStream:otherStream]) {
        ccHandle = CSSM_INVALID_HANDLE;
        algorithm = CSSM_ALGID_SHA1;
        _CSPModule = [[CSSMModule defaultCSPModule] retain];
    }
            
    return self;
}

- (NSInteger)write:(const uint8_t*)buffer maxLength:(NSUInteger)len {
    if (CSSM_INVALID_HANDLE == ccHandle) {
        PDEBUG(@"Attempted to write to stream before opening it.\n");
        return -1;
    } else {
        NSInteger result = [super write:buffer maxLength:len];
        
        if (0 < result) {
            CSSM_DATA data = {result, (uint8_t*)buffer};
            
            err = CSSM_DigestDataUpdate(ccHandle, &data, 1);
            
            if (CSSM_OK != err) {
                PSYSLOGND(LOG_ERR, @"Unable to calculate [part of] digest because of error %@.\n", CSSMErrorAsString(err));
                PDEBUG(@"CSSM_DigestDataUpdate(%"PRIccHandle", %p, 1) returned error %@.\n", ccHandle, &data, CSSMErrorAsString(err));
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
    
    if (nil != _CSPModule) {
        [_CSPModule release];
        _CSPModule = nil;
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
            PSYSLOGND(LOG_ERR, @"Unable to clone digest context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DigestDataClone(%"PRIccHandle", %p) returned error %@.\n", ccHandle, &tempHandle, CSSMErrorAsString(err));
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
                PSYSLOGND(LOG_WARNING, @"Failed to destroy [cloned] digest context because of error %@.\n", CSSMErrorAsString(err));
                PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", tempHandle, CSSMErrorAsString(err));
                
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
#pragma unused (ioValue) // Not used at present... could be, but doesn't have to be.
    
    if (CSSM_INVALID_HANDLE == ccHandle) {
        return YES;
    } else {
        if (outError) {
            *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:EPERM userInfo:[NSDictionary dictionaryWithObject:@"Cannot change the algorithm of an open DigestOutputStream." forKey:NSLocalizedDescriptionKey]];
        }
        
        return NO;
    }
}

- (BOOL)setModule:(CSSMModule*)CSPModule {
    if (CSSM_INVALID_HANDLE == ccHandle) {
        id old = _CSPModule;
        
        if (nil != CSPModule) {
            _CSPModule = [CSPModule retain];
        } else {
            _CSPModule = [[CSSMModule defaultCSPModule] retain];
        }
        
        [old release];
        
        return YES;
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to change CSPModule of an open DigestOutputStream.\n");
        PDEBUG(@"setModule:%p called on DigestOutputStream %p which is already open.\n", CSPModule, self);
        return NO;
    }
}

- (CSSMModule*)module {
    return _CSPModule;
}

@end
