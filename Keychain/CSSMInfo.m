//
//  CSSMInfo.m
//  Keychain
//
//  Created by Wade Tregaskis on Thu Jul 08 2004.
//
//  Copyright (c) 2004, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "CSSMInfo.h"
#import "CSSMModule.h"
#import "CSSMControl.h"


NSString *USER_AUTHENTICATED = @"USER_AUTHENTICATED"; // True if the user has authenticated on the token

NSString *TOKEN_WRITE_PROTECTED = @"TOKEN_WRITE_PROTECTED"; // Service provider is write protected
NSString *TOKEN_LOGIN_REQUIRED = @"TOKEN_LOGIN_REQUIRED"; // User must login to access private objects.
NSString *TOKEN_USER_PIN_INITIALIZED = @"TOKEN_USER_PIN_INITIALIZED"; // User's PIN has been initialized.
NSString *TOKEN_PROT_AUTHENTICATION = @"TOKEN_PROT_AUTHENTICATION"; // Service provider has protected authentication path for entering a user PIN. No password should be supplied to the CSSM_CSP_Login API.
NSString *TOKEN_USER_PIN_EXPIRED = @"TOKEN_USER_PIN_EXPIRED"; // The user PIN must be changed before the service provider can be used.
NSString *TOKEN_SESSION_KEY_PASSWORD = @"TOKEN_SESSION_KEY_PASSWORD"; // Session keys held by the CSP require individual passwords, possibly in addition to a login password.
NSString *TOKEN_PRIVATE_KEY_PASSWORD = @"TOKEN_PRIVATE_KEY_PASSWORD"; // Private keys held by the CSP require individual passwords, possibly in addition to a login password
NSString *TOKEN_STORES_PRIVATE_KEYS = @"TOKEN_STORES_PRIVATE_KEYS"; // CSP can store private keys.
NSString *TOKEN_STORES_PUBLIC_KEYS = @"TOKEN_STORES_PUBLIC_KEYS"; // CSP can store public keys.
NSString *TOKEN_STORES_SESSION_KEYS = @"TOKEN_STORES_SESSION_KEYS"; // CSP can store session/secret keys
NSString *TOKEN_STORES_CERTIFICATES = @"TOKEN_STORES_CERTIFICATES"; // Service provider can store certs using DL APIs.
NSString *TOKEN_STORES_GENERIC = @"TOKEN_STORES_GENERIC"; // Service provider can store generic objects using DL APIs.

NSString *MAX_SESSION_COUNT = @"MAX_SESSION_COUNT"; // Maximum number of CSP handles referencing the token that may exist simultaneously.
NSString *OPEN_SESSION_COUNT = @"OPEN_SESSION_COUNT"; // Number of existing CSP handles referencing the token.
NSString *MAX_RW_SESSION_COUNT = @"MAX_RW_SESSION_COUNT"; // Maximum number of CSP handles that can reference the token simultaneously in read-write mode.
NSString *OPEN_RW_SESSION_COUNT = @"OPEN_RW_SESSION_COUNT"; // Number of existing CSP handles referencing the token in read-write mode.
NSString *TOTAL_PUBLIC_MEMORY = @"TOTAL_PUBLIC_MEMORY"; // Amount of public storage space in the CSP. This value will be set to CSSM_VALUE_NOT_AVAILABLE if the CSP does not wish to expose this information.
NSString *FREE_PUBLIC_MEMORY = @"FREE_PUBLIC_MEMORY"; // Amount of public storage space available for use in the CSP. This value will be set to CSSM_VALUE_NOT_AVAILABLE if the CSP does not wish to expose this information.
NSString *TOTAL_PRIVATE_MEMORY = @"TOTAL_PRIVATE_MEMORY"; // Amount of private storage space in the CSP. This value will be set to CSSM_VALUE_NOT_AVAILABLE if the CSP does not wish to expose this information.
NSString *FREE_PRIVATE_MEMORY = @"FREE_PRIVATE_MEMORY"; // Amount of private storage space available for use in the CSP. This value will be set to CSSM_VALUE_NOT_AVAILABLE if the CSP does not wish to expose this information.


