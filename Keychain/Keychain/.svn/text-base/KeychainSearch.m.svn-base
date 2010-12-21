//
//  KeychainSearch.m
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

#import <Keychain/KeychainSearch.h>
#import <Keychain/KeychainSearchInternal.h>

#import <Keychain/SecurityUtils.h>

#import <Keychain/KeychainItem.h>
#import <Keychain/NSDataAdditions.h>
#import <Keychain/NSCalendarDateAdditions.h>
#import <Keychain/Logging.h>


@implementation SearchAttribute

+ (SearchAttribute*)attributeWithTag:(SecKeychainAttrType)tag length:(size_t)length data:(void*)data freeWhenDone:(BOOL)fre {
    return [[[[self class] alloc] initWithTag:tag length:length data:data freeWhenDone:fre] autorelease];
}

+ (SearchAttribute*)attributeWithTag:(SecKeychainAttrType)tag length:(size_t)length data:(const void *)data {
    return [[[[self class] alloc] initWithTag:tag length:length data:data] autorelease];
}

- (SearchAttribute*)initWithTag:(SecKeychainAttrType)tag length:(size_t)length data:(void*)data freeWhenDone:(BOOL)fre {
	if (length <= UINT32_MAX) {		
		if ((NULL != data) || (0 == length)) {
			if (self = [super init]) {
				attribute.tag = tag;
				attribute.length = (uint32)length;
				attribute.data = data;

				freeWhenDone = fre;
			}
		} else {
			[self release], self = nil;
		}
    } else {
		PSYSLOG(LOG_ERR, @"Invalid argument, length (value %llu) is greater than UINT32_MAX.\n", (unsigned long long)length);
        [self release], self = nil;
	}
	
	return self;
}

- (SearchAttribute*)initWithTag:(SecKeychainAttrType)tag length:(size_t)length data:(const void *)data {
    void *copyOfData;
    
    if ((length >= 0) && ((NULL != data) || (0 == length))) {
		if (self = [super init]) {
			if ((0 < length) && (NULL != data)) {
				copyOfData = malloc(length);
				memcpy(copyOfData, data, length);
			} else {
				copyOfData = NULL;
			}
			
			attribute.tag = tag;
			attribute.length = (uint32)length;
			attribute.data = copyOfData;

			freeWhenDone = YES;
		}

        return self;
    } else {
        PSYSLOG(LOG_ERR, @"Invalid parameters; 0 == length (%"PRIu32") and/or NULL == data (%p).\n", length, data);
        [self release];
        
        return nil;
    }
}

- (SearchAttribute*)init {
	PSYSLOG(LOG_ERR, @"SearchAttribute's cannot be created using -init.\n");
    [self release];
    return nil;
}

- (SecKeychainAttrType)type {
    return attribute.tag;
}

- (SecKeychainAttributePtr)attributePtr {
    return &attribute;
}

