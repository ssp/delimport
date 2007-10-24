//
//  KeychainSearch.m
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

#import "KeychainSearch.h"

#import <Keychain/KeychainItem.h>
#import <Keychain/NSDataAdditions.h>
#import <Keychain/Logging.h>


@implementation SearchAttribute

+ (SearchAttribute*)attributeWithTag:(SecKeychainAttrType)tag length:(UInt32)length data:(void*)data freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithTag:tag length:length data:data freeWhenDone:fre] autorelease];
}

+ (SearchAttribute*)attributeWithTag:(SecKeychainAttrType)tag length:(UInt32)length data:(const void *)data {
    return [[[[self class] alloc] initWithTag:tag length:length data:data] autorelease];
}

- (SearchAttribute*)initWithTag:(SecKeychainAttrType)tag length:(UInt32)length data:(void*)data freeWhenDone:(BOOL)fre {
    if ((length >= 0) && (data)) {
        attribute.tag = tag;
        attribute.length = length;
        attribute.data = data;

        freeWhenDone = fre;
        
        return self;
    } else {
        [self release];
        
        return nil;
    }
}

- (SearchAttribute*)initWithTag:(SecKeychainAttrType)tag length:(UInt32)length data:(const void *)data {
    void *copyOfData;
    
    if ((length >= 0) && (NULL != data)) {
        copyOfData = malloc(length);
        memcpy(copyOfData, data, length);
        
        attribute.tag = tag;
        attribute.length = length;
        attribute.data = copyOfData;

        freeWhenDone = YES;

        return self;
    } else {
        PERR(@"Invalid parameters; 0 == length (%"PRIu32") and/or NULL == data (%p).\n", length, data);
        [self release];
        
        return nil;
    }
}

- (SearchAttribute*)init {
    [self release];
    return nil;
}

- (SecKeychainAttrType)type {
    return attribute.tag;
}

- (SecKeychainAttributePtr)attributePtr {
    return &attribute;
}

- (void)dealloc {
    if (freeWhenDone) {
        free(attribute.data);
    }

    [super dealloc];
}

@end



@implementation KeychainSearch

+ (KeychainSearch*)keychainSearchWithKeychains:(NSArray*)keychains {
    return [[[[self class] alloc] initWithKeychains:keychains] autorelease];
}

- (KeychainSearch*)initWithKeychains:(NSArray*)keychains {
    if (self = [super init]) {
        if (keychains) {
            keychainList = [keychains copy];
        } else {
            keychainList = nil;
        }
        
        attributes = [NSMutableArray arrayWithCapacity:13];
    }
    
    return self;
}

- (KeychainSearch*)init {
    return [self initWithKeychains:nil];
}

- (void)_removeAttributesOfType:(SecKeychainAttrType)type {
    unsigned int i = [attributes count];
    SearchAttribute *current;
    
    while (0 < i) {
        current = [attributes objectAtIndex:i];
        
        if (type == [current type]) {
            [attributes removeObjectAtIndex:i];
        }
        
        --i;
    }
}

- (void)setCreationDate:(NSDate*)date {
    [self _removeAttributesOfType:kSecCreationDateItemAttr];

    if (nil != date) {
        //[attributes addObject:[SearchAttribute attributeWithTag:kSecCreationDateItemAttr length:sizeof(uint32_t) data:(void*)((uint32_t)[date timeIntervalSince1970]) freeWhenDone:NO]]; // *Definitely* not this one; causes a crash because of the invalid pointer.
        
        /*uint32_t *temp = malloc(sizeof(uint32_t));
        
        *temp = (uint32_t)[date timeIntervalSinceReferenceDate];
        
        [attributes addObject:[SearchAttribute attributeWithTag:kSecCreationDateItemAttr length:sizeof(uint32_t) data:(void*)temp freeWhenDone:YES]];*/
        
        uint32_t *temp = malloc(sizeof(uint32_t));

        *temp = (uint32_t)[date timeIntervalSince1970];
        
        [attributes addObject:[SearchAttribute attributeWithTag:kSecCreationDateItemAttr length:sizeof(uint32_t) data:(void*)temp freeWhenDone:YES]];
        
        /*uint8_t *temp = malloc(16);
        temp[15] = 0;
        
        [[date descriptionWithCalendarFormat:@"%Y%m%d%H%M%SZ" timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0] locale:nil] getCString:temp maxLength:16 encoding:NSUTF8StringEncoding];
        
        PDEBUG(@"Date = %s", temp);
        
        [attributes addObject:[SearchAttribute attributeWithTag:kSecCreationDateItemAttr length:16 data:(void*)temp freeWhenDone:YES]];*/
    }
}

