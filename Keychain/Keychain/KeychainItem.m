//
//  KeychainItem.m
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

#import <Keychain/KeychainItem.h>

#import <Keychain/Keychain.h>
#import <Keychain/Certificate.h>
#import <Keychain/Trust.h>
#import <Keychain/SecurityUtils.h>
#import <Keychain/Logging.h>
#import <Keychain/CSSMTypes.h>

// For pre-10.5 SDKs:
#ifndef NSINTEGER_DEFINED
typedef int NSInteger;
typedef unsigned int NSUInteger;
#define NSINTEGER_DEFINED
#endif
typedef size_t CSSM_SIZE;


BOOL KeychainFrameworkWarnForMissingKeychainItemAttributes = NO;


@implementation KeychainItem

+ (NSString*)nameOfGetterForAttribute:(SecKeychainAttrType)type {
	switch (type) {
		case kSecCreationDateItemAttr:
			return @"creationDate";
		case kSecModDateItemAttr:
			return @"modificationDate";
		case kSecDescriptionItemAttr:
			return @"typeDescription";
		case kSecCommentItemAttr:
			return @"comment";
		case kSecCreatorItemAttr:
			return @"creator";
		case kSecTypeItemAttr:
			return @"type";
		case kSecLabelItemAttr:
			return @"label";
		case kSecAccountItemAttr:
			return @"account";
		case kSecServiceItemAttr:
			return @"service";
		case kSecGenericItemAttr:
			return @"userDefinedAttribute";
		case kSecSecurityDomainItemAttr:
			return @"securityDomain";
		case kSecServerItemAttr:
			return @"server";
		case kSecPathItemAttr:
			return @"path";
		case kSecVolumeItemAttr:
			return @"appleShareVolume";
		case kSecAddressItemAttr:
			return @"appleShareAddress";
		//case kSecScriptCodeItemAttr:
			// TODO; WTF is this?			
		case kSecInvisibleItemAttr:
			return @"isVisible";
		case kSecNegativeItemAttr:
			return @"passwordIsValid";
		case kSecCustomIconItemAttr:
			return @"hasCustomIcon";
		case kSecAlias:
			return @"alias";
		case kSecAuthenticationTypeItemAttr:
			return @"authenticationType";
		case kSecPortItemAttr:
			return @"port";
		case kSecSignatureItemAttr:
			return @"appleShareSignature";
		case kSecProtocolItemAttr:
			return @"protocol";
		case kSecCertificateType:
			return @"certificateType";
		case kSecCertificateEncoding:
			return @"certificateEncoding";
		case kSecCrlType:
			return @"CRLType";
		case kSecCrlEncoding:
			return @"CRLEncoding";
		default:
			PSYSLOG(LOG_ERR, @"Unknown/unsupported attribute \"%@\" - don't know the name of the method used to get this from a KeychainItem.\n", nameOfKeychainAttributeConstant(type));
			return nil;
	}
}

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
                _keychainItem = keychainIt;
            }

            return self;
        }
    } else {
        [self release];

        return nil;
    }
}

- (KeychainItem*)init {
	PSYSLOG(LOG_ERR, @"\"init\" is not a valid initialiser for KeychainItems.\n");
    [self release];
    return nil;
}