- (NSPredicate*)_predicate {
	NSPredicate *result = nil;
	id equalityValue = nil;
	
	switch (attribute.tag) {
		case kSecCreationDateItemAttr:
		case kSecModDateItemAttr:
			equalityValue = [NSCalendarDate dateWithClassicMacLongDateTime:*((int64_t*)(attribute.data)) timeZone:[NSTimeZone defaultTimeZone]];
			break;
		case kSecDescriptionItemAttr:
		case kSecCommentItemAttr:
		case kSecCreatorItemAttr: // Should we be treating this as just a generic string?  It's actually a FourCharCode.
		case kSecTypeItemAttr: // Should we be treating this as just a generic string?  It's actually a FourCharCode.
		case kSecLabelItemAttr:
		case kSecAccountItemAttr:
		case kSecServiceItemAttr:
		case kSecSecurityDomainItemAttr:
		case kSecServerItemAttr:
		case kSecPathItemAttr:
		case kSecVolumeItemAttr:
		case kSecAddressItemAttr:
		case kSecAlias:
			equalityValue = [[[NSString alloc] initWithBytes:attribute.data length:attribute.length encoding:NSUTF8StringEncoding] autorelease];
			break;
		case kSecGenericItemAttr:
			equalityValue = [[NSData dataWithBytes:attribute.data length:attribute.length] description];
			break;
		case kSecScriptCodeItemAttr:
			// TODO; WTF is this?
			break;
		case kSecInvisibleItemAttr:
			equalityValue = [NSNumber numberWithBool:(0 == *((uint32_t*)(attribute.data)))];
			break;
		case kSecNegativeItemAttr:
		case kSecCustomIconItemAttr:
			equalityValue = [NSNumber numberWithBool:(0 != *((uint32_t*)(attribute.data)))];
			break;
		case kSecAuthenticationTypeItemAttr:
			equalityValue = nameOfAuthenticationTypeConstant(*((SecAuthenticationType*)(attribute.data)));
			break;
		case kSecPortItemAttr:
			equalityValue = [NSNumber numberWithUnsignedShort:(*((uint16_t*)(attribute.data)))];
			break;
		case kSecSignatureItemAttr:
			equalityValue = AFPServerSignatureAsString((SecAFPServerSignature*)(attribute.data));
			break;
		case kSecProtocolItemAttr:
			equalityValue = nameOfProtocolConstant(*((SecProtocolType*)(attribute.data)));
			break;
		case kSecCertificateType:
			equalityValue = nameOfCertificateTypeConstant(*((CSSM_CERT_TYPE*)(attribute.data)));
			break;
		case kSecCertificateEncoding:
			equalityValue = nameOfCertificateEncodingConstant(*((CSSM_CERT_ENCODING*)(attribute.data)));
			break;
		case kSecCrlType:
			equalityValue = nameOfCRLTypeConstant(*((CSSM_CRL_TYPE*)(attribute.data)));
			break;
		case kSecCrlEncoding:
			equalityValue = nameOfCRLEncodingConstant(*((CSSM_CRL_ENCODING*)(attribute.data)));
			break;
		default:
			PSYSLOG(LOG_ERR, @"Don't know how to represent the attribute \"%@\" as a predicate string.\n", nameOfKeychainAttributeConstant(attribute.tag));
	}
	
	if (nil == result) {
		if (nil != equalityValue) {
			result = [NSPredicate predicateWithFormat:@"%K = %@", [KeychainItem nameOfGetterForAttribute:attribute.tag], equalityValue];
		}
	}
	
	return result;
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

+ (KeychainSearch*)keychainSearchWithKeychains:(NSArray*)keychains predicate:(NSPredicate*)predicate {
	return [[[[self class] alloc] initWithKeychains:keychains predicate:predicate] autorelease];
}

- (KeychainSearch*)initWithKeychains:(NSArray*)keychains {
    return [self initWithKeychains:keychains predicate:nil];
}

- (KeychainSearch*)initWithKeychains:(NSArray*)keychains predicate:(NSPredicate*)predicate {
	if (self = [super init]) {
        if (keychains) {
            _keychainList = [keychains copy];
        } else {
            _keychainList = nil;
        }
        
		if (nil == predicate) {
			_attributes = [[NSMutableArray alloc] init];
		} else {
			_attributes = nil;
		}
		
		_predicate = [predicate copy];
		
        _error = 0;
    }
    
    return self;
}

- (KeychainSearch*)init {
    return [self initWithKeychains:nil];
}

- (void)dealloc {
	[_attributes release];
	[_predicate release];
	
	[super dealloc];
}

- (void)setPredicate:(NSPredicate*)predicate {
	if (_predicate != predicate) {
		if (nil != predicate) {
			[_attributes release];
			_attributes = nil;
		} else {
			_attributes = [[NSMutableArray alloc] init];
		}
		
		NSPredicate *newPredicate = [predicate copy];
		[_predicate release];
		_predicate = newPredicate;
	}
}

- (NSPredicate*)_generatePredicate {
	NSEnumerator *enumerator = [_attributes objectEnumerator];
	SearchAttribute *current;
	NSMutableArray *predicateComponents = [NSMutableArray arrayWithCapacity:[_attributes count]];
	NSPredicate *currentPredicate;
	
	while (current = [enumerator nextObject]) {
		currentPredicate = [current _predicate];
		
		if (nil == currentPredicate) {
			PSYSLOG(LOG_ERR, @"Unable to express the attribute \"%@\" as a predicate - cannot then represent the keychain search as a predicate.\n", [current description]);
			return nil;
		} else {
			[predicateComponents addObject:currentPredicate];
		}
	}
	
	return [NSCompoundPredicate andPredicateWithSubpredicates:predicateComponents];
}

- (void)_promoteToPredicateBecause:(NSString*)reason {
	PDEBUG(@"KeychainSearch %p needed to be promoted to predicate-form because: %@", self, reason);
	
	if (nil != _predicate) {
		if (nil != _attributes) {
			PSYSLOG(LOG_WARNING, @"Somehow _predicate is not nil (== \"%@\"), but then neither is _attributes (== \"%@\")... that's not good.  Going to try concatentating them, but it's not guaranteed to work.\n", _predicate, _attributes);
			
			NSPredicate *predicateVersionOfCurrentAttributes = [self _generatePredicate];
			
			if (nil != predicateVersionOfCurrentAttributes) {
				_predicate = [[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:_predicate, predicateVersionOfCurrentAttributes, nil]] retain];
				
				[_attributes release];
				_attributes = nil;
			} else {
				PSYSLOG(LOG_ERR, @"Unable to represent current attributes as a predicate, so cannot combine them with the existing predicate.  KeychainSearch %p remains in an unstable state.\n", self);
			}
		} // Else we're already promoted to a predicate, so we do nothing.
	} else {
		_predicate = [[self _generatePredicate] retain];
		
		if (nil != _predicate) {
			[_attributes release];
			_attributes = nil;
		} else {
			PSYSLOG(LOG_ERR, @"Unable to represent current attributes as a predicate - unable to perform promotion.\n");
		}
	}
}

