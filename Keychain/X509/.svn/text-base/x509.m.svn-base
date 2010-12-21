//
//  x509.m
//  Keychain
//
//  Created by Wade Tregaskis on Wed May 21 2003.
//
//  Copyright (c) 2003 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Keychain/x509.h>

#import <Keychain/Logging.h>


@implementation SignedCRL

+ (SignedCRL*)signedCRLWithRawRef:(CSSM_X509_SIGNED_CRL*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithSignedCRLRef:ref freeWhenDone:fre] autorelease];
}

+ (SignedCRL*)signedCRLWithCertificates:(TBSCertList*)certificates signature:(X509Signature*)signature {
    return [[[[self class] alloc] initWithCertificates:certificates signature:signature] autorelease];
}

- (SignedCRL*)initWithSignedCRLRef:(CSSM_X509_SIGNED_CRL*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _CRL = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (SignedCRL*)initWithCertificates:(TBSCertList*)certificates signature:(X509Signature*)signature {
    _CRL = calloc(1, sizeof(CSSM_X509_SIGNED_CRL));
    freeWhenDone = YES;

    _CRL->tbsCertList = *[certificates TBSCertListRef];
    _CRL->signature = *[signature signatureRef];

    return self;
}

- (TBSCertList*)certificateList {
    return [TBSCertList listWithRawRef:(&(_CRL->tbsCertList)) freeWhenDone:NO];
}

- (X509Signature*)signature {
    return [X509Signature signatureWithRawRef:(&(_CRL->signature)) freeWhenDone:NO];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Certificate List:\n%@\nSignature:\n%@", [[TBSCertList listWithRawRef:(&(_CRL->tbsCertList)) freeWhenDone:NO] description], [[X509Signature signatureWithRawRef:(&(_CRL->signature)) freeWhenDone:NO] description]];
}

- (CSSM_X509_SIGNED_CRL*)signedCRLRef {
    return _CRL;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_CRL);
    }

    [super dealloc];
}

@end


@implementation TBSCertList

+ (TBSCertList*)listWithRawRef:(CSSM_X509_TBS_CERTLIST*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithTBSCertListRef:ref freeWhenDone:fre] autorelease];
}

+ (TBSCertList*)listWithIssuer:(NameList*)issuer signatureAlgorithm:(AlgorithmIdentifier*)signatureAlgorithm thisUpdate:(Time*)thisUpdate nextUpdate:(Time*)nextUpdate certificates:(RevokedCertificateList*)revokedCertificates extensions:(ExtensionList*)extensions {
    return [[[[self class] alloc] initWithIssuer:issuer signatureAlgorithm:signatureAlgorithm thisUpdate:thisUpdate nextUpdate:nextUpdate certificates:revokedCertificates extensions:extensions] autorelease];
}

- (TBSCertList*)initWithTBSCertListRef:(CSSM_X509_TBS_CERTLIST*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _CertList = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (TBSCertList*)initWithIssuer:(NameList*)issuer signatureAlgorithm:(AlgorithmIdentifier*)signatureAlgorithm thisUpdate:(Time*)thisUpdate nextUpdate:(Time*)nextUpdate certificates:(RevokedCertificateList*)revokedCertificates extensions:(ExtensionList*)extensions {
    _CertList = calloc(1, sizeof(CSSM_X509_TBS_CERTLIST));
    freeWhenDone = YES;

    intToDER(2, &(_CertList->version));
    _CertList->signature = *[signatureAlgorithm algorithmIdentifierRef];
    _CertList->issuer = *[issuer nameListRef];
    _CertList->thisUpdate = *[thisUpdate timeRef];
    _CertList->nextUpdate = *[nextUpdate timeRef];
    _CertList->revokedCertificates = [revokedCertificates RCLRef];
    _CertList->extensions = *[extensions extensionListRef];

    return self;
}

- (NSData*)version {
    return NSDataFromData(&(_CertList->version));
}

- (void)setVersion:(NSData*)version {
    copyNSDataToData(version, &(_CertList->version));
}

- (AlgorithmIdentifier*)signatureAlgorithm {
    return [AlgorithmIdentifier identifierWithRawRef:&(_CertList->signature) freeWhenDone:NO];
}

- (NameList*)issuer {
    return [NameList nameListWithRawRef:&(_CertList->issuer) freeWhenDone:NO];
}

- (Time*)thisUpdate {
    return [Time timeWithRawRef:&(_CertList->thisUpdate) freeWhenDone:NO];
}

- (Time*)nextUpdate {
    return [Time timeWithRawRef:&(_CertList->nextUpdate) freeWhenDone:NO];
}

- (RevokedCertificateList*)certificateList {
    return [RevokedCertificateList listWithRCLRef:(_CertList->revokedCertificates) freeWhenDone:NO];
}

- (ExtensionList*)extensionList {
    return [ExtensionList listWithRawRef:&(_CertList->extensions) freeWhenDone:NO];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Version: %@\nSignature Algorithm: %@\nIssuer: %@\nThis update: %@\nNext update: %@\nRevoked certificates: %@\nExtensions: %@", NSDataFromData(&(_CertList->version)), [[AlgorithmIdentifier identifierWithRawRef:&(_CertList->signature) freeWhenDone:NO] description], [[NameList nameListWithRawRef:&(_CertList->issuer) freeWhenDone:NO] description], [[Time timeWithRawRef:&(_CertList->thisUpdate) freeWhenDone:NO] description], [[Time timeWithRawRef:&(_CertList->nextUpdate) freeWhenDone:NO] description], [[RevokedCertificateList listWithRCLRef:(_CertList->revokedCertificates) freeWhenDone:NO] description], [[ExtensionList listWithRawRef:&(_CertList->extensions) freeWhenDone:NO] description]];
}

- (CSSM_X509_TBS_CERTLIST*)TBSCertListRef {
    return _CertList;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_CertList);
    }

    [super dealloc];
}

@end


@implementation RevokedCertificateList

+ (RevokedCertificateList*)listWithRCLRef:(CSSM_X509_REVOKED_CERT_LIST*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithRCLRef:ref freeWhenDone:fre] autorelease];
}

+ (RevokedCertificateList*)initWithCertificates:(NSArray*)arrayOfRevokedCertificates {
    return [[[[self class] alloc] initWithCertificates:arrayOfRevokedCertificates] autorelease];
}

- (RevokedCertificateList*)initWithRCLRef:(CSSM_X509_REVOKED_CERT_LIST*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _RevokedCertList = ref;
        _capacity = _RevokedCertList->numberOfRevokedCertEntries;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (RevokedCertificateList*)initWithCertificates:(NSArray*)arrayOfRevokedCertificates {
    NSEnumerator *enumerator;
    id current;

    if (arrayOfRevokedCertificates) {
        _RevokedCertList = calloc(1, sizeof(CSSM_X509EXT_POLICYQUALIFIERS));
        freeWhenDone = YES;

        enumerator = [arrayOfRevokedCertificates objectEnumerator];

        while (current = [enumerator nextObject]) {
            if ([current isKindOfClass:[RevokedCertificate class]]) {
                [self addCertificate:(RevokedCertificate*)current];
            }
        }

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (RevokedCertificate*)certificateAtIndex:(uint32_t)index {
    NSAssert(index >= 0, @"index < 0");
    NSAssert(index < _RevokedCertList->numberOfRevokedCertEntries, @"index >= number of names");

    return [RevokedCertificate revokedCertificateWithRawRef:&(_RevokedCertList->revokedCertEntry[index]) freeWhenDone:NO];
}

- (void)removeCertificateAtIndex:(uint32_t)index {
    NSAssert(index >= 0, @"index < 0");
    NSAssert(index < _RevokedCertList->numberOfRevokedCertEntries, @"index >= number of names");

    bcopy(&(_RevokedCertList->revokedCertEntry[index + 1]), &(_RevokedCertList->revokedCertEntry[index]), sizeof(CSSM_X509_REVOKED_CERT_ENTRY) * (_RevokedCertList->numberOfRevokedCertEntries - (index + 1)));

    --(_RevokedCertList->numberOfRevokedCertEntries);
}

- (void)addCertificate:(RevokedCertificate*)certificate {
    CSSM_X509_REVOKED_CERT_ENTRY *newList;

    if (_RevokedCertList->numberOfRevokedCertEntries == _capacity) { // need to allocate more space for new entry
        _capacity += 5;

        newList = calloc(_capacity, sizeof(CSSM_X509_REVOKED_CERT_ENTRY));
        memcpy(newList, _RevokedCertList->revokedCertEntry, sizeof(CSSM_X509EXT_POLICYQUALIFIERINFO) * _RevokedCertList->numberOfRevokedCertEntries);

        free(_RevokedCertList->revokedCertEntry);
        _RevokedCertList->revokedCertEntry = newList;
    }

    _RevokedCertList->revokedCertEntry[_RevokedCertList->numberOfRevokedCertEntries] = *[certificate revokedCertificateRef];
    ++(_RevokedCertList->numberOfRevokedCertEntries);
}

- (uint32_t)numberOfCertificates {
    return _RevokedCertList->numberOfRevokedCertEntries;
}

- (NSEnumerator*)certificateEnumerator {
    return [RevokedCertificateListEnumerator enumeratorForRevokedCertificateList:self];
}

- (NSString*)description {
    unsigned int i;
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:(_RevokedCertList->numberOfRevokedCertEntries * 50)];

    for (i = 0; i < _RevokedCertList->numberOfRevokedCertEntries; ++i) {
        [result appendString:[[RevokedCertificate revokedCertificateWithRawRef:&(_RevokedCertList->revokedCertEntry[i]) freeWhenDone:NO] description]];
        [result appendString:@"\n"];
    }

    return [result autorelease];
}

- (CSSM_X509_REVOKED_CERT_LIST*)RCLRef {
    return _RevokedCertList;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_RevokedCertList);
    }

    [super dealloc];
}

@end


@implementation RevokedCertificate

+ (RevokedCertificate*)revokedCertificateWithRawRef:(CSSM_X509_REVOKED_CERT_ENTRY*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithRevokedCertificateRef:ref freeWhenDone:fre] autorelease];
}

+ (RevokedCertificate*)revokedCertificateWithSerial:(uint32_t)serial date:(Time*)revocationDate extensions:(ExtensionList*)extensions {
    return [[[[self class] alloc] initWithSerial:serial date:revocationDate extensions:extensions] autorelease];
}

- (RevokedCertificate*)initWithRevokedCertificateRef:(CSSM_X509_REVOKED_CERT_ENTRY*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _RevokedCert = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (RevokedCertificate*)initWithSerial:(uint32_t)serial date:(Time*)revocationDate extensions:(ExtensionList*)extensions {
    _RevokedCert = calloc(1, sizeof(CSSM_X509_REVOKED_CERT_ENTRY));
    freeWhenDone = YES;

    intToDER(serial, &(_RevokedCert->certificateSerialNumber));
    _RevokedCert->revocationDate = *[revocationDate timeRef];
    _RevokedCert->extensions = *[extensions extensionListRef];

    return self;
}

- (NSData*)serialNumber {
    return NSDataFromData(&(_RevokedCert->certificateSerialNumber));
}

- (void)setSerialNumber:(NSData*)serial {
    copyNSDataToData(serial, &(_RevokedCert->certificateSerialNumber));
}

- (Time*)revocationDate {
    return [Time timeWithRawRef:&(_RevokedCert->revocationDate) freeWhenDone:NO];
}

- (ExtensionList*)extensionList {
    return [ExtensionList listWithRawRef:&(_RevokedCert->extensions) freeWhenDone:NO];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Serial: %@\tRevocation Date: %@\tExtensions:\n%@", NSDataFromData(&(_RevokedCert->certificateSerialNumber)), [[Time timeWithRawRef:(&(_RevokedCert->revocationDate)) freeWhenDone:NO] description], [[ExtensionList listWithRawRef:(&(_RevokedCert->extensions)) freeWhenDone:NO] description]];
}

- (CSSM_X509_REVOKED_CERT_ENTRY*)revokedCertificateRef {
    return _RevokedCert;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_RevokedCert);
    }

    [super dealloc];
}

@end


@implementation RevokedCertificateListEnumerator

+ (RevokedCertificateListEnumerator*)enumeratorForRevokedCertificateList:(RevokedCertificateList*)list {
    return [[[[self class] alloc] initWithRevokedCertificateList:list] autorelease];
}

- (RevokedCertificateListEnumerator*)initWithRevokedCertificateList:(RevokedCertificateList*)list {
    if (self = [super init]) {
        if (list) {
            _list = [list retain];
            _index = 0;
        } else {
            [self release];
            return nil;
        }
    }

    return self;
}