- (SecItemClass)kind {
    uint32 unused = 0;
    SecItemClass result;

    _error = SecKeychainItemCopyContent(_keychainItem, &result, NULL, &unused, NULL);

    if (noErr == _error) {
        return result;
    } else {
		PSYSLOGND(LOG_ERR, @"Unable to retrieve KeychainItem kind - error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecKeychainItemCopyContent(%p, %p, NULL, %p, NULL) returned error %@.\n", _keychainItem, &result, &unused, OSStatusAsString(_error));
		
        return -1;
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
	NSUInteger dataLength = ((nil != data) ? [data length] : 0);
	const void *dataBytes = ((nil != data) ? [data bytes] : "");
	
    _error = SecKeychainItemModifyContent(_keychainItem, NULL, (uint32_t)dataLength, dataBytes);
	
	if (noErr != _error) {
		PSYSLOGND(LOG_ERR, @"Unable to set KeychainItem data - error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecKeychainItemModifyContent(%p, NULL, %lu, %p) returned error %@.\n", _keychainItem, (unsigned long)dataLength, dataBytes, OSStatusAsString(_error));
	}
}

- (void)setDataFromString:(NSString*)data {
	[self setData:[data dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSData*)data {
	NSData *res = nil;
	uint32 length;
	char *result;
	
	_error = SecKeychainItemCopyContent(_keychainItem, NULL, NULL, &length, (void**)&result);
	
	if (noErr == _error) {
		res = [NSData dataWithBytes:result length:length];

		OSStatus _freeError = SecKeychainItemFreeContent(NULL, result);

		if (noErr != _freeError) {
			PSYSLOGND(LOG_WARNING, @"Unable to free temporary buffer of KeychainItem data - error %@.\n", OSStatusAsString(_freeError));
			PDEBUG(@"SecKeychainItemFreeContent(NULL, %p) returned error %@.\n", result, OSStatusAsString(_freeError));
		}
	} else {
		PSYSLOGND(LOG_ERR, @"Unable to get KeychainItem data - error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecKeychainItemCopyContent(%p, NULL, NULL, %p [%lu], %p [%p]) returned error %@.\n", _keychainItem, &length, length, &result, result, OSStatusAsString(_error));
	}

    return res;
}

- (NSString*)dataAsString {
	return NSStringFromNSData([self data]);
}

- (BOOL)_setAttribute:(SecKeychainAttrType)type bytes:(const void*)data length:(size_t)length {
	SecKeychainAttributeList list;
    SecKeychainAttribute attr;
	
    list.count = 1;
    list.attr = &attr;
	
    attr.tag = type;
    attr.length = (uint32_t)length;
    attr.data = (void*)data;
	
    _error = SecKeychainItemModifyAttributesAndData(_keychainItem, &list, 0, NULL);
	
	if (noErr != _error) {
		PSYSLOGND(LOG_ERR, @"Unable to set KeychainItem attribute %@ - error %@.\n", nameOfKeychainAttribute(type), OSStatusAsString(_error));
		PDEBUG(@"SecKeychainItemModifyAttributesAndData(%p, %p [attribute = %@, data = %p (length %lu)], 0, NULL) returned error %@.\n", _keychainItem, &list, nameOfKeychainAttribute(type), data, length, OSStatusAsString(_error));
	}
	
	return (noErr == _error);
}

- (BOOL)_setAttribute:(SecKeychainAttrType)type data:(NSData*)data {	
	return [self _setAttribute:type bytes:[data bytes] length:[data length]];
}

- (BOOL)_setAttribute:(SecKeychainAttrType)type string:(NSString*)string encoding:(NSStringEncoding)encoding {
	const char *bytes = [string cStringUsingEncoding:encoding];
	
	return [self _setAttribute:type bytes:bytes length:[string lengthOfBytesUsingEncoding:encoding]];
}

- (BOOL)_setAttribute:(SecKeychainAttrType)type date:(NSDate*)date {
	NSString *dateString = [date descriptionWithCalendarFormat:@"%Y%m%d%H%M%SZ" timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0] locale:nil];
	const char *bytes = [dateString cStringUsingEncoding:NSASCIIStringEncoding];
	
	return [self _setAttribute:type bytes:bytes length:([dateString lengthOfBytesUsingEncoding:NSASCIIStringEncoding] + 1)];
}

- (BOOL)_setAttribute:(SecKeychainAttrType)type boolValue:(BOOL)value {
	uint32_t intValue = (value ? 1 : 0);
	
	if (![self _setAttribute:type bytes:&intValue length:sizeof(uint32_t)]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's %@ - error %@.\n", self, nameOfKeychainAttribute(type), OSStatusAsString(_error));
		return NO;
	} else {
		return YES;
	}
}

- (void)setCreationDate:(NSDate*)date {
	if (![self _setAttribute:kSecCreationDateItemAttr date:date]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's creation date - error %@.\n", self, OSStatusAsString(_error));
	}
}

#if 0
- (void)setModificationDate:(NSDate*)date {
	// This is a special case.  If we use any of the Sec* level API, it will automatically update the modification date, defeating our attempted change.  D'oh.  So we need to go down to the CSSM level and change it there, where there are no automatic behaviours like that.
	
	// Unfortunately, it doesn't work.  For some reason the myType parameter isn't accepted, and worse, whatever magic value it needs to be changes each time you run... I suspect at this point that it's accidentally comparing against a pointer, rather than the value, but I haven't checked that hypothesis yet.
	
	SecKeychainItemRef keychainItemRef = [self keychainItemRef];
	CSSM_DL_DB_HANDLE dldbHandle;
	
	_error = SecKeychainItemGetDLDBHandle(keychainItemRef, &dldbHandle);
	
	if (noErr == _error) {
		const CSSM_DB_UNIQUE_RECORD *uniqueRecordID;
		
		_error = SecKeychainItemGetUniqueRecordID(keychainItemRef, &uniqueRecordID);
		
		if (noErr == _error) {
			CSSM_DB_RECORD_ATTRIBUTE_DATA attributesToBeModified;
			CSSM_DB_RECORDTYPE myType = ????; // God damn Security framework seems to change what this value's supposed to be every time, so it's impossible to get it right.  //2442152336;//CSSM_DL_DB_RECORD_INTERNET_PASSWORD;//[self kind]; // Not sure if this will work, but then I don't know how to determine this properly..?
			CSSM_DB_ATTRIBUTE_DATA attribute;
			CSSM_DATA attributeValue;
			
			resetCSSMData(&attributeValue);
			copyNSDataToData([[date descriptionWithCalendarFormat:@"%Y%m%d%H%M%SZ" timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0] locale:nil] dataUsingEncoding:NSASCIIStringEncoding], &attributeValue);
			
			attribute.NumberOfValues = 1;
			attribute.Info.AttributeFormat = CSSM_DB_ATTRIBUTE_FORMAT_BLOB;
			attribute.Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_INTEGER;
			attribute.Info.Label.AttributeID = kSecModDateItemAttr;
			attribute.Value = &attributeValue;
			
			attributesToBeModified.NumberOfAttributes = 1;
			attributesToBeModified.SemanticInformation = 0;
			attributesToBeModified.DataRecordType = myType;
			attributesToBeModified.AttributeData = &attribute;
			
			//do {
				_error = CSSM_DL_DataModify(dldbHandle, myType/*++*/, (CSSM_DB_UNIQUE_RECORD*)uniqueRecordID, &attributesToBeModified, NULL, CSSM_DB_MODIFY_ATTRIBUTE_REPLACE);
			//} while ((CSSM_OK != _error) && (myType != -1));
			
			PDEBUG(@"myType = %"PRIu32".\n", myType);
			
			if (CSSM_OK != _error) {
				PSYSLOGND(LOG_ERR, @"Unable to modify KeychainItem %p's modification date - error %@.\n", self, CSSMErrorAsString(_error));
				PDEBUG(@"CSSM_DL_DataModify(%"PRIdldbHandle", %"PRIu32", <pretty printing not supported>, %p, NULL, CSSM_DB_MODIFY_ATTRIBUTE_REPLACE) returned error %@.\n", dldbHandle, myType, &attributesToBeModified, CSSMErrorAsString(_error));
			}
		} else {
			PSYSLOGND(LOG_ERR, @"Unable to get KeychainItem %p's unique record ID - error %@.\n", self, OSStatusAsString(_error));
			PDEBUG(@"SecKeychainItemGetUniqueRecordID(%p, %p) returned error %@.\n", keychainItemRef, &uniqueRecordID, OSStatusAsString(_error));
		}
	} else {
		PSYSLOGND(LOG_ERR, @"Unable to get KeychainItem %p's DL/DB handle - error %@.\n", self, OSStatusAsString(_error));
		PDEBUG(@"SecKeychainItemGetDLDBHandle(%p, %p) returned error %@.\n", keychainItemRef, &dldbHandle, OSStatusAsString(_error));
	}
	
	/*if (![self _setAttribute:kSecModDateItemAttr date:date]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's modification date - error %@.\n", self, OSStatusAsString(_error));
	}*/
}
#endif

- (void)setTypeDescription:(NSString*)desc {
	if (![self _setAttribute:kSecDescriptionItemAttr string:desc encoding:NSUTF8StringEncoding]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's type description - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setComment:(NSString*)comment {
	if (![self _setAttribute:kSecCommentItemAttr string:comment encoding:NSUTF8StringEncoding]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's comment - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setCreator:(FourCharCode)creator {
	if (![self _setAttribute:kSecCreatorItemAttr bytes:(const void*)&creator length:sizeof(FourCharCode)]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's creator - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setCreatorFromString:(NSString*)creator {
	if ((nil != creator) && (4 != [creator length]) && (0 != [creator length])) {
		PDEBUG(@"Warning: \"%@\" is not a valid creator code - should be 4 bytes long.\n", creator);
	}
	
	if (![self _setAttribute:kSecCreatorItemAttr string:creator encoding:NSUTF8StringEncoding]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's creator code - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setType:(FourCharCode)type {
	if (![self _setAttribute:kSecTypeItemAttr bytes:(const void*)&type length:sizeof(FourCharCode)]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's type - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setTypeFromString:(NSString*)type {
	if ((nil != type) && (4 != [type length]) && (0 != [type length])) {
		PDEBUG(@"Warning: \"%@\" is not a valid type code - should be 4 bytes long.\n", type);
	}
	
	if (![self _setAttribute:kSecTypeItemAttr string:type encoding:NSUTF8StringEncoding]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's type code - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setLabel:(NSString*)label {
	// This SHOULD be just the three lines below, except for a bug in the Security framework.  rdar://problem/3425797
	//
	//if (![self _setAttribute:kSecLabelItemAttr string:label encoding:NSUTF8StringEncoding]) {
	// 		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem label - error %@.\n", OSStatusAsString(_error));
  	//}
	
	SecKeychainAttributeList list;
    SecKeychainAttribute attr;
	const char *utf8String = [label UTF8String];
	
    list.count = 1;
    list.attr = &attr;
	
    attr.tag = kSecLabelItemAttr;
    attr.length = (uint32_t)strlen(utf8String);
    attr.data = (void*)utf8String;
	
    _error = SecKeychainItemModifyContent(_keychainItem, &list, 0, NULL);
	
	if (noErr != _error) {
		PSYSLOGND(LOG_ERR, @"Unable to set KeychainItem %p's label - error %@.\n", self, OSStatusAsString(_error));
		PDEBUG(@"SecKeychainItemModifyContent(%p, %p [attribute = kSecLabelItemAttr, data = %p (length %lu)], 0, NULL) returned error %@.\n", _keychainItem, &list, attr.data, attr.length, OSStatusAsString(_error));
	}
}

- (void)setIsVisible:(BOOL)visible {
	if (![self _setAttribute:kSecInvisibleItemAttr boolValue:!visible]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's visibility - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setPasswordIsValid:(BOOL)valid {
	if (![self _setAttribute:kSecNegativeItemAttr boolValue:!valid]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's validity - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setHasCustomIcon:(BOOL)icon {
	if (![self _setAttribute:kSecCustomIconItemAttr boolValue:icon]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's custom icon flag - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setAccount:(NSString*)account {
	if (![self _setAttribute:kSecAccountItemAttr string:account encoding:NSUTF8StringEncoding]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's account - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setService:(NSString*)service {
	if (![self _setAttribute:kSecServiceItemAttr string:service encoding:NSUTF8StringEncoding]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's service - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setUserDefinedAttribute:(NSData*)data {
	if (![self _setAttribute:kSecGenericItemAttr data:data]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's user-defined attribute - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setSecurityDomain:(NSString*)securityDomain {
	if (![self _setAttribute:kSecSecurityDomainItemAttr string:securityDomain encoding:NSUTF8StringEncoding]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's security domain - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setServer:(NSString*)server {
	if (![self _setAttribute:kSecServerItemAttr string:server encoding:NSUTF8StringEncoding]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's server - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setAuthenticationType:(SecAuthenticationType)authType {
	if (![self _setAttribute:kSecAuthenticationTypeItemAttr bytes:(const void*)&authType length:sizeof(SecAuthenticationType)]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's authentication type - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setPort:(uint32_t)port {
    uint32_t temp = port;
	
	if (![self _setAttribute:kSecPortItemAttr bytes:(const void*)&temp length:sizeof(temp)]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's port - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setPath:(NSString*)path {
	if (![self _setAttribute:kSecPathItemAttr string:path encoding:NSUTF8StringEncoding]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's path - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setAppleShareVolume:(NSString*)volume {
	if (![self _setAttribute:kSecVolumeItemAttr string:volume encoding:NSUTF8StringEncoding]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's AppleShare volume - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setAppleShareAddress:(NSString*)address {
	if (![self _setAttribute:kSecAddressItemAttr string:address encoding:NSUTF8StringEncoding]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's AppleShare address - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setAppleShareSignature:(SecAFPServerSignature*)sig {
	if (![self _setAttribute:kSecSignatureItemAttr bytes:sig length:sizeof(SecAFPServerSignature)]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's AppleShare signature - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setProtocol:(SecProtocolType)protocol {
	if (![self _setAttribute:kSecProtocolItemAttr bytes:(const void*)&protocol length:sizeof(SecProtocolType)]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's protocol - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setCertificateType:(CSSM_CERT_TYPE)certType {
	if (![self _setAttribute:kSecCertificateType bytes:(const void*)&certType length:sizeof(CSSM_CERT_TYPE)]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's certificate type - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setCertificateEncoding:(CSSM_CERT_ENCODING)certEncoding {
	if (![self _setAttribute:kSecCertificateEncoding bytes:(const void*)&certEncoding length:sizeof(CSSM_CERT_ENCODING)]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's certificate encoding - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setCRLType:(CSSM_CRL_TYPE)type {
	if (![self _setAttribute:kSecCrlType bytes:(const void*)&type length:sizeof(CSSM_CRL_TYPE)]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's CRL type - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setCRLEncoding:(CSSM_CRL_ENCODING)encoding {
	if (![self _setAttribute:kSecCrlEncoding bytes:(const void*)&encoding length:sizeof(CSSM_CRL_ENCODING)]) {
		PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's CRL encoding - error %@.\n", self, OSStatusAsString(_error));
	}
}

- (void)setAlias:(NSString*)alias {
	// This SHOULD be just the three lines below, except for a bug in the Security framework.  rdar://problem/5551704
	//
	//if (![self _setAttribute:kSecAlias string:alias encoding:NSUTF8StringEncoding]) {
	//	PSYSLOG(LOG_ERR, @"Unable to set KeychainItem %p's alias - error %@.\n", self, OSStatusAsString(_error));
	//}
	
	SecKeychainAttributeList list;
    SecKeychainAttribute attr;
	const char *utf8String = [alias UTF8String];

    list.count = 1;
    list.attr = &attr;

    attr.tag = kSecAlias;
    attr.length = (uint32_t)strlen(utf8String);
    attr.data = (void*)utf8String;

    _error = SecKeychainItemModifyContent(_keychainItem, &list, 0, NULL);

	if (noErr != _error) {
		PSYSLOGND(LOG_ERR, @"Unable to set KeychainItem %p's alias - error %@.\n", self, OSStatusAsString(_error));
		PDEBUG(@"SecKeychainItemModifyContent(%p, %p [attribute = kSecAlias, data = %p (length %lu)], 0, NULL) returned error %@.\n", _keychainItem, &list, attr.data, attr.length, OSStatusAsString(_error));
	}
}

- (SecKeychainAttributeList*)_attributesOfType:(SecKeychainAttrType)type {
	SecKeychainAttributeList *list = NULL;
	SecKeychainAttributeInfo info;
	uint32 format = kSecFormatUnknown;
	
	info.count = 1;
	info.tag = &type;
	info.format = &format;
	
    _error = SecKeychainItemCopyAttributesAndData(_keychainItem, &info, NULL, &list, NULL, NULL);
	
    if (noErr == _error) {
		if (NULL == list) {
			PSYSLOGND(LOG_ERR, @"Unable to get KeychainItem attribute %@, nothing returned.\n", nameOfKeychainAttribute(type));
			PDEBUG(@"SecKeychainItemCopyAttributesAndData(%p, %p (attribute = %@), NULL, %p, NULL, NULL) returned no data.\n", _keychainItem, &info, nameOfKeychainAttribute(type), &list);
			_error = errSecDataNotAvailable;
		}
	} else {
		if ((errSecNoSuchAttr != _error) || KeychainFrameworkWarnForMissingKeychainItemAttributes) {
			PSYSLOGND(LOG_ERR, @"Unable to get KeychainItem attribute %@ - error %@.\n", nameOfKeychainAttribute(type), OSStatusAsString(_error));
			PDEBUG(@"SecKeychainItemCopyAttributesAndData(%p, %p (attribute = %@), NULL, %p, NULL, NULL) returned error %@.\n", _keychainItem, &info, nameOfKeychainAttribute(type), &list, OSStatusAsString(_error));
		}
		
		list = NULL; // Should be anyway, but just in case the Security framework is lazy.
	}
	
    return list;
}

- (NSData*)_attributeOfType:(SecKeychainAttrType)type {
	SecKeychainAttributeList *list = [self _attributesOfType:type];
	NSData *result = nil;
	
	if (nil != list) {
		if (1 == list->count) {
			result = [NSData dataWithBytes:list->attr->data length:list->attr->length];
		} else if (0 == list->count) {
			PDEBUG(@"No results for attribute %@ of KeychainItem %p (SecRef = %p).\n", nameOfKeychainAttribute(type), self, _keychainItem);
			_error = errSecDataNotAvailable;
		} else {
			PSYSLOG(LOG_ERR, @"Multiple (%lu) results returned for attribute %@ of KeychainItem %p (SecRef = %p); cannot handle.\n", (unsigned long)(list->count), nameOfKeychainAttribute(type), self, _keychainItem);
			_error = errSecDuplicateItem;
		}
		
		OSStatus _localError = SecKeychainItemFreeAttributesAndData(list, NULL);
		
		if (noErr != _localError) {
			PSYSLOGND(LOG_WARNING, @"Unable to free temporary buffer of KeychainItem attributes - error %@.\n", OSStatusAsString(_localError));
			PDEBUG(@"SecKeychainItemFreeAttributesAndData(%p, NULL) returned error %@.\n", result, OSStatusAsString(_localError));
		}
	} // else don't worry, an error occurred, but appropriate logging will have been performed by _attributesOfType:
	
    return result;
}

- (NSString*)_attributeOfType:(SecKeychainAttrType)type asStringUsingEncoding:(NSStringEncoding)encoding {
	SecKeychainAttributeList *list = [self _attributesOfType:type];
	NSString *result = nil;
	
	if (nil != list) {
		if (1 == list->count) {
			result = [[[NSString alloc] initWithBytes:list->attr->data length:list->attr->length encoding:encoding] autorelease];
		} else if (0 == list->count) {
			PDEBUG(@"No results for attribute %@ of KeychainItem %p (SecRef = %p).\n", nameOfKeychainAttribute(type), self, _keychainItem);
			_error = errSecDataNotAvailable;
		} else {
			PSYSLOG(LOG_ERR, @"Multiple (%lu) results returned for attribute %@ of KeychainItem %p (SecRef = %p); cannot handle.\n", (unsigned long)(list->count), nameOfKeychainAttribute(type), self, _keychainItem);
			_error = errSecDuplicateItem;
		}
		
		OSStatus _localError = SecKeychainItemFreeAttributesAndData(list, NULL);
		
		if (noErr != _localError) {
			PSYSLOGND(LOG_WARNING, @"Unable to free temporary buffer of KeychainItem attributes - error %@.\n", OSStatusAsString(_localError));
			PDEBUG(@"SecKeychainItemFreeAttributesAndData(%p, NULL) returned error %@.\n", result, OSStatusAsString(_localError));
		}
	} // else don't worry, an error occurred, but appropriate logging will have been performed by _attributesOfType:
	
    return result;
	
	// Alternative implementation, which is simpler but more wasteful as it creates an intermediary NSData.
	//return [[[NSString alloc] initWithData:[self _attribute:type] encoding:encoding] autorelease];
}

- (BOOL)_attributeOfType:(SecKeychainAttrType)type asInteger:(unsigned long long*)value ofExpectedLength:(NSUInteger)expectedLength {
	BOOL successful = NO;
	unsigned long long result = 0;
	
	if (0 == expectedLength) {
		PSYSLOG(LOG_ERR, @"Asked for integer attribute of expected length 0, which is bogus.\n");
		_error = EINVAL;
	} else if (expectedLength > sizeof(unsigned long long)) {
		PSYSLOG(LOG_ERR, @"Asked for integer attribute of expected length %u, but that's larger than the maximum supported length of %u.\n", expectedLength, sizeof(unsigned long long));
		_error = EINVAL;
	} else {
		SecKeychainAttributeList *list = [self _attributesOfType:type];
		
		if (nil != list) {
			if (1 == list->count) {
				if (expectedLength != list->attr->length) {
					PDEBUG(@"Expected result to have length %u for attribute %@, but it has length %"PRIu32".\n", expectedLength, nameOfKeychainAttributeConstant(type), list->attr->length);
				}
				
				uint32_t i;
				
#if __BIG_ENDIAN__
				for (i = 0; i < list->attr->length; ++i) {
					result <<= 8;
					result |= ((uint8_t*)(list->attr->data))[i];
				}
#elif __LITTLE_ENDIAN__
				for (i = list->attr->length; i > 0; --i) {
					result <<= 8;
					result |= ((uint8_t*)(list->attr->data))[i - 1];
				}
#else
#error Unknown endianness.
#endif
				
				successful = YES;
			} else if (0 == list->count) {
				PDEBUG(@"No results for attribute %@ of KeychainItem %p (SecRef = %p).\n", nameOfKeychainAttribute(type), self, _keychainItem);
				_error = errSecDataNotAvailable;
			} else {
				PSYSLOG(LOG_ERR, @"Multiple (%lu) results returned for attribute %@ of KeychainItem %p (SecRef = %p); cannot handle.\n", (unsigned long)(list->count), nameOfKeychainAttribute(type), self, _keychainItem);
				_error = errSecDuplicateItem;
			}
			
			OSStatus _localError = SecKeychainItemFreeAttributesAndData(list, NULL);
			
			if (noErr != _localError) {
				PSYSLOGND(LOG_WARNING, @"Unable to free temporary buffer of KeychainItem attributes - error %@.\n", OSStatusAsString(_localError));
				PDEBUG(@"SecKeychainItemFreeAttributesAndData(%p, NULL) returned error %@.\n", result, OSStatusAsString(_localError));
			}
		} // else don't worry about it; appropriate logging and setting of _error will have been performed by _attributesOfType:
	}
	
	if (successful) {
		*value = result;
	}
	
    return successful;
}

- (BOOL)_attributeOfType:(SecKeychainAttrType)type boolValue:(BOOL*)value {
	SecKeychainAttributeList *list = [self _attributesOfType:type];
	BOOL successful = NO;
	
	if (nil != list) {
		if (1 == list->count) {
			*value = NO; // It's no until we say otherwise.  Note that a length of 0 for the returned attribute is perfectly valid, and means NO, so this is a suitable default.
			
			uint32_t i;
			
			for (i = 0; i < list->attr->length; ++i) {
				if (0 != ((char*)(list->attr->data))[i]) {
					*value = YES;
					break;
				}
			}
			
			successful = YES;
		} else if (0 == list->count) {
			PDEBUG(@"No results for attribute %@ of KeychainItem %p (SecRef = %p).\n", nameOfKeychainAttribute(type), self, _keychainItem);
			_error = errSecDataNotAvailable;
		} else {
			PSYSLOG(LOG_ERR, @"Multiple (%lu) results returned for attribute %@ of KeychainItem %p (SecRef = %p); cannot handle.\n", (unsigned long)(list->count), nameOfKeychainAttribute(type), self, _keychainItem);
			_error = errSecDuplicateItem;
		}
		
		OSStatus _localError = SecKeychainItemFreeAttributesAndData(list, NULL);
		
		if (noErr != _localError) {
			PSYSLOGND(LOG_WARNING, @"Unable to free temporary buffer of KeychainItem attributes - error %@.\n", OSStatusAsString(_localError));
			PDEBUG(@"SecKeychainItemFreeAttributesAndData(%p, NULL) returned error %@.\n", list, OSStatusAsString(_localError));
		}
	} // else don't worry, an error occurred, but appropriate logging will have been performed by _attributesOfType:
	
    return successful;
}

- (NSCalendarDate*)_calendarDateFromAttribute:(SecKeychainAttrType)type {
	NSString *dateString = [self _attributeOfType:type asStringUsingEncoding:NSASCIIStringEncoding];
	NSCalendarDate *result = nil;
	
	if (nil != dateString) {
		NSRange locationOfZ = [dateString rangeOfString:@"Z"];
		
		if (NSNotFound != locationOfZ.location) {
			dateString = [[dateString substringToIndex:locationOfZ.location] stringByAppendingString:@"0000"];
		} else {
			PSYSLOG(LOG_WARNING, @"Warning: date string \"%@\" for %@ of KeychainItem %p (%@) does not have a 'Z' suffixed... going to assume it has proper time zone info, but that's just a guess.\n", dateString, nameOfKeychainAttributeConstant(type), self, self);
		}
		
		result = [NSCalendarDate dateWithString:dateString calendarFormat:@"%Y%m%d%H%M%S%z"];
		[result setTimeZone:[NSTimeZone defaultTimeZone]];
		[result setCalendarFormat:nil];
	} else {
		if ((errSecNoSuchAttr != _error) || KeychainFrameworkWarnForMissingKeychainItemAttributes) {
			PSYSLOG(LOG_ERR, @"Unable to get KeychainItem %p's %@ - error %@.\n", self, nameOfKeychainAttributeConstant(type), OSStatusAsString(_error));
		}
	}
	
	return result;
}

- (NSCalendarDate*)creationDate {
	return [self _calendarDateFromAttribute:kSecCreationDateItemAttr];
}

- (NSCalendarDate*)modificationDate {
	return [self _calendarDateFromAttribute:kSecModDateItemAttr];
}

- (NSString*)typeDescription {
	return [self _attributeOfType:kSecDescriptionItemAttr asStringUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)comment {
	return [self _attributeOfType:kSecCommentItemAttr asStringUsingEncoding:NSUTF8StringEncoding];
}

- (FourCharCode)creator {
	unsigned long long value = 0;
	
	[self _attributeOfType:kSecCreatorItemAttr asInteger:&value ofExpectedLength:sizeof(FourCharCode)];
	
	return (FourCharCode)value;
}

- (NSString*)creatorAsString {
	FourCharCode creator = [self creator];
	
	if (noErr == [self lastError]) {
		if (0 == creator) {
			return @"";
		} else {
			return [NSString stringWithFormat:@"%4.4s", (char*)(&creator)];
		}
	} else {
		return nil;
	}
}

- (FourCharCode)type {
	unsigned long long value = 0;
	
	[self _attributeOfType:kSecTypeItemAttr asInteger:&value ofExpectedLength:sizeof(FourCharCode)];
	
	return (FourCharCode)value;
}

- (NSString*)typeAsString {
	FourCharCode type = [self type];
	
	if (noErr == [self lastError]) {
		if (0 == type) {
			return @"";
		} else {
			return [NSString stringWithFormat:@"%4.4s", (char*)(&type)];
		}
	} else {
		return nil;
	}
}

- (NSString*)label {
	// This SHOULD be just the line below, except for a bug in the Security framework.  rdar://problem/3425797
	//return [self _attributeOfType:kSecLabelItemAttr asStringUsingEncoding:NSUTF8StringEncoding];

	SecKeychainAttributeList list;
	SecKeychainAttribute attr;
	NSString *result = nil;
	
	list.count = 1;
	list.attr = &attr;
	
	attr.tag = kSecLabelItemAttr;
	attr.data = NULL;
	attr.length = 0;
		
	_error = SecKeychainItemCopyContent(_keychainItem, NULL, &list, NULL, NULL);
	
    if (noErr == _error) {
		result = [[[NSString alloc] initWithBytes:attr.data length:attr.length encoding:NSUTF8StringEncoding] autorelease];
		
		OSStatus _localError = SecKeychainItemFreeContent(&list, NULL);
		
		if (noErr != _localError) {
			PSYSLOGND(LOG_WARNING, @"Unable to free temporary buffer of KeychainItem attributes - error %@.\n", OSStatusAsString(_localError));
			PDEBUG(@"SecKeychainItemFreeContent(%p, NULL) returned error %@.\n", &list, OSStatusAsString(_localError));
		}
	} else {
		if ((errSecNoSuchAttr != _error) || KeychainFrameworkWarnForMissingKeychainItemAttributes) {
			PSYSLOGND(LOG_ERR, @"Unable to get KeychainItem label - error %@.\n", OSStatusAsString(_error));
			PDEBUG(@"SecKeychainItemCopyContent(%p, NULL, %p, NULL, NULL) returned error %@.\n", _keychainItem, &list, OSStatusAsString(_error));
		}
	}

    return result;
}

- (BOOL)isVisible {
	BOOL value = NO;
	
	if (![self _attributeOfType:kSecInvisibleItemAttr boolValue:&value]) {
		if ((errSecNoSuchAttr != _error) || KeychainFrameworkWarnForMissingKeychainItemAttributes) {
			PSYSLOG(LOG_ERR, @"Unable to get KeychainItem visibility - error %@.\n", OSStatusAsString(_error));
		}
	}
	
	return !value;
}

- (BOOL)passwordIsValid {
	BOOL value = NO;
	
	if (![self _attributeOfType:kSecNegativeItemAttr boolValue:&value]) {
		if ((errSecNoSuchAttr != _error) || KeychainFrameworkWarnForMissingKeychainItemAttributes) {
			PSYSLOG(LOG_ERR, @"Unable to get KeychainItem validity - error %@.\n", OSStatusAsString(_error));
		}
	}
	
	return !value;
}

- (BOOL)hasCustomIcon {
	BOOL value = NO;
	
	if (![self _attributeOfType:kSecCustomIconItemAttr boolValue:&value]) {
		if ((errSecNoSuchAttr != _error) || KeychainFrameworkWarnForMissingKeychainItemAttributes) {
			PSYSLOG(LOG_ERR, @"Unable to get KeychainItem validity - error %@.\n", OSStatusAsString(_error));
		}
	}
	
	return value;
}

- (NSString*)account {
	return [self _attributeOfType:kSecAccountItemAttr asStringUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)service {
	return [self _attributeOfType:kSecServiceItemAttr asStringUsingEncoding:NSUTF8StringEncoding];
}

- (NSData*)userDefinedAttribute {
	NSData *result = [self _attributeOfType:kSecGenericItemAttr];
	
	// TODO: Check if it's nil and whether it's likely we're of the wrong type.  Then, double-check our type and if it is indeed not a generic password, print a helpful error message.
	
	return result;
}

- (NSString*)securityDomain {
	return [self _attributeOfType:kSecSecurityDomainItemAttr asStringUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)server {
	return [self _attributeOfType:kSecServerItemAttr asStringUsingEncoding:NSUTF8StringEncoding];
}

- (SecAuthenticationType)authenticationType {
	unsigned long long value = 0;
	
	[self _attributeOfType:kSecAuthenticationTypeItemAttr asInteger:&value ofExpectedLength:sizeof(SecAuthenticationType)];
	
	return (SecAuthenticationType)value;
}

- (uint32_t)port {
	unsigned long long value = 0;
	
	[self _attributeOfType:kSecPortItemAttr asInteger:&value ofExpectedLength:sizeof(uint32_t)];
	
	return (uint32_t)value;
}

- (NSString*)path {
	return [self _attributeOfType:kSecPathItemAttr asStringUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)appleShareVolume {
	return [self _attributeOfType:kSecVolumeItemAttr asStringUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)appleShareAddress {
	return [self _attributeOfType:kSecAddressItemAttr asStringUsingEncoding:NSUTF8StringEncoding];
}

- (SecAFPServerSignature*)appleShareSignature {
	SecKeychainAttributeList *list = [self _attributesOfType:kSecSignatureItemAttr];
    SecAFPServerSignature *result = NULL;
	
	if (nil != list) {
		if (1 == list->count) {
			if (sizeof(SecAFPServerSignature) == list->attr->length) {
				result = malloc(sizeof(SecAFPServerSignature));
				memcpy(result, list->attr->data, sizeof(SecAFPServerSignature));
			} else {
				PSYSLOG(LOG_ERR, @"Sizes don't match in result - expected a SecAFPServerSignature which is %u bytes, but the data returned is %lu bytes long.\n", sizeof(SecAFPServerSignature), (unsigned long)(list->attr->length));
				_error = errSecUnknownFormat;
			}
		} else if (0 == list->count) {
			PDEBUG(@"No results for attribute %@ of KeychainItem %p (SecRef = %p).\n", nameOfKeychainAttribute(kSecSignatureItemAttr), self, _keychainItem);
			_error = errSecDataNotAvailable;
		} else {
			PSYSLOG(LOG_ERR, @"Multiple (%lu) results returned for attribute %@ of KeychainItem %p (SecRef = %p); cannot handle.\n", (unsigned long)(list->count), nameOfKeychainAttribute(kSecSignatureItemAttr), self, _keychainItem);
			_error = errSecDuplicateItem;
		}
		
		OSStatus _localError = SecKeychainItemFreeAttributesAndData(list, NULL);
		
		if (noErr != _localError) {
			PSYSLOGND(LOG_WARNING, @"Unable to free temporary buffer of KeychainItem attributes - error %@.\n", OSStatusAsString(_localError));
			PDEBUG(@"SecKeychainItemFreeAttributesAndData(%p, NULL) returned error %@.\n", result, OSStatusAsString(_localError));
		}
	} // else don't worry about it; appropriate logging and setting of _error will have been performed by _attributesOfType:
	
    return result;
}

- (NSData*)appleShareSignatureData {
	return [self _attributeOfType:kSecSignatureItemAttr];
}

- (SecProtocolType)protocol {
	unsigned long long value = 0;
	
	[self _attributeOfType:kSecProtocolItemAttr asInteger:&value ofExpectedLength:sizeof(SecProtocolType)];
	
	return (SecProtocolType)value;
}

- (CSSM_CERT_TYPE)certificateType {
	unsigned long long value = CSSM_CERT_UNKNOWN;
	
	[self _attributeOfType:kSecCertificateType asInteger:&value ofExpectedLength:sizeof(CSSM_CERT_TYPE)];
	
	return (CSSM_CERT_TYPE)value;
}

- (CSSM_CERT_ENCODING)certificateEncoding {
	unsigned long long value = CSSM_CERT_ENCODING_UNKNOWN;
	
	[self _attributeOfType:kSecCertificateEncoding asInteger:&value ofExpectedLength:sizeof(CSSM_CERT_ENCODING)];
	
	return (CSSM_CERT_ENCODING)value;
}

- (CSSM_CRL_TYPE)CRLType {
	unsigned long long value = CSSM_CRL_TYPE_UNKNOWN;
	
	[self _attributeOfType:kSecCrlType asInteger:&value ofExpectedLength:sizeof(CSSM_CRL_TYPE)];
	
	return (CSSM_CRL_TYPE)value;
}

- (CSSM_CRL_ENCODING)CRLEncoding {
	unsigned long long value = CSSM_CRL_ENCODING_UNKNOWN;
	
	[self _attributeOfType:kSecCrlEncoding asInteger:&value ofExpectedLength:sizeof(CSSM_CRL_ENCODING)];
	
	return (CSSM_CRL_ENCODING)value;
}

- (NSString*)alias {
	// This SHOULD be just the line below, except for an apparent bug in the Security framework.  rdar://problem/5551704
	//return [self _attributeOfType:kSecAlias asStringUsingEncoding:NSUTF8StringEncoding];
	
	SecKeychainAttributeList list;
	SecKeychainAttribute attr;
	NSString *result = nil;
	
	list.count = 1;
	list.attr = &attr;
	
	attr.tag = kSecAlias;
	attr.data = NULL;
	attr.length = 0;
	
	_error = SecKeychainItemCopyContent(_keychainItem, NULL, &list, NULL, NULL);
	
    if (noErr == _error) {
		result = [[[NSString alloc] initWithBytes:attr.data length:attr.length encoding:NSUTF8StringEncoding] autorelease];
		
		OSStatus _localError = SecKeychainItemFreeContent(&list, NULL);
		
		if (noErr != _localError) {
			PSYSLOGND(LOG_WARNING, @"Unable to free temporary buffer of KeychainItem attributes - error %@.\n", OSStatusAsString(_localError));
			PDEBUG(@"SecKeychainItemFreeContent(%p, NULL) returned error %@.\n", &list, OSStatusAsString(_localError));
		}
	} else {
		if ((errSecNoSuchAttr != _error) || KeychainFrameworkWarnForMissingKeychainItemAttributes) {
			PSYSLOGND(LOG_ERR, @"Unable to get KeychainItem alias - error %@.\n", OSStatusAsString(_error));
			PDEBUG(@"SecKeychainItemCopyContent(%p, NULL, %p, NULL, NULL) returned error %@.\n", _keychainItem, &list, OSStatusAsString(_error));
		}
	}
	
    return result;
}

- (void)setAccess:(Access*)acc {
	SecAccessRef accessRef = [acc accessRef];
	
    _error = SecKeychainItemSetAccess(_keychainItem, accessRef);
	
	if (noErr != _error) {
		PSYSLOGND(LOG_ERR, @"Unable to set KeychainItem's access - error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecKeychainItemSetAccess(%p, %p) returned error %@.\n", _keychainItem, accessRef, OSStatusAsString(_error));
	}
}

- (Access*)access {
    SecAccessRef result = NULL;
    Access *res = nil;

    _error = SecKeychainItemCopyAccess(_keychainItem, &result);

    if (noErr == _error) {
		if (nil != result) {
			res = [Access accessWithAccessRef:result];
			CFRelease(result);
		}
    } else {
		if (errSecNoAccessForItem != _error) {
			PSYSLOGND(LOG_ERR, @"Unable to get KeychainItem's access - error %@.\n", OSStatusAsString(_error));
			PDEBUG(@"SecKeychainItemCopyAccess(%p, %p) returned error %@.\n", _keychainItem, &result, OSStatusAsString(_error));
		}
	}
	
	return res;
}

- (Keychain*)keychain {
    SecKeychainRef result = NULL;
    Keychain *res = nil;

    _error = SecKeychainItemCopyKeychain(_keychainItem, &result);

    if (noErr == _error) {
		if (nil != result) {
			res = [Keychain keychainWithKeychainRef:result];
			CFRelease(result);
		}
    } else {
		if (errSecNoSuchKeychain != _error) {
			// We can end up with a KeychainItem that has no keychain, because it's a standalone entity (e.g. a certificate).  So this failing isn't entirely unexpected, and shouldn't produce an error message.  We should still provide a debug message, though.
			PSYSLOGND(LOG_ERR, @"Unable to get KeychainItem's keychain - error %@.\n", OSStatusAsString(_error));
		}
		
		PDEBUG(@"SecKeychainItemCopyKeychain(%p, %p) returned error %@.\n", _keychainItem, &result, OSStatusAsString(_error));
    }
	
	return res;
}

- (KeychainItem*)createDuplicate {
    SecKeychainItemRef result = NULL;
    KeychainItem *res = nil;
	SecKeychainRef keychain = (SecKeychainRef)[[self keychain] keychainRef];
	SecAccessRef access = [[self access] accessRef];
	
	// TODO: verify this will ever actually work; we surely can't just create a complete duplicate of an item within the same keychain... I'm pretty sure SecKeychainItemCreateCopy is intended for copying items *between* keychains.
    _error = SecKeychainItemCreateCopy(_keychainItem, keychain, access, &result);

    if (noErr != _error) {
		if (nil != result) {
			res = [[self class] keychainItemWithKeychainItemRef:result];
			CFRelease(result);
		}
    } else {
		PSYSLOGND(LOG_ERR, @"Unable to copy KeychainItem - error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecKeychainItemCreateCopy(%p, %p, %p, %p) returned error %@.\n", _keychainItem, keychain, access, &result, OSStatusAsString(_error));
    }
	
	return res;
}

- (Certificate*)certificate {
	if ([self isCertificate]) {
		return [Certificate certificateWithCertificateRef:(SecCertificateRef)_keychainItem];
	} else {
		return nil;
	}
}

- (NSString*)description {
    Certificate *cert = nil;
    NSString *label = nil, *account = nil, *protocol = nil, *server = nil, *service = nil, *path = nil, *comment = nil, *typeDescription = nil;
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:50];

    switch ([self kind]) {
        case kSecInternetPasswordItemClass: // <label>: <account> @ <protocol>://<server>:<port>/<path> (<comment>)
            label = [self label];

            if (label) {
                [result appendString:label];
                [result appendString:@": "];
            }

            account = [self account];

            if (account) {
                [result appendString:account];
                [result appendString:@" @ "];
            }

            protocol = shortNameOfProtocol([self protocol]);

            if (protocol) {
                [result appendString:protocol];
                [result appendString:@"://"];
            }

            server = [self server];

            if (server) {
                [result appendString:server];
				
				uint32_t port = [self port];
				
                if (port != 0) {
                    [result appendString:[NSString stringWithFormat:@":%"PRIu32, port]];
                }
            }

            path = [self path];

            if (path) {
                [result appendString:@"/"];
                [result appendString:path];
            }

            comment = [self comment];

            if (comment) {
                [result appendString:@" ("];
                [result appendString:comment];
                [result appendString:@")"];
            }

            break;
            //return [NSString stringWithFormat:@"%@: %@ @ %@://%@:%d/%@ (%@)", [self label], [self account], [self protocolString], [self server], (int)[self port], [self path], [self comment]]; break;
        case kSecGenericPasswordItemClass: // <label>: <account> @ [<typeDescription>] <service> (<comment>)
            label = [self label];

            if (label) {
                [result appendString:label];
                [result appendString:@": "];
            }

            account = [self account];

            if (account) {
                [result appendString:account];
                [result appendString:@" @ "];
            }

            typeDescription = [self typeDescription];

            if (typeDescription) {
                [result appendString:typeDescription];
                [result appendString:@" "];
            }

            service = [self service];

            if (service) {
                [result appendString:service];
            }

            comment = [self comment];

            if (comment) {
                [result appendString:@" ("];
                [result appendString:comment];
                [result appendString:@")"];
            }

            break;
            
            //return [NSString stringWithFormat:@"%@: %@ @ [%@] %@ (%@)", [self label], [self account], [self typeDescription], [self service], [self comment]]; break;
        case kSecAppleSharePasswordItemClass: // <label>: <account> @ <protocol>://<server> (<comment>)
            label = [self label];

            if (label) {
                [result appendString:label];
                [result appendString:@": "];
            }

            account = [self account];

            if (account) {
                [result appendString:account];
                [result appendString:@" @ "];
            }

            protocol = shortNameOfProtocol([self protocol]);

            if (protocol) {
                [result appendString:protocol];
                [result appendString:@"://"];
            }

            server = [self server];

            if (server) {
                [result appendString:server];
            }

            comment = [self comment];

            if (comment) {
                [result appendString:@" ("];
                [result appendString:comment];
                [result appendString:@")"];
            }

            break;
            
            //return [NSString stringWithFormat:@"%@: %@ @ %@://%@ (%@)", [self label], [self account], [self protocolString], [self server], [self comment]]; break;
        case kSecCertificateItemClass: // <label>: \"<subject common name>\", signed by \"<issuer common name>\" (<comment>)
        case CSSM_DL_DB_RECORD_CERT: // Should be equivalent to kSecCertificateItemClass in content (not the same numerical type, though)
            cert = [self certificate];

            label = [self label];

            if (label) {
                [result appendString:label];
                [result appendString:@": "];
            }

            [result appendString:[NSString stringWithFormat:@"\"%@\", signed by %@", [[cert subject] firstPairForType:&CSSMOID_CommonName], [[cert issuer] firstPairForType:&CSSMOID_CommonName]]];

            comment = [self comment];

            if (comment) {
                [result appendString:@" ("];
                [result appendString:comment];
                [result appendString:@")"];
            }
            
            break;
        case CSSM_DL_DB_RECORD_USER_TRUST:
            return @"Trust Object (Description forthcoming)"; break;
            //return [[Trust trustWithTrustRef:(SecTrustRef)_keychainItem] description]; break;
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
    _error = SecKeychainItemDelete(_keychainItem);
	
	if (noErr != _error) {
		PSYSLOGND(LOG_ERR, @"Unable to delete KeychainItem - error %@.\n", OSStatusAsString(_error));
		PDEBUG(@"SecKeychainItemDelete(%p) returned error %@.\n", _keychainItem, OSStatusAsString(_error));
	}
}

- (OSStatus)lastError {
    return _error;
}

- (SecKeychainItemRef)keychainItemRef {
    return _keychainItem;
}

- (void)dealloc {
    if (_keychainItem) {
        CFRelease(_keychainItem);
    }
    
    [super dealloc];
}

@end


/*! @class KeychainItemPredicateProxy
	@abstract Translates a KeychainItem's attributes into a form suitable for use in an NSPredicate.
	@discussion You can use this as the evaluation object for an NSPredicate instead of the KeychainItem directly.  It translates the attributes of the KeychainItem into a form that is more conducive to use in an NSPredicate. */

@interface KeychainItemPredicateProxy : NSObject {
	KeychainItem *_keychainItem;
}

+ (KeychainItemPredicateProxy*)proxyForKeychainItem:(KeychainItem*)keychainItem;

- (KeychainItemPredicateProxy*)initWithKeychainItem:(KeychainItem*)keychainItem;

- (id)valueForKey:(NSString*)key;

@end

@implementation KeychainItemPredicateProxy

+ (KeychainItemPredicateProxy*)proxyForKeychainItem:(KeychainItem*)keychainItem {
	return [[[[self class] alloc] initWithKeychainItem:keychainItem] autorelease];
}

- (KeychainItemPredicateProxy*)initWithKeychainItem:(KeychainItem*)keychainItem {
	if (nil == keychainItem) {
		PSYSLOG(LOG_ERR, @"Cannot create KeychainItemPredicateProxy without a KeychainItem.\n");
		[self release];
		self = nil;
	} else if (![keychainItem isKindOfClass:[KeychainItem class]]) {
		PSYSLOG(LOG_ERR, @"Cannot create a KeychainItemPredicateProxy for objects of class \"%@\".\n", [keychainItem className]);
		[self release];
		self = nil;
	} else {
		if (self = [super init]) {
			_keychainItem = [keychainItem retain];
		}
	}
	
	return self;
}

- (void)dealloc {
	[_keychainItem release];
	
	[super dealloc];
}

- (id)valueForKey:(NSString*)key {
	// TODO: The problem with all these is that we use the constants.  That's nice and precise and perfectly fine if you're working with the predicate strings programmatically.  However, it'd be really sweet if we supported the case where you can just take a string from the user, and they're naturally going to want to use natural names like "private key" or "x.509" or "pkcs7" or whatever.  We could return an array as the value, containing all the different representations for a given value, but then the user has to write "IN" instead of "=", which is unnatural... so we'd probably need to provide a method to suitably upgrade predicates... gah.
	
	if ([key isEqualToString:@"authenticationType"]) {
		return nameOfAuthenticationTypeConstant([_keychainItem authenticationType]);
	} else if ([key isEqualToString:@"appleShareSignature"]) {
		return AFPServerSignatureAsString([_keychainItem appleShareSignature]);
	} else if ([key isEqualToString:@"protocol"]) {
		return nameOfProtocolConstant([_keychainItem protocol]);
	} else if ([key isEqualToString:@"certificateType"]) {
		return nameOfCertificateTypeConstant([_keychainItem certificateType]);
	} else if ([key isEqualToString:@"CRLType"]) {
		return nameOfCRLTypeConstant([_keychainItem CRLType]);
	} else if ([key isEqualToString:@"CRLEncoding"]) {
		return nameOfCRLEncodingConstant([_keychainItem CRLEncoding]);
	} else {
		// We don't recognise it as anything that needs special handling, so we'll just pass it on directly.
		return [_keychainItem valueForKey:key];
	}
}

@end


@implementation NSArray (KeychainFrameworkPredicateSupport)

- (NSArray*)filteredArrayUsingKeychainPredicate:(NSPredicate*)predicate {
	NSMutableArray *results = [NSMutableArray array];
	NSEnumerator *enumerator = [self objectEnumerator];
	id current;
	
	while (current = [enumerator nextObject]) {
		if ([predicate evaluateWithObject:[KeychainItemPredicateProxy proxyForKeychainItem:current]]) {
			[results addObject:current];
		}
	}
	
	return results;
}

@end