- (NSPredicate*)predicate {
	if (nil != _predicate) {
		return _predicate;
	} else {
		return [self _generatePredicate];
	}
}

- (void)_removeAttributesOfType:(SecKeychainAttrType)type {
    NSInteger i = [_attributes count] - 1;
    SearchAttribute *current;
    
	// FLAG: this is tricky... we should either figure out a *reliable* way to remove the appropriate attributes from a predicate string, or perhaps better yet fully convert to allowing multiple (logically or'd) predicates on a single attribute, in which case this method can go away entirely.
	
    while (0 <= i) {
        current = [_attributes objectAtIndex:i];
        
        if (type == [current type]) {
            [_attributes removeObjectAtIndex:i];
        }
        
        --i;
    }
}

- (void)_addAttribute:(SearchAttribute*)searchAttribute {
	if (nil != searchAttribute) {
		if (nil != _predicate) {
			NSPredicate *attributesPredicate = [searchAttribute _predicate];
			
			if (nil != attributesPredicate) {
				NSPredicate *newPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:_predicate, attributesPredicate, nil]];
				
				if (nil != newPredicate) {
					_predicate = [newPredicate retain];
				} else {
					PSYSLOG(LOG_ERR, @"Unable to construct compound predicate composed of existing predicate (%@) and new attribute's predicate (%@).  The existing predicate has not been modified.\n", _predicate, attributesPredicate);
					_error = errSecUnsupportedFormat;
				}
			} else {
				PSYSLOG(LOG_ERR, @"Unable to convert attribute to a predicate.  Attribute is: %@\n", attributesPredicate);
				_error = errSecUnsupportedFormat;
			}
		} else {
			[_attributes addObject:searchAttribute];
		}
	} else {
		PSYSLOG(LOG_ERR, @"Invalid parameter - searchAttribute is nil.\n");
	}
}