// is allObjects supposed to return nil or an empty array, in the case that it has finished enumerating the list?
- (NSArray*)allObjects {
    NSMutableArray *result;
    int resultCount = [_list numberOfCertificates] - _index;
    uint32_t i;

    if (resultCount > 0) {
        result = [[NSMutableArray alloc] initWithCapacity:resultCount];

        for (i = _index; i < [_list numberOfCertificates]; ++i) {
            [result addObject:[_list certificateAtIndex:i]];
        }

        _index += resultCount;

        return [result autorelease];
    } else {
        return nil;
    }
}

- (RevokedCertificate*)nextObject {
    if ([_list numberOfCertificates] > _index) {
        return [_list certificateAtIndex:(_index++)];
    } else {
        return nil;
    }
}

- (void)dealloc {
    [_list release];

    [super dealloc];
}

@end


@implementation PolicyInfo

+ (PolicyInfo*)infoWithRawRef:(CSSM_X509EXT_POLICYINFO*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithPolicyInfoRef:ref freeWhenDone:fre] autorelease];
}

+ (PolicyInfo*)infoWithID:(const CSSM_OID*)policyID qualifiers:(PolicyQualifierList*)qualifiers {
    return [[[[self class] alloc] initWithID:policyID qualifiers:qualifiers] autorelease];
}

- (PolicyInfo*)initWithPolicyInfoRef:(CSSM_X509EXT_POLICYINFO*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _PolicyInfo = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (PolicyInfo*)initWithID:(const CSSM_OID*)policyID qualifiers:(PolicyQualifierList*)qualifiers {
    _PolicyInfo = calloc(1, sizeof(CSSM_X509EXT_POLICYINFO));
    freeWhenDone = YES;

    _PolicyInfo->policyIdentifier = *policyID;
    _PolicyInfo->policyQualifiers = *[qualifiers qualifierListRef];

    return self;
}

- (NSData*)identifier {
    return NSDataFromData(&(_PolicyInfo->policyIdentifier));
}

- (void)setIdentifier:(NSData*)identifier {
    copyNSDataToData(identifier, &(_PolicyInfo->policyIdentifier));
}

- (PolicyQualifierList*)qualifierList {
    return [PolicyQualifierList listWithRawRef:(&(_PolicyInfo->policyQualifiers)) freeWhenDone:NO];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Policy ID: %@\tValue:\n%@", NSDataFromData(&(_PolicyInfo->policyIdentifier)), [[PolicyQualifierList listWithRawRef:(&(_PolicyInfo->policyQualifiers)) freeWhenDone:NO] description]];
}

- (CSSM_X509EXT_POLICYINFO*)policyInfoRef {
    return _PolicyInfo;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_PolicyInfo);
    }

    [super dealloc];
}

@end


@implementation PolicyQualifierList

+ (PolicyQualifierList*)listWithRawRef:(CSSM_X509EXT_POLICYQUALIFIERS*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithPolicyQualifierListRef:ref freeWhenDone:fre] autorelease];
}

+ (PolicyQualifierList*)listWithQualifiers:(NSArray*)arrayOfQualifiers {
    return [[[[self class] alloc] initWithQualifiers:arrayOfQualifiers] autorelease];
}

- (PolicyQualifierList*)initWithPolicyQualifierListRef:(CSSM_X509EXT_POLICYQUALIFIERS*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _PolicyQualifierList = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (PolicyQualifierList*)initWithQualifiers:(NSArray*)arrayOfQualifiers {
    NSEnumerator *enumerator;
    id current;

    if (arrayOfQualifiers) {
        _PolicyQualifierList = calloc(1, sizeof(CSSM_X509EXT_POLICYQUALIFIERS));
        freeWhenDone = YES;

        enumerator = [arrayOfQualifiers objectEnumerator];

        while (current = [enumerator nextObject]) {
            if ([current isKindOfClass:[PolicyQualifierList class]]) {
                [self addQualifier:(PolicyQualifier*)current];
            }
        }

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (PolicyQualifier*)qualifierAtIndex:(uint32_t)index {
    NSAssert(index >= 0, @"index < 0");
    NSAssert(index < _PolicyQualifierList->numberOfPolicyQualifiers, @"index >= number of names");

    return [PolicyQualifier qualifierWithRawRef:&(_PolicyQualifierList->policyQualifier[index]) freeWhenDone:NO];
}

- (void)removeQualifierAtIndex:(uint32_t)index {
    NSAssert(index >= 0, @"index < 0");
    NSAssert(index < _PolicyQualifierList->numberOfPolicyQualifiers, @"index >= number of names");

    bcopy(&(_PolicyQualifierList->policyQualifier[index + 1]), &(_PolicyQualifierList->policyQualifier[index]), sizeof(CSSM_X509EXT_POLICYQUALIFIERINFO) * (_PolicyQualifierList->numberOfPolicyQualifiers - (index + 1)));

    --(_PolicyQualifierList->numberOfPolicyQualifiers);
}

- (void)addQualifier:(PolicyQualifier*)qualifier {
    CSSM_X509EXT_POLICYQUALIFIERINFO *newList;

    if (_PolicyQualifierList->numberOfPolicyQualifiers == _capacity) { // need to allocate more space for new entry
        _capacity += 5;

        newList = calloc(_capacity, sizeof(CSSM_X509EXT_POLICYQUALIFIERINFO));
        memcpy(newList, _PolicyQualifierList->policyQualifier, sizeof(CSSM_X509EXT_POLICYQUALIFIERINFO) * _PolicyQualifierList->numberOfPolicyQualifiers);

        free(_PolicyQualifierList->policyQualifier);
        _PolicyQualifierList->policyQualifier = newList;
    }

    _PolicyQualifierList->policyQualifier[_PolicyQualifierList->numberOfPolicyQualifiers] = *[qualifier qualifierRef];
    ++(_PolicyQualifierList->numberOfPolicyQualifiers);
}

- (uint32_t)numberOfQualifiers {
    return _PolicyQualifierList->numberOfPolicyQualifiers;
}

- (NSString*)description {
    unsigned int i;
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:(_PolicyQualifierList->numberOfPolicyQualifiers * 50)];

    for (i = 0; i < _PolicyQualifierList->numberOfPolicyQualifiers; ++i) {
        [result appendString:[[PolicyQualifier qualifierWithRawRef:&(_PolicyQualifierList->policyQualifier[i]) freeWhenDone:NO] description]];
        [result appendString:@"\n"];
    }

    return [result autorelease];    
}

- (CSSM_X509EXT_POLICYQUALIFIERS*)qualifierListRef {
    return _PolicyQualifierList;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_PolicyQualifierList);
    }

    [super dealloc];
}

@end


@implementation PolicyQualifierListEnumerator

+ (PolicyQualifierListEnumerator*)enumeratorForQualifierList:(PolicyQualifierList*)list {
    return [[[[self class] alloc] initWithQualifierList:list] autorelease];
}

- (PolicyQualifierListEnumerator*)initWithQualifierList:(PolicyQualifierList*)list {
    if (self = [super init]) {
        if (list) {
            _list = [list retain];
            _index = 0;
        } else {
            [self release];
            return nil;
        }
    }

    return self;
}

// is allObjects supposed to return nil or an empty array, in the case that it has finished enumerating the list?
- (NSArray*)allObjects {
    NSMutableArray *result;
    int resultCount = [_list numberOfQualifiers] - _index;
    uint32_t i;

    if (resultCount > 0) {
        result = [[NSMutableArray alloc] initWithCapacity:resultCount];

        for (i = _index; i < [_list numberOfQualifiers]; ++i) {
            [result addObject:[_list qualifierAtIndex:i]];
        }

        _index += resultCount;

        return [result autorelease];
    } else {
        return nil;
    }
}

- (PolicyQualifier*)nextObject {
    if ([_list numberOfQualifiers] > _index) {
        return [_list qualifierAtIndex:(_index++)];
    } else {
        return nil;
    }
}

- (void)dealloc {
    [_list release];

    [super dealloc];
}

@end


@implementation PolicyQualifier

+ (PolicyQualifier*)qualifierWithRawRef:(CSSM_X509EXT_POLICYQUALIFIERINFO*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithPolicyQualifierRef:ref freeWhenDone:fre] autorelease];
}

+ (PolicyQualifier*)qualifierWithID:(const CSSM_OID*)qualifierID value:(NSData*)value {
    return [[[[self class] alloc] initWithID:qualifierID value:value] autorelease];
}

- (PolicyQualifier*)initWithPolicyQualifierRef:(CSSM_X509EXT_POLICYQUALIFIERINFO*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _PolicyQualifier = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (PolicyQualifier*)initWithID:(const CSSM_OID*)qualifierID value:(NSData*)value {
    _PolicyQualifier = calloc(1, sizeof(CSSM_X509EXT_POLICYQUALIFIERINFO));
    freeWhenDone = YES;

    _PolicyQualifier->policyQualifierId = *qualifierID;
    copyNSDataToData(value, &(_PolicyQualifier->value));

    return self;
}

- (NSData*)qualifierID {
    return NSDataFromData(&(_PolicyQualifier->policyQualifierId));
}

- (void)setQualifierID:(NSData*)qualifierID {
    copyNSDataToData(qualifierID, &(_PolicyQualifier->policyQualifierId));
}

- (NSData*)value {
    return NSDataFromData(&(_PolicyQualifier->value));
}

- (void)setValue:(NSData*)value {
    copyNSDataToData(value, &(_PolicyQualifier->value));
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Qualifier: %@\tData: %@\n", NSDataFromData(&(_PolicyQualifier->policyQualifierId)), NSDataFromData(&(_PolicyQualifier->value))];
}

- (CSSM_X509EXT_POLICYQUALIFIERINFO*)qualifierRef {
    return _PolicyQualifier;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_PolicyQualifier);
    }

    [super dealloc];
}

@end


@implementation SignedCertificate

+ (SignedCertificate*)signedCertificateWithRawRef:(CSSM_X509_SIGNED_CERTIFICATE*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithSignedCertificateRef:ref freeWhenDone:fre] autorelease];
}

+ (SignedCertificate*)signedCertificateWithCertificate:(TBSCertificate*)certificate signature:(X509Signature*)signature {
    return [[[[self class] alloc] initWithCertificate:certificate signature:signature] autorelease];
}

- (SignedCertificate*)initWithSignedCertificateRef:(CSSM_X509_SIGNED_CERTIFICATE*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _SignedCertificate = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (SignedCertificate*)initWithCertificate:(TBSCertificate*)certificate signature:(X509Signature*)signature {
    _SignedCertificate = calloc(1, sizeof(CSSM_X509_SIGNED_CERTIFICATE));
    freeWhenDone = YES;

    _SignedCertificate->certificate = *[certificate TBSCertificateRef];
    _SignedCertificate->signature = *[signature signatureRef];

    return self;
}

- (TBSCertificate*)certificate {
    return [TBSCertificate certificateWithRawRef:(&(_SignedCertificate->certificate)) freeWhenDone:NO];
}

- (X509Signature*)signature {
    return [X509Signature signatureWithRawRef:(&(_SignedCertificate->signature)) freeWhenDone:NO];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Certificate: %@\nSignature: %@", [[TBSCertificate certificateWithRawRef:(&(_SignedCertificate->certificate)) freeWhenDone:NO] description], [[X509Signature signatureWithRawRef:(&(_SignedCertificate->signature)) freeWhenDone:NO] description]];
}

- (CSSM_X509_SIGNED_CERTIFICATE*)signedCertificateRef {
    return _SignedCertificate;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_SignedCertificate);
    }

    [super dealloc];
}

@end


@implementation X509Signature

+ (X509Signature*)signatureWithRawRef:(CSSM_X509_SIGNATURE*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithSignatureRef:ref freeWhenDone:fre] autorelease];
}

+ (X509Signature*)signatureWithAlgorithm:(AlgorithmIdentifier*)algorithm data:(NSData*)data {
    return [[[[self class] alloc] initWithAlgorithm:algorithm data:data] autorelease];
}

- (X509Signature*)initWithSignatureRef:(CSSM_X509_SIGNATURE*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _Signature = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (X509Signature*)initWithAlgorithm:(AlgorithmIdentifier*)algorithm data:(NSData*)data {
    _Signature = calloc(1, sizeof(CSSM_X509_SIGNATURE));
    freeWhenDone = YES;

    _Signature->algorithmIdentifier = *[algorithm algorithmIdentifierRef];
    copyNSDataToData(data, &(_Signature->encrypted));

    return self;
}

- (AlgorithmIdentifier*)algorithm {
    return [AlgorithmIdentifier identifierWithRawRef:&(_Signature->algorithmIdentifier) freeWhenDone:NO];
}

- (NSData*)data {
    return NSDataFromData(&(_Signature->encrypted));
}

- (NSString*)description {
    return signatureAsString(_Signature);
}

- (CSSM_X509_SIGNATURE*)signatureRef {
    return _Signature;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_Signature);
    }

    [super dealloc];
}

@end


@implementation TBSCertificate

