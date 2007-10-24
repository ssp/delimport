//
//  Trust.m
//  Keychain
//
//  Created by Wade Tregaskis on Wed Feb 05 2003.
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "Trust.h"

#import <Keychain/Keychain.h>


@implementation Trust

+ (SecTrustUserSetting)userTrustForCeritifcate:(Certificate*)cert policy:(Policy*)pol {
    int err;
    SecTrustUserSetting result;
    
    err = SecTrustGetUserTrust([cert certificateRef], [pol policyRef], &result);

    if (err == 0) {
        return result;
    } else {
        return -1;
    }
}

+ (void)setUserTrustForCertificate:(Certificate*)cert policy:(Policy*)pol trust:(SecTrustUserSetting)tru {
    SecTrustSetUserTrust([cert certificateRef], [pol policyRef], tru);
}

+ (Trust*)trustForCertificates:(NSArray*)certificates policies:(NSArray*)policies {
    return [[[[self class] alloc] initForCertificates:certificates policies:policies] autorelease];
}

+ (Trust*)trustWithTrustRef:(SecTrustRef)tru {
    return [[[[self class] alloc] initWithTrustRef:tru] autorelease];
}

- (Trust*)initForCertificates:(NSArray*)certificates policies:(NSArray*)policies {
    CFMutableArrayRef certs, pols;
    NSEnumerator *enumerator;
    id current;
    
    certs = CFArrayCreateMutable(NULL, [certificates count], NULL);
    pols = CFArrayCreateMutable(NULL, [policies count], NULL);

    if (certs && pols) {
        enumerator = [certificates objectEnumerator];
        
        while (current = [enumerator nextObject]) {
            if ([current isKindOfClass:[Certificate class]]) {
                CFArrayAppendValue(certs, [current certificateRef]);
            }
        }
        
        enumerator = [policies objectEnumerator];
        
        while (current = [enumerator nextObject]) {
            if ([current isKindOfClass:[Policy class]]) {
                CFArrayAppendValue(pols, [current policyRef]);
            }
        }
        
        error = SecTrustCreateWithCertificates(certs, pols, &trust);
        
        CFRelease(certs);
        CFRelease(pols);
        
        if (error == 0) {
            self = [super init];
            
            return self;
        } else {
            [self release];
            
            return nil;
        }
    } else {
        return nil;
    }
}

- (Trust*)initWithTrustRef:(SecTrustRef)tru {
    Trust *existingObject;
    
    if (tru) {
        existingObject = [[self class] instanceWithKey:(id)tru from:@selector(trustRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            return [existingObject retain];
        } else {
            if (self = [super init]) {
                CFRetain(tru);
                trust = tru;
            }

            return self;
        }
    } else {
        [self release];
        
        return nil;
    }
}

- (Trust*)init {
    [self release];
    return nil;
}

- (void)makeTrustForKeychains:(NSArray*)chains {
    CFMutableArrayRef keychains;
    NSEnumerator *enumerator = [chains objectEnumerator];
    id current;
    CFTypeID keychainType = SecKeychainGetTypeID();
    
    keychains = CFArrayCreateMutable(NULL, [chains count], NULL);
    
    if (keychains) {
        while (current = [enumerator nextObject]) {
            if ([current isKindOfClass:[Keychain class]]) {
                CFArrayAppendValue(keychains, [current keychainRef]);
            } else if (CFGetTypeID(current) == keychainType) {
                CFArrayAppendValue(keychains, current);
            }
        }
        
        error = SecTrustSetKeychains(trust, keychains);
        
        CFRelease(keychains);
    }
}

- (void)allowExpiredCertificates:(BOOL)allow {
    uint8_t *result = malloc(sizeof(BOOL));
    CFDataRef temp;
    
    if (result) {
        *result = allow;
        
        temp = CFDataCreate(NULL, result, sizeof(BOOL));
        
        if (temp) {
            error = SecTrustSetParameters(trust, CSSM_TP_ACTION_ALLOW_EXPIRED, temp);
            
            free(result);
            CFRelease(temp);
        }
    }
}

- (BOOL)canEvaluate {
    error = SecTrustEvaluate(trust, &lastEval);

    return (error == 0);
}

- (BOOL)isInvalid {
    if (!lastEval) {
        if (![self canEvaluate]) {
            return YES;
        }
    }

    return (lastEval == kSecTrustResultInvalid);
}

- (BOOL)canProceed {
    if (!lastEval) {
        if (![self canEvaluate]) {
            return NO;
        }
    }

    return (lastEval == kSecTrustResultProceed);
}

- (BOOL)needsConfirmation {
    if (!lastEval) {
        if (![self canEvaluate]) {
            return NO;
        }
    }

    return (lastEval == kSecTrustResultConfirm);
}

- (BOOL)userDenied {
    if (!lastEval) {
        if (![self canEvaluate]) {
            return NO;
        }
    }

    return (lastEval == kSecTrustResultDeny);
}

- (BOOL)userDidNotSpecify {
    if (!lastEval) {
        if (![self canEvaluate]) {
            return NO;
        }
    }

    return (lastEval == kSecTrustResultUnspecified);
}

- (BOOL)hasRecoverableFailure {
    if (!lastEval) {
        if (![self canEvaluate]) {
            return YES;
        }
    }

    return (lastEval == kSecTrustResultRecoverableTrustFailure);
}

- (BOOL)hasFatalFailure {
    if (!lastEval) {
        if (![self canEvaluate]) {
            return NO;
        }
    }

    return (lastEval == kSecTrustResultFatalTrustFailure);
}

- (BOOL)hasUnknownError {
    if (!lastEval) {
        if (![self canEvaluate]) {
            return NO;
        }
    }

    return (lastEval == kSecTrustResultOtherError);
}

- (int)lastError {
    return error;
}

- (SecTrustRef)trustRef {
    return trust;
}

- (void)dealloc {
    if (trust) {
        CFRelease(trust);
    }

    [super dealloc];
}

@end