NSDictionary* CSPOperatingStatistics(CSSM_CSP_HANDLE handle) {
    CSSM_CSP_OPERATIONAL_STATISTICS statistics;
    NSMutableDictionary *result = nil;

    if (CSSM_OK == CSSM_CSP_GetOperationalStatistics((handle != 0) ? handle : [[CSSMModule defaultCSPModule] handle], &statistics)) {
        result = [NSMutableDictionary dictionaryWithCapacity:10];
        
        [result setObject:[NSNumber numberWithBool:statistics.UserAuthenticated] forKey:USER_AUTHENTICATED];
        
        [result setObject:[NSNumber numberWithBool:(statistics.DeviceFlags & CSSM_CSP_TOK_WRITE_PROTECTED)] forKey:TOKEN_WRITE_PROTECTED];
        [result setObject:[NSNumber numberWithBool:(statistics.DeviceFlags & CSSM_CSP_TOK_LOGIN_REQUIRED)] forKey:TOKEN_LOGIN_REQUIRED];
        [result setObject:[NSNumber numberWithBool:(statistics.DeviceFlags & CSSM_CSP_TOK_USER_PIN_INITIALIZED)] forKey:TOKEN_USER_PIN_INITIALIZED];
        [result setObject:[NSNumber numberWithBool:(statistics.DeviceFlags & CSSM_CSP_TOK_PROT_AUTHENTICATION)] forKey:TOKEN_PROT_AUTHENTICATION];
        [result setObject:[NSNumber numberWithBool:(statistics.DeviceFlags & CSSM_CSP_TOK_USER_PIN_EXPIRED)] forKey:TOKEN_USER_PIN_EXPIRED];
        [result setObject:[NSNumber numberWithBool:(statistics.DeviceFlags & CSSM_CSP_TOK_SESSION_KEY_PASSWORD)] forKey:TOKEN_SESSION_KEY_PASSWORD];
        [result setObject:[NSNumber numberWithBool:(statistics.DeviceFlags & CSSM_CSP_TOK_PRIVATE_KEY_PASSWORD)] forKey:TOKEN_PRIVATE_KEY_PASSWORD];
        [result setObject:[NSNumber numberWithBool:(statistics.DeviceFlags & CSSM_CSP_STORES_PRIVATE_KEYS)] forKey:TOKEN_STORES_PRIVATE_KEYS];
        [result setObject:[NSNumber numberWithBool:(statistics.DeviceFlags & CSSM_CSP_STORES_PUBLIC_KEYS)] forKey:TOKEN_STORES_PUBLIC_KEYS];
        [result setObject:[NSNumber numberWithBool:(statistics.DeviceFlags & CSSM_CSP_STORES_SESSION_KEYS)] forKey:TOKEN_STORES_SESSION_KEYS];
        [result setObject:[NSNumber numberWithBool:(statistics.DeviceFlags & CSSM_CSP_STORES_CERTIFICATES)] forKey:TOKEN_STORES_CERTIFICATES];
        [result setObject:[NSNumber numberWithBool:(statistics.DeviceFlags & CSSM_CSP_STORES_GENERIC)] forKey:TOKEN_STORES_GENERIC];

        [result setObject:[NSNumber numberWithUnsignedInt:statistics.TokenMaxSessionCount] forKey:MAX_SESSION_COUNT];
        [result setObject:[NSNumber numberWithUnsignedInt:statistics.TokenOpenedSessionCount] forKey:OPEN_SESSION_COUNT];
        [result setObject:[NSNumber numberWithUnsignedInt:statistics.TokenMaxRWSessionCount] forKey:MAX_RW_SESSION_COUNT];
        [result setObject:[NSNumber numberWithUnsignedInt:statistics.TokenOpenedRWSessionCount] forKey:OPEN_RW_SESSION_COUNT];
        [result setObject:[NSNumber numberWithUnsignedInt:statistics.TokenTotalPublicMem] forKey:TOTAL_PUBLIC_MEMORY];
        [result setObject:[NSNumber numberWithUnsignedInt:statistics.TokenFreePublicMem] forKey:FREE_PUBLIC_MEMORY];
        [result setObject:[NSNumber numberWithUnsignedInt:statistics.TokenTotalPrivateMem] forKey:TOTAL_PRIVATE_MEMORY];
        [result setObject:[NSNumber numberWithUnsignedInt:statistics.TokenFreePrivateMem] forKey:FREE_PRIVATE_MEMORY];
    }
    
    return result;
}
