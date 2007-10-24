//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of the <ORGANIZATION> nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>
#import <Keychain/Certificate.h>
#import <Keychain/CertificateGeneration.h>
#import <Keychain/MutableKey.h>
#import <Keychain/CSSMDefaults.h>
#import <Keychain/Keychain.h>

#import "TestingCommon.h"


int main (int argc, const char * argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSData *result = nil, *signedResult = nil;
    NameList *subject = nil, *issuer = nil;
    Validity *validity = nil;
    AlgorithmIdentifier *signatureAlgorithm = nil;
    MutableKey *pubKey = nil, *privKey = nil, *current = nil;
    NSEnumerator *enumerator = nil;
    NSData *serialNumber = [NSData dataWithBytes:"\001\002\003\004" length:4];
    ExtensionList *extensions = nil;
    NSArray *pubKeyTest = nil;
    Certificate *finalCertificate = nil;
    Keychain *theKeychain = [[Keychain defaultKeychain] retain];
    NSCalendarDate *validFrom = [[NSCalendarDate calendarDate] retain], *validTo = [[validFrom dateByAddingYears:0 months:0 days:30 hours:0 minutes:0 seconds:0] retain];
    //NSArray *identities = nil;
    Identity *curIdentity = nil;

    START_TEST("Generate public/private key pair");

    TEST(((pubKeyTest = [generateKeyPair(CSSM_ALGID_RSA, 2048, validFrom, validTo, CSSM_KEYUSE_ANY, CSSM_KEYUSE_ANY, @"RSA Public Key", @"RSA Private Key") retain]) != nil) && ([pubKeyTest count] == 2), "\tgenerateKeyPair() for RSA (2048-bit)...");
    //TEST(((pubKeyTest = [generateKeyPair(CSSM_ALGID_DSA, 1024, validFrom, validTo, CSSM_KEYUSE_ANY, CSSM_KEYUSE_ANY, @"DSA Public Key", @"DSA Private Key") retain]) != nil) && ([pubKeyTest count] == 2), "\tgenerateKeyPair() for DSA (1024-bit)...");

    pubKey = privKey = nil;

    enumerator = [pubKeyTest objectEnumerator];

    while ((current = (MutableKey*)[enumerator nextObject]) != nil) {
        switch ([current keyClass]) {
            case CSSM_KEYCLASS_PUBLIC_KEY:
                if (pubKey != nil) {
                    TEST(NO, "\t\tSingle public key returned");
                } else {
                    pubKey = current;
                }

                break;
            case CSSM_KEYCLASS_PRIVATE_KEY:
                if (privKey != nil) {
                    TEST(NO, "\t\tSingle private keys returned");
                } else {
                    privKey = current;
                }

                break;
            case CSSM_KEYCLASS_SESSION_KEY:
                TEST(NO, "\t\tSymmetric key not returned"); break;
            case CSSM_KEYCLASS_SECRET_PART:
                TEST(NO, "\t\tSecret key part not returned"); break;
            default:
                TEST(NO, "\t\tUnknown key not returned");
        }
    }

    TEST((privKey != nil) && (pubKey != nil), "\tPublic and private key present");

    TEST_NOTE([[pubKey description] UTF8String], [[privKey description] UTF8String], "\t\tPublic Key:\n\n%s\n\nPrivate Key:\n\n%s\n");
    
    END_TEST();
    
    START_TEST("Generate Certificate using template");
    
    validity = [[Validity alloc] initFrom:[Time timeWithCalendarDate:validFrom format:BER_TAG_GENERALIZED_TIME] to:[Time timeWithCalendarDate:validTo format:BER_TAG_GENERALIZED_TIME]];
    
    subject = [[NameList alloc] initWithCommonName:@"Wade Tregaskis" organisation:@"La Trobe University" country:@"Australia" state:@"Victoria"];
    issuer = [[NameList alloc] initWithCommonName:@"Bob Smith" organisation:@"Issuers Inc." country:@"All" state:@"All"];

    TEST_NOTE("\tSubject:\n%sIssuer:\n%sValidity: %s", [[subject description] UTF8String], [[issuer description] UTF8String], [[validity description] UTF8String]);
    
    signatureAlgorithm = [[AlgorithmIdentifier alloc] initForAlgorithm:defaultDigestForAlgorithm([privKey algorithm])];

    TEST(((result = [createCertificateTemplate(subject, issuer, validity, pubKey, signatureAlgorithm, serialNumber, extensions) retain]) != NULL), "\tCan create certificate template");
    TEST(NULL != result, "\t\tDid get a result");
    
    if (result) {
        TEST_NOTE("\t\tResult is: %s", [[result description] UTF8String]);
        
        TEST(((signedResult = signCertificate(result, privKey, [signatureAlgorithm algorithm])) != NULL), "\tCan sign certificate");
        TEST(NULL != signedResult, "\t\tDid get a result");
        
        if (signedResult) {
            [signedResult retain];

            TEST_NOTE("%s", [[signedResult description] UTF8String]);
            
            TEST((finalCertificate = [[Certificate alloc] initWithData:signedResult type:CSSM_CERT_UNKNOWN encoding:CSSM_CERT_ENCODING_UNKNOWN]), "\tCan construct a Certificate instance from raw data");

            TEST_NOTE([[finalCertificate description] UTF8String], "\t\tResult: %s");
        }
    }

    [finalCertificate release];

    END_TEST();
    
    START_TEST("Generate Certificate using createCertificate()");
    
    TEST((finalCertificate = [createCertificate(subject, issuer, validity, pubKey, privKey, signatureAlgorithm, serialNumber, extensions) retain]) != nil, "\tCan create certificate using createCertificate()");

    TEST_NOTE("\t\tResult: %s", [[finalCertificate description] UTF8String]);
    
    END_TEST();
    
    START_TEST("Can add new identity to default keychain");
    
    curIdentity = [Identity identityWithCertificate:finalCertificate privateKey:privKey inKeychain:theKeychain label:@"Tester"];

    TEST(nil != curIdentity, "\tCan create identity");
    
    if (nil != curIdentity) {
        TEST_NOTE("\t\tIdentity: %s", [[curIdentity description] UTF8String]);
    }
    
    END_TEST();
    
    /*Test("listing all identities in the default keychain", (identities = [theKeychain identities]) != nil);
    //Test("listing identities in default keychain that are capable of signing operations", (identities = [theKeychain identitiesForSigning]) != nil);
    //Test("listing identities in default keychain that are capable of any operation", (identities = [theKeychain identitiesForAnyUse]) != nil);
    
    if (fullOutput && identities) {
        enumerator = [identities objectEnumerator];

        while (curIdentity = (Identity*)[enumerator nextObject]) {
            NSLog(@"%@", [curIdentity description]);
        }
    }*/
    
    [finalCertificate release];

    [signedResult release];
    [result release];
    
    [signatureAlgorithm release];
    [validity release];
    
    [subject release];
    [issuer release];
    
    [pool release];

    FINAL_SUMMARY();
    
    return 0;
}