- (void)_setAttribute:(SecKeychainAttrType)tag stringValue:(NSString*)value {
	[self _removeAttributesOfType:tag]; // Note: see comment in _removeAttributesOfType: about whether or not we really should be doing this anyway.
    
    if (nil != value) {
		const char *utf8Value = [value UTF8String];
		
		[self _addAttribute:[SearchAttribute attributeWithTag:tag length:strlen(utf8Value) data:utf8Value]];
		
		if (0 == [value length]) {
			[self _promoteToPredicateBecause:[NSString stringWithFormat:@"empty string comparison for %@", nameOfKeychainAttributeConstant(tag)]];
		}
	}
}

- (void)_setAttribute:(SecKeychainAttrType)tag dataValue:(NSData*)value {
	[self _removeAttributesOfType:tag]; // Note: see comment in _removeAttributesOfType: about whether or not we really should be doing this anyway.
	
	if (nil != value) {
		[self _addAttribute:[SearchAttribute attributeWithTag:tag length:[value length] data:[value bytes]]];
		
		if (0 == [value length]) {
			[self _promoteToPredicateBecause:[NSString stringWithFormat:@"use of empty binary blob attribute %@", nameOfKeychainAttributeConstant(tag)]];
		}
	}
}

- (void)_setAttribute:(SecKeychainAttrType)tag calendarDateValue:(NSCalendarDate*)date {
	[self _removeAttributesOfType:tag]; // Note: see comment in _removeAttributesOfType: about whether or not we really should be doing this anyway.
    
    if (nil != date) {
        int64_t *temp = malloc(sizeof(int64_t));
        
        if (NULL != temp) {
            *temp = [date classicMacLongDateTimeForTimeZone:[NSTimeZone defaultTimeZone]];
            
            [self _addAttribute:[SearchAttribute attributeWithTag:tag length:sizeof(int64_t) data:(void*)temp freeWhenDone:YES]];
        } else {
            [NSException raise:@"UnableToAllocateMemoryException" format:@"Unable to allocate memory for %@ attribute.", nameOfKeychainAttributeConstant(tag)];
        }
    }
}

- (void)_setAttribute:(SecKeychainAttrType)tag boolValue:(BOOL)value {
	uint32_t *valuePtr = malloc(sizeof(uint32_t));
	
	[self _removeAttributesOfType:tag]; // Note: see comment in _removeAttributesOfType: about whether or not we really should be doing this anyway.
    
	*valuePtr = (value ? 1 : 0);
	
    [self _addAttribute:[SearchAttribute attributeWithTag:tag length:sizeof(uint32_t) data:(void*)valuePtr freeWhenDone:YES]];
	
	[self _promoteToPredicateBecause:[NSString stringWithFormat:@"use of boolean attribute %@", nameOfKeychainAttributeConstant(tag)]];
}

- (void)setCreationDate:(NSCalendarDate*)date {
	[self _setAttribute:kSecCreationDateItemAttr calendarDateValue:date];
}

- (void)setModificationDate:(NSCalendarDate*)date {
	[self _setAttribute:kSecModDateItemAttr calendarDateValue:date];
}

- (void)setTypeDescription:(NSString*)desc {
	[self _setAttribute:kSecDescriptionItemAttr stringValue:desc];
}

- (void)setComment:(NSString*)comment {
	[self _setAttribute:kSecCommentItemAttr stringValue:comment];
}

- (void)setCreator:(NSString*)creator {
	[self _setAttribute:kSecCreatorItemAttr stringValue:creator];
}