+ (TBSCertificate*)certificateWithRawRef:(CSSM_X509_TBS_CERTIFICATE*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithTBSCertificateRef:ref freeWhenDone:fre] autorelease];
}

+ (TBSCertificate*)certificateWithSerial:(uint32_t)serial signatureAlgorithm:(AlgorithmIdentifier*)signatureAlgorithm issuer:(NameList*)issuer subject:(NameList*)subject validity:(Validity*)validity publicKeyInfo:(SPKInfo*)publicKeyInfo issuerID:(NSData*)issuerID subjectID:(NSData*)subjectID extensions:(ExtensionList*)extensions {
    return [[[[self class] alloc] initWithSerial:serial signatureAlgorithm:signatureAlgorithm issuer:issuer subject:subject validity:validity publicKeyInfo:publicKeyInfo issuerID:issuerID subjectID:subjectID extensions:extensions] autorelease];
}

- (TBSCertificate*)initWithTBSCertificateRef:(CSSM_X509_TBS_CERTIFICATE*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _TBSCertificate = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (TBSCertificate*)initWithSerial:(uint32_t)serial signatureAlgorithm:(AlgorithmIdentifier*)signatureAlgorithm issuer:(NameList*)issuer subject:(NameList*)subject validity:(Validity*)validity publicKeyInfo:(SPKInfo*)publicKeyInfo issuerID:(NSData*)issuerID subjectID:(NSData*)subjectID extensions:(ExtensionList*)extensions {
    _TBSCertificate = calloc(1, sizeof(CSSM_X509_TBS_CERTIFICATE));
    freeWhenDone = YES;

    intToDER(2, &(_TBSCertificate->version));
    intToDER(serial, &(_TBSCertificate->serialNumber));

    _TBSCertificate->signature = *[signatureAlgorithm algorithmIdentifierRef];
    _TBSCertificate->issuer = *[issuer nameListRef];
    _TBSCertificate->validity = *[validity validityRef];
    _TBSCertificate->subject = *[subject nameListRef];
    _TBSCertificate->subjectPublicKeyInfo = *[publicKeyInfo infoRef];
    copyNSDataToData(issuerID, &(_TBSCertificate->issuerUniqueIdentifier));
    copyNSDataToData(subjectID, &(_TBSCertificate->subjectUniqueIdentifier));
    _TBSCertificate->extensions = *[extensions extensionListRef];

    return self;
}

- (NSData*)version {
    return NSDataFromData(&(_TBSCertificate->version));
}

- (void)setVersion:(NSData*)version {
    copyNSDataToData(version, &(_TBSCertificate->version));
}

- (NSData*)serialNumber {
    return NSDataFromData(&(_TBSCertificate->serialNumber));
}

- (void)setSerialNumber:(NSData*)serial {
    copyNSDataToData(serial, &(_TBSCertificate->serialNumber));
}

- (AlgorithmIdentifier*)signatureAlgorithm {
    return [AlgorithmIdentifier identifierWithRawRef:(&(_TBSCertificate->signature)) freeWhenDone:NO];
}

- (void)setSignatureAlgorithm:(AlgorithmIdentifier*)signatureAlgorithm {
    _TBSCertificate->signature = *[signatureAlgorithm algorithmIdentifierRef];
}

- (NameList*)issuer {
    return [NameList nameListWithRawRef:(&(_TBSCertificate->issuer)) freeWhenDone:NO];
}

- (void)setIssuer:(NameList*)issuer {
    _TBSCertificate->issuer = *[issuer nameListRef];
}

- (Validity*)validity {
    return [Validity validityWithRawRef:(&(_TBSCertificate->validity)) freeWhenDone:NO];
}

- (void)setValidity:(Validity*)validity {
    _TBSCertificate->validity = *[validity validityRef];
}

- (NameList*)subject {
    return [NameList nameListWithRawRef:(&(_TBSCertificate->subject)) freeWhenDone:NO];
}

- (void)setSubject:(NameList*)subject {
    _TBSCertificate->subject = *[subject nameListRef];
}

- (SPKInfo*)subjectPublicKeyInfo {
    return [SPKInfo infoWithRawRef:(&(_TBSCertificate->subjectPublicKeyInfo)) freeWhenDone:NO];
}

- (void)setSubjectPublicKeyInfo:(SPKInfo*)publicKeyInfo {
    _TBSCertificate->subjectPublicKeyInfo = *[publicKeyInfo infoRef];
}

- (NSData*)issuerID {
    return NSDataFromData(&(_TBSCertificate->issuerUniqueIdentifier));
}

- (void)setIssuerID:(NSData*)issuerID {
    copyNSDataToData(issuerID, &(_TBSCertificate->issuerUniqueIdentifier));
}

- (NSData*)subjectID {
    return NSDataFromData(&(_TBSCertificate->subjectUniqueIdentifier));
}

- (void)setSubjectID:(NSData*)subjectID {
    copyNSDataToData(subjectID, &(_TBSCertificate->subjectUniqueIdentifier));
}

- (ExtensionList*)extensions {
    return [ExtensionList listWithRawRef:(&(_TBSCertificate->extensions)) freeWhenDone:NO];
}

- (void)setExtensions:(ExtensionList*)extensions {
    _TBSCertificate->extensions = *[extensions extensionListRef];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Version: %@\nSerial number: %@\nSignature algorithm: %@\nIssuer: %@\nValidity: %@\nSubject: %@\nSPK Info: %@\nIssuer unique ID: %@\nSubject unique ID: %@\nExtensions: %@", [self version], [self serialNumber], [[self signatureAlgorithm] description], [[self issuer] description], [[self validity] description], [[self subject] description], [[self subjectPublicKeyInfo] description], [self issuerID], [self subjectID], [[self extensions] description]];

    // The problem with this older code [below] is that it will make it harder to update this class, as I intend to in the near future.
    //return [NSString stringWithFormat:@"Version: %@\nSerial number: %@\nSignature algorithm: %@\nIssuer: %@\nValidity: %@\nSubject: %@\nSPK Info: %@\nIssuer unique ID: %@\nSubject unique ID: %@\nExtensions: %@", NSDataFromData(&(_TBSCertificate->version)), NSDataFromData(&(_TBSCertificate->serialNumber)), [[AlgorithmIdentifier identifierWithRawRef:(&(_TBSCertificate->signature)) freeWhenDone:NO] description], [[NameList nameListWithRawRef:(&(_TBSCertificate->issuer)) freeWhenDone:NO] description], [[Validity validityWithRawRef:(&(_TBSCertificate->validity)) freeWhenDone:NO] description], [[NameList nameListWithRawRef:(&(_TBSCertificate->subject)) freeWhenDone:NO] description], [[SPKInfo infoWithRawRef:(&(_TBSCertificate->subjectPublicKeyInfo)) freeWhenDone:NO] description], NSDataFromData(&(_TBSCertificate->issuerUniqueIdentifier)), NSDataFromData(&(_TBSCertificate->subjectUniqueIdentifier)), [[ExtensionList listWithRawRef:(&(_TBSCertificate->extensions)) freeWhenDone:NO] description]];
}

- (CSSM_X509_TBS_CERTIFICATE*)TBSCertificateRef {
    return _TBSCertificate;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_TBSCertificate);
    }

    [super dealloc];
}

@end


@implementation ExtensionListEnumerator

+ (ExtensionListEnumerator*)enumeratorForExtensionList:(ExtensionList*)list {
    return [[[[self class] alloc] initWithExtensionList:list] autorelease];
}

- (ExtensionListEnumerator*)initWithExtensionList:(ExtensionList*)list {
    if (self = [super init]) {
        if (list) {
            _list = [list retain];
            _index = 0;
        } else {
            [self release];
            return nil;
        }
    }

    return self;
}

// is allObjects supposed to return nil or an empty array, in the case that it has finished enumerating the list?
- (NSArray*)allObjects {
    NSMutableArray *result;
    int resultCount = [_list numberOfExtensions] - _index;
    uint32_t i;

    if (resultCount > 0) {
        result = [[NSMutableArray alloc] initWithCapacity:resultCount];

        for (i = _index; i < [_list numberOfExtensions]; ++i) {
            [result addObject:[_list extensionAtIndex:i]];
        }

        _index += resultCount;

        return [result autorelease];
    } else {
        return nil;
    }
}

- (Extension*)nextObject {
    if ([_list numberOfExtensions] > _index) {
        return [_list extensionAtIndex:(_index++)];
    } else {
        return nil;
    }
}

- (void)dealloc {
    [_list release];

    [super dealloc];
}

@end


@implementation ExtensionList

+ (ExtensionList*)listWithRawRef:(CSSM_X509_EXTENSIONS*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithExtensionListRef:ref freeWhenDone:fre] autorelease];
}

+ (ExtensionList*)listWithExtensions:(NSArray*)arrayOfExtensions {
    return [[[[self class] alloc] initWithExtensions:arrayOfExtensions] autorelease];
}

- (ExtensionList*)initWithExtensionListRef:(CSSM_X509_EXTENSIONS*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _ExtensionList = ref;
        _capacity = _ExtensionList->numberOfExtensions;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (ExtensionList*)initWithExtensions:(NSArray*)arrayOfExtensions {
    NSEnumerator *enumerator;
    id current;

    if (arrayOfExtensions) {
        _ExtensionList = calloc(1, sizeof(CSSM_X509_EXTENSIONS));
        freeWhenDone = YES;

        enumerator = [arrayOfExtensions objectEnumerator];

        while (current = [enumerator nextObject]) {
            if ([current isKindOfClass:[Extension class]]) {
                [self addExtension:(Extension*)current];
            }
        }

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (Extension*)extensionAtIndex:(uint32_t)index {
    NSAssert(index >= 0, @"index < 0");
    NSAssert(index < _ExtensionList->numberOfExtensions, @"index >= number of names");

    return [Extension extensionWithRawRef:&(_ExtensionList->extensions[index]) freeWhenDone:NO];
}

- (void)removeExtensionAtIndex:(uint32_t)index {
    NSAssert(index >= 0, @"index < 0");
    NSAssert(index < _ExtensionList->numberOfExtensions, @"index >= number of names");

    bcopy(&(_ExtensionList->extensions[index + 1]), &(_ExtensionList->extensions[index]), sizeof(CSSM_X509_EXTENSION) * (_ExtensionList->numberOfExtensions - (index + 1)));

    --(_ExtensionList->numberOfExtensions);
}

- (void)addExtension:(Extension*)extension {
    CSSM_X509_EXTENSION *newList;

    if (_ExtensionList->numberOfExtensions == _capacity) { // need to allocate more space for new entry
        _capacity += 5;

        newList = calloc(_capacity, sizeof(CSSM_X509_EXTENSION));
        memcpy(newList, _ExtensionList->extensions, sizeof(CSSM_X509_EXTENSION) * _ExtensionList->numberOfExtensions);

        free(_ExtensionList->extensions);
        _ExtensionList->extensions = newList;
    }

    _ExtensionList->extensions[_ExtensionList->numberOfExtensions] = *[extension extensionRef];
    ++(_ExtensionList->numberOfExtensions);
}

- (uint32_t)numberOfExtensions {
    return _ExtensionList->numberOfExtensions;
}

- (NSEnumerator*)extensionEnumerator {
    return [ExtensionListEnumerator enumeratorForExtensionList:self];
}

- (NSString*)description {
    return extensionsAsString(_ExtensionList);
}

- (CSSM_X509_EXTENSIONS*)extensionListRef {
    return _ExtensionList;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_ExtensionList);
    }

    [super dealloc];
}

@end


@implementation Extension

+ (Extension*)extensionWithRawRef:(CSSM_X509_EXTENSION*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithExtensionRef:ref freeWhenDone:fre] autorelease];
}

+ (Extension*)extensionWithID:(const CSSM_OID*)extnId tagAndValue:(TagAndValue*)tagAndValue critical:(BOOL)isCritical {
    return [[[[self class] alloc] initWithID:extnId tagAndValue:tagAndValue critical:isCritical] autorelease];
}

+ (Extension*)extensionWithID:(const CSSM_OID*)extnId parsedValue:(NSData*)parsedValue critical:(BOOL)isCritical {
    return [[[[self class] alloc] initWithID:extnId parsedValue:parsedValue critical:isCritical] autorelease];
}

+ (Extension*)extensionWithID:(const CSSM_OID*)extnId pairValue:(Pair*)pairValue critical:(BOOL)isCritical {
    return [[[[self class] alloc] initWithID:extnId pairValue:pairValue critical:isCritical] autorelease];
}

- (Extension*)initWithID:(const CSSM_OID*)extnId tagAndValue:(TagAndValue*)tagAndValue critical:(BOOL)isCritical {
    _Extension = calloc(1, sizeof(CSSM_X509_EXTENSION));
    freeWhenDone = YES;

    _Extension->extnId = *extnId;
    _Extension->critical = (isCritical ? CSSM_TRUE : CSSM_FALSE);
    _Extension->format = CSSM_X509_DATAFORMAT_ENCODED;
    _Extension->value.tagAndValue = [tagAndValue tagAndValueRef];
    //copyNSDataToData(berValue, &(_Extension->BERvalue)); // FLAG - need to construct BER form automagically
    
    return self;
}

