//
//  CertificateBundle.m
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

#import "CertificateBundle.h"


@implementation CertificateBundle

+ (CertificateBundle*)certificateBundleWithCertificates:(NSArray*)certs {
    return [[self class] certificateBundleOfType:CSSM_CERT_BUNDLE_PGP_KEYRING withEncoding:CSSM_CERT_BUNDLE_ENCODING_PGP withCertificates:certs];
}

+ (CertificateBundle*)certificateBundleOfType:(CSSM_CERT_BUNDLE_TYPE)type withEncoding:(CSSM_CERT_BUNDLE_ENCODING)encoding withCertificates:(NSArray*)certs {
    return [[[[self class] alloc] initWithType:type withEncoding:encoding withCertificates:certs] autorelease];
}

+ (CertificateBundle*)certificateBundleWithBundle:(CSSM_CERT_BUNDLE_PTR)bun {
    return [[self class] certificateBundleWithBundle:bun releasingWhenDone:NO];
}

+ (CertificateBundle*)certificateBundleWithBundle:(CSSM_CERT_BUNDLE_PTR)bun releasingWhenDone:(BOOL)release {
    return [[[[self class] alloc] initWithBundle:bun releasingWhenDone:release] autorelease];
}

- (CertificateBundle*)initWithCertificates:(NSArray*)certs {
    return [self initWithType:CSSM_CERT_BUNDLE_PGP_KEYRING withEncoding:CSSM_CERT_BUNDLE_ENCODING_PGP withCertificates:certs];
}

- (CertificateBundle*)initWithType:(CSSM_CERT_BUNDLE_TYPE)type withEncoding:(CSSM_CERT_BUNDLE_ENCODING)encoding withCertificates:(NSArray*)certs {
    if (certs && (self = [super init])) {
        CFMutableArrayRef array;
        NSEnumerator *enumerator;
        id current;
        
        array = CFArrayCreateMutable(NULL, [certs count], NULL);
        
        if (array) {
            enumerator = [certs objectEnumerator];
            
            while (current = [enumerator nextObject]) {
                if ([current isKindOfClass:[Certificate class]]) {
                    CFArrayAppendValue(array, [current certificateRef]);
                }
            }
            
            bundle = malloc(sizeof(CSSM_CERT_BUNDLE));
            releaseWhenDone = YES;
            
            error = SecCertifcateBundleExport(array, type, encoding, &(bundle->Bundle));
            
            CFRelease(array);
            
            if (error == 0) {
                bundle->BundleHeader.BundleType = type;
                bundle->BundleHeader.BundleEncoding = encoding;
                
                return self;
            } else {
                [self release];
                
                self = nil;
            }
        } else {
            [self release];
            
            self = nil;
        }
    }
    
    return self;
}

- (CertificateBundle*)initWithBundle:(CSSM_CERT_BUNDLE_PTR)bun {
    return [self initWithBundle:bun releasingWhenDone:NO];
}

- (CertificateBundle*)initWithBundle:(CSSM_CERT_BUNDLE_PTR)bun releasingWhenDone:(BOOL)release {
    if (bun && (self = [super init])) {
        releaseWhenDone = release;
        bundle = bun;
    } else {
        [self release];
        self = nil;
    }
    
    return self;
}

- (CertificateBundle*)init {
    [self release];
    return nil;
}

- (CSSM_CERT_BUNDLE_TYPE)type {
    return bundle->BundleHeader.BundleType;
}

- (BOOL)typeIsCustom {
    return ([self type] == CSSM_CERT_BUNDLE_CUSTOM);
}

- (BOOL)typeIsPKCS7 {
    return ([self type] == CSSM_CERT_BUNDLE_PKCS7_SIGNED_DATA);
}

- (BOOL)typeIsPKCS7Enveloped {
    return ([self type] == CSSM_CERT_BUNDLE_PKCS7_SIGNED_ENVELOPED_DATA);
}

- (BOOL)typeIsPKCS12 {
    return ([self type] == CSSM_CERT_BUNDLE_PKCS12);
}

- (BOOL)typeIsPFX {
    return ([self type] == CSSM_CERT_BUNDLE_PFX);
}

- (BOOL)typeIsSPKI {
    return ([self type] == CSSM_CERT_BUNDLE_SPKI_SEQUENCE);
}

- (BOOL)typeIsPGP {
    return ([self type] == CSSM_CERT_BUNDLE_PGP_KEYRING);
}

- (BOOL)typeIsUnknown {
    return ([self type] == CSSM_CERT_BUNDLE_UNKNOWN);
}

- (CSSM_CERT_BUNDLE_ENCODING)encoding {
    return bundle->BundleHeader.BundleEncoding;
}

- (BOOL)encodingIsCustom {
    return ([self encoding] == CSSM_CERT_BUNDLE_ENCODING_CUSTOM);
}

- (BOOL)encodingIsBER {
    return ([self encoding] == CSSM_CERT_BUNDLE_ENCODING_BER);
}

- (BOOL)encodingIsDER {
    return ([self encoding] == CSSM_CERT_BUNDLE_ENCODING_DER);
}

- (BOOL)encodingIsSEXPR {
    return ([self encoding] == CSSM_CERT_BUNDLE_ENCODING_SEXPR);
}

- (BOOL)encodingIsPGP {
    return ([self encoding] == CSSM_CERT_BUNDLE_ENCODING_PGP);
}

- (BOOL)encodingIsUnknown {
    return ([self encoding] == CSSM_CERT_BUNDLE_ENCODING_UNKNOWN);
}

- (int)lastError {
    return error;
}

- (CSSM_CERT_BUNDLE_PTR)bundle {
    return bundle;
}

- (void)dealloc {
    if (releaseWhenDone && bundle) {
        free(bundle);
    }

    [super dealloc];
}

@end
