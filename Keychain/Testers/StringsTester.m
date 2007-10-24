//
//  StringsTester.m
//  Keychain
//
//  Created by Wade Tregaskis on 25/5/2005.
//
//  Copyright (c) 2005, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Keychain/CSSMUtils.h>

#import "TestingCommon.h"


void test_algorithmModeStrings(void) {
    NSString *result;
    
    START_TEST("Algorithm Modes.strings");
    
    result = nameOfAlgorithmMode(CSSM_ALGMODE_X9_31);
    
    TEST(nil != result, "nameOfAlgorithmMode(CSSM_ALGMODE_X9_31) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"X9 31"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_algorithmStrings(void) {
    NSString *result;
    
    START_TEST("Algorithms.strings");
    
    result = nameOfAlgorithm(CSSM_ALGID_RUNNING_COUNTER);
    
    TEST(nil != result, "nameOfAlgorithm(CSSM_ALGID_RUNNING_COUNTER) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"Running Counter"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_BERNameStrings(void) {
    NSString *result;
    
    START_TEST("BER Names.strings");
    
    result = nameOfBERCode(BER_TAG_PKIX_BMP_STRING);
    
    TEST(nil != result, "nameOfBERCode(BER_TAG_PKIX_BMP_STRING) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"PKIX BMP String"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_certificateEncodingStrings(void) {
    NSString *result;
    
    START_TEST("Certificate Encodings.strings");
    
    result = nameOfCertificateEncoding(CSSM_CERT_ENCODING_MULTIPLE);
    
    TEST(nil != result, "nameOfCertificateEncoding(CSSM_CERT_ENCODING_MULTIPLE) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"Multiple"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_certificateTypeStrings(void) {
    NSString *result;
    
    START_TEST("Certificate Types.strings");
    
    result = nameOfCertificateType(CSSM_CERT_MULTIPLE);
    
    TEST(nil != result, "nameOfCertificateType(CSSM_CERT_MULTIPLE) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"Multiple"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_CSSMErrorStrings(void) {
    NSString *result;
    
    START_TEST("CSSM Errors.strings");
    
    result = CSSMErrorAsString(CSSMERR_APPLE_DOTMAC_REQ_SERVER_SERVICE_ERROR);
    
    TEST(nil != result, "CSSMErrorAsString(CSSMERR_APPLE_DOTMAC_REQ_SERVER_SERVICE_ERROR) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@".Mac server reported: Service error (CSSMERR_APPLE_DOTMAC_REQ_SERVER_SERVICE_ERROR)"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_extensionFormatStrings(void) {
    NSString *result;
    
    START_TEST("Extension Formats.strings");
    
    result = nameOfExtensionFormat(CSSM_X509_DATAFORMAT_PAIR);
    
    TEST(nil != result, "nameOfExtensionFormat(CSSM_X509_DATAFORMAT_PAIR) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"Pair"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_GUIDNameStrings(void) {
    NSString *result;
    
    START_TEST("GUID Names.strings");
    
    result = nameOfGUID(&gGuidAppleDotMacDL);
    
    TEST(nil != result, "nameOfGUID(&gGuidAppleDotMacDL) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"Apple .Mac DL"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_KeyAttributeStrings(void) {
    NSString *result;
    
    START_TEST("Key Attributes.strings");
    
    result = namesOfAttributes(0x20000023);
    
    TEST(nil != result, "namesOfAttributes(0x20000023) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"Permanent, Private, Extractable, Return Reference"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_keyClassStrings(void) {
    NSString *result;
    
    START_TEST("Key Classes.strings");
    
    result = nameOfKeyClass(CSSM_KEYCLASS_SECRET_PART);
    
    TEST(nil != result, "nameOfKeyClass(CSSM_KEYCLASS_SECRET_PART) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"Secret part"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_KeyUsageStrings(void) {
    NSString *result;
    
    START_TEST("Key Usage.strings");

    result = namesOfUsages(0x000000c3);
    
    TEST(nil != result, "namesOfUsages(0x000000c3) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"Encrypt, Decrypt, Wrap, Unwrap"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_keyBlobFormatStrings(void) {
    NSString *result;
    
    START_TEST("Keyblob Formats.strings");
    
    result = nameOfTypedFormat(CSSM_KEYBLOB_WRAPPED_FORMAT_MSCAPI, CSSM_KEYBLOB_WRAPPED);
    
    TEST(nil != result, "nameOfTypedFormat(CSSM_KEYBLOB_WRAPPED_FORMAT_MSCAPI, CSSM_KEYBLOB_WRAPPED) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"Microsoft CAPI"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_keyBlobTypeStrings(void) {
    NSString *result;
    
    START_TEST("Keyblob Types.strings");
    
    result = nameOfKeyBlob(CSSM_KEYBLOB_WRAPPED);
    
    TEST(nil != result, "nameOfKeyBlob(CSSM_KEYBLOB_WRAPPED) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"Wrapped"], "\tResult is as expected");
    }
    
    END_TEST();
}

void test_OIDNameStrings(void) {
    NSString *result;
    
    START_TEST("OID Names.strings");
    
    result = nameOfOID(&CSSMOID_PKIX_OCSP_SERVICE_LOCATOR);
    
    TEST(nil != result, "nameOfOID(&CSSMOID_PKIX_OCSP_SERVICE_LOCATOR) returns result");
    
    if (nil != result) {
        TEST_NOTE("\tResult is: %s", [result UTF8String]);
        TEST([result isEqualToString:@"PKIX OCSP Service Locator"], "\tResult is as expected");
    }
    
    END_TEST();
}

int main(int argc, char const *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    test_algorithmModeStrings();
    test_algorithmStrings();
    test_BERNameStrings();
    test_certificateEncodingStrings();
    test_certificateTypeStrings();
    test_CSSMErrorStrings();
    test_extensionFormatStrings();
    test_GUIDNameStrings();
    test_KeyAttributeStrings();
    test_keyClassStrings();
    test_KeyUsageStrings();
    test_keyBlobFormatStrings();
    test_keyBlobTypeStrings();
    test_OIDNameStrings();
    
    [pool release];

    FINAL_SUMMARY();    
}