- (Extension*)initWithID:(const CSSM_OID*)extnId parsedValue:(NSData*)parsedValue critical:(BOOL)isCritical {
    /*_Extension = calloc(1, sizeof(CSSM_X509_EXTENSION));
    freeWhenDone = YES;

    _Extension->extnId = *extnId;
    _Extension->critical = (isCritical ? CSSM_TRUE : CSSM_FALSE);
    _Extension->format = CSSM_X509_DATAFORMAT_PARSED;
    _Extension->value.parsedValue = ???;
    copyNSDataToData(berValue, &(_Extension->BERvalue));*/

    PDEBUG(@"I don't know how to handle parsed values yet.\n");

    [self release];
    return self;
}

- (Extension*)initWithID:(const CSSM_OID*)extnId pairValue:(Pair*)pairValue critical:(BOOL)isCritical {
    _Extension = calloc(1, sizeof(CSSM_X509_EXTENSION));
    freeWhenDone = YES;

    _Extension->extnId = *extnId;
    _Extension->critical = (isCritical ? CSSM_TRUE : CSSM_FALSE);
    _Extension->format = CSSM_X509_DATAFORMAT_PAIR;
    _Extension->value.valuePair = [pairValue pairRef];
    //copyNSDataToData(berValue, &(_Extension->BERvalue)); // FLAG - need to construct BER form automagically

    return self;
}

- (Extension*)initWithExtensionRef:(CSSM_X509_EXTENSION*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _Extension = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (NSData*)extensionID {
    return NSDataFromData(&(_Extension->extnId));
}

- (void)setExtensionID:(NSData*)extensionID {
    copyNSDataToData(extensionID, &(_Extension->extnId));
}

- (BOOL)critical {
    return (_Extension->critical == CSSM_TRUE);
}

- (void)setCritical:(BOOL)critical {
    _Extension->critical = (critical ? CSSM_TRUE : CSSM_FALSE);
}

- (CSSM_X509EXT_DATA_FORMAT)dataFormat {
    return _Extension->format;
}

- (void)setDataFormat:(CSSM_X509EXT_DATA_FORMAT)format {
    _Extension->format = format;
}

- (BOOL)isEncoded {
    return ((_Extension->format == CSSM_X509_DATAFORMAT_ENCODED) || (_Extension->format == CSSM_X509_DATAFORMAT_PAIR));
}

- (BOOL)isParsed {
    return ((_Extension->format == CSSM_X509_DATAFORMAT_PARSED) || (_Extension->format == CSSM_X509_DATAFORMAT_PAIR));
}

- (void)setIsEncoded:(BOOL)enc {
    // FLAG - to be completed
}

- (void)setIsParsed:(BOOL)enc {
    // FLAG - to be completed
}

- (TagAndValue*)tagAndValue {
    if (_Extension->format == CSSM_X509_DATAFORMAT_ENCODED) {
        return [TagAndValue tagAndValueWithRawRef:_Extension->value.tagAndValue freeWhenDone:NO];
    } else {
        return nil;
    }
}

- (void)releaseData {
    switch (_Extension->format) {
        case CSSM_X509_DATAFORMAT_ENCODED:
            if (_Extension->value.tagAndValue) {
                free(_Extension->value.tagAndValue);
                _Extension->value.tagAndValue = NULL;
            }
            
            break;
        case CSSM_X509_DATAFORMAT_PARSED:
            if (_Extension->value.parsedValue) {
                free(_Extension->value.parsedValue);
                _Extension->value.parsedValue = NULL;
            }
            
            break;
        case CSSM_X509_DATAFORMAT_PAIR:
            if (_Extension->value.valuePair) {
                free(_Extension->value.valuePair);
                _Extension->value.valuePair = NULL;
            }
            
            break;
        default:
            PDEBUG(@"Data is in a format I don't understand (%d).\n", _Extension->format);
    }
}

- (void)setTagAndValue:(TagAndValue*)tagAndValue {
    [self releaseData];
    
    if (_Extension->format == CSSM_X509_DATAFORMAT_PAIR) {
        
    } else if (_Extension->format == CSSM_X509_DATAFORMAT_ENCODED) {
       
    } else if (_Extension->format == CSSM_X509_DATAFORMAT_PARSED) {
        
    }
    _Extension->format = CSSM_X509_DATAFORMAT_ENCODED;
    _Extension->value.tagAndValue = [tagAndValue tagAndValueRef]; // note: refers to the data by reference
}

- (void*)parsedValue {
    return NULL; // FLAG - to be completed
}

- (void)setParsedValue:(void*)parsedValue {
    
}

- (Pair*)pairValue {
    return nil; // FLAG - to be completed
}

- (void)setPairValue:(Pair*)pairValue {
    
}

- (NSData*)parsedData {
    // I'm not sure how to parse this void*, so to be safe I'll just have to return nil for the moment
    PDEBUG(@"I don't know how to parse the data yet.\n");

    return nil;
}

- (void)setParsedData:(NSData*)data {
    PDEBUG(@"I don't know how to handle parsed data yet.\n");
}

- (Pair*)pairData {
    if (_Extension->format == CSSM_X509_DATAFORMAT_PAIR) {
        return [Pair pairWithRawRef:_Extension->value.valuePair freeWhenDone:NO];
    } else {
        return nil;
    }
}

- (void)setPairData:(Pair*)data {
    [self releaseData];
    _Extension->format = CSSM_X509_DATAFORMAT_PAIR;
    _Extension->value.valuePair = [data pairRef]; // note: refers to data by reference!
}

- (NSData*)BERvalue {
    return NSDataFromData(&(_Extension->BERvalue));
}

- (NSString*)description {
    return extensionAsString(_Extension);
}

- (CSSM_X509_EXTENSION*)extensionRef {
    return _Extension;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_Extension);
    }

    [super dealloc];
}

@end


@implementation Pair

+ (Pair*)pairWithRawRef:(CSSM_X509EXT_PAIR*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithPairRef:ref freeWhenDone:fre] autorelease];
}

+ (Pair*)pairWithTagAndValue:(TagAndValue*)tagAndValue value:(NSData*)value {
    return [[[[self class] alloc] initWithTagAndValue:tagAndValue value:value] autorelease];
}

- (Pair*)initWithPairRef:(CSSM_X509EXT_PAIR*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _Pair = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (Pair*)initWithTagAndValue:(TagAndValue*)tagAndValue value:(NSData*)value {
    //_Pair = calloc(1, sizeof(CSSM_X509EXT_PAIR));

    //_Pair->tagAndValue = [tagAndValue tagAndValueRef];
    PDEBUG(@"I don't know how to correctly format parsed data.\n");

    [self release];
    return nil;
}

- (TagAndValue*)tagAndValue {
    return [TagAndValue tagAndValueWithRawRef:&(_Pair->tagAndValue) freeWhenDone:NO];
}

- (NSData*)value {
    PDEBUG(@"I don't know how to interpret parsed data.\n");
    return nil;
}

- (NSString*)description {
    return @"Don't know how to correctly parse a Pair";
}

- (CSSM_X509EXT_PAIR*)pairRef {
    return _Pair;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_Pair);
    }

    [super dealloc];
}

@end


@implementation TagAndValue

+ (TagAndValue*)tagAndValueWithRawRef:(CSSM_X509EXT_TAGandVALUE*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithTagAndValueRef:ref freeWhenDone:fre] autorelease];
}

+ (TagAndValue*)tagAndValueWithType:(CSSM_BER_TAG)type value:(NSData*)value {
    return [[[[self class] alloc] initWithType:type value:value] autorelease];
}

- (TagAndValue*)initWithTagAndValueRef:(CSSM_X509EXT_TAGandVALUE*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _TagAndValue = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (TagAndValue*)initWithType:(CSSM_BER_TAG)type value:(NSData*)value {
    _TagAndValue = calloc(1, sizeof(CSSM_X509EXT_TAGandVALUE));

    _TagAndValue->type = type;
    copyNSDataToData(value, &(_TagAndValue->value));

    freeWhenDone = YES;

    return self;
}

- (CSSM_BER_TAG)type {
    return _TagAndValue->type;
}

- (NSData*)value {
    return NSDataFromData(&(_TagAndValue->value));
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Name: %@\tValue: %@", nameOfBERCode(_TagAndValue->type), NSDataFromData(&(_TagAndValue->value))];
}

- (CSSM_X509EXT_TAGandVALUE*)tagAndValueRef {
    return _TagAndValue;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_TagAndValue);
    }

    [super dealloc];
}

@end


@implementation Validity

+ (Validity*)validityWithRawRef:(CSSM_X509_VALIDITY*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithValidityRef:ref freeWhenDone:fre] autorelease];
}

+ (Validity*)validityFrom:(Time*)from to:(Time*)to {
    return [[[[self class] alloc] initFrom:from to:to] autorelease];
}

- (Validity*)initWithValidityRef:(CSSM_X509_VALIDITY*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _Validity = ref;
        freeWhenDone = fre;
        
        return self;
    } else {
        [self release];
        return nil;
    }
}

- (Validity*)initFrom:(Time*)from to:(Time*)to {
    _Validity = calloc(1, sizeof(CSSM_X509_VALIDITY));
    freeWhenDone = YES;

    memcpy(&(_Validity->notBefore), [from timeRef], sizeof(CSSM_X509_TIME));
    memcpy(&(_Validity->notAfter), [to timeRef], sizeof(CSSM_X509_TIME));
    //_Validity->notBefore = *[from timeRef];
    //_Validity->notAfter = *[to timeRef];

    return self;
}

- (Time*)from {
    return [Time timeWithRawRef:&(_Validity->notBefore) freeWhenDone:NO];
}

- (Time*)to {
    return [Time timeWithRawRef:&(_Validity->notAfter) freeWhenDone:NO];
}

- (BOOL)isCurrentlyValid {
    return [self isValidAtDate:[NSCalendarDate date]];
}

- (BOOL)isValidAtDate:(NSCalendarDate*)date {
    return (([[[self from] calendarDate] compare:date] == NSOrderedAscending) && ([[[self to] calendarDate] compare:date] == NSOrderedDescending));
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ to %@", [[self from] description], [[self to] description]];
}

- (CSSM_X509_VALIDITY*)validityRef {
    return _Validity;
}

- (void)dealloc {
    //PDEBUG(@"Validity::dealloc called with freeWhenDone == %@\n", freeWhenDone ? @"YES" : @"NO");

    if (freeWhenDone) {
        free(_Validity);
    }

    [super dealloc];
}

@end


@implementation Time

+ (Time*)timeWithRawRef:(CSSM_X509_TIME*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithTimeRef:ref freeWhenDone:fre] autorelease];
}

+ (Time*)timeWithCalendarDate:(NSCalendarDate*)date format:(CSSM_BER_TAG)format {
    return [[[[self class] alloc] initWithCalendarDate:date format:format] autorelease];
}

- (Time*)initWithTimeRef:(CSSM_X509_TIME*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _Time = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (Time*)initWithCalendarDate:(NSCalendarDate*)date format:(CSSM_BER_TAG)format {
    _Time = calloc(1, sizeof(CSSM_X509_TIME));
    freeWhenDone = YES;

    *_Time = timeForNSCalendarDate(date, format);
    
    return self;
}

- (BOOL)isNullTime {
    return ((_Time->time.Length == 0) || (_Time->time.Data == NULL));
}

- (NSCalendarDate*)calendarDate {
    return calendarDateForTime(_Time);
}

- (NSString*)description {
    return [[self calendarDate] descriptionWithCalendarFormat:@"%H:%M:%S %e/%m/%Y"];
}

- (CSSM_X509_TIME*)timeRef {
    return _Time;
}

- (void)dealloc {
    //PDEBUG(@"Time::dealloc called with freeWhenDone == %@\n", freeWhenDone ? @"YES" : @"NO");

    if (freeWhenDone) {
        free(_Time);
    }

    [super dealloc];
}

@end


@implementation SPKInfo

+ (SPKInfo*)infoWithRawRef:(CSSM_X509_SUBJECT_PUBLIC_KEY_INFO*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithSPKInfoRef:ref freeWhenDone:fre] autorelease];
}

+ (SPKInfo*)infoWithAlgorithm:(AlgorithmIdentifier*)algorithm keyData:(NSData*)data {
    return [[[[self class] alloc] initWithAlgorithm:(AlgorithmIdentifier*)algorithm keyData:(NSData*)data] autorelease];
}