- (void)setType:(NSString*)type {
	[self _setAttribute:kSecTypeItemAttr stringValue:type];
	
	// I'm not sure if the special-casing below is necessary or useful... it doesn't seem to help; I don't think it addresses the fundamental issue, which is how the Security framework handles missing and/or empty values.
	
    /*[self _removeAttributesOfType:kSecTypeItemAttr];
	
    if (nil != type) {		
		if (0 == [type length]) {
			static const uint32_t blankType = 0;
			
			searchAttribute = [SearchAttribute attributeWithTag:kSecTypeItemAttr length:4 data:(void*)&blankType];
		} else {
			searchAttribute = [SearchAttribute attributeWithTag:kSecTypeItemAttr length:[type cStringLength] data:[type cString]];
		}
		
		[_attributes addObject:searchAttribute];
	}*/
}

- (void)setLabel:(NSString*)label {
	[self _setAttribute:kSecLabelItemAttr stringValue:label];
}

- (void)setIsVisible:(BOOL)visible {
	[self _setAttribute:kSecInvisibleItemAttr boolValue:!visible];
}

- (void)setPasswordIsValid:(BOOL)valid {
	[self _setAttribute:kSecNegativeItemAttr boolValue:valid];
}

- (void)setHasCustomIcon:(BOOL)customIcon {
	[self _setAttribute:kSecCustomIconItemAttr boolValue:customIcon];
}

- (void)setAccount:(NSString*)account {
	[self _setAttribute:kSecAccountItemAttr stringValue:account];
}

- (void)setService:(NSString*)service {
	[self _setAttribute:kSecServiceItemAttr stringValue:service];
}

- (void)setUserDefinedAttribute:(NSData*)attr {
	[self _setAttribute:kSecGenericItemAttr dataValue:attr];
}

- (void)setSecurityDomain:(NSString*)securityDomain {
	[self _setAttribute:kSecSecurityDomainItemAttr stringValue:securityDomain];
}

- (void)setServer:(NSString*)server {
	[self _setAttribute:kSecServerItemAttr stringValue:server];
}

- (void)setAuthenticationType:(SecAuthenticationType)type {
    SecAuthenticationType *temp = malloc(sizeof(SecAuthenticationType));

    [self _removeAttributesOfType:kSecAuthenticationTypeItemAttr];
    
    *temp = type;

    [_attributes addObject:[SearchAttribute attributeWithTag:kSecAuthenticationTypeItemAttr length:sizeof(SecAuthenticationType) data:(void*)temp freeWhenDone:YES]];
	
	if (0 == type) {
		[self _promoteToPredicateBecause:@"use of value 0 for kSecAuthenticationTypeItemAttr"];
	}
}

- (void)setPort:(uint16_t)port {
    uint16_t *temp = malloc(sizeof(uint16_t));

    [self _removeAttributesOfType:kSecPortItemAttr];
    
    *temp = port;

    [_attributes addObject:[SearchAttribute attributeWithTag:kSecPortItemAttr length:sizeof(uint16_t) data:(void*)temp freeWhenDone:YES]];
	
	if (0 == port) {
		[self _promoteToPredicateBecause:@"use of value 0 for kSecPortItemAttr"];
	}
}

- (void)setPath:(NSString*)path {
	[self _setAttribute:kSecPathItemAttr stringValue:path];
}

- (void)setAppleShareVolume:(NSString*)volume {
	[self _setAttribute:kSecVolumeItemAttr stringValue:volume];
}

- (void)setAppleShareAddress:(NSString*)address {
	[self _setAttribute:kSecAddressItemAttr stringValue:address];
}

- (void)setAppleShareSignature:(SecAFPServerSignature*)sig {
    [self _removeAttributesOfType:kSecSignatureItemAttr];
    
    if (NULL != sig) {
        SecAFPServerSignature *temp = malloc(sizeof(SecAFPServerSignature));

        memcpy(temp, (void*)sig, sizeof(SecAFPServerSignature));

        [_attributes addObject:[SearchAttribute attributeWithTag:kSecSignatureItemAttr length:sizeof(SecAFPServerSignature) data:(void*)temp freeWhenDone:YES]];
    }
}

