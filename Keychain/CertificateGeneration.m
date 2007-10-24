//
//  CertificateGeneration.m
//  Keychain
//
//  Created by Wade Tregaskis on Tue May 27 2003.
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "CertificateGeneration.h"

#import "CSSMDefaults.h"
#import "CSSMUtils.h"
#import "CSSMControl.h"
#import "CSSMTypes.h"
#import "CSSMModule.h"

#import "UtilitySupport.h"
#import "Logging.h"


NSData* createCertificateTemplate(NameList *subject, NameList *issuer, Validity *validity, Key *publicKey, AlgorithmIdentifier *signingAlgorithm, NSData *serialNumber, ExtensionList *extensions) {
    CSSM_RETURN err;
    CSSM_DATA result;
    CSSM_FIELD *fields = NULL;
    CSSM_X509_TIME *from = NULL, *to = NULL;
    NSEnumerator *extensionEnumerator;
    Extension *current;
    CSSM_X509_EXTENSION *currentRaw;
    uint32 index = 0, numberOfFields = 5; // always requires at least 5 user-supplied fields
    Key *pubKey = publicKey;
    
    if (subject && issuer && publicKey && signingAlgorithm && validity) { // required parameters
        if ([publicKey keyClass] == CSSM_KEYCLASS_PUBLIC_KEY) { // must have a public key
            if (([publicKey blobType] != CSSM_KEYBLOB_RAW) && ((pubKey = [publicKey wrappedKeyUnsafe]) == NULL)) { // must be able to get the raw bytes of the public key; cannot be sensitive
                PCONSOLE(@"createCertificateTemplate() given a sensitive public key - unable to include in certificate.\n");
                PDEBUG(@"publicKey blobType == %d.\n", [publicKey blobType]);
            } else {
                if (validity) {
                    if (![[validity from] isNullTime]) {
                        from = [[validity from] timeRef];
                        ++numberOfFields;
                    }

                    if (![[validity to] isNullTime]) {
                        to = [[validity to] timeRef];
                        ++numberOfFields;
                    }
                }

                if (extensions) {
                    numberOfFields += [extensions numberOfExtensions];
                }

                if (serialNumber != 0) {
                    ++numberOfFields;
                }
                
                fields = calloc(numberOfFields, sizeof(CSSM_FIELD));

                // now we fill in the fields appropriately
                
                fields[index].FieldOid = CSSMOID_X509V1Version;
                intToDER(2, &(fields[index++].FieldValue));

                if (serialNumber) {
                    fields[index].FieldOid = CSSMOID_X509V1SerialNumber;
                    copyNSDataToData(serialNumber, &(fields[index++].FieldValue));
                }

                fields[index].FieldOid = CSSMOID_X509V1IssuerNameCStruct;
                fields[index].FieldValue.Data = (uint8*)[issuer nameListRef];
                fields[index++].FieldValue.Length = sizeof(CSSM_X509_NAME);

                fields[index].FieldOid = CSSMOID_X509V1SubjectNameCStruct;
                fields[index].FieldValue.Data = (uint8*)[subject nameListRef];
                fields[index++].FieldValue.Length = sizeof(CSSM_X509_NAME);

                if (from) {
                    fields[index].FieldOid = CSSMOID_X509V1ValidityNotBefore;
                    fields[index].FieldValue.Data = (uint8*)from;
                    fields[index++].FieldValue.Length = sizeof(CSSM_X509_TIME);
                }
                
                if (to) {
                    fields[index].FieldOid = CSSMOID_X509V1ValidityNotAfter;
                    fields[index].FieldValue.Data = (uint8*)to;
                    fields[index++].FieldValue.Length = sizeof(CSSM_X509_TIME);
                }
                
                fields[index].FieldOid = CSSMOID_CSSMKeyStruct;
                fields[index].FieldValue.Data = (uint8*)[pubKey CSSMKey];
                fields[index++].FieldValue.Length = sizeof(CSSM_KEY);

                fields[index].FieldOid = CSSMOID_X509V1SignatureAlgorithmTBS;
                fields[index].FieldValue.Data = (uint8*)[signingAlgorithm algorithmIdentifierRef];
                fields[index++].FieldValue.Length = sizeof(CSSM_X509_ALGORITHM_IDENTIFIER);

                if (extensions) {
                    extensionEnumerator = [extensions extensionEnumerator];

                    while (current = [extensionEnumerator nextObject]) {
                        currentRaw = [current extensionRef];
                        
                        if(currentRaw->format == CSSM_X509_DATAFORMAT_PARSED) {
                            fields[index].FieldOid = currentRaw->extnId;
                        }
                        else {
                            fields[index].FieldOid = CSSMOID_X509V3CertificateExtensionCStruct;
                        }
                        
                        fields[index].FieldValue.Data = (uint8*)currentRaw;
                        fields[index++].FieldValue.Length = sizeof(CSSM_X509_EXTENSION);
                    }
                }

                NSCAssert(index == numberOfFields, @"index != numberOfFields in createCertificateTemplate() - I think I dropped something... or made something up...");

                resetCSSMData(&result);
                
                err = CSSM_CL_CertCreateTemplate([[CSSMModule defaultCLModule] handle], numberOfFields, fields, &result);

                if (err != CSSM_OK) {
                    PDEBUG(@"CSSM_CL_CertCreateTemplate(X, %d, %p, %p) died miserably because of error #%u - %@", /* [[CSSMModule defaultCLModule] handle], */numberOfFields, fields, result, err, CSSMErrorAsString(err));
                }

                free(fields);
            }
        } else {
            PCONSOLE(@"createCertificateTemplate() given a non-public key where it should have a public key.\n");
            PDEBUG(@"publicKey keyClass = %d.\n", [publicKey keyClass]);
        }
    } else {
        PDEBUG(@"Invalid parameters (%p, %p, %p, %p, %p, %p, %p).\n", subject, issuer, validity, publicKey, signingAlgorithm, serialNumber, extensions);
    }

    return NSDataFromDataNoCopy(&result, YES);
}


