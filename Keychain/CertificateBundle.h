//
//  CertificateBundle.h
//  Keychain
//
//  Created by Wade Tregaskis on Sat Feb 01 2003.
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <Keychain/Certificate.h>


@interface CertificateBundle : NSObject {
    CSSM_CERT_BUNDLE_PTR bundle;
    BOOL releaseWhenDone;
    int error;
}

+ (CertificateBundle*)certificateBundleWithCertificates:(NSArray*)certs;
+ (CertificateBundle*)certificateBundleOfType:(CSSM_CERT_BUNDLE_TYPE)type withEncoding:(CSSM_CERT_BUNDLE_ENCODING)encoding withCertificates:(NSArray*)certs;
+ (CertificateBundle*)certificateBundleWithBundle:(CSSM_CERT_BUNDLE_PTR)bun;
+ (CertificateBundle*)certificateBundleWithBundle:(CSSM_CERT_BUNDLE_PTR)bun releasingWhenDone:(BOOL)release;

- (CertificateBundle*)initWithCertificates:(NSArray*)certs;
- (CertificateBundle*)initWithType:(CSSM_CERT_BUNDLE_TYPE)type withEncoding:(CSSM_CERT_BUNDLE_ENCODING)encoding withCertificates:(NSArray*)certs;
- (CertificateBundle*)initWithBundle:(CSSM_CERT_BUNDLE_PTR)bun;
- (CertificateBundle*)initWithBundle:(CSSM_CERT_BUNDLE_PTR)bun releasingWhenDone:(BOOL)release;

/*! @method init:
    @abstract Reject initialiser.
    @discussion You cannot initialise a CertificateBundle using "init" - use one of the other initialisation methods.
    @result This method always releases the receiver and returns nil. */

- (CertificateBundle*)init;

- (CSSM_CERT_BUNDLE_TYPE)type;
- (BOOL)typeIsCustom;
- (BOOL)typeIsPKCS7;
- (BOOL)typeIsPKCS7Enveloped;
- (BOOL)typeIsPKCS12;
- (BOOL)typeIsPFX;
- (BOOL)typeIsSPKI;
- (BOOL)typeIsPGP;
- (BOOL)typeIsUnknown;

- (CSSM_CERT_BUNDLE_ENCODING)encoding;
- (BOOL)encodingIsCustom;
- (BOOL)encodingIsBER;
- (BOOL)encodingIsDER;
- (BOOL)encodingIsSEXPR;
- (BOOL)encodingIsPGP;
- (BOOL)encodingIsUnknown;

- (int)lastError;
- (CSSM_CERT_BUNDLE_PTR)bundle;

@end
