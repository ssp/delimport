//
//  SKeyPlusTester.m
//  Keychain
//
//  Created by Wade Tregaskis on 10/2/2006.
//
//  Copyright (c) 2006, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Keychain/SKeyPlus.h>

#import "TestingCommon.h"


void test_singleUse(void) {
    NSData *password, *seed, *firstPassword, *secondPassword;
    CSSM_ALGORITHMS algorithm = CSSM_ALGID_SHA512;
    SKeyPlusGenerator *generator;
    SKeyPlusVerifier *verifier;
    
    START_TEST("Single-Use S/Key");
    
    password = [@"theworldisnotenough" dataUsingEncoding:NSUTF8StringEncoding];
    
    TEST(nil != password, "Able to setup test password");
    
    generator = [SKeyPlusGenerator generatorWithPassword:password algorithm:algorithm maximumUses:1];
    
    TEST(nil != generator, "Able to create generator");
    
    seed = [generator seed];
    
    TEST(nil != seed, "Able to obtain seed password");
    TEST(![seed isEqual:password], "Seed is not base password");
    
    firstPassword = [generator currentPassword];
    
    TEST(nil != firstPassword, "Generator returns first password");
    TEST(![firstPassword isEqual:password], "First password is not the base password");
    TEST(![firstPassword isEqual:seed], "First password is not the seed");
    
    verifier = [SKeyPlusVerifier verifierWithSeed:seed algorithm:algorithm maximumUses:1];
    
    TEST(nil != verifier, "Able to create verifier");
    TEST(0 == [verifier maximumNumberOfSkips], "Verifier's default maximum number of skips is 0 (i.e. no skips)");
    
    TEST([verifier verify:firstPassword andUpdate:NO], "First password is validated by the verifier, without updating");
    TEST([verifier verify:firstPassword andUpdate:NO], "First password is still valid because no update was made");
    TEST([verifier verify:firstPassword andUpdate:YES], "First password is still valid, and verifier is updated");
    TEST(![verifier verify:firstPassword andUpdate:NO], "First password is no longer valid (no update)");
    TEST(![verifier verify:firstPassword andUpdate:YES], "First password is no longer valid (with update)");
    TEST(![verifier verify:firstPassword andUpdate:NO], "First password is still no longer valid");
    
    secondPassword = [generator nextPassword];
    
    TEST(nil == secondPassword, "Unable to generate second password");
    TEST(nil == [generator currentPassword], "Generator returns nil for second password");

    END_TEST();
}

void test_doubleUse(void) {
    NSData *password, *seed, *firstPassword, *secondPassword;
    CSSM_ALGORITHMS algorithm = CSSM_ALGID_SHA512;
    SKeyPlusGenerator *generator;
    SKeyPlusVerifier *verifier;
    
    START_TEST("Double-Use S/Key");
    
    password = [@"theworldisnotenough" dataUsingEncoding:NSUTF8StringEncoding];
    
    TEST(nil != password, "Able to setup test password");
    
    generator = [SKeyPlusGenerator generatorWithPassword:password algorithm:algorithm maximumUses:2];
    
    TEST(nil != generator, "Able to create generator");
    
    seed = [generator seed];
    
    TEST(nil != seed, "Able to obtain seed password");
    TEST(![seed isEqual:password], "Seed password is not base password");
    
    firstPassword = [generator currentPassword];
    
    TEST(nil != firstPassword, "Generator returns first password");
    TEST(![firstPassword isEqual:password], "First password is not the base password");
    TEST(![firstPassword isEqual:seed], "First password is not the seed");

    verifier = [SKeyPlusVerifier verifierWithSeed:seed algorithm:algorithm maximumUses:2];
    
    TEST(nil != verifier, "Able to create verifier");
    TEST(0 == [verifier maximumNumberOfSkips], "Verifier's default maximum number of skips is 0 (i.e. no skips)");
    
    TEST([verifier verify:firstPassword andUpdate:NO], "First password is validated by the verifier, without updating");
    TEST([verifier verify:firstPassword andUpdate:NO], "First password is still valid because no update was made");
    TEST([verifier verify:firstPassword andUpdate:YES], "First password is still valid, and verifier is updated");
    TEST(![verifier verify:firstPassword andUpdate:NO], "First password is no longer valid (no update)");
    TEST(![verifier verify:firstPassword andUpdate:YES], "First password is no longer valid (with update)");
    TEST(![verifier verify:firstPassword andUpdate:NO], "First password is still no longer valid");
    
    secondPassword = [generator nextPassword];

    TEST(nil != secondPassword, "Able to generate next password");
    TEST(![secondPassword isEqual:firstPassword], "First & second passwords aren't the same");
    TEST(![secondPassword isEqual:password], "Second password is not the base password");
    
    TEST([verifier verify:secondPassword andUpdate:NO], "Second password is validated by the verifier, without updating");
    TEST([verifier verify:secondPassword andUpdate:NO], "Second password is still valid because no update was made");
    TEST([verifier verify:secondPassword andUpdate:YES], "Second password is still valid, and verifier is updated");
    TEST(![verifier verify:secondPassword andUpdate:NO], "Second password is no longer valid (no update)");
    TEST(![verifier verify:firstPassword andUpdate:NO], "First password is no longer valid");
    TEST(![verifier verify:secondPassword andUpdate:YES], "Second password is no longer valid (with update)");
    TEST(![verifier verify:secondPassword andUpdate:NO], "Second password is still no longer valid");
    
    END_TEST();
}

int main(int argc, char const *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    test_singleUse();
    test_doubleUse();
    
    [pool release];

    FINAL_SUMMARY();    
}
