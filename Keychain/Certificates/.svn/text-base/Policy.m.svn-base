//
//  Policy.m
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

#import "Policy.h"

#import "Utilities/UtilitySupport.h"
#import "CDSA/CSSMUtils.h"
#import "Utilities/SecurityUtils.h"

#import "Utilities/Logging.h"


@implementation Policy

+ (Policy*)policyWithPolicyRef:(SecPolicyRef)poli {
    return [[[[self class] alloc] initWithPolicyRef:poli] autorelease];
}

- (Policy*)initWithPolicyRef:(SecPolicyRef)poli {
    Policy *existingObject;
    
    if (poli) {
        existingObject = [[self class] instanceWithKey:(id)poli from:@selector(policyRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            return [existingObject retain];
        } else {
            if (self = [super init]) {
                CFRetain(poli);
                policy = poli;
            }

            return self;
        }
    } else {
        [self release];

        return nil;
    }
}

- (Policy*)init {
    [self release];
    return nil;
}

- (NSData*)type {
    CSSM_OID result;

    error = SecPolicyGetOID(policy, &result);

    if (error == 0) {
        return NSDataFromData(&result);
    } else {
        return nil;
    }
}

- (NSData*)data {
    CSSM_DATA result;

    error = SecPolicyGetValue(policy, &result);

    if (error == 0) {
        return NSDataFromData(&result);
    } else {
        return nil;
    }
}

- (int)lastError {
    return error;
}

- (SecPolicyRef)policyRef {
    return policy;
}

- (void)dealloc {
    if (policy) {
        CFRelease(policy);
    }
    
    [super dealloc];
}

@end


NSArray *allPolicies(CSSM_CERT_TYPE certificateType, const CSSM_OID *policyType) {
    if (NULL == policyType) {
        PSYSLOG(LOG_ERR, @"Invalid parameters, policyType is NULL.\n");
        return nil;
    }
    
    SecPolicySearchRef searchRef;
    OSStatus err = SecPolicySearchCreate(certificateType, policyType, NULL, &searchRef);
    
    if (0 != err) {
        PSYSLOGND(LOG_ERR, @"Unable to create policy search for certificates of type %@, policies of type %@ - error %@.\n", nameOfCertificateType(certificateType), nameOfOID(policyType), OSStatusAsString(err));
        PDEBUG(@"SecPolicySearchCreate(%@, %@, NULL, %p) returned error %@.\n", nameOfCertificateType(certificateType), nameOfOID(policyType), &searchRef, OSStatusAsString(err));
        return nil;
    }
    
    NSMutableArray *result = [NSMutableArray array];
    SecPolicyRef policyRef;
    
    do {
        err = SecPolicySearchCopyNext(searchRef, &policyRef);
        
        if (0 == err) {
            [result addObject:[Policy policyWithPolicyRef:policyRef]];
        } else if (errSecPolicyNotFound != err) {
            PSYSLOGND(LOG_ERR, @"Unable to retrieve results of policy search (for certificates of type %@, policies of type %@), error %@.\n", nameOfCertificateType(certificateType), nameOfOID(policyType), err, OSStatusAsString(err));
            PDEBUG(@"SecPolicySearchCopyNext(%p, %p) returned error %@.\n", searchRef, policyRef, OSStatusAsString(err));
            result = nil;
        }
    } while (0 == err);
    
    CFRelease(searchRef);
    
    return result;
}