- (void)setProtocol:(SecProtocolType)protocol {
    SecProtocolType *temp = malloc(sizeof(SecProtocolType));

    [self _removeAttributesOfType:kSecProtocolItemAttr];
    
    *temp = protocol;

    [_attributes addObject:[SearchAttribute attributeWithTag:kSecProtocolItemAttr length:sizeof(SecProtocolType) data:(void*)temp freeWhenDone:YES]];
	
	if (0 == protocol) {
		[self _promoteToPredicateBecause:@"use of value 0 for kSecProtocolItemAttr"];
	}
}

- (void)setCertificateType:(CSSM_CERT_TYPE)type {
    CSSM_CERT_TYPE *temp = malloc(sizeof(CSSM_CERT_TYPE));

    [self _removeAttributesOfType:kSecCertificateType];
    
    *temp = type;

    [_attributes addObject:[SearchAttribute attributeWithTag:kSecCertificateType length:sizeof(CSSM_CERT_TYPE) data:(void*)temp freeWhenDone:YES]];
	
	if (0 == type) {
		[self _promoteToPredicateBecause:@"use of value 0 for kSecCertificateType"];
	}
}

- (void)setCertificateEncoding:(CSSM_CERT_ENCODING)encoding {
    CSSM_CERT_ENCODING *temp = malloc(sizeof(CSSM_CERT_ENCODING));

    [self _removeAttributesOfType:kSecCertificateEncoding];
    
    *temp = encoding;

    [_attributes addObject:[SearchAttribute attributeWithTag:kSecCertificateEncoding length:sizeof(CSSM_CERT_ENCODING) data:(void*)temp freeWhenDone:YES]];
	
	if (0 == encoding) {
		[self _promoteToPredicateBecause:@"use of value 0 for kSecCertificateEncoding"];
	}
}

- (void)setCRLType:(CSSM_CRL_TYPE)type {
    CSSM_CRL_TYPE *temp = malloc(sizeof(CSSM_CRL_TYPE));

    [self _removeAttributesOfType:kSecCrlType];
    
    *temp = type;

    [_attributes addObject:[SearchAttribute attributeWithTag:kSecCrlType length:sizeof(CSSM_CRL_TYPE) data:(void*)temp freeWhenDone:YES]];
	
	if (0 == type) {
		[self _promoteToPredicateBecause:@"use of value 0 for kSecCrlType"];
	}
}

- (void)setCRLEncoding:(CSSM_CRL_ENCODING)encoding {
    CSSM_CRL_ENCODING *temp = malloc(sizeof(CSSM_CRL_ENCODING));

    [self _removeAttributesOfType:kSecCrlEncoding];
    
    *temp = encoding;

    [_attributes addObject:[SearchAttribute attributeWithTag:kSecCrlEncoding length:sizeof(CSSM_CRL_ENCODING) data:(void*)temp freeWhenDone:YES]];
	
	if (0 == encoding) {
		[self _promoteToPredicateBecause:@"use of value 0 for kSecCrlEncoding"];
	}
}

- (void)setAlias:(NSString*)alias {
	[self _setAttribute:kSecAlias stringValue:alias];
}

