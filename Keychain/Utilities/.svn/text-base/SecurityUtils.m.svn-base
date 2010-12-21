//
//  SecurityUtils.m
//  Keychain
//
//  Created by Wade Tregaskis on Fri Jun 30 2006.
//
//  Copyright (c) 2006 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Keychain/SecurityUtils.h>

#import <Keychain/LocalisationUtils.h>
#import <Keychain/CSSMUtils.h>


NSString* OSStatusConstant(OSStatus error) {
	NSString *constantName = localizedString([NSString stringWithFormat:@"%d", error], @"OSStatus Constants");
	
	if (nil == constantName) {
		return CSSMErrorConstant((CSSM_RETURN)error);
	} else {
		return constantName;
	}
}

NSString* OSStatusDescription(OSStatus error) {
	NSString *description = localizedString([NSString stringWithFormat:@"%d", error], @"OSStatus Descriptions");
	
	if (nil == description) {
		return CSSMErrorDescription((CSSM_RETURN)error);
	} else {
		return description;
	}
}

NSString* OSStatusAsString(OSStatus error) {
	// This is implemented without using OSStatusConstant or OSStatusDescription as we don't want to put in "Unknown (XXX)" crap into our string; if we can't find any info for it we defer to CSSMErrorAsString entirely, otherwise we just include the bits we have.
	
	NSString *errorCodeAsString = [NSString stringWithFormat:@"%ld", (long)error];
    NSString *constantName = localizedString(errorCodeAsString, @"OSStatus Constants");
	NSString *description = localizedString(errorCodeAsString, @"OSStatus Descriptions");
	
    if (nil != constantName) {
		if (nil != description) {
			return [NSString stringWithFormat:@"%@ (#%@) - %@", constantName, errorCodeAsString, description];
		} else {
			return [NSString stringWithFormat:@"%@ (#%@)", constantName, errorCodeAsString];
		}
    } else {
		if (nil != description) {
			return [NSString stringWithFormat:@"#%@ - %@", errorCodeAsString, description];
		} else {
			return CSSMErrorAsString((CSSM_RETURN)error);
		}
    }
}

FOUNDATION_STATIC_INLINE NSString *NSStringFromBigEndianFourCharCode(FourCharCode code)
{
	FourCharCode swappedCode = NSSwapBigIntToHost(code);
	NSData *data = [NSData dataWithBytes:&swappedCode length:sizeof(FourCharCode)];
	NSString *string = [[NSString alloc] initWithData:data encoding:NSMacOSRomanStringEncoding];
	
	return [string autorelease];
}

FOUNDATION_STATIC_INLINE NSString *NSStringFromHostFourCharCode(FourCharCode code)
{
	NSData *data = [NSData dataWithBytes:&code length:sizeof(FourCharCode)];
	NSString *string = [[NSString alloc] initWithData:data encoding:NSMacOSRomanStringEncoding];
	
	return [string autorelease];
}

NSString* nameOfAuthenticationTypeConstant(SecAuthenticationType type) {
    return localizedStringWithFallback(NSStringFromHostFourCharCode(type), @"Authentication Type Constants");
}

NSString* nameOfAuthenticationType(SecAuthenticationType type) {
    return localizedStringWithFallback(NSStringFromHostFourCharCode(type), @"Authentication Type Names");
}

NSString* nameOfProtocolConstant(SecProtocolType type) {
    return localizedStringWithFallback(NSStringFromBigEndianFourCharCode(type), @"Protocol Type Constants");
}

NSString* shortNameOfProtocol(SecProtocolType type) {
    return localizedStringWithFallback(NSStringFromBigEndianFourCharCode(type), @"Protocol Type Short Names");
}

NSString* longNameOfProtocol(SecProtocolType type) {
    return localizedStringWithFallback(NSStringFromBigEndianFourCharCode(type), @"Protocol Type Long Names");
}

NSString* nameOfKeychainAttributeConstant(SecKeychainAttrType type) {
    return localizedStringWithFallback(NSStringFromBigEndianFourCharCode(type), @"Keychain Attribute Type Constants");
}

NSString* nameOfKeychainAttribute(SecKeychainAttrType type) {
    return localizedStringWithFallback(NSStringFromBigEndianFourCharCode(type), @"Keychain Attribute Type Names");
}

NSString* nameOfKeychainItemClassConstant(SecItemClass class) {
	return localizedStringWithFallback([NSString stringWithFormat:@"0x%08x", (unsigned int)class], @"KeychainItem Class Constants");
}

NSString* nameOfKeychainItemClass(SecItemClass class) {
	return localizedStringWithFallback([NSString stringWithFormat:@"0x%08x", (unsigned int)class], @"KeychainItem Class Names");
}

NSString* AFPServerSignatureAsString(SecAFPServerSignature *signature) {
	if (nil == signature) {
		return nil;
	} else {
		unsigned int i;
		NSMutableString *result = [NSMutableString string];
		const char *signatureBytes = (const char*)signature;

		for (i = 0; i < sizeof(SecAFPServerSignature); ++i) {
			[result appendFormat:@"%02x", signatureBytes[i]];
		}

		return result;
	}
}

NSString* nameOfExternalFormat(SecExternalFormat format) {
	return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu32, format], @"External Format Names");
}

NSString* nameOfExternalFormatConstant(SecExternalFormat format) {
	return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu32, format], @"External Format Constants");
}

NSString* nameOfExternalItemType(SecExternalItemType type) {
	return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu32, type], @"External Item Type Names");
}

NSString* nameOfExternalItemTypeConstant(SecExternalItemType type) {
	return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu32, type], @"External Item Type Constants");
}
