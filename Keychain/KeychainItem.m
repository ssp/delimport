//
//  KeychainItem.m
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

#import "KeychainItem.h"

#import "Keychain.h"
#import "Certificate.h"
#import "Trust.h"


@implementation KeychainItem

+ (KeychainItem*)keychainItemWithKeychainItemRef:(SecKeychainItemRef)keychainIt {
    return [[[[self class] alloc] initWithKeychainItemRef:keychainIt] autorelease];
}

- (KeychainItem*)initWithKeychainItemRef:(SecKeychainItemRef)keychainIt {
    KeychainItem *existingObject;
    
    if (keychainIt) {
        existingObject = [[self class] instanceWithKey:(id)keychainIt from:@selector(keychainItemRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            return [existingObject retain];
        } else {
            if (self = [super init]) {
                CFRetain(keychainIt);
                keychainItem = keychainIt;
            }

            return self;
        }
    } else {
        [self release];

        return nil;
    }
}

- (KeychainItem*)init {
    [self release];
    return nil;
}

- (SecItemClass)kind {
    UInt32 unused = 0;
    SecItemClass result;

    error = SecKeychainItemCopyContent(keychainItem, &result, NULL, &unused, NULL);

    if (error == 0) {
        return result;
    } else {
        return -1;
    }
}

- (NSString*)kindString {
    switch ([self kind]) {
        case -1:
            return @"Error"; break;
        case 0:
            return nil; break;
        case kSecInternetPasswordItemClass:
            return @"Internet Password"; break;
        case kSecGenericPasswordItemClass:
            return @"Generic Password"; break;
        case kSecAppleSharePasswordItemClass:
            return @"AppleShare Password"; break;
        case kSecCertificateItemClass:
            return @"Certificate"; break;
        default:
            return @"Unknown";
    }
}

- (BOOL)isInternetItem {
    return ([self kind] == kSecInternetPasswordItemClass);
}

- (BOOL)isGenericItem {
    return ([self kind] == kSecGenericPasswordItemClass);
}

- (BOOL)isAppleShareItem {
    return ([self kind] == kSecAppleSharePasswordItemClass);
}

- (BOOL)isCertificate {
    return ([self kind] == kSecCertificateItemClass);
}

- (void)setData:(NSData*)data {
    error = SecKeychainItemModifyContent(keychainItem, NULL, [data length], [data bytes]);
}

- (void)setDataString:(NSString*)data {
    error = SecKeychainItemModifyContent(keychainItem, NULL, [data cStringLength], [data cString]);
}

- (NSData*)data {
    UInt32 length;
    char *result;
    NSData *res = nil;
    
    error = SecKeychainItemCopyContent(keychainItem, NULL, NULL, &length, (void**)&result);

    if (error == 0) {
        res = [NSData dataWithBytes:result length:length];

        error = SecKeychainItemFreeContent(NULL, result);

        if (error != 0) {
            res = nil;
        }
    }

    return res;
}

- (NSString*)dataAsString {
    UInt32 length;
    char *result;
    NSString *res = nil;

    error = SecKeychainItemCopyContent(keychainItem, NULL, NULL, &length, (void**)&result);

    if (error == 0) {
        res = [NSString stringWithCString:result length:length];

        error = SecKeychainItemFreeContent(NULL, result);

        if (error != 0) {
            res = nil;
        }
    }

    return res;
}

- (void)setCreationDate:(NSCalendarDate*)date {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *desc;
    NSTimeZone *previousTimeZone = [NSTimeZone defaultTimeZone];

    [NSTimeZone setDefaultTimeZone:[NSTimeZone localTimeZone]];
    
    [date setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    desc = [date description];

    [NSTimeZone setDefaultTimeZone:previousTimeZone];
    
    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCreationDateItemAttr;
    attr.length = [desc cStringLength];
    attr.data = (void*)[desc cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setModificationDate:(NSCalendarDate*)date {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *desc;
    NSTimeZone *previousTimeZone = [NSTimeZone defaultTimeZone];

    [NSTimeZone setDefaultTimeZone:[NSTimeZone localTimeZone]];

    [date setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    desc = [date description];

    [NSTimeZone setDefaultTimeZone:previousTimeZone];

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecModDateItemAttr;
    attr.length = [desc cStringLength];
    attr.data = (void*)[desc cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setTypeDescription:(NSString*)desc {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecDescriptionItemAttr;
    attr.length = [desc cStringLength];
    attr.data = (void*)[desc cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setComment:(NSString*)comment {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCommentItemAttr;
    attr.length = [comment cStringLength];
    attr.data = (void*)[comment cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setCreator:(NSString*)creator {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCreatorItemAttr;
    attr.length = [creator cStringLength];
    attr.data = (void*)[creator cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setType:(NSString*)type {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecTypeItemAttr;
    attr.length = [type cStringLength];
    attr.data = (void*)[type cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setLabel:(NSString*)label {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecLabelItemAttr;
    attr.length = [label cStringLength];
    attr.data = (void*)[label cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setIsVisible:(BOOL)visible {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecInvisibleItemAttr;
    attr.length = 0;
    attr.data = !visible ? (void*)0x1 : (void*)0x0;

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setIsValid:(BOOL)valid {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecNegativeItemAttr;
    attr.length = 0;
    attr.data = !valid ? (void*)0x1 : (void*)0x0;

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setHasCustomIcon:(BOOL)icon {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCustomIconItemAttr;
    attr.length = 0;
    attr.data = icon ? (void*)0x1 : (void*)0x0;

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setAccount:(NSString*)account {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecAccountItemAttr;
    attr.length = [account cStringLength];
    attr.data = (void*)[account cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setService:(NSString*)service {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecServiceItemAttr;
    attr.length = [service cStringLength];
    attr.data = (void*)[service cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setAttribute:(NSString*)attribute {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecGenericItemAttr;
    attr.length = [attribute cStringLength];
    attr.data = (void*)[attribute cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setDomain:(NSString*)domain {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecSecurityDomainItemAttr;
    attr.length = [domain cStringLength];
    attr.data = (void*)[domain cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setServer:(NSString*)server {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecServerItemAttr;
    attr.length = [server cStringLength];
    attr.data = (void*)[server cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setAuthenticationType:(SecAuthenticationType)authType {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecAuthenticationTypeItemAttr;
    attr.length = sizeof(SecAuthenticationType);
    attr.data = &authType;

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setPort:(UInt16)port {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    UInt32 temp = port;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecAuthenticationTypeItemAttr;
    attr.length = sizeof(UInt32);
    attr.data = &temp;

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setPath:(NSString*)path {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecPathItemAttr;
    attr.length = [path cStringLength];
    attr.data = (void*)[path cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setAppleShareVolume:(NSString*)volume {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecVolumeItemAttr;
    attr.length = [volume cStringLength];
    attr.data = (void*)[volume cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setAppleShareAddress:(NSString*)address {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecAddressItemAttr;
    attr.length = [address cStringLength];
    attr.data = (void*)[address cString];

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setAppleShareSignature:(SecAFPServerSignature*)sig {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecSignatureItemAttr;
    attr.length = sizeof(SecAFPServerSignature);
    attr.data = sig;

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setProtocol:(SecProtocolType)protocol {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecProtocolItemAttr;
    attr.length = sizeof(SecProtocolType);
    attr.data = &protocol;

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setCertificateType:(CSSM_CERT_TYPE)certType {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCertificateType;
    attr.length = sizeof(CSSM_CERT_TYPE);
    attr.data = &certType;

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setCertificateEncoding:(CSSM_CERT_ENCODING)certEncoding {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCertificateEncoding;
    attr.length = sizeof(CSSM_CERT_ENCODING);
    attr.data = &certEncoding;

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setCRLtype:(CSSM_CRL_TYPE)type {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCrlType;
    attr.length = sizeof(CSSM_CRL_TYPE);
    attr.data = &type;

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setCRLencoding:(CSSM_CRL_ENCODING)encoding {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCrlEncoding;
    attr.length = sizeof(CSSM_CRL_ENCODING);
    attr.data = &encoding;

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (void)setIsAlias:(BOOL)alias {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecAlias;
    attr.length = 0;
    attr.data = alias ? (void*)0x1 : (void*)0x0;

    error = SecKeychainItemModifyContent(keychainItem, &list, 0, NULL);
}

- (NSCalendarDate*)creationDate {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSCalendarDate *result = nil;
    
    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCreationDateItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSCalendarDate dateWithString:[NSString stringWithCString:(char*)attr.data length:attr.length] calendarFormat:@"%Y%m%d%H%M%S%Z"];
            [result setTimeZone:[NSTimeZone defaultTimeZone]];
            [result setCalendarFormat:nil];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }
    
    return result;
}

- (NSCalendarDate*)modificationDate {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSCalendarDate *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecModDateItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSCalendarDate dateWithString:[NSString stringWithCString:(char*)attr.data length:attr.length] calendarFormat:@"%Y%m%d%H%M%S%Z"];
            [result setTimeZone:[NSTimeZone defaultTimeZone]];
            [result setCalendarFormat:nil];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (NSString*)typeDescription {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecDescriptionItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (NSString*)comment {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCommentItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (NSString*)creator {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCreatorItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (NSString*)type {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecTypeItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (NSString*)label {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;
    
    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecLabelItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (BOOL)isVisible {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    BOOL result = NO;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecInvisibleItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        result = (attr.data == NULL);

        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = NO;
        }
    }

    return result;
}

- (BOOL)passwordIsValid {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    BOOL result = NO;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecNegativeItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        result = (attr.data == NULL);

        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = NO;
        }
    }

    return result;
}

- (BOOL)hasCustomIcon {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    BOOL result = NO;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCustomIconItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        result = (attr.data != NULL);

        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = NO;
        }
    }

    return result;
}

- (NSString*)account {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecAccountItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (NSString*)service {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecServiceItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
            
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (NSString*)attribute {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecGenericItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (NSString*)domain {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecSecurityDomainItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (NSString*)server {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecServerItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (SecAuthenticationType)authenticationType {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    SecAuthenticationType result = 0;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecAuthenticationTypeItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = *(SecAuthenticationType*)attr.data;
        }

        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = 0;
        }
    }

    return result;
}

- (NSString*)authenticationTypeString {
    switch ([self authenticationType]) {
        case 0:
            return nil; break;
        case kSecAuthenticationTypeNTLM:
            return @"Windows NT LAN Manager"; break;
        case kSecAuthenticationTypeMSN:
            return @"Microsoft Network"; break;
        case kSecAuthenticationTypeDPA:
            return @"Distributed Password"; break;
        case kSecAuthenticationTypeRPA:
            return @"Remote Password"; break;
        case kSecAuthenticationTypeHTTPDigest:
            return @"HTTP Digest Access"; break;
        case kSecAuthenticationTypeDefault:
            return @"Default"; break;
        default:
            return @"Unknown";
    }
}

- (UInt16)port {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    UInt16 result = 0;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecPortItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = (UInt16)(*(UInt32*)attr.data);
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = 0;
        }
    }

    return result;
}

- (NSString*)path {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecPathItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (NSString*)appleShareVolume {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecVolumeItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (NSString*)appleShareAddress {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    NSString *result = nil;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecAddressItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = [NSString stringWithCString:attr.data length:attr.length];
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = nil;
        }
    }

    return result;
}

- (SecAFPServerSignature*)appleShareSignature {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    SecAFPServerSignature *result = NULL;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecSignatureItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = malloc(sizeof(SecAFPServerSignature));
            memcpy(result, attr.data, sizeof(SecAFPServerSignature));
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            free(result);
            result = NULL;
        }
    }

    return result;
}

- (NSData*)appleShareSignatureData {
    SecAFPServerSignature *res;

    res = [self appleShareSignature];
    
    if (res != NULL) {
        return [NSData dataWithBytesNoCopy:res length:sizeof(SecAFPServerSignature) freeWhenDone:YES];
    } else {
        return nil;
    }
}

- (SecProtocolType)protocol {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    SecProtocolType result = 0;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecProtocolItemAttr;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = (*(SecProtocolType*)attr.data);
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = 0;
        }
    }

    return result;
}

- (NSString*)protocolString {
    switch ([self protocol]) {
        case 0:
            return nil; break;
        case kSecProtocolTypeFTP:
            return @"ftp"; break;
        case kSecProtocolTypeFTPAccount:
            return @"ftp"; break;
        case kSecProtocolTypeHTTP:
            return @"http"; break;
        case kSecProtocolTypeIRC:
            return @"irc"; break;
        case kSecProtocolTypeNNTP:
            return @"nntp"; break;
        case kSecProtocolTypePOP3:
            return @"pop3"; break;
        case kSecProtocolTypeSMTP:
            return @"smtp"; break;
        case kSecProtocolTypeSOCKS:
            return @"socks"; break;
        case kSecProtocolTypeIMAP:
            return @"imap"; break;
        case kSecProtocolTypeLDAP:
            return @"ldap"; break;
        case kSecProtocolTypeAppleTalk:
            return @"appletalk"; break;
        case kSecProtocolTypeAFP:
            return @"afp"; break;
        case kSecProtocolTypeTelnet:
            return @"telnet"; break;
        case kSecProtocolTypeSSH:
            return @"ssh"; break;
        default:
            return @"unknown";
    }    
}

- (CSSM_CERT_TYPE)certificateType {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    CSSM_CERT_TYPE result = 0;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCertificateType;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = (*(CSSM_CERT_TYPE*)attr.data);
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = 0;
        }
    }

    return result;
}

- (CSSM_CERT_ENCODING)certificateEncoding {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    CSSM_CERT_ENCODING result = 0;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCertificateEncoding;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = (*(CSSM_CERT_ENCODING*)attr.data);
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = 0;
        }
    }

    return result;
}

- (CSSM_CRL_TYPE)CRLtype {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    CSSM_CRL_TYPE result = 0;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCrlType;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = (*(CSSM_CRL_TYPE*)attr.data);
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = 0;
        }
    }

    return result;
}

- (NSString*)CRLtypeString {
    switch ([self CRLtype]) {
        case 0:
            return nil; break;
        case CSSM_CRL_TYPE_X_509v1:
            return @"X509v1"; break;
        case CSSM_CRL_TYPE_X_509v2:
            return @"X509v2"; break;
        case CSSM_CRL_TYPE_SPKI:
            return @"SPKI"; break;
        default:
            return @"Unknown";
    }
}

- (CSSM_CRL_ENCODING)CRLencoding {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    CSSM_CRL_ENCODING result = 0;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecCrlEncoding;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        if (attr.data != NULL) {
            result = (*(CSSM_CRL_ENCODING*)attr.data);
        }
        
        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = 0;
        }
    }

    return result;
}

- (NSString*)CRLencodingString {
    switch ([self CRLencoding]) {
        case 0:
            return nil; break;
        case CSSM_CRL_ENCODING_CUSTOM:
            return @"Custom"; break;
        case CSSM_CRL_ENCODING_BER:
            return @"BER"; break;
        case CSSM_CRL_ENCODING_DER:
            return @"DER"; break;
        case CSSM_CRL_ENCODING_BLOOM:
            return @"BLOOM"; break;
        case CSSM_CRL_ENCODING_SEXPR:
            return @"SEXPR"; break;
        default:
            return @"Unknown";
    }
}

- (BOOL)isAlias {
    SecKeychainAttributeList list;
    SecKeychainAttribute attr;
    BOOL result = NO;

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecAlias;

    error = SecKeychainItemCopyContent(keychainItem, NULL, &list, NULL, NULL);

    if (error == 0) {
        result = (attr.data != NULL);

        error = SecKeychainItemFreeContent(&list, NULL);

        if (error != 0) {
            result = NO;
        }
    }

    return result;
}

- (void)setAccess:(Access*)acc {
    error = SecKeychainItemSetAccess(keychainItem, [acc accessRef]);
}

- (Access*)access {
    SecAccessRef result = NULL;
    Access *res;

    error = SecKeychainItemCopyAccess(keychainItem, &result);

    if ((error == 0) && result) {
        res = [Access accessWithAccessRef:result];
        CFRelease(result);

        return res;
    } else {
        return nil;
    }
}

- (Keychain*)keychain {
    SecKeychainRef result = NULL;
    Keychain *res;

    error = SecKeychainItemCopyKeychain(keychainItem, &result);

    if ((error == 0) && result) {
        res = [Keychain keychainWithKeychainRef:result];
        CFRelease(result);

        return res;
    } else {
        return nil;
    }
}

- (KeychainItem*)createDuplicate {
    SecKeychainItemRef result = NULL;
    KeychainItem *res;

    error = SecKeychainItemCreateCopy(keychainItem, (SecKeychainRef)[[self keychain] keychainRef], [[self access] accessRef], &result);

    if ((error == 0) && result) {
        res = [[self class] keychainItemWithKeychainItemRef:result];
        CFRelease(result);

        return res;
    } else {
        return nil;
    }
}

- (Certificate*)certificate {
    return [Certificate certificateWithCertificateRef:(SecCertificateRef)keychainItem];
}

- (NSString*)description {
    Certificate *cert;
    NSString *label, *account, *protocol, *server, *path, *comment, *typeDescription;
    int port = [self port];
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:50];

    switch ([self kind]) {
        case kSecInternetPasswordItemClass: // <label>: <account> @ <protocol>://<server>:<port>/<path> (<comment>)
            label = [[self label] retain];

            if (label) {
                [result appendString:label];
                [result appendString:@": "];
                [label release];
            }

                account = [[self account] retain];

            if (account) {
                [result appendString:account];
                [result appendString:@" @ "];
                [account release];
            }

                protocol = [[self protocolString] retain];

            if (protocol) {
                [result appendString:protocol];
                [result appendString:@"://"];
                [protocol release];
            }

                server = [[self server] retain];

            if (server) {
                [result appendString:server];

                if (port != 0) {
                    [result appendString:[NSString stringWithFormat:@":%d", port]];
                }

                [server release];
            }

                path = [[self path] retain];

            if (path) {
                [result appendString:@"/"];
                [result appendString:path];
                [path release];
            }

                comment = [[self comment] retain];

            if (comment) {
                [result appendString:@" ("];
                [result appendString:comment];
                [result appendString:@")"];
                [comment release];
            }

                break;
            //return [NSString stringWithFormat:@"%@: %@ @ %@://%@:%d/%@ (%@)", [self label], [self account], [self protocolString], [self server], (int)[self port], [self path], [self comment]]; break;
        case kSecGenericPasswordItemClass: // <label>: <account> @ [<typeDescription>] <server>:<port>/<path> (<comment>)
            label = [[self label] retain];

            if (label) {
                [result appendString:label];
                [result appendString:@": "];
                [label release];
            }

                account = [[self account] retain];

            if (account) {
                [result appendString:account];
                [result appendString:@" @ "];
                [account release];
            }

                typeDescription = [[self typeDescription] retain];

            if (typeDescription) {
                [result appendString:typeDescription];
                [result appendString:@" "];
                [typeDescription release];
            }

                server = [[self server] retain];

            if (server) {
                [result appendString:server];

                if (port != 0) {
                    [result appendString:[NSString stringWithFormat:@":%d", port]];
                }

                [server release];
            }

                path = [[self path] retain];

            if (path) {
                [result appendString:@"/"];
                [result appendString:path];
                [path release];
            }

                comment = [[self comment] retain];

            if (comment) {
                [result appendString:@" ("];
                [result appendString:comment];
                [result appendString:@")"];
                [comment release];
            }

                break;
            
            //return [NSString stringWithFormat:@"%@: %@ @ [%@] %@:%d (%@)", [self label], [self account], [self typeDescription], [self server], (int)[self port], [self comment]]; break;
        case kSecAppleSharePasswordItemClass: // <label>: <account> @ <protocol>://<server> (<comment>)
            label = [[self label] retain];

            if (label) {
                [result appendString:label];
                [result appendString:@": "];
                [label release];
            }

                account = [[self account] retain];

            if (account) {
                [result appendString:account];
                [result appendString:@" @ "];
                [account release];
            }

                protocol = [[self protocolString] retain];

            if (protocol) {
                [result appendString:protocol];
                [result appendString:@"://"];
                [protocol release];
            }

                server = [[self server] retain];

            if (server) {
                [result appendString:server];
                [server release];
            }

                comment = [[self comment] retain];

            if (comment) {
                [result appendString:@" ("];
                [result appendString:comment];
                [result appendString:@")"];
                [comment release];
            }

                break;
            
            //return [NSString stringWithFormat:@"%@: %@ @ %@://%@ (%@)", [self label], [self account], [self protocolString], [self server], [self comment]]; break;
        case kSecCertificateItemClass: // <label>: \"<subject common name>\", signed by \"<issuer common name>\" (<comment>)
        case CSSM_DL_DB_RECORD_CERT: // Should be equivalent to kSecCertificateItemClass in content (not the same numerical type, though)
            cert = [[self certificate] retain];

            label = [[self label] retain];

            if (label) {
                [result appendString:label];
                [result appendString:@": "];
                [label release];
            }

                [result appendString:[NSString stringWithFormat:@"\"%@\", signed by %@", [[cert subject] firstPairForType:&CSSMOID_CommonName], [[cert issuer] firstPairForType:&CSSMOID_CommonName]]];

            comment = [[self comment] retain];

            if (comment) {
                [result appendString:@" ("];
                [result appendString:comment];
                [result appendString:@")"];
                [comment release];
            }

                [cert release];
            
                break;
        case CSSM_DL_DB_RECORD_USER_TRUST:
            return @"Trust Object (Description forthcoming)"; break;
            //return [[Trust trustWithTrustRef:(SecTrustRef)keychainItem] description]; break;
        case CSSM_DL_DB_RECORD_X509_CRL:
            return @"X509 CRL (Description forthcoming)"; break;
        case CSSM_DL_DB_RECORD_UNLOCK_REFERRAL:
            return @"Unlock referral (Description forthcoming)"; break;
        case CSSM_DL_DB_RECORD_METADATA:
            return @"Metadata (Description forthcoming)"; break;
        case CSSM_DL_DB_RECORD_ANY:
            return @"Any (Description forthcoming)"; break;
        case CSSM_DL_DB_RECORD_CRL:
            return @"CRL (Description forthcoming)"; break;
        case CSSM_DL_DB_RECORD_POLICY:
            return @"Policy (Description forthcoming)"; break;
        case CSSM_DL_DB_RECORD_GENERIC:
            return @"Generic (Description forthcoming)"; break;
        case CSSM_DL_DB_RECORD_PUBLIC_KEY:
            return @"Public Key (Description forthcoming)"; break;
        case CSSM_DL_DB_RECORD_PRIVATE_KEY:
            return @"Private Key (Description forthcoming)"; break;
        case CSSM_DL_DB_RECORD_SYMMETRIC_KEY:
            return @"Symmetric Key (Description forthcoming)"; break;
        case CSSM_DL_DB_RECORD_ALL_KEYS:
            return @"All Keys (Description forthcoming)"; break;
        default:
            return [NSString stringWithFormat:@"Unknown Type (0x%x)", [self kind]];
    }

    return [result autorelease];
}

- (void)deleteCompletely {
    error = SecKeychainItemDelete(keychainItem);
}

- (int)lastError {
    return error;
}

- (SecKeychainItemRef)keychainItemRef {
    return keychainItem;
}

- (void)dealloc {
    if (keychainItem) {
        CFRelease(keychainItem);
    }
    
    [super dealloc];
}

@end
