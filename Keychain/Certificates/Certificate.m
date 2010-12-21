//
//  Certificate.m
//  Keychain
//
//  Created by Wade Tregaskis on Fri Jan 24 2003.
//
//  Copyright (c) 2003 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "Certificate.h"

#import "Utilities/UtilitySupport.h"
#import "CDSA/CSSMUtils.h"
#import "Utilities/SecurityUtils.h"

#import "CDSA/CSSMTypes.h"

#import "Keychain/KeychainItem.h"
//#import "Keychain/Keychain.h"
@class Keychain;

#import "Utilities/Logging.h"


@implementation Certificate

+ (Certificate*)certificateWithCertificateRef:(SecCertificateRef)cert {
    return [[[[self class] alloc] initWithCertificateRef:cert] autorelease];
}

+ (Certificate*)certificateWithData:(NSData*)data type:(CSSM_CERT_TYPE)type encoding:(CSSM_CERT_ENCODING)encoding {
    return [[[[self class] alloc] initWithData:data type:type encoding:encoding] autorelease];
}

+ (Certificate*)certificateWithEncodedData:(CSSM_ENCODED_CERT*)encodedCert {
    return [[[[self class] alloc] initWithEncodedData:encodedCert] autorelease];
}

- (Certificate*)initWithCertificateRef:(SecCertificateRef)cert {
    Certificate *existingObject;
    
    if (cert) {
        existingObject = [[self class] instanceWithKey:(id)cert from:@selector(certificateRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            return [existingObject retain];
        } else {
            if (self = [super init]) {
                CFRetain(cert);
                certificate = cert;
            }

            return self;
        }
    } else {
        [self release];

        return nil;
    }
}

- (Certificate*)initWithData:(NSData*)data type:(CSSM_CERT_TYPE)type encoding:(CSSM_CERT_ENCODING)encoding {
    if (self = [super init]) {
        error = SecCertificateCreateFromData(dataFromNSData(data), type, encoding, &certificate);
        
        if (error != 0) {
            [self release];
            
            self = nil;
        }
    }
    
    return self;
}

- (Certificate*)initWithEncodedData:(CSSM_ENCODED_CERT*)encodedCert {
    if (encodedCert) {
        return [self initWithData:NSDataFromDataNoCopy(&(encodedCert->CertBlob), NO) type:encodedCert->CertType encoding:encodedCert->CertEncoding];
    } else {
        PDEBUG(@"'encodedCert' is nil.\n");
        return nil;
    }
}

- (Certificate*)init {
    [self release];
    return nil;
}

- (NSData*)data {
    CSSM_DATA result;

    error = SecCertificateGetData(certificate, &result);

    if (error == 0) {
        return NSDataFromData(&result);
    } else {
        return nil;
    }
}

- (CSSM_CERT_TYPE)type {
    CSSM_CERT_TYPE result;

    error = SecCertificateGetType(certificate, &result);

    if (error == 0) {
        return result;
    } else {
        return 0;
    }
}

- (CSSM_CERT_ENCODING)encoding {
    // How retarded is this - we have to convert ourselves to another object just to get our own encoding
    return [[self keychainItem] certificateEncoding];
}

- (CSSM_DATA*)rawValueOfField:(const CSSM_OID*)tag {
    if (tag) {
        //CSSM_FIELD_PTR fields;
        CSSM_DATA *rawResult;
        //uint32_t numberOfFields;
        uint32 numberOfResults;
        CSSM_DATA certData;
        CSSM_CL_HANDLE CLhandle;
        CSSM_HANDLE furtherResultsHandle;
        //int i;
        
        error = SecCertificateGetCLHandle(certificate, &CLhandle);
        
        if (error != 0) {
            return nil;
        }
        
        error = SecCertificateGetData(certificate, &certData);
        
        if (error != 0) {
            return nil;
        }
        
        error = CSSM_CL_CertGetFirstFieldValue(CLhandle, &certData, tag, &furtherResultsHandle, &numberOfResults, &rawResult);
        
        if ((error == CSSM_OK) && (numberOfResults > 0)) {
            if (numberOfResults > 1) {
                PDEBUG(@"Warning: valueOfField found multiple matches for \"%@\"; only the first was returned.\n", nameOfOID(tag));
            }
            
            return rawResult;
        }
    }
    
    return nil;
}

void freeRawField(SecCertificateRef certificate, CSSM_DATA *field, const CSSM_OID* tag) {
    if (certificate && field && tag) {
        CSSM_CL_HANDLE CLhandle;
        CSSM_RETURN error;
        
        error = SecCertificateGetCLHandle(certificate, &CLhandle);
        
        if (error != CSSM_OK) {
            PSYSLOGND(LOG_ERR, @"Cannot get CL handle needed to free the field, error %@.\n", OSStatusAsString(error));
            PDEBUG(@"SecCertificateGetCLHandle(%p, %p) returned error %@.\n", certificate, &CLhandle, OSStatusAsString(error));
        } else {
            error = CSSM_CL_FreeFieldValue(CLhandle, tag, field);
            
            if (error != CSSM_OK) {
                PSYSLOGND(LOG_WARNING, @"non-fatal error (%@) trying to free data in [Certificate freeRawField]... this may cause a minor memory leak.\n", CSSMErrorAsString(error));
                PDEBUG(@"CSSM_CL_FreeFieldValue(%"PRIclHandle", %p, %p) returned error %@.\n", CLhandle, tag, field, CSSMErrorAsString(error));
            }
        }
    }
}

- (NSData*)valueOfField:(const CSSM_OID*)tag {
    NSData *result = nil;
    
    if (tag) {
        CSSM_DATA *rawResult  = [self rawValueOfField:tag];
        
        if (rawResult) {
            result = [NSDataFromData(rawResult) retain];
            
            freeRawField(certificate, rawResult, tag);
        }
    }

    return result;
}

- (int)version {
    CSSM_DATA *result = [self rawValueOfField:&CSSMOID_X509V1Version];
    uint32_t vers;
    
    if (result) {
        if (!DERToInt(result, &vers)) {
            PDEBUG(@"Unable to convert DER form of version into integer; returning 0.\n");
            vers = 0;
        }

        freeRawField(certificate, result, &CSSMOID_X509V1Version);
        
        return (int)(vers + 1);
    } else {
        return 0;
    }
}

- (NSData*)serialNumber {
    return [self valueOfField:&CSSMOID_X509V1SerialNumber];
}

- (X509Signature*)signature {
    const CSSM_DATA *data = [self rawValueOfField:&CSSMOID_X509V1SignatureCStruct], *data2;
    
    if (data) {
        return [X509Signature signatureWithRawRef:(CSSM_X509_SIGNATURE*)(data->Data) freeWhenDone:YES];
    } else {
        data = [self rawValueOfField:&CSSMOID_X509V1SignatureAlgorithm];
        
        if (data) {
            data2 = [self rawValueOfField:&CSSMOID_X509V1Signature];
            
            if (data2) {                
                return [X509Signature signatureWithAlgorithm:[AlgorithmIdentifier identifierForOIDAlgorithm:(CSSM_OID*)(data->Data)] data:NSDataFromDataNoCopy(data2, YES)];
            } else {
                return nil;
            }
        } else {
            return nil;
        }
    }
}
        
- (Key*)publicKey {
    CSSM_DATA *theKey = [self rawValueOfField:&CSSMOID_CSSMKeyStruct];
                                   
    if (NULL == theKey) {
        PDEBUG(@"Unable to obtain CSSMOID_CSSMKeyStruct field for myself (certificate %p).\n", self);
        return nil;
    } else {
        return [Key keyWithCSSMKey:(CSSM_KEY*)(theKey->Data) module:[[self keychain] CSPModule]];
        // This probably leaks, because the key data won't be destroyed by the key instance, and we obviously don't touch it here
    }
}

- (SPKInfo*)publicKeyInfo {
    CSSM_DATA *theInfo = [self rawValueOfField:&CSSMOID_X509V1SubjectPublicKeyCStruct];
    
    if (NULL == theInfo) {
        PDEBUG(@"Unable to obtain CSSMOID_X509V1SubjectPublicKeyCStruct field for myself (certificate %p).\n", self);
        return nil;
    } else {
        return [SPKInfo infoWithRawRef:(CSSM_X509_SUBJECT_PUBLIC_KEY_INFO*)(theInfo->Data) freeWhenDone:YES];
    }
}

- (NameList*)subject {
    CSSM_DATA *theSubject = [self rawValueOfField:&CSSMOID_X509V1SubjectNameCStruct];
    
    if (NULL == theSubject) {
        PDEBUG(@"Unable to obtain CSSMOID_X509V1SubjectNameCStruct field for myself (certificate %p).\n", self);
        return nil;
    } else {
        return [NameList nameListWithRawRef:(CSSM_X509_NAME*)(theSubject->Data) freeWhenDone:YES];
    }
}

- (NameList*)issuer {
    CSSM_DATA *theIssuer = [self rawValueOfField:&CSSMOID_X509V1IssuerNameCStruct];
    
    if (NULL == theIssuer) {
        PDEBUG(@"Unable to obtain CSSMOID_X509V1IssuerNameCStruct field for myself (certificate %p).\n", self);
        return nil;
    } else {
        return [NameList nameListWithRawRef:(CSSM_X509_NAME*)(theIssuer->Data) freeWhenDone:YES];
    }
}

/*- (TBSCertificate*)TBSCertificate {
    return [TBSCertificate certificateWithRawRef:(CSSM_X509_TBS_CERTIFICATE*)[self rawValueOfField:&CSSMOID_X509V3TbsCertificateCStruct] freeWhenDone:YES];
}*/ // doesn't seem to exist, this CSSMOID_X509V3TbsCertificateCStruct type

- (SignedCertificate*)signedCertificate {
    CSSM_DATA *theCert = [self rawValueOfField:&CSSMOID_X509V3SignedCertificateCStruct];
    
    if (NULL == theCert) {
        PDEBUG(@"Unable to obtain CSSMOID_X509V3SignedCertificateCStruct field for myself (certificate %p).\n", self);
        return nil;
    } else {
        return [SignedCertificate signedCertificateWithRawRef:(CSSM_X509_SIGNED_CERTIFICATE*)(theCert->Data) freeWhenDone:YES];
    }
}

- (Validity*)validity {
    CSSM_DATA *from = [self rawValueOfField:&CSSMOID_X509V1ValidityNotBefore], *to = [self rawValueOfField:&CSSMOID_X509V1ValidityNotAfter];
    
    if ((NULL == from) || (NULL == to)) {
        PDEBUG(@"Unable to obtain CSSMOID_X509V1ValidityNotBefore and/or CSSMOID_X509V1ValidityNotAfter field (%p & %p, respectively) for myself (certificate %p).\n", from, to, self);
        return nil;
    } else {
        return [Validity validityFrom:[Time timeWithRawRef:(CSSM_X509_TIME*)(from->Data) freeWhenDone:YES] to:[Time timeWithRawRef:(CSSM_X509_TIME*)(to->Data) freeWhenDone:YES]];
    }
}

- (ExtensionList*)extensions {
    CSSM_DATA *theExtensions = [self rawValueOfField:&CSSMOID_X509V3CertificateExtensionsCStruct];
    
    if (NULL == theExtensions) {
        PDEBUG(@"Unable to obtain CSSMOID_X509V3CertificateExtensionsCStruct field for myself (certificate %p).\n", self);
        return nil;
    } else {
        return [ExtensionList listWithRawRef:(CSSM_X509_EXTENSIONS*)(theExtensions->Data) freeWhenDone:YES];
    }
}

- (NSString*)description {
    CSSM_DATA certificateData;
    uint32 numberOfFields, i;
    CSSM_FIELD_PTR fields;
    NSMutableString *result = [NSMutableString stringWithCapacity:4000];

    error = SecCertificateGetData(certificate, &certificateData);

    if (error == CSSM_OK) {
        error = CSSM_CL_CertGetAllFields([[self CLModule] handle], &certificateData, &numberOfFields, &fields);

        if (error != CSSM_OK) {
            [result appendFormat:@"Error parsing certificate in 'description' instance method, error %@.", CSSMErrorAsString(error)];
        } else {
            for (i = 0; i < numberOfFields; ++i) {
                if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3SignedCertificate)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3SignedCertificate", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3SignedCertificateCStruct)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3SignedCertificateCStruct", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3Certificate)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3Certificate", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3CertificateCStruct)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3CertificateCStruct", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1Version)) {
                    //[result appendString:[NSString stringWithFormat:@"%@:  %u\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1Version", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), *((uint32_t*)fields[i].FieldValue.Data) + 1]];
                    uint32_t temp;
                    
                    if (DERToInt(&(fields[i].FieldValue), &temp)) {
                        [result appendString:[NSString stringWithFormat:@"%@:  %u\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1Version", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), temp]];
                    } else {
                        PDEBUG(@"Unable to convert DER form of version into integer.\n");
                        [result appendString:[NSString stringWithFormat:@"%@:  Unknown\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1Version", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil)]];
                    }
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SerialNumber)) {
                    [result appendString:[NSString stringWithFormat:@"%@:  %u\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SerialNumber", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), [NSDataFromDataNoCopy(&(fields[i].FieldValue), NO) description]]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1IssuerName)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1IssuerName", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1IssuerNameCStruct)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1IssuerNameCStruct", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), x509NameAsString((CSSM_X509_NAME_PTR)fields[i].FieldValue.Data)]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1IssuerNameLDAP)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1IssuerNameLDAP", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1ValidityNotBefore)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1ValidityNotBefore", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), [calendarDateForTime((CSSM_X509_TIME_PTR)fields[i].FieldValue.Data) descriptionWithCalendarFormat:@"%c"]]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1ValidityNotAfter)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1ValidityNotAfter", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), [calendarDateForTime((CSSM_X509_TIME_PTR)fields[i].FieldValue.Data) descriptionWithCalendarFormat:@"%c"]]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SubjectName)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SubjectName", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SubjectNameCStruct)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SubjectNameCStruct", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), x509NameAsString((CSSM_X509_NAME_PTR)fields[i].FieldValue.Data)]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SubjectNameLDAP)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SubjectNameLDAP", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_CSSMKeyStruct)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_CSSMKeyStruct", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), [[Key keyWithCSSMKey:(CSSM_KEY_PTR)fields[i].FieldValue.Data module:[[self keychain] CSPModule]] description]]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SubjectPublicKeyCStruct)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SubjectPublicKeyCStruct", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), subjectPublicKeyAsString((CSSM_X509_SUBJECT_PUBLIC_KEY_INFO_PTR)fields[i].FieldValue.Data)]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SubjectPublicKeyAlgorithm)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SubjectPublicKeyAlgorithm", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), nameOfOID((CSSM_OID_PTR)fields[i].FieldValue.Data)]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SubjectPublicKeyAlgorithmParameters)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SubjectPublicKeyAlgorithmParameters", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), [NSDataFromData(&fields[i].FieldValue) description]]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SubjectPublicKey)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SubjectPublicKey", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), subjectPublicKeyAsString((CSSM_X509_SUBJECT_PUBLIC_KEY_INFO_PTR)fields[i].FieldValue.Data)]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1CertificateIssuerUniqueId)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1CertificateIssuerUniqueId", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), [NSDataFromData(&fields[i].FieldValue) description]]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1CertificateSubjectUniqueId)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1CertificateSubjectUniqueId", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), [NSDataFromData(&fields[i].FieldValue) description]]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3CertificateExtensionsStruct)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3CertificateExtensionsStruct", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), extensionsAsString((CSSM_X509_EXTENSIONS_PTR)fields[i].FieldValue.Data)]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3CertificateExtensionsCStruct)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3CertificateExtensionsCStruct", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), extensionsAsString((CSSM_X509_EXTENSIONS_PTR)fields[i].FieldValue.Data)]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3CertificateNumberOfExtensions)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3CertificateNumberOfExtensions", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3CertificateExtensionStruct)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3CertificateExtensionStruct", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), extensionAsString((CSSM_X509_EXTENSION_PTR)fields[i].FieldValue.Data)]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3CertificateExtensionCStruct)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3CertificateExtensionCStruct", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), extensionAsString((CSSM_X509_EXTENSION_PTR)fields[i].FieldValue.Data)]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3CertificateExtensionId)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3CertificateExtensionId", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3CertificateExtensionCritical)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3CertificateExtensionCritical", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3CertificateExtensionType)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3CertificateExtensionType", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V3CertificateExtensionValue)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V3CertificateExtensionValue", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SignatureStruct)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SignatureStruct", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SignatureCStruct)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SignatureCStruct", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), signatureAsString((CSSM_X509_SIGNATURE_PTR)fields[i].FieldValue.Data)]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SignatureAlgorithm)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SignatureAlgorithm", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), nameOfOID((CSSM_OID_PTR)fields[i].FieldValue.Data)]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SignatureAlgorithmTBS)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SignatureAlgorithmTBS", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), nameOfOID((CSSM_OID_PTR)fields[i].FieldValue.Data)]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1SignatureAlgorithmParameters)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1SignatureAlgorithmParameters", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_X509V1Signature)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"CSSMOID_X509V1Signature", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), [NSDataFromData(&fields[i].FieldValue) description]]];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_SubjectSignatureBitmap)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_SubjectSignatureBitmap", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_SubjectPicture)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_SubjectPicture", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_SubjectEmailAddress)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_SubjectEmailAddress", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_UseExemptions)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t(%d) ", NSLocalizedStringFromTableInBundle(@"CSSMOID_UseExemptions", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), fields[i].FieldValue.Length]];
                    [result appendString:[[[NSString alloc] initWithData:NSDataFromData(&fields[i].FieldValue) encoding:NSMacOSRomanStringEncoding] autorelease]];
                    [result appendString:@"\n\n"];
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_SubjectAltName) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_IssuerAltName) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_AuthorityKeyIdentifier)) {
                    
                } else if (OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_SubjectDirectoryAttributes) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_SubjectKeyIdentifier) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_KeyUsage) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_PrivateKeyUsagePeriod) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_BasicConstraints) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_CrlNumber) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_CrlReason) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_HoldInstructionCode) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_InvalidityDate) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_DeltaCrlIndicator) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_IssuingDistributionPoints) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_NameConstraints) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_CrlDistributionPoints) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_CertificatePolicies) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_PolicyMappings) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_PolicyConstraints) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_ExtendedKeyUsage) || OIDsAreEqual(&fields[i].FieldOid, &CSSMOID_ExtendedUseCodeSigning)) {
                    [result appendString:[NSString stringWithFormat:@"%@\n\t%@\n\n", NSLocalizedStringFromTableInBundle(@"Generic Extension", @"OID Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil), extensionAsString((CSSM_X509_EXTENSION_PTR)fields[i].FieldValue.Data)]];
                } else {
                    [result appendString:@"Unknown Field\n\n"];
                }
            }
        }
    }

    return result;
}

- (BOOL)isEqualToCertificate:(Certificate*)cert {
    return ((self == cert) || [[self data] isEqualToData:[cert data]]);
}

- (KeychainItem*)keychainItem {
    return [KeychainItem keychainItemWithKeychainItemRef:(SecKeychainItemRef)certificate];
}

- (Keychain*)keychain {
    return [[self keychainItem] keychain];
}

- (CSSMModule*)CLModule {
    CSSM_CL_HANDLE result;

    error = SecCertificateGetCLHandle(certificate, &result);

    if (error == 0) {
        return [CSSMModule moduleWithHandle:result];
    } else {
        PDEBUG(@"Unable to obtain CSSM CL handle for the certificate %p (SecCertificateRef = %p), error %@.\n", self, certificate, OSStatusAsString(error));
        return nil;
    }
}

- (int)lastError {
    return error;
}

- (SecCertificateRef)certificateRef {
    return certificate;
}

- (void)dealloc {
    if (certificate) {
        CFRelease(certificate);
    }
    
    [super dealloc];
}

@end