- (SPKInfo*)initWithSPKInfoRef:(CSSM_X509_SUBJECT_PUBLIC_KEY_INFO*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _SPKInfo = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (SPKInfo*)initWithAlgorithm:(AlgorithmIdentifier*)algorithm keyData:(NSData*)data {
    _SPKInfo = calloc(1, sizeof(CSSM_X509_SUBJECT_PUBLIC_KEY_INFO));
    _SPKInfo->algorithm = *[algorithm algorithmIdentifierRef];
    copyNSDataToData(data, &(_SPKInfo->subjectPublicKey));

    freeWhenDone = YES;
    
    return self;
}

- (AlgorithmIdentifier*)algorithm {
    return [AlgorithmIdentifier identifierWithRawRef:&(_SPKInfo->algorithm) freeWhenDone:NO];
}

- (NSData*)keyData {
    return NSDataFromData(&(_SPKInfo->subjectPublicKey));
}

- (NSString*)description {
    return subjectPublicKeyAsString(_SPKInfo);
}

- (CSSM_X509_SUBJECT_PUBLIC_KEY_INFO*)infoRef {
    return _SPKInfo;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_SPKInfo);
    }

    [super dealloc];
}

@end


@implementation NameListEnumerator

+ (NameListEnumerator*)enumeratorForNameList:(NameList*)list {
    return [[[[self class] alloc] initWithNameList:list] autorelease];
}

- (NameListEnumerator*)initWithNameList:(NameList*)list {
    if (self = [super init]) {
        if (list) {
            _list = [list retain];
            _index = 0;
        } else {
            [self release];
            return nil;
        }
    }

    return self;
}

// is allObjects supposed to return nil or an empty array, in the case that it has finished enumerating the list?
- (NSArray*)allObjects {
    NSMutableArray *result;
    int resultCount = [_list numberOfNames] - _index;
    uint32_t i;

    if (resultCount > 0) {
        result = [[NSMutableArray alloc] initWithCapacity:resultCount];

        for (i = _index; i < [_list numberOfNames]; ++i) {
            [result addObject:[_list nameAtIndex:i]];
        }

        _index += resultCount;

        return [result autorelease];
    } else {
        return nil;
    }
}

- (DistinguishedName*)nextObject {
    if ([_list numberOfNames] > _index) {
        return [_list nameAtIndex:(_index++)];
    } else {
        return nil;
    }
}

- (void)dealloc {
    [_list release];

    [super dealloc];
}

@end


@implementation NameList

+ (NameList*)nameListWithRawRef:(CSSM_X509_NAME*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithNameListRef:ref freeWhenDone:fre] autorelease];
}

+ (NameList*)nameListWithNames:(NSArray*)arrayOfNames {
    return [[[[self class] alloc] initWithNames:arrayOfNames] autorelease];
}

+ (NameList*)nameListWithCommonName:(NSString*)commonName organisation:(NSString*)organisation country:(NSString*)country state:(NSString*)state {
    return [[[[self class] alloc] initWithCommonName:commonName organisation:organisation country:country state:state] autorelease];
}

- (NameList*)initWithNameListRef:(CSSM_X509_NAME*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _NameList = ref;
        _capacity = _NameList->numberOfRDNs;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (NameList*)initWithNames:(NSArray*)arrayOfNames {
    NSEnumerator *enumerator;
    id current;

    if (arrayOfNames) {
        _NameList = calloc(1, sizeof(CSSM_X509_NAME));
        freeWhenDone = YES;

        enumerator = [arrayOfNames objectEnumerator];

        while (current = [enumerator nextObject]) {
            if ([current isKindOfClass:[DistinguishedName class]]) {
                [self addName:(DistinguishedName*)current];
            }
        }

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (NameList*)initWithCommonName:(NSString*)commonName organisation:(NSString*)organisation country:(NSString*)country state:(NSString*)state {
    return [self initWithNames:[NSArray arrayWithObjects:[DistinguishedName distinguishedNameWithTypeValuePair:[TypeValuePair pairForCommonName:commonName]], [DistinguishedName distinguishedNameWithTypeValuePair:[TypeValuePair pairForOrganisation:organisation]], [DistinguishedName distinguishedNameWithTypeValuePair:[TypeValuePair pairForCountry:country]], [DistinguishedName distinguishedNameWithTypeValuePair:[TypeValuePair pairForState:state]], nil]];
}

- (TypeValuePair*)firstPairForType:(const CSSM_OID*)type {
    unsigned int i;
    TypeValuePair *thePair = nil;
    
    for (i = 0; (i < _NameList->numberOfRDNs) && (thePair == nil); ++i) {
        thePair = [[[DistinguishedName distinguishedNameWithRawRef:&(_NameList->RelativeDistinguishedName[i]) freeWhenDone:NO] firstPairForType:type] retain];
    }

    return [thePair autorelease];
}

- (DistinguishedName*)nameAtIndex:(uint32_t)index {
    NSAssert(index >= 0, @"index < 0");
    NSAssert(index < _NameList->numberOfRDNs, @"index >= number of names");

    return [DistinguishedName distinguishedNameWithRawRef:&(_NameList->RelativeDistinguishedName[index]) freeWhenDone:NO];
}

- (void)removeNameAtIndex:(uint32_t)index {
    NSAssert(index >= 0, @"index < 0");
    NSAssert(index < _NameList->numberOfRDNs, @"index >= number of names");

    bcopy(&(_NameList->RelativeDistinguishedName[index + 1]), &(_NameList->RelativeDistinguishedName[index]), sizeof(CSSM_X509_RDN) * (_NameList->numberOfRDNs - (index + 1)));

    --(_NameList->numberOfRDNs);
}

- (void)addName:(DistinguishedName*)name {
    CSSM_X509_RDN *newList;

    if (_NameList->numberOfRDNs == _capacity) { // need to allocate more space for new entry
        _capacity += 5;

        newList = calloc(_capacity, sizeof(CSSM_X509_RDN));
        memcpy(newList, _NameList->RelativeDistinguishedName, sizeof(CSSM_X509_RDN) * _NameList->numberOfRDNs);

        free(_NameList->RelativeDistinguishedName);
        _NameList->RelativeDistinguishedName = newList;
    }

    _NameList->RelativeDistinguishedName[_NameList->numberOfRDNs] = *[name distinguishedNameRef];
    ++(_NameList->numberOfRDNs);
}

- (uint32_t)numberOfNames {
    return _NameList->numberOfRDNs;
}

- (NSEnumerator*)nameEnumerator {
    return [NameListEnumerator enumeratorForNameList:self];
}

- (NSString*)description {
    unsigned int i;
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:(_NameList->numberOfRDNs * 150)];

    for (i = 0; i < _NameList->numberOfRDNs; ++i) {
        [result appendString:[[DistinguishedName distinguishedNameWithRawRef:&(_NameList->RelativeDistinguishedName[i]) freeWhenDone:NO] description]];
        
        if (i < (_NameList->numberOfRDNs - 1)) {
            [result appendString:@"\n"];
        }
    }

    return [result autorelease];
}

- (CSSM_X509_NAME*)nameListRef {
    return _NameList;
}

- (void)dealloc {
    //PDEBUG(@"NameList::dealloc called with freeWhenDone == %@.\n", freeWhenDone ? @"YES" : @"NO");

    if (freeWhenDone) {
        free(_NameList);
    }

    [super dealloc];
}

@end


@implementation DistinguishedNameEnumerator

+ (DistinguishedNameEnumerator*)enumeratorForDistinguishedName:(DistinguishedName*)name {
    return [[[[self class] alloc] initWithDistinguishedName:name] autorelease];
}

- (DistinguishedNameEnumerator*)initWithDistinguishedName:(DistinguishedName*)name {
    if (self = [super init]) {
        if (name) {
            _name = [name retain];
            _index = 0;
        } else {
            [self release];
            return nil;
        }
    }
    
    return self;
}

// is allObjects supposed to return nil or an empty array, in the case that it has finished enumerating the list?
- (NSArray*)allObjects {
    NSMutableArray *result;
    int resultCount = [_name numberOfEntries] - _index;
    uint32_t i;

    if (resultCount > 0) {
        result = [[NSMutableArray alloc] initWithCapacity:resultCount];

        for (i = _index; i < [_name numberOfEntries]; ++i) {
            [result addObject:[_name entryAtIndex:i]];
        }

        _index += resultCount;

        return [result autorelease];
    } else {
        return nil;
    }
}

- (TypeValuePair*)nextObject {
    if ([_name numberOfEntries] > _index) {
        return [_name entryAtIndex:(_index++)];
    } else {
        return nil;
    }
}

- (void)dealloc {
    [_name release];

    [super dealloc];
}

@end


@implementation DistinguishedName

+ (DistinguishedName*)distinguishedNameWithRawRef:(CSSM_X509_RDN*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithDistinguishedNameRef:ref freeWhenDone:fre] autorelease];
}

+ (DistinguishedName*)distinguishedNameWithTypeValuePairs:(NSArray*)arrayOfPairs {
    return [[[[self class] alloc] initWithTypeValuePairs:arrayOfPairs] autorelease];
}

+ (DistinguishedName*)distinguishedNameWithTypeValuePair:(TypeValuePair*)value {
    return [[[[self class] alloc] initWithTypeValuePair:value] autorelease];
}

// Use of the following class method is currently disallowed, as Apple's CL module has issues with having more than one TypeValuePair per DistinguishedName, and there may also be existing real world systems which don't cope well with this fact.  Use the equivelant NameList class method.
/*+ (DistinguishedName*)distinguishedNameWithCommonName:(NSString*)commonName organisation:(NSString*)organisation country:(NSString*)country state:(NSString*)state {
    return [[[[self class] alloc] initWithCommonName:commonName organisation:organisation country:country state:state] autorelease];
}*/

- (DistinguishedName*)initWithDistinguishedNameRef:(CSSM_X509_RDN*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _DistinguishedName = ref;
        _capacity = _DistinguishedName->numberOfPairs;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (DistinguishedName*)initWithTypeValuePairs:(NSArray*)arrayOfPairs {
    NSEnumerator *enumerator;
    id current;
    
    if (arrayOfPairs) {
        _DistinguishedName = calloc(1, sizeof(CSSM_X509_RDN));
        freeWhenDone = YES;

        enumerator = [arrayOfPairs objectEnumerator];

        while (current = [enumerator nextObject]) {
            if ([current isKindOfClass:[TypeValuePair class]]) {
                [self addEntry:(TypeValuePair*)current];
            }
        }
        
        return self;
    } else {
        [self release];
        return nil;
    }
}

- (DistinguishedName*)initWithTypeValuePair:(TypeValuePair*)value {
    if (value) {
        _DistinguishedName = calloc(1, sizeof(CSSM_X509_RDN));
        freeWhenDone = YES;

        [self addEntry:value];

        return self;
    } else {
        [self release];
        return nil;
    }
}

// Use of the following instance method is currently disallowed, as Apple's CL module has issues with having more than one TypeValuePair per DistinguishedName, and there may also be existing real world systems which don't cope well with this fact.  Use the equivelant NameList instance method.
/*- (DistinguishedName*)initWithCommonName:(NSString*)commonName organisation:(NSString*)organisation country:(NSString*)country state:(NSString*)state {    
    return [self initWithTypeValuePairs:[NSArray arrayWithObjects:[TypeValuePair pairWithType:&CSSMOID_CommonName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(commonName)], [TypeValuePair pairWithType:&CSSMOID_OrganizationName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(organisation)], [TypeValuePair pairWithType:&CSSMOID_CountryName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(country)], [TypeValuePair pairWithType:&CSSMOID_StateProvinceName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(state)], nil]];
}*/

- (TypeValuePair*)firstPairForType:(const CSSM_OID*)type {
    unsigned int i;
    TypeValuePair *thePair = nil;

    for (i = 0; (i < _DistinguishedName->numberOfPairs) && (thePair == nil); ++i) {
        thePair = [[TypeValuePair pairWithRawRef:&(_DistinguishedName->AttributeTypeAndValue[i]) freeWhenDone:NO] retain];

        if (!OIDsAreEqual([thePair type], type)) {
            [thePair release];
            thePair = nil;
        }
    }

    return [thePair autorelease];
}

- (TypeValuePair*)entryAtIndex:(uint32_t)index {
    NSAssert(index >= 0, @"index < 0");
    NSAssert(index < _DistinguishedName->numberOfPairs, @"index >= number of pairs");

    return [TypeValuePair pairWithRawRef:&(_DistinguishedName->AttributeTypeAndValue[index]) freeWhenDone:NO];
}

- (void)removeEntryAtIndex:(uint32_t)index {
    NSAssert(index >= 0, @"index < 0");
    NSAssert(index < _DistinguishedName->numberOfPairs, @"index >= number of pairs");

    bcopy(&(_DistinguishedName->AttributeTypeAndValue[index + 1]), &(_DistinguishedName->AttributeTypeAndValue[index]), sizeof(CSSM_X509_TYPE_VALUE_PAIR) * (_DistinguishedName->numberOfPairs - (index + 1)));

    --(_DistinguishedName->numberOfPairs);
}

- (void)addEntry:(TypeValuePair*)entry {
    CSSM_X509_TYPE_VALUE_PAIR *newList;

    if (_DistinguishedName->numberOfPairs > 1) {
        PDEBUG(@"Warning: While technically valid, using more than 1 TypeValuePair per DistinguishedName may confuse some implementations, and may not be supported by some CDSA components (e.g. Apple's CL module).\n");
    }

    if (_DistinguishedName->numberOfPairs == _capacity) { // need to allocate more space for new entry
        _capacity += 5;

        newList = calloc(_capacity, sizeof(CSSM_X509_TYPE_VALUE_PAIR));
        memcpy(newList, _DistinguishedName->AttributeTypeAndValue, sizeof(CSSM_X509_TYPE_VALUE_PAIR) * _DistinguishedName->numberOfPairs);

        free(_DistinguishedName->AttributeTypeAndValue);
        _DistinguishedName->AttributeTypeAndValue = newList;
    }

    _DistinguishedName->AttributeTypeAndValue[_DistinguishedName->numberOfPairs] = *[entry typeValuePairRef];
    ++(_DistinguishedName->numberOfPairs);
}

- (uint32_t)numberOfEntries {
    return _DistinguishedName->numberOfPairs;
}

- (NSEnumerator*)fieldEnumerator {
    return [DistinguishedNameEnumerator enumeratorForDistinguishedName:self];
}

- (NSString*)description {
    unsigned int i;
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:(_DistinguishedName->numberOfPairs * 25)];
    
    for (i = 0; i < _DistinguishedName->numberOfPairs; ++i) {
        [result appendString:[[TypeValuePair pairWithRawRef:&(_DistinguishedName->AttributeTypeAndValue[i]) freeWhenDone:NO] description]];
        
        if (i < (_DistinguishedName->numberOfPairs - 1)) {
            [result appendString:@"\n"];
        }
    }

    return [result autorelease];
}