// There is no fool bigger than the one who does not believe he is one.

NSData* signCertificate(NSData *certificate, Key *privateKey, CSSM_ALGORITHMS signingAlgorithm) {
    CSSM_DATA rawCert = {0, NULL};
    CSSM_DATA signedResult;
    CSSM_CC_HANDLE ccHandle;
    CSSM_RETURN err;

    if (certificate && privateKey && ([privateKey keyClass] == CSSM_KEYCLASS_PRIVATE_KEY)) {
        [certificate retain]; // Grab a copy of this while we need it's data directly
        copyNSDataToDataNoCopy(certificate, &rawCert);
        
        if ((err = CSSM_CSP_CreateSignatureContext([[CSSMModule defaultCSPModule] handle], signingAlgorithm, keychainFrameworkDefaultCredentials(), [privateKey CSSMKey], &ccHandle)) == CSSM_OK) {            
            resetCSSMData(&signedResult);

            if ((err = CSSM_CL_CertSign([[CSSMModule defaultCLModule] handle], ccHandle, &rawCert, NULL, 0, &signedResult)) != CSSM_OK) {
                PDEBUG(@"CSSM_CL_CertSign(X, %"PRIccHandle", %p, NULL, 0, %p) was unable to sign the certificate because of error #%u - %@.\n", ccHandle, &rawCert, signedResult, err, CSSMErrorAsString(err));
            }
        
            if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
                PDEBUG(@"Warning: Failed to destroy signing context (CSSM_DeleteContext(%"PRIccHandle") returned error #%u - %@).\n", ccHandle, err, CSSMErrorAsString(err));
            }
        } else {
            PDEBUG(@"CSSM_CSP_CreateSignatureContext(X, %p, Z, %p, %p [%"PRIccHandle"]) failed with error #%u - %@.\n", signingAlgorithm, [privateKey CSSMKey], &ccHandle, ccHandle, err, CSSMErrorAsString(err));
        }

        [certificate release]; // Release the certificate we grabbed earlier
    }
    
    return NSDataFromDataNoCopy(&signedResult, YES);
}

Certificate *createCertificate(NameList *subject, NameList *issuer, Validity *validity, Key *publicKey, Key *privateKey, AlgorithmIdentifier *signingAlgorithm, NSData *serialNumber, ExtensionList *extensions) {
    NSData *template, *signedCertificate = nil;

    template = createCertificateTemplate(subject, issuer, validity, publicKey, signingAlgorithm, serialNumber, extensions);

    if (template) {
        signedCertificate = signCertificate(template, privateKey, [signingAlgorithm algorithm]);
    }

    return [Certificate certificateWithData:signedCertificate type:CSSM_CERT_UNKNOWN encoding:CSSM_CERT_ENCODING_UNKNOWN];
}