- (NSArray*)searchResultsForClass:(SecItemClass)class {
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:33], *pureKeychainList;
    SecKeychainSearchRef searchRef = NULL;
    SecKeychainAttributeList list;
    SearchAttribute *current;
    SecKeychainItemRef currentItem = NULL;
    NSEnumerator *enumerator = [_attributes objectEnumerator];
    
    if (_keychainList) {
        id currentKeychain;
        NSEnumerator *keychainEnumerator = [_keychainList objectEnumerator];
        
        pureKeychainList = [NSMutableArray arrayWithCapacity:[_keychainList count]];
            
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

    if ((nil != _attributes) && (0 < [_attributes count])) {
        int i = 0;

        list.count = (uint32_t)[_attributes count];
        list.attr = malloc(sizeof(SecKeychainAttribute) * list.count);

        while (current = (SearchAttribute*)[enumerator nextObject]) {
            list.attr[i++] = *[current attributePtr];
        }

        _error = SecKeychainSearchCreateFromAttributes(pureKeychainList, class, &list, &searchRef);
    } else {
        _error = SecKeychainSearchCreateFromAttributes(pureKeychainList, class, NULL, &searchRef);
    }
    
    if ((_error == 0) && searchRef) {
        while (((_error = SecKeychainSearchCopyNext(searchRef, &currentItem)) == 0) && currentItem) {
            [results addObject:[KeychainItem keychainItemWithKeychainItemRef:currentItem]];
            CFRelease(currentItem);
        }

        CFRelease(searchRef);
    } else {
        results = nil;
    }

    if ((nil != _attributes) && (0 < [_attributes count])) {
        free(list.attr);
    }

	if (nil != _predicate) {
		return [results filteredArrayUsingKeychainPredicate:_predicate];
	} else {
		return results;
	}
}

- (NSArray*)anySearchResults {
    NSMutableArray *results = [NSMutableArray array], *pureKeychainList;
    SecKeychainSearchRef searchRef = NULL;
    SecKeychainAttributeList list;
    SecItemClass class[] = {kSecGenericPasswordItemClass, kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass, kSecCertificateItemClass};
    SearchAttribute *current;
    SecKeychainItemRef currentItem = NULL;
    NSEnumerator *enumerator = [_attributes objectEnumerator];
    int i = 0, z = 0;

    if (nil != _keychainList) {
        id currentKeychain;
        NSEnumerator *keychainEnumerator = [_keychainList objectEnumerator];
        
        pureKeychainList = [NSMutableArray arrayWithCapacity:[_keychainList count]];
        
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
    
    if ((nil != _attributes) && (0 < [_attributes count])) {
        list.count = (uint32_t)[_attributes count];
        list.attr = malloc(sizeof(SecKeychainAttribute) * list.count);

        while (current = (SearchAttribute*)[enumerator nextObject]) {
            list.attr[i++] = *[current attributePtr];
        }
    }

    for (z = 0; z < 4; ++z) {
		if ((nil != _attributes) && (0 < [_attributes count])) {
            _error = SecKeychainSearchCreateFromAttributes(pureKeychainList, class[z], &list, &searchRef);
        } else {
            _error = SecKeychainSearchCreateFromAttributes(pureKeychainList, class[z], NULL, &searchRef);
        }

        if ((noErr == _error) && (NULL != searchRef)) {
            while ((noErr == (_error = SecKeychainSearchCopyNext(searchRef, &currentItem))) && (NULL != currentItem)) {
                [results addObject:[KeychainItem keychainItemWithKeychainItemRef:currentItem]];
                CFRelease(currentItem);
            }
            
            CFRelease(searchRef);
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to create search (predicate = \"%@\") for keychain items of class %@, error %@.\n", [self predicate], nameOfKeychainItemClassConstant(class[z]), OSStatusAsString(_error));
			PDEBUG(@"SecKeychainSearchCreateFromAttributes(%@, %@, NULL, %p [%p]) return error %@.\n", pureKeychainList, nameOfKeychainItemClassConstant(class[z]), &searchRef, searchRef, OSStatusAsString(_error));
			
            results = nil;
            break;
        }
    }

    if ((nil != _attributes) && (0 < [_attributes count])) {
        free(list.attr);
    }
    
	if (nil != _predicate) {
		return [results filteredArrayUsingKeychainPredicate:_predicate];
	} else {
		return results;
	}
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

- (OSStatus)lastError {
    return _error;
}

- (NSArray*)keychains {
    return _keychainList;
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