- (CSSM_X509_RDN*)distinguishedNameRef {
    return _DistinguishedName;
}

- (void)dealloc {
    //PDEBUG(@"DistinguishedName::dealloc called with freeWhenDone == %@.\n", freeWhenDone ? @"YES" : @"NO");

    if (freeWhenDone) {
        free(_DistinguishedName);
    }

    [super dealloc];
}

@end


@implementation TypeValuePair

+ (NSArray*)supportedTypes {
    static NSArray *theArray;

    if (!theArray) {
        theArray = [NSArray arrayWithObjects:@"Common Name", @"Organisation", @"Country", @"State", @"Surname", @"Serial Number", @"Locality", @"Collective State", @"Street Address", @"Collective Street Address", @"Collective Organisation Name", @"Organisational Unit Name", @"Collective Organisational Unit Name", @"Title", @"Description", @"Business Category", @"Postal Address", @"Collective Postal Address", @"Postcode", @"Collective Postcode", @"Post Office Box", @"Collective Post Office Box", @"Physical Delivery Office Name", @"Collective Physical Delivery Office Name", @"Telephone Number", @"Collective Telephone Number", @"Fax Number", @"Collective Fax Telephone Number", @"Name", @"Given Name", @"Initials", @"Email Address", @"Unstructured Name", @"Unstructured Address", nil];
    }

    return theArray;
}

+ (TypeValuePair*)pairWithRawRef:(CSSM_X509_TYPE_VALUE_PAIR*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithTypeValuePairRef:ref freeWhenDone:fre] autorelease];
}

+ (TypeValuePair*)pairWithType:(const CSSM_OID*)type valueType:(CSSM_BER_TAG)valueType value:(NSData*)value {
    return [[[[self class] alloc] initWithType:(const CSSM_OID*)type valueType:(CSSM_BER_TAG)valueType value:(NSData*)value] autorelease];
}

+ (TypeValuePair*)pairFromType:(NSString*)type valueType:(CSSM_BER_TAG)valueType value:(NSData*)value {
    const char *string = [type UTF8String];
    size_t stringLength = strlen(string);

    if (stringLength > 0) {
        switch (toupper(string[0])) {
            case 'B':
                if ([type isEqualToString:@"Business Category"]) {
                    return [[self class] pairWithType:&CSSMOID_BusinessCategory valueType:valueType value:value];
                }

                break;
            case 'C':
                if (stringLength > 2) {
                    switch (toupper(string[2])) {
                        case 'L':
                            if (stringLength > 11) {
                                switch (toupper(string[11])) {
                                    case 'F':
                                        if ([type isEqualToString:@"Collective Fax Number"]) {
                                            return [[self class] pairWithType:&CSSMOID_CollectiveFacsimileTelephoneNumber valueType:valueType value:value];
                                        }

                                        break;
                                    case 'O':
                                        if (stringLength > 23) {
                                            switch (toupper(string[23])) {
                                                case ' ':
                                                    if ([type isEqualToString:@"Collective Organisation Name"]) {
                                                        return [[self class] pairWithType:&CSSMOID_CollectiveOrganizationName valueType:valueType value:value];
                                                    }

                                                    break;
                                                case 'A':
                                                    if ([type isEqualToString:@"Collective Organisational Unit Name"]) {
                                                        return [[self class] pairWithType:&CSSMOID_CollectiveOrganizationalUnitName valueType:valueType value:value];
                                                    }

                                                    break;
                                            }
                                        }

                                        break;
                                    case 'P':
                                        if (stringLength > 12) {
                                            switch (toupper(string[12])) {
                                                case 'H':
                                                    if ([type isEqualToString:@"Collective Physical Delivery Office Name"]) {
                                                        return [[self class] pairWithType:&CSSMOID_CollectivePhysicalDeliveryOfficeName valueType:valueType value:value];
                                                    }

                                                    break;
                                                case 'O':
                                                    if (stringLength > 15) {
                                                        switch (toupper(string[15])) {
                                                            case 'A':
                                                                if ([type isEqualToString:@"Collective Postal Address"]) {
                                                                    return [[self class] pairWithType:&CSSMOID_CollectivePostalAddress valueType:valueType value:value];
                                                                }

                                                                break;
                                                            case 'C':
                                                                if ([type isEqualToString:@"Collective Postcode"]) {
                                                                    return [[self class] pairWithType:&CSSMOID_CollectivePostalCode valueType:valueType value:value];
                                                                }

                                                                break;
                                                            case ' ':
                                                                if ([type isEqualToString:@"Collective Post Office Box"]) {
                                                                    return [[self class] pairWithType:&CSSMOID_CollectivePostOfficeBox valueType:valueType value:value];
                                                                }

                                                                break;
                                                        }
                                                    }

                                                        break;
                                                    
                                            }
                                        }

                                        break;
                                    case 'S':
                                        if (stringLength > 13) {
                                            switch (toupper(string[13])) {
                                                case 'A':
                                                    if ([type isEqualToString:@"Collective State Name"]) {
                                                        return [[self class] pairWithType:&CSSMOID_CollectiveStateProvinceName valueType:valueType value:value];
                                                    }

                                                    break;
                                                case 'R':
                                                    if ([type isEqualToString:@"Collective Street Address"]) {
                                                        return [[self class] pairWithType:&CSSMOID_CollectiveStreetAddress valueType:valueType value:value];
                                                    }

                                                    break;
                                            }
                                        }

                                        break;
                                    case 'T':
                                        if ([type isEqualToString:@"Collective Telephone Number"]) {
                                            return [[self class] pairWithType:&CSSMOID_CollectiveTelephoneNumber valueType:valueType value:value];
                                        }

                                        break;
                                }
                            }

                            break;
                        case 'M':
                            if ([type isEqualToString:@"Common Name"]) {
                                return [[self class] pairWithType:&CSSMOID_CommonName valueType:valueType value:value];
                            }

                            break;
                        case 'U':
                            if ([type isEqualToString:@"Country"]) {
                                return [[self class] pairWithType:&CSSMOID_CountryName valueType:valueType value:value];
                            }

                            break;
                    }
                }

                break;
            case 'D':
                if ([type isEqualToString:@"Description"]) {
                    return [[self class] pairWithType:&CSSMOID_Description valueType:valueType value:value];
                }

                break;
            case 'E':
                if ([type isEqualToString:@"Email Address"]) {
                    return [[self class] pairWithType:&CSSMOID_EmailAddress valueType:valueType value:value];
                }

                break;
            case 'F':
                if ([type isEqualToString:@"Fax Number"]) {
                    return [[self class] pairWithType:&CSSMOID_FacsimileTelephoneNumber valueType:valueType value:value];
                }

                break;
            case 'G':
                if ([type isEqualToString:@"Given Name"]) {
                    return [[self class] pairWithType:&CSSMOID_GivenName valueType:valueType value:value];
                }

                break;
            case 'I':
                if ([type isEqualToString:@"Initials"]) {
                    return [[self class] pairWithType:&CSSMOID_Initials valueType:valueType value:value];
                }

                break;
            case 'L':
                if ([type isEqualToString:@"Locality"]) {
                    return [[self class] pairWithType:&CSSMOID_LocalityName valueType:valueType value:value];
                }

                break;
            case 'N':
                if ([type isEqualToString:@"Name"]) {
                    return [[self class] pairWithType:&CSSMOID_Name valueType:valueType value:value];
                }

                break;
            case 'O':
                if (stringLength > 12) {
                    if ([type isEqualToString:@"Organisational Unit Name"]) {
                        return [[self class] pairWithType:&CSSMOID_OrganizationalUnitName valueType:valueType value:value];
                    }
                } else {
                    if ([type isEqualToString:@"Organisation"]) {
                        return [[self class] pairWithType:&CSSMOID_OrganizationName valueType:valueType value:value];
                    }
                }

                break;
            case 'P':
                if (stringLength > 1) {
                    switch (toupper(string[1])) {
                        case 'H':
                            if ([type isEqualToString:@"Physical Delivery Office Name"]) {
                                return [[self class] pairWithType:&CSSMOID_PhysicalDeliveryOfficeName valueType:valueType value:value];
                            }

                            break;
                        case 'O':
                            if (stringLength > 4) {
                                switch (toupper(string[4])) {
                                    case 'A':
                                        if ([type isEqualToString:@"Postal Address"]) {
                                            return [[self class] pairWithType:&CSSMOID_PostalAddress valueType:valueType value:value];
                                        }

                                        break;
                                    case 'C':
                                        if ([type isEqualToString:@"Postcode"]) {
                                            return [[self class] pairWithType:&CSSMOID_PostalCode valueType:valueType value:value];
                                        }

                                        break;
                                    case ' ':
                                        if ([type isEqualToString:@"Post Office Box"]) {
                                            return [[self class] pairWithType:&CSSMOID_PostOfficeBox valueType:valueType value:value];
                                        }

                                        break;
                                }
                            }

                            break;
                    }
                }

                
                
                break;
            case 'S':
                if (stringLength > 1) {
                    switch (toupper(string[1])) {
                        case 'E':
                            if ([type isEqualToString:@"Serial Number"]) {
                                return [[self class] pairWithType:&CSSMOID_SerialNumber valueType:valueType value:value];
                            }

                            break;
                        case 'T':
                            if (stringLength > 2) {
                                switch (toupper(string[2])) {
                                    case 'A':
                                        if ([type isEqualToString:@"State"]) {
                                            return [[self class] pairWithType:&CSSMOID_StateProvinceName valueType:valueType value:value];
                                        }

                                        break;
                                    case 'R':
                                        if ([type isEqualToString:@"Street Address"]) {
                                            return [[self class] pairWithType:&CSSMOID_StreetAddress valueType:valueType value:value];
                                        }

                                        break;
                                }
                            }
                        case 'U':
                            if ([type isEqualToString:@"Surname"]) {
                                return [[self class] pairWithType:&CSSMOID_Surname valueType:valueType value:value];
                            }

                            break;
                    }
                }
                
                break;
            case 'T':
                if (stringLength > 1) {
                    switch (toupper(string[1])) {
                        case 'E':
                            if ([type isEqualToString:@"Telephone Number"]) {
                                return [[self class] pairWithType:&CSSMOID_TelephoneNumber valueType:valueType value:value];
                            }

                            break;
                        case 'I':
                            if ([type isEqualToString:@"Title"]) {
                                return [[self class] pairWithType:&CSSMOID_Title valueType:valueType value:value];
                            }

                            break;
                    }
                }

                break;
            case 'U':
                if (stringLength > 13) {
                    switch (toupper(string[13])) {
                        case 'A':
                            if ([type isEqualToString:@"Unstructured Address"]) {
                                return [[self class] pairWithType:&CSSMOID_UnstructuredAddress valueType:valueType value:value];
                            }

                            break;
                        case 'N':
                            if ([type isEqualToString:@"Unstructured Name"]) {
                                return [[self class] pairWithType:&CSSMOID_UnstructuredName valueType:valueType value:value];
                            }

                            break;
                    }
                }

                break;
        }
    }

    PDEBUG(@"Unknown pair type, \"%@\".", type);
    
    return nil;
}

