//
//  Identity.m
//  Keychain
//
//  Created by Wade Tregaskis on Fri Jan 24 2003.
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "Identity.h"

#import "Logging.h"


@implementation Identity

+ (Identity*)identityWithIdentityRef:(SecIdentityRef)ident {
    return [[[[self class] alloc] initWithIdentityRef:ident] autorelease];
}

+ (Identity*)identityWithCertificate:(Certificate*)certificate privateKey:(Key*)privateKey inKeychain:(Keychain*)keychain label:(NSString*)label {
    if (certificate && privateKey && keychain) {
        [keychain addCertificate:certificate privateKey:privateKey withName:label];

        if ([keychain lastError] == CSSM_OK) {
            NSArray *idents = [[keychain identitiesForUse:[privateKey usage]] retain];

            if (idents) {
                NSEnumerator *enumerator = [idents objectEnumerator];
                Identity *current;

                while (current = [enumerator nextObject]) {                    
                    if ([[current certificate] isEqualToCertificate:certificate]) {
                        // We need to retain the identity, because it's currently only retained by the idents array and we don't want it disappearing when that array does.  But we need to return it autoreleased in order to maintain expected class constructor behaviour.
                        
                        [current retain];
                        [idents release];
                        
                        return [current autorelease];
                    }
                }

                PDEBUG(@"I was able to create and add the identity, but then... umm... well, um.. lost it.  Sorry.  Although there was a list of identities retrieved from the keychain, the new one wasn't in there.\n");
            } else {
                PDEBUG(@"I was able to create and add the identity, but then... umm... well, um.. lost it.  Sorry.  This was due to an error searching for identities in the keychain.\n");
            }
        } else {
            PDEBUG(@"Unable to add the certificate and private key to the given keychain.\n");
        }
    } else {
        PDEBUG(@"Invalid parameters (identityWithCertificate:%p privateKey:%p inKeychain:%p label:%p).\n", certificate, privateKey, keychain, label);
    }

    return nil;
}

- (Identity*)initWithIdentityRef:(SecIdentityRef)ident {
    Identity *existingObject;
    
    if (ident) {
        existingObject = [[self class] instanceWithKey:(id)ident from:@selector(identityRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            self = [existingObject retain];
        } else {
            if (self = [super init]) {
                CFRetain(ident);
                identity = ident;
            }
        }
    } else {
        [self release];
        self = nil;
    }
    
    return self;
}

- (Identity*)init {
    [self release];
    return nil;
}

- (Certificate*)certificate {
    SecCertificateRef result = NULL;
    Certificate *res;

    error = SecIdentityCopyCertificate(identity, &result);

    if ((error == 0) && result) {
        res = [Certificate certificateWithCertificateRef:result];

        CFRelease(result);
        
        return res;
    } else {
        return nil;
    }
}

- (Key*)publicKey {
    return [[self certificate] publicKey];
}

- (Key*)privateKey {
    SecKeyRef result = NULL;
    Key *res;
    
    error = SecIdentityCopyPrivateKey(identity, &result);

    if ((error == 0) && result) {
        res = [Key keyWithKeyRef:result];

        CFRelease(result);

        return res;
    } else {
        return nil;
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Certificate: %@\nPrivate key: %@", [[self certificate] description], [[self privateKey] description]];
}

- (int)lastError {
    return error;
}

- (SecIdentityRef)identityRef {
    return identity;
}

- (void)dealloc {
    if (identity) {
        CFRelease(identity);
    }
    
    [super dealloc];
}

@end
