//
//  ABPersonAdditions.m
//  Keychain
//
//  Created by Wade Tregaskis on Fri Nov 14 2003.
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "ABPersonAdditions.h"

#import <Keychain/NSDataAdditions.h>
#import <Keychain/KeychainSearch.h>


/*! @const kABCertificateProperty
    @discussion An address book type identifying a property as being a certificate of some sort.  The certificate is included as the data, in raw form. */

NSString * const kABCertificateProperty = @"kABCertificateProperty";

/*! @const kABCertificateRefProperty
    @discussion An address book type identifying a property as being a certificate reference of some sort.  This reference is usually in the form of some sort of hash of the original certificate, by which the original can be located in some other database (e.g. a keychain). */

NSString * const kABCertificateRefProperty = @"kABCertificateRefProperty";

/*! @const kABCertificatePortableLabel
    @discussion An address book label given to certificates which are specified as being portable and context insensitive. */

NSString * const kABCertificatePortableLabel = @"portable";

/*! @const kABCertificateWorkLabel
    @discussion An address book label given to certificates which are specified as work related. */

#define kABCertificateWorkLabel kABWorkLabel

/*! @const kABCertificateHomeLabel
    @discussion An address book label given to certificates which are specified as personal or home related. */

#define kABCertificateHomeLabel kABHomeLabel


@implementation ABPerson (ABPersonCertificateAdditions)

Certificate* certFromAlmostRawData(NSData *rawData) {
    int type, encoding;
    
    if (rawData) {
        memcpy(&type, [rawData bytes], sizeof(int));
        memcpy(&encoding, [rawData bytes] + sizeof(int), sizeof(int));

        return [Certificate certificateWithData:[rawData subdataWithRange:NSMakeRange(2 * sizeof(int), [rawData length] - (2 * sizeof(int)))] type:type encoding:encoding];
    } else {
        return nil;
    }
}

- (NSArray*)primaryCertificates {
    id certList;
    int primaryCert;

    certList = [self valueForProperty:kABCertificateRefProperty];

    if (certList) {
        if ([certList isKindOfClass:[ABMultiValue class]]) {
            primaryCert = [certList indexForIdentifier:[certList primaryIdentifier]];

            if (primaryCert != NSNotFound) {
                return FindCertificatesMatchingPublicKeyHash([certList valueAtIndex:primaryCert]);
            }
        } else if ([certList isKindOfClass:[NSData class]]) {
            return FindCertificatesMatchingPublicKeyHash(certList);
        }
    } else {
        certList = [self valueForProperty:kABCertificateProperty];

        if (certList) {
            if ([certList isKindOfClass:[ABMultiValue class]]) {
                primaryCert = [certList indexForIdentifier:[certList primaryIdentifier]];

                if (primaryCert != NSNotFound) {
                    return [NSArray arrayWithObject:certFromAlmostRawData([certList valueAtIndex:primaryCert])];
                }
            } else if ([certList isKindOfClass:[NSData class]]) {
                return [NSArray arrayWithObject:certFromAlmostRawData(certList)];
            }
        }
    }

    return nil;
}

- (NSArray*)certificates {
    NSMutableArray *certs = [NSMutableArray arrayWithCapacity:5];
    id certList, theCert;
    int i;

    certList = [self valueForProperty:kABCertificateRefProperty];

    if (certList) {
        if ([certList isKindOfClass:[ABMultiValue class]]) {
            for (i = [certList count] - 1; i >= 0; --i) {
                theCert = [certList valueAtIndex:i];

                if (theCert && [theCert isKindOfClass:[NSData class]]) {
                    theCert = FindCertificatesMatchingPublicKeyHash(theCert);

                    if (theCert) {
                        [certs addObjectsFromArray:theCert];
                    }
                }
            }
        } else if ([certList isKindOfClass:[NSData class]]) {
            theCert = FindCertificatesMatchingPublicKeyHash(certList);

            if (theCert) {
                [certs addObjectsFromArray:theCert];
            }
        }
    }
    
    certList = [self valueForProperty:kABCertificateProperty];

    if (certList) {
        if ([certList isKindOfClass:[ABMultiValue class]]) {            
            for (i = [certList count] - 1; i >= 0; --i) {
                theCert = [certList valueAtIndex:i];

                if (theCert && [theCert isKindOfClass:[NSData class]]) {
                    theCert = certFromAlmostRawData(theCert);

                    if (theCert) {
                        [certs addObject:theCert];
                    }
                }
            }
        } else if ([certList isKindOfClass:[NSData class]]) {
            theCert = certFromAlmostRawData(certList);

            if (theCert) {
                [certs addObject:theCert];
            }
        }
    }

    return certs;
}

- (BOOL)addRawCertificate:(Certificate*)certificate label:(NSString*)label primary:(BOOL)primary {
    id certList;
    ABMutableMultiValue *valueList;
    char *bytes;
    int byteLength;
    NSData *certData;
    int i;
    
    certList = [self valueForProperty:kABCertificateProperty];

    if (!certList) {
        valueList = [[[ABMutableMultiValue alloc] init] autorelease];
    } else if ([certList isKindOfClass:[ABMutableMultiValue class]]) {
        valueList = certList;
    } else if ([certList isKindOfClass:[NSData class]]) {
        valueList = [[[ABMutableMultiValue alloc] init] autorelease];

        if (nil == [valueList addValue:certList withLabel:kABCertificatePortableLabel]) {
            return NO;
        }
    } else {
        return NO;
    }

    certData = [certificate data];
    byteLength = [certData length] + (2 * sizeof(int));
    bytes = malloc(byteLength);

    i = [[certificate keychainItem] certificateType];
    memcpy(bytes, &i, sizeof(int));
    i = [[certificate keychainItem] certificateEncoding];
    memcpy(bytes + sizeof(int), &i, sizeof(int));

    [certData getBytes:(bytes + (2 * sizeof(int)))];

    if (nil == [valueList insertValue:[NSData dataWithBytesNoCopy:bytes length:byteLength freeWhenDone:YES] withLabel:label atIndex:0]) {
        return NO;
    }

    if (primary) {
        [valueList setPrimaryIdentifier:0];
    }

    return [self setValue:valueList forProperty:kABCertificateProperty];
}

- (BOOL)addCertificate:(Certificate*)certificate label:(NSString*)label primary:(BOOL)primary {
    id certList;
    ABMutableMultiValue *valueList;
    
    certList = [self valueForProperty:kABCertificateRefProperty];

    if (!certList) {
        valueList = [[[ABMutableMultiValue alloc] init] autorelease];
    } else if ([certList isKindOfClass:[ABMutableMultiValue class]]) {
        valueList = certList;
    } else if ([certList isKindOfClass:[NSData class]]) {
        valueList = [[[ABMutableMultiValue alloc] init] autorelease];

        if (nil == [valueList addValue:certList withLabel:kABCertificatePortableLabel]) {
            return NO;
        }
    } else {
        return NO;
    }

    if (nil == [valueList insertValue:[[certificate publicKey] keyHash] withLabel:label atIndex:0]) {
        return NO;
    }

    if (primary) {
        [valueList setPrimaryIdentifier:0];
    }

    return [self setValue:valueList forProperty:kABCertificateRefProperty];
}

@end
