//
//  PolicyProber.m
//  Keychain
//
//  Created by Wade Tregaskis on Tue Jun 13 2006.
//
//  Copyright (c) 2006 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Keychain/Policy.h>
#import <Keychain/CSSMUtils.h>
#import <Security/Security.h>

#import "TestingCommon.h"


void test_allPolicies(const CSSM_OID *policyType) {
    const char *desc = [[NSString stringWithFormat:@"allPolicies for policies of type %@", nameOfOID(policyType)] UTF8String];
    
    START_TEST(desc);
        
    NSArray *policies;
    
    TEST(nil != (policies = allPolicies(CSSM_CERT_X_509v3, policyType)), "Able to retrieve policies");
    
    if (nil != policies) {
        NSEnumerator *enumerator = [policies objectEnumerator];
        Policy *current;
        
        while (current = [enumerator nextObject]) {
            TEST_NOTE("\t%s", [[current description] UTF8String]);
        }
    }
    
    END_TEST();
}

int main(int argc, char const *argv[]) {
#pragma unused (argc, argv) // We have no need for these right now.

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    test_allPolicies(&CSSMOID_APPLE_X509_BASIC);
    test_allPolicies(&CSSMOID_APPLE_TP_SSL);
    test_allPolicies(&CSSMOID_APPLE_TP_LOCAL_CERT_GEN);
    test_allPolicies(&CSSMOID_APPLE_TP_CSR_GEN);
    test_allPolicies(&CSSMOID_APPLE_TP_REVOCATION_CRL);
    test_allPolicies(&CSSMOID_APPLE_TP_REVOCATION_OCSP);
    test_allPolicies(&CSSMOID_APPLE_TP_SMIME);
    test_allPolicies(&CSSMOID_APPLE_TP_EAP);
    test_allPolicies(&CSSMOID_APPLE_TP_CODE_SIGN);
    test_allPolicies(&CSSMOID_APPLE_TP_IP_SEC);
    test_allPolicies(&CSSMOID_APPLE_TP_ICHAT);

    [pool release];

    FINAL_SUMMARY();    
}