+ (TypeValuePair*)pairForCommonName:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_CommonName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForOrganisation:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_OrganizationName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForCountry:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_CountryName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForState:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_StateProvinceName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForSurname:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_Surname valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForSerialNumber:(uint32_t)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_SerialNumber valueType:BER_TAG_INTEGER value:NSDataForDERFormattedInteger(value)] autorelease];
}

+ (TypeValuePair*)pairForLocality:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_LocalityName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForCollectiveStateName:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_CollectiveStateProvinceName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForStreetAddress:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_StreetAddress valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForCollectiveStreetAddress:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_CollectiveStreetAddress valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForCollectiveOrganisationName:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_CollectiveOrganizationName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForOrganisationalUnitName:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_OrganizationalUnitName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForCollectiveOrganisationalUnitName:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_CollectiveOrganizationalUnitName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForTitle:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_Title valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForDescription:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_Description valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForBusinessCategory:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_BusinessCategory valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForPostalAddress:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_PostalAddress valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForCollectivePostalAddress:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_CollectivePostalAddress valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForPostcode:(uint32_t)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_PostalCode valueType:BER_TAG_INTEGER value:NSDataForDERFormattedInteger(value)] autorelease];
}

+ (TypeValuePair*)pairForCollectivePostcode:(uint32_t)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_CollectivePostalCode valueType:BER_TAG_INTEGER value:NSDataForDERFormattedInteger(value)] autorelease];
}

+ (TypeValuePair*)pairForPostOfficeBox:(uint32_t)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_PostOfficeBox valueType:BER_TAG_INTEGER value:NSDataForDERFormattedInteger(value)] autorelease];
}

+ (TypeValuePair*)pairForCollectivePostOfficeBox:(uint32_t)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_CollectivePostOfficeBox valueType:BER_TAG_INTEGER value:NSDataForDERFormattedInteger(value)] autorelease];
}

+ (TypeValuePair*)pairForPhysicalDeliveryOfficeName:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_PhysicalDeliveryOfficeName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForCollectivePhysicalDeliveryOfficeName:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_CollectivePhysicalDeliveryOfficeName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForTelephoneNumber:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_TelephoneNumber valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForCollectiveTelephoneNumber:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_CollectiveTelephoneNumber valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForFaxNumber:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_FacsimileTelephoneNumber valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForCollectiveFaxNumber:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_CollectiveFacsimileTelephoneNumber valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForName:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_Name valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForGivenName:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_GivenName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForInitials:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_Initials valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForEmailAddress:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_EmailAddress valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForUnstructuredName:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_UnstructuredName valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

+ (TypeValuePair*)pairForUnstructuredAddress:(NSString*)value {
    return [[[[self class] alloc] initWithType:&CSSMOID_UnstructuredAddress valueType:BER_TAG_PRINTABLE_STRING value:NSDataFromNSString(value)] autorelease];
}

// I don't know how to handle the following OID's, because I don't know what data type they should be
//CSSMOID_ObjectClass,
//CSSMOID_AliasedEntryName,
//CSSMOID_KnowledgeInformation,
//CSSMOID_SearchGuide,
//CSSMOID_TelexNumber
//CSSMOID_CollectiveTelexNumber,
//CSSMOID_TelexTerminalIdentifier,
//CSSMOID_CollectiveTelexTerminalIdentifier,
//CSSMOID_X_121Address,
//CSSMOID_InternationalISDNNumber,
//CSSMOID_CollectiveInternationalISDNNumber,
//CSSMOID_RegisteredAddress,
//CSSMOID_DestinationIndicator,
//CSSMOID_PreferredDeliveryMethod,
//CSSMOID_PresentationAddress,
//CSSMOID_SupportedApplicationContext,
//CSSMOID_Member,
//CSSMOID_Owner,
//CSSMOID_RoleOccupant,
//CSSMOID_SeeAlso,
//CSSMOID_UserPassword,
//CSSMOID_UserCertificate,
//CSSMOID_CACertificate,
//CSSMOID_AuthorityRevocationList,
//CSSMOID_CertificateRevocationList,
//CSSMOID_CrossCertificatePair,
//CSSMOID_GenerationQualifier,
//CSSMOID_UniqueIdentifier,
//CSSMOID_DNQualifier,
//CSSMOID_EnhancedSearchGuide,
//CSSMOID_ProtocolInformation,
//CSSMOID_DistinguishedName,
//CSSMOID_UniqueMember,
//CSSMOID_HouseIdentifier;
//CSSMOID_ContentType,
//CSSMOID_MessageDigest,
//CSSMOID_SigningTime,
//CSSMOID_CounterSignature,
//CSSMOID_ChallengePassword,
//CSSMOID_ExtendedCertificateAttributes;
//CSSMOID_QT_CPS,
//CSSMOID_QT_UNOTICE

- (TypeValuePair*)initWithTypeValuePairRef:(CSSM_X509_TYPE_VALUE_PAIR*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _TypeValuePair = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (TypeValuePair*)initWithType:(const CSSM_OID*)type valueType:(CSSM_BER_TAG)valueType value:(NSData*)value {
    freeWhenDone = YES;

    _TypeValuePair = calloc(1, sizeof(CSSM_X509_TYPE_VALUE_PAIR));
    
    _TypeValuePair->type = *type;
    _TypeValuePair->valueType = valueType;
    copyNSDataToData(value, &(_TypeValuePair->value));

    return self;
}

- (void)setType:(const CSSM_OID*)type {
    if (type) {
        _TypeValuePair->type = *type; // should just byte-copy the struct
    }
}

- (const CSSM_OID*)type {
    return &(_TypeValuePair->type); // obviously you could thus change this; but you shouldn't
}

- (BOOL)isCommonName {
    return OIDsAreEqual(&CSSMOID_CommonName, &(_TypeValuePair->type));
}

- (BOOL)isOrganisation {
    return OIDsAreEqual(&CSSMOID_OrganizationName, &(_TypeValuePair->type));
}

- (BOOL)isCountry {
    return OIDsAreEqual(&CSSMOID_CountryName, &(_TypeValuePair->type));
}

- (BOOL)isState {
    return OIDsAreEqual(&CSSMOID_StateProvinceName, &(_TypeValuePair->type));
}

- (BOOL)isSurname {
    return OIDsAreEqual(&CSSMOID_Surname, &(_TypeValuePair->type));
}

- (BOOL)isSerialNumber {
    return OIDsAreEqual(&CSSMOID_SerialNumber, &(_TypeValuePair->type));
}

- (BOOL)isLocality {
    return OIDsAreEqual(&CSSMOID_LocalityName, &(_TypeValuePair->type));
}

- (BOOL)isCollectiveStateName {
    return OIDsAreEqual(&CSSMOID_CollectiveStateProvinceName, &(_TypeValuePair->type));
}

- (BOOL)isStreetAddress {
    return OIDsAreEqual(&CSSMOID_StreetAddress, &(_TypeValuePair->type));
}

- (BOOL)isCollectiveStreetAddress {
    return OIDsAreEqual(&CSSMOID_CollectiveStreetAddress, &(_TypeValuePair->type));
}

- (BOOL)isCollectiveOrganisationName {
    return OIDsAreEqual(&CSSMOID_CollectiveOrganizationName, &(_TypeValuePair->type));
}

- (BOOL)isOrganisationalUnitName {
    return OIDsAreEqual(&CSSMOID_OrganizationalUnitName, &(_TypeValuePair->type));
}

- (BOOL)isCollectiveOrganisationalUnitName {
    return OIDsAreEqual(&CSSMOID_CollectiveOrganizationalUnitName, &(_TypeValuePair->type));
}

- (BOOL)isTitle {
    return OIDsAreEqual(&CSSMOID_Title, &(_TypeValuePair->type));
}

- (BOOL)isDescription {
    return OIDsAreEqual(&CSSMOID_Description, &(_TypeValuePair->type));
}

- (BOOL)isBusinessCategory {
    return OIDsAreEqual(&CSSMOID_BusinessCategory, &(_TypeValuePair->type));
}

- (BOOL)isPostalAddress {
    return OIDsAreEqual(&CSSMOID_PostalAddress, &(_TypeValuePair->type));
}

- (BOOL)isCollectivePostalAddress {
    return OIDsAreEqual(&CSSMOID_CollectivePostalAddress, &(_TypeValuePair->type));
}

- (BOOL)isPostalCode {
    return OIDsAreEqual(&CSSMOID_PostalCode, &(_TypeValuePair->type));
}

- (BOOL)isCollectivePostalCode {
    return OIDsAreEqual(&CSSMOID_CollectivePostalCode, &(_TypeValuePair->type));
}

- (BOOL)isPostOfficeBox {
    return OIDsAreEqual(&CSSMOID_PostOfficeBox, &(_TypeValuePair->type));
}

- (BOOL)isCollectivePostOfficeBox {
    return OIDsAreEqual(&CSSMOID_CollectivePostOfficeBox, &(_TypeValuePair->type));
}

- (BOOL)isPhysicalDeliveryOfficeName {
    return OIDsAreEqual(&CSSMOID_PhysicalDeliveryOfficeName, &(_TypeValuePair->type));
}

- (BOOL)isCollectivePhysicalDeliveryOfficeName {
    return OIDsAreEqual(&CSSMOID_CollectivePhysicalDeliveryOfficeName, &(_TypeValuePair->type));
}

- (BOOL)isTelephoneNumber {
    return OIDsAreEqual(&CSSMOID_TelephoneNumber, &(_TypeValuePair->type));
}

- (BOOL)isCollectiveTelephoneNumber {
    return OIDsAreEqual(&CSSMOID_CollectiveTelephoneNumber, &(_TypeValuePair->type));
}

- (BOOL)isFaxNumber {
    return OIDsAreEqual(&CSSMOID_FacsimileTelephoneNumber, &(_TypeValuePair->type));
}

- (BOOL)isCollectiveFaxNumber {
    return OIDsAreEqual(&CSSMOID_CollectiveFacsimileTelephoneNumber, &(_TypeValuePair->type));
}

- (BOOL)isName {
    return OIDsAreEqual(&CSSMOID_Name, &(_TypeValuePair->type));
}

- (BOOL)isGivenName {
    return OIDsAreEqual(&CSSMOID_GivenName, &(_TypeValuePair->type));
}

- (BOOL)isInitials {
    return OIDsAreEqual(&CSSMOID_Initials, &(_TypeValuePair->type));
}

- (BOOL)isEmailAddress {
    return OIDsAreEqual(&CSSMOID_EmailAddress, &(_TypeValuePair->type));
}

- (BOOL)isUnstructuredName {
    return OIDsAreEqual(&CSSMOID_UnstructuredName, &(_TypeValuePair->type));
}

- (BOOL)isUnstructuredAddress {
    return OIDsAreEqual(&CSSMOID_UnstructuredAddress, &(_TypeValuePair->type));
}

- (BOOL)isObjectClass {
    return OIDsAreEqual(&CSSMOID_ObjectClass, &(_TypeValuePair->type));
}

- (BOOL)isAliasedEntryName {
    return OIDsAreEqual(&CSSMOID_AliasedEntryName, &(_TypeValuePair->type));
}

- (BOOL)isKnowledgeInformation {
    return OIDsAreEqual(&CSSMOID_KnowledgeInformation, &(_TypeValuePair->type));
}

- (BOOL)isSearchGuide {
    return OIDsAreEqual(&CSSMOID_SearchGuide, &(_TypeValuePair->type));
}

- (BOOL)isTelexNumber {
    return OIDsAreEqual(&CSSMOID_TelexNumber, &(_TypeValuePair->type));
}

- (BOOL)isCollectiveTelexNumber {
    return OIDsAreEqual(&CSSMOID_CollectiveTelexNumber, &(_TypeValuePair->type));
}

- (BOOL)isTelexTerminalIdentifier {
    return OIDsAreEqual(&CSSMOID_TelexTerminalIdentifier, &(_TypeValuePair->type));
}

- (BOOL)isCollectiveTelexTerminalIdentifier {
    return OIDsAreEqual(&CSSMOID_CollectiveTelexTerminalIdentifier, &(_TypeValuePair->type));
}

- (BOOL)isX121Address {
    return OIDsAreEqual(&CSSMOID_X_121Address, &(_TypeValuePair->type));
}

- (BOOL)isInternationalISDNNumber {
    return OIDsAreEqual(&CSSMOID_InternationalISDNNumber, &(_TypeValuePair->type));
}

- (BOOL)isCollectiveInternationalISDNNumber {
    return OIDsAreEqual(&CSSMOID_CollectiveInternationalISDNNumber, &(_TypeValuePair->type));
}

- (BOOL)isRegisteredAddress {
    return OIDsAreEqual(&CSSMOID_RegisteredAddress, &(_TypeValuePair->type));
}

- (BOOL)isDestinationIndicator {
    return OIDsAreEqual(&CSSMOID_DestinationIndicator, &(_TypeValuePair->type));
}

- (BOOL)isPreferredDeliveryMethod {
    return OIDsAreEqual(&CSSMOID_PreferredDeliveryMethod, &(_TypeValuePair->type));
}

- (BOOL)isPresentationAddress {
    return OIDsAreEqual(&CSSMOID_PresentationAddress, &(_TypeValuePair->type));
}

- (BOOL)isSupportedApplicationContext {
    return OIDsAreEqual(&CSSMOID_SupportedApplicationContext, &(_TypeValuePair->type));
}

- (BOOL)isMember {
    return OIDsAreEqual(&CSSMOID_Member, &(_TypeValuePair->type));
}

- (BOOL)isOwner {
    return OIDsAreEqual(&CSSMOID_Owner, &(_TypeValuePair->type));
}

- (BOOL)isRoleOccupant {
    return OIDsAreEqual(&CSSMOID_RoleOccupant, &(_TypeValuePair->type));
}

- (BOOL)isSeeAlso {
    return OIDsAreEqual(&CSSMOID_SeeAlso, &(_TypeValuePair->type));
}

- (BOOL)isUserPassword {
    return OIDsAreEqual(&CSSMOID_UserPassword, &(_TypeValuePair->type));
}

- (BOOL)isUserCertificate {
    return OIDsAreEqual(&CSSMOID_UserCertificate, &(_TypeValuePair->type));
}

- (BOOL)isCACertificate {
    return OIDsAreEqual(&CSSMOID_CACertificate, &(_TypeValuePair->type));
}

- (BOOL)isAuthorityRevocationList {
    return OIDsAreEqual(&CSSMOID_AuthorityRevocationList, &(_TypeValuePair->type));
}

- (BOOL)isCertificateRevocationList {
    return OIDsAreEqual(&CSSMOID_CertificateRevocationList, &(_TypeValuePair->type));
}

- (BOOL)isCrossCertificatePair {
    return OIDsAreEqual(&CSSMOID_CrossCertificatePair, &(_TypeValuePair->type));
}

- (BOOL)isGenerationQualifier {
    return OIDsAreEqual(&CSSMOID_GenerationQualifier, &(_TypeValuePair->type));
}

- (BOOL)isUniqueIdentifier {
    return OIDsAreEqual(&CSSMOID_UniqueIdentifier, &(_TypeValuePair->type));
}

- (BOOL)isDNQualifier {
    return OIDsAreEqual(&CSSMOID_DNQualifier, &(_TypeValuePair->type));
}

- (BOOL)isEnhancedSearchGuide {
    return OIDsAreEqual(&CSSMOID_EnhancedSearchGuide, &(_TypeValuePair->type));
}

- (BOOL)isProtocolInformation {
    return OIDsAreEqual(&CSSMOID_ProtocolInformation, &(_TypeValuePair->type));
}

- (BOOL)isDistinguishedName {
    return OIDsAreEqual(&CSSMOID_DistinguishedName, &(_TypeValuePair->type));
}

- (BOOL)isUniqueMember {
    return OIDsAreEqual(&CSSMOID_UniqueMember, &(_TypeValuePair->type));
}

- (BOOL)isHouseIdentifier {
    return OIDsAreEqual(&CSSMOID_HouseIdentifier, &(_TypeValuePair->type));
}

- (BOOL)isContentType {
    return OIDsAreEqual(&CSSMOID_ContentType, &(_TypeValuePair->type));
}

- (BOOL)isMessageDigest {
    return OIDsAreEqual(&CSSMOID_MessageDigest, &(_TypeValuePair->type));
}

- (BOOL)isSigningTime {
    return OIDsAreEqual(&CSSMOID_SigningTime, &(_TypeValuePair->type));
}

- (BOOL)isCounterSignature {
    return OIDsAreEqual(&CSSMOID_CounterSignature, &(_TypeValuePair->type));
}

- (BOOL)isChallengePassword {
    return OIDsAreEqual(&CSSMOID_ChallengePassword, &(_TypeValuePair->type));
}

- (BOOL)isExtendedCertificateAttributes {
    return OIDsAreEqual(&CSSMOID_ExtendedCertificateAttributes, &(_TypeValuePair->type));
}

- (BOOL)isQTCPS {
    return OIDsAreEqual(&CSSMOID_QT_CPS, &(_TypeValuePair->type));
}

- (BOOL)isQTUNOTICE {
    return OIDsAreEqual(&CSSMOID_QT_UNOTICE, &(_TypeValuePair->type));
}

- (void)setValueType:(CSSM_BER_TAG)valueType {
    _TypeValuePair->valueType = valueType;
}

- (CSSM_BER_TAG)valueType {
    return _TypeValuePair->valueType;
}

- (void)setValue:(NSData*)data {
    copyNSDataToData(data, &(_TypeValuePair->value));
}

- (NSData*)value {
    return NSDataFromData(&(_TypeValuePair->value));
}

- (const CSSM_DATA*)rawValue {
    return &(_TypeValuePair->value);
}

- (NSString*)description {
    if (_TypeValuePair->valueType == BER_TAG_PRINTABLE_STRING) {
        return [NSString stringWithFormat:@"%@: %@", nameOfOID(&_TypeValuePair->type), NSStringFromData(&(_TypeValuePair->value))];
    } else {
        return [NSString stringWithFormat:@"%@: (%@) %@", nameOfOID(&(_TypeValuePair->type)), nameOfBERCode(_TypeValuePair->valueType), NSDataFromData(&(_TypeValuePair->value))];
    }
}

- (CSSM_X509_TYPE_VALUE_PAIR*)typeValuePairRef {
    return _TypeValuePair;
}

- (void)dealloc {
    //PDEBUG(@"TypeValuePair::dealloc called with freeWhenDone == %@.\n", freeWhenDone ? @"YES" : @"NO");
    
    if (freeWhenDone) {
        free(_TypeValuePair);
    }

    [super dealloc];
}

@end


@implementation AlgorithmIdentifier

+ (AlgorithmIdentifier*)identifierWithRawRef:(CSSM_X509_ALGORITHM_IDENTIFIER*)ref freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithAlgorithmIdentifierRef:ref freeWhenDone:fre] autorelease];
}