- (void)setModificationDate:(NSDate*)date {
    [self _removeAttributesOfType:kSecModDateItemAttr];

    if (nil != date) {
        uint32_t *temp = malloc(sizeof(uint32_t));

        *temp = (uint32_t)[date timeIntervalSince1970];

        [attributes addObject:[SearchAttribute attributeWithTag:kSecModDateItemAttr length:sizeof(uint32_t) data:(void*)temp freeWhenDone:YES]];
    }
}

- (void)setDescription:(NSString*)desc {
    [self _removeAttributesOfType:kSecDescriptionItemAttr];
    
    if (nil != desc) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecDescriptionItemAttr length:[desc cStringLength] data:[desc cString]]];
    }
}

- (void)setComment:(NSString*)comment {
    [self _removeAttributesOfType:kSecCommentItemAttr];

    if (nil != comment) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecCommentItemAttr length:[comment cStringLength] data:[comment cString]]];
    }
}

- (void)setCreator:(NSString*)creator {
    [self _removeAttributesOfType:kSecCreatorItemAttr];

    if (nil != creator) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecCreatorItemAttr length:[creator cStringLength] data:[creator cString]]];
    }
}

- (void)setType:(NSString*)type {
    [self _removeAttributesOfType:kSecTypeItemAttr];

    if (nil != type) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecTypeItemAttr length:[type cStringLength] data:[type cString]]];
    }
}

- (void)setLabel:(NSString*)label {
    [self _removeAttributesOfType:kSecLabelItemAttr];
    
    if (nil != label) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecLabelItemAttr length:[label cStringLength] data:[label cString]]];
    }
}

- (void)setIsVisible:(BOOL)visible {
    char *temp = malloc(sizeof(BOOL));

    [self _removeAttributesOfType:kSecInvisibleItemAttr];
    
    *temp = !visible;

    [attributes addObject:[SearchAttribute attributeWithTag:kSecInvisibleItemAttr length:sizeof(BOOL) data:(void*)temp freeWhenDone:YES]];
}

- (void)setPasswordIsValid:(BOOL)valid {
    char *temp = malloc(sizeof(BOOL));

    [self _removeAttributesOfType:kSecNegativeItemAttr];
    
    *temp = !valid;

    [attributes addObject:[SearchAttribute attributeWithTag:kSecNegativeItemAttr length:sizeof(BOOL) data:(void*)temp freeWhenDone:YES]];
}

- (void)setHasCustomIcon:(BOOL)customIcon {
    char *temp = malloc(sizeof(BOOL));

    [self _removeAttributesOfType:kSecCustomIconItemAttr];
    
    *temp = customIcon;

    [attributes addObject:[SearchAttribute attributeWithTag:kSecCustomIconItemAttr length:sizeof(BOOL) data:(void*)temp freeWhenDone:YES]];
}

- (void)setAccount:(NSString*)account {
    [self _removeAttributesOfType:kSecAccountItemAttr];
    
    if (nil != account) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecAccountItemAttr length:[account cStringLength] data:[account cString]]];
    }
}

- (void)setService:(NSString*)service {
    [self _removeAttributesOfType:kSecServiceItemAttr];

    if (nil != service) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecServiceItemAttr length:[service cStringLength] data:[service cString]]];
    }
}

- (void)setAttribute:(NSString*)attr {
    [self _removeAttributesOfType:kSecGenericItemAttr];
   
    if (nil != attr) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecGenericItemAttr length:[attr cStringLength] data:[attr cString]]];
    }
}

- (void)setDomain:(NSString*)domain {
    [self _removeAttributesOfType:kSecSecurityDomainItemAttr];

    if (nil != domain) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecSecurityDomainItemAttr length:[domain cStringLength] data:[domain cString]]];
    }
}

- (void)setServer:(NSString*)server {
    [self _removeAttributesOfType:kSecServerItemAttr];

    if (nil != server) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecServerItemAttr length:[server cStringLength] data:[server cString]]];
    }
}

- (void)setAuthenticationType:(SecAuthenticationType)type {
    char *temp = malloc(sizeof(SecAuthenticationType));

    [self _removeAttributesOfType:kSecAuthenticationTypeItemAttr];
    
    *temp = type;

    [attributes addObject:[SearchAttribute attributeWithTag:kSecAuthenticationTypeItemAttr length:sizeof(SecAuthenticationType) data:(void*)temp freeWhenDone:YES]];
}

- (void)setPort:(UInt16)port {
    char *temp = malloc(sizeof(UInt16));

    [self _removeAttributesOfType:kSecPortItemAttr];
    
    *temp = port;

    [attributes addObject:[SearchAttribute attributeWithTag:kSecPortItemAttr length:sizeof(UInt16) data:(void*)temp freeWhenDone:YES]];
}

- (void)setPath:(NSString*)path {
    [self _removeAttributesOfType:kSecPathItemAttr];
    
    if (nil != path) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecPathItemAttr length:[path cStringLength] data:[path cString]]];
    }
}

- (void)setAppleShareVolume:(NSString*)volume {
    [self _removeAttributesOfType:kSecVolumeItemAttr];
    
    if (nil != volume) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecVolumeItemAttr length:[volume cStringLength] data:[volume cString]]];
    }
}

- (void)setAppleShareAddress:(NSString*)address {
    [self _removeAttributesOfType:kSecAddressItemAttr];
    
    if (nil != address) {
        [attributes addObject:[SearchAttribute attributeWithTag:kSecAddressItemAttr length:[address cStringLength] data:[address cString]]];
    }
}

- (void)setAppleShareSignature:(SecAFPServerSignature*)sig {
    [self _removeAttributesOfType:kSecSignatureItemAttr];
    
    if (NULL != sig) {
        char *temp = malloc(sizeof(SecAFPServerSignature));

        memcpy(temp, (void*)sig, sizeof(SecAFPServerSignature));

        [attributes addObject:[SearchAttribute attributeWithTag:kSecSignatureItemAttr length:sizeof(SecAFPServerSignature) data:(void*)temp freeWhenDone:YES]];
    }
}

- (void)setProtocol:(SecProtocolType)protocol {
    char *temp = malloc(sizeof(SecProtocolType));

    [self _removeAttributesOfType:kSecProtocolItemAttr];
    
    *temp = protocol;

    [attributes addObject:[SearchAttribute attributeWithTag:kSecProtocolItemAttr length:sizeof(SecProtocolType) data:(void*)temp freeWhenDone:YES]];
}

- (void)setCertificateType:(CSSM_CERT_TYPE)type {
    char *temp = malloc(sizeof(CSSM_CERT_TYPE));

    [self _removeAttributesOfType:kSecCertificateType];
    
    *temp = type;

    [attributes addObject:[SearchAttribute attributeWithTag:kSecCertificateType length:sizeof(CSSM_CERT_TYPE) data:(void*)temp freeWhenDone:YES]];
}

- (void)setCertificateEncoding:(CSSM_CERT_ENCODING)encoding {
    char *temp = malloc(sizeof(CSSM_CERT_ENCODING));

    [self _removeAttributesOfType:kSecCertificateEncoding];
    
    *temp = encoding;

    [attributes addObject:[SearchAttribute attributeWithTag:kSecCertificateEncoding length:sizeof(CSSM_CERT_ENCODING) data:(void*)temp freeWhenDone:YES]];
}

- (void)setCRLType:(CSSM_CRL_TYPE)type {
    char *temp = malloc(sizeof(CSSM_CRL_TYPE));

    [self _removeAttributesOfType:kSecCrlType];
    
    *temp = type;

    [attributes addObject:[SearchAttribute attributeWithTag:kSecCrlType length:sizeof(CSSM_CRL_TYPE) data:(void*)temp freeWhenDone:YES]];
}

- (void)setCRLEncoding:(CSSM_CRL_ENCODING)encoding {
    char *temp = malloc(sizeof(CSSM_CRL_ENCODING));

    [self _removeAttributesOfType:kSecCrlEncoding];
    
    *temp = encoding;

    [attributes addObject:[SearchAttribute attributeWithTag:kSecCrlEncoding length:sizeof(CSSM_CRL_ENCODING) data:(void*)temp freeWhenDone:YES]];
}

- (void)setIsAlias:(BOOL)alias {
    char *temp = malloc(sizeof(BOOL));

    [self _removeAttributesOfType:kSecAlias];
    
    *temp = alias;

    [attributes addObject:[SearchAttribute attributeWithTag:kSecAlias length:sizeof(BOOL) data:(void*)temp freeWhenDone:YES]];
}