+ (AlgorithmIdentifier*)identifierForAlgorithm:(CSSM_ALGORITHMS)algorithm {
    return [[[[self class] alloc] initForAlgorithm:algorithm] autorelease];
}

+ (AlgorithmIdentifier*)identifierForOIDAlgorithm:(const CSSM_OID*)algorithm {
    return [[[[self class] alloc] initForOIDAlgorithm:algorithm] autorelease];
}

- (AlgorithmIdentifier*)initWithAlgorithmIdentifierRef:(CSSM_X509_ALGORITHM_IDENTIFIER*)ref freeWhenDone:(BOOL)fre {
    if (ref) {
        _AlgorithmIdentifier = ref;
        freeWhenDone = fre;

        return self;
    } else {
        [self release];
        return nil;
    }
}

- (AlgorithmIdentifier*)initForAlgorithm:(CSSM_ALGORITHMS)algorithm {
    _AlgorithmIdentifier = calloc(1, sizeof(CSSM_X509_ALGORITHM_IDENTIFIER));
    freeWhenDone = YES;

    // The following are all valid OIDs, but without CSSM_ALGORITHMS equivelants
       /* CSSMOID_MD4WithRSA,
        CSSMOID_APPLE_ISIGN,
        CSSMOID_APPLE_X509_BASIC,
        CSSMOID_APPLE_TP_SSL,
        CSSMOID_APPLE_TP_LOCAL_CERT_GEN,
        CSSMOID_APPLE_TP_CSR_GEN,
        CSSMOID_APPLE_ASC,
        CSSMOID_APPLE_FEE_MD5,
        CSSMOID_APPLE_FEED,
        CSSMOID_APPLE_FEEDEXP */
    
    switch (algorithm) {
        case CSSM_ALGID_DH:
            _AlgorithmIdentifier->algorithm = CSSMOID_DH; break;
        case CSSM_ALGID_MD2:
            _AlgorithmIdentifier->algorithm = CSSMOID_MD2; break;
        case CSSM_ALGID_MD4:
            _AlgorithmIdentifier->algorithm = CSSMOID_MD4; break;
        case CSSM_ALGID_MD5:
            _AlgorithmIdentifier->algorithm = CSSMOID_MD5; break;
        case CSSM_ALGID_SHA1:
            _AlgorithmIdentifier->algorithm = CSSMOID_SHA1; break;
        case CSSM_ALGID_RSA:
            _AlgorithmIdentifier->algorithm = CSSMOID_RSA; break;
        case CSSM_ALGID_DSA:
            _AlgorithmIdentifier->algorithm = CSSMOID_DSA; break;
        case CSSM_ALGID_MD5WithRSA:
            _AlgorithmIdentifier->algorithm = CSSMOID_MD5WithRSA; break;
        case CSSM_ALGID_MD2WithRSA:
            _AlgorithmIdentifier->algorithm = CSSMOID_MD2WithRSA; break;
        case CSSM_ALGID_SHA1WithRSA:
            _AlgorithmIdentifier->algorithm = CSSMOID_SHA1WithRSA; break;
        case CSSM_ALGID_ECDSA:
            _AlgorithmIdentifier->algorithm = CSSMOID_APPLE_ECDSA; break;
        case CSSM_ALGID_SHA1WithDSA:
            _AlgorithmIdentifier->algorithm = CSSMOID_SHA1WithDSA; break;
        case CSSM_ALGID_FEE:
            _AlgorithmIdentifier->algorithm = CSSMOID_APPLE_FEE; break;
        case CSSM_ALGID_FEE_SHA1:
            _AlgorithmIdentifier->algorithm = CSSMOID_APPLE_FEE_SHA1; break;
        default:
            PDEBUG(@"I don't know the OID equivelant of %@.\n", nameOfAlgorithm(algorithm));
            
            [self release];
            self = nil;
    }
    
    return self;
}

- (AlgorithmIdentifier*)initForOIDAlgorithm:(const CSSM_OID*)algorithm {
    _AlgorithmIdentifier = calloc(1, sizeof(CSSM_X509_ALGORITHM_IDENTIFIER));
    freeWhenDone = YES;
    
    _AlgorithmIdentifier->algorithm = *algorithm; // should byte-copy the structure
    
    return self;
}

- (void)setAlgorithm:(const CSSM_OID*)algorithm {
    _AlgorithmIdentifier->algorithm = *algorithm; // should byte-copy the structure
}

- (const CSSM_OID*)algorithmOID {
    return &(_AlgorithmIdentifier->algorithm); // so you could write directly into the OID, but you shouldn't
}

- (CSSM_ALGORITHMS)algorithm {
    if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_DH)) {
        return CSSM_ALGID_DH;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_MD2)) {
        return CSSM_ALGID_MD2;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_MD4)) {
        return CSSM_ALGID_MD4;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_MD5)) {
        return CSSM_ALGID_MD5;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_SHA1)) {
        return CSSM_ALGID_SHA1;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_RSA)) {
        return CSSM_ALGID_RSA;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_DSA)) {
        return CSSM_ALGID_DSA;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_MD5WithRSA)) {
        return CSSM_ALGID_MD5WithRSA;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_MD2WithRSA)) {
        return CSSM_ALGID_MD2WithRSA;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_SHA1WithRSA)) {
        return CSSM_ALGID_SHA1WithRSA;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_APPLE_ECDSA)) {
        return CSSM_ALGID_ECDSA;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_SHA1WithDSA)) {
        return CSSM_ALGID_SHA1WithDSA;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_APPLE_FEE)) {
        return CSSM_ALGID_FEE;
    } else if (OIDsAreEqual(&(_AlgorithmIdentifier->algorithm), &CSSMOID_APPLE_FEE_SHA1)) {
        return CSSM_ALGID_FEE_SHA1;
    } else {
        PDEBUG(@"I don't know how to represent my algorithm as a CSSM_ALGORITHMS type.\n");
        return 0;
    }
}

- (void)setParameters:(NSData*)parameters {
    copyNSDataToData(parameters, &(_AlgorithmIdentifier->parameters));
}

- (NSData*)parameters {
    return NSDataFromData(&(_AlgorithmIdentifier->parameters));
}

- (NSString*)description {
    return x509AlgorithmAsString(_AlgorithmIdentifier);
}

- (CSSM_X509_ALGORITHM_IDENTIFIER*)algorithmIdentifierRef {
    return _AlgorithmIdentifier;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(_AlgorithmIdentifier);
    }

    [super dealloc];
}

@end