- (NSArray*)searchResultsForClass:(SecItemClass)class {
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:33], *pureKeychainList;
    SecKeychainSearchRef searchRef = NULL;
    SecKeychainAttributeList list;
    SearchAttribute *current;
    SecKeychainItemRef currentItem = NULL;
    NSEnumerator *enumerator = [attributes objectEnumerator];
    
    if (keychainList) {
        id currentKeychain;
        NSEnumerator *keychainEnumerator = [keychainList objectEnumerator];
        
        pureKeychainList = [NSMutableArray arrayWithCapacity:[keychainList count]];
            
        while (currentKeychain = [keychainEnumerator nextObject]) {
            if ([currentKeychain isKindOfClass:[Keychain class]]) {
                [pureKeychainList addObject:(id)[currentKeychain keychainRef]];
            } else { // Presume it's a SecKeychainRef
                [pureKeychainList addObject:currentKeychain];
            }
        }
    } else {
        pureKeychainList = nil;
    }

    if ([attributes count] > 0) {
        int i = 0;

        list.count = [attributes count];
        list.attr = malloc(sizeof(SecKeychainAttribute) * list.count);

        while (current = (SearchAttribute*)[enumerator nextObject]) {
            list.attr[i++] = *[current attributePtr];
        }

        error = SecKeychainSearchCreateFromAttributes(pureKeychainList, class, &list, &searchRef);
    } else {
        error = SecKeychainSearchCreateFromAttributes(pureKeychainList, class, NULL, &searchRef);
    }
    
    if ((error == 0) && searchRef) {
        while (((error = SecKeychainSearchCopyNext(searchRef, &currentItem)) == 0) && currentItem) {
            [results addObject:[KeychainItem keychainItemWithKeychainItemRef:currentItem]];
            CFRelease(currentItem);
        }

        CFRelease(searchRef);
    } else {
        results = nil;
    }

    if ([attributes count] > 0) {
        free(list.attr);
    }

    return results;
}

- (NSArray*)anySearchResults {
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:33], *pureKeychainList;
    SecKeychainSearchRef searchRef = NULL;
    SecKeychainAttributeList list;
    SecItemClass class[] = {kSecGenericPasswordItemClass, kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass, kSecCertificateItemClass};
    SearchAttribute *current;
    SecKeychainItemRef currentItem = NULL;
    NSEnumerator *enumerator = [attributes objectEnumerator];
    int i = 0, z = 0;

    if (nil != keychainList) {
        id currentKeychain;
        NSEnumerator *keychainEnumerator = [keychainList objectEnumerator];
        
        pureKeychainList = [NSMutableArray arrayWithCapacity:[keychainList count]];
        
        while (currentKeychain = [keychainEnumerator nextObject]) {
            if ([currentKeychain isKindOfClass:[Keychain class]]) {
                [pureKeychainList addObject:(id)[currentKeychain keychainRef]];
            } else { // Presume it's a SecKeychainRef
                [pureKeychainList addObject:currentKeychain];
            }
        }
    } else {
        pureKeychainList = nil;
    }
    
    if ([attributes count] > 0) {
        list.count = [attributes count];
        list.attr = malloc(sizeof(SecKeychainAttribute) * list.count);

        while (current = (SearchAttribute*)[enumerator nextObject]) {
            list.attr[i++] = *[current attributePtr];
        }
    }

    for (z = 0; z < 4; ++z) {
        if ([attributes count] > 0) {
            error = SecKeychainSearchCreateFromAttributes(pureKeychainList, class[z], &list, &searchRef);
        } else {
            error = SecKeychainSearchCreateFromAttributes(pureKeychainList, class[z], NULL, &searchRef);
        }

        if ((error == 0) && searchRef) {
            while (((error = SecKeychainSearchCopyNext(searchRef, &currentItem)) == 0) && currentItem) {
                [results addObject:[KeychainItem keychainItemWithKeychainItemRef:currentItem]];
                CFRelease(currentItem);
            }
            
            PDEBUG(@"Error = %d - %@.\n", error, CSSMErrorAsString(error));

            CFRelease(searchRef);
        } else {
            PERR(@"SecKeychainSearchCreateFromAttributes returned error %d.\n", error);
            results = nil;
            break;
        }
    }

    if ([attributes count] > 0) {
        free(list.attr);
    }
    
    return results;
}

- (NSArray*)genericSearchResults {
    return [self searchResultsForClass:kSecGenericPasswordItemClass];
}

- (NSArray*)internetSearchResults {
    return [self searchResultsForClass:kSecInternetPasswordItemClass];
}

- (NSArray*)appleShareSearchResults {
    return [self searchResultsForClass:kSecAppleSharePasswordItemClass];
}

- (NSArray*)certificateSearchResults {
    return [self searchResultsForClass:kSecCertificateItemClass];
}

- (int)lastError {
    return error;
}

- (NSArray*)keychains {
    return keychainList;
}

@end

NSArray* FindCertificatesMatchingPublicKeyHash(NSData *hash) {
    KeychainSearch *searcher = [KeychainSearch keychainSearchWithKeychains:defaultSetOfKeychains()];
    NSArray *results = [searcher certificateSearchResults];
    NSEnumerator *enumerator = [results objectEnumerator];
    id current;
    Certificate *curCert;
    NSMutableArray *finalResults = [NSMutableArray arrayWithCapacity:1];
    
    while (current = [enumerator nextObject]) {
        curCert = [Certificate certificateWithCertificateRef:(SecCertificateRef)current];

        if ([hash isEqual:[[curCert publicKey] keyHash]]) {
            [finalResults addObject:curCert];
        }
    }

    return finalResults;
}
