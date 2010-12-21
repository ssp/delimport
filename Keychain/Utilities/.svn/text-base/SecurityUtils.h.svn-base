//
//  SecurityUtils.h
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

/*! @header SecurityUtils
	@abstract Utility functions and paraphernalia for the Security framework layer.
	@discussion This file is something of a catch-all for numerous utility functions based around types or functions in the Security framework layer of the Security framework (i.e. basically, anything which is prefixed with "Sec").  A similar but distinct set of functions for handling the CSSM layer is available in @link CSSMUtils.h CSSMUtils.h@/link. */

#import <Security/Security.h>
#import <Foundation/Foundation.h>


/*! @function OSStatusConstant
	@abstract Returns the constant for a given OSStatus error code.
	@discussion The constants are those you would use, as a developer, in writing code - e.g. "errSecNotAvailable".  You should use them whenever you need to display an error code aimed at a developer - e.g. in debug messages.
	@param error The error.
	@result Returns the constant for the given error, or if the error code is not recognised as an OSStatus code, calls @link CSSMErrorConstant CSSMErrorConstant@/link with it. */

NSString* OSStatusConstant(OSStatus error);

/*! @function OSStatusDescription
	@abstract Returns a human-readable description for a given OSStatus error code.
	@discussion The descriptions are medium-length, human-readable strings detailing what the given error code means.  Not all error codes are guaranteed to have a description.
	@param error The error to describe.
	@result Returns a human-readable description of the given error, or if the error code is not recognised or not one that has a description, calls @link CSSMErrorDescription CSSMErrorDescription@/link. */

NSString* OSStatusDescription(OSStatus error);

/*! @function OSStatusAsString
    @abstract Returns the name and description of a given OSStatus error code.
    @discussion When displaying errors to the user you should always provide at least the numeric code and a human-readable description.  It typically doesn't hurt to also provide the constant corresponding to the error code, to aid in recognition and to speed debugging.  This function returns a string containing all three, in the general format "<constant> (<code>) - <description>".
				
                The description part of the returned string may be localised.
				
                The Security framework treats OSStatus' as a superset of CSSM errors.  If this function cannot find an appropriate translation as an OSStatus error code, it defers to CSSMErrorAsString.
    @param error The OSStatus error code.
    @result Returns a human-readable string of the format "<constant> (<code>) - <description>".  Defers to CSSMErrorAsString for unrecognised codes. */

NSString* OSStatusAsString(OSStatus error);

/*! @function nameOfAuthenticationTypeConstant
    @abstract Returns the constant corresponding to a given authentication type.
    @discussion The constants are defined in SecKeychain.h of the Security framework.
	@param type The authentication type.
    @result Returns the constant corresponding to the given authentication type, or a localised string of the form "Unknown (XXXX)" - where XXXX is the authentication type as a string (FourCharCode) value - if an unknown authentication type is provided. */

NSString* nameOfAuthenticationTypeConstant(SecAuthenticationType type);

/*! @function nameOfAuthenticationType
    @abstract Returns the human-readable name of a given authentication type.
    @discussion The names returned are simple, short & human-readable.  e.g. the authentication type kSecAuthenticationTypeHTTPDigest returns "HTTP Digest Access".  The names may be localised.
    @param type The authentication type.
    @result Returns the localised name of the given authentication type, or a localised string of the form "Unknown (XXXX)" - where XXXX is the authentication type as a string (FourCharCode) value - if an unknown authentication type is provided. */

NSString* nameOfAuthenticationType(SecAuthenticationType type);

/*! @function nameOfProtocolConstant
    @abstract Returns the constant corresponding to a given protocol.
    @discussion The constants are defined in SecKeychain.h of the Security framework.
	@param protocol The protocol.
    @result Returns the constant corresponding to the given protocol, or a localised string of the form "Unknown (XXXX)" - where XXXX is the protocol as a string (FourCharCode) value - if an unknown protocol is provided. */

NSString* nameOfProtocolConstant(SecProtocolType protocol);

/*! @function shortNameOfProtocol
    @abstract Returns a short, human-readable name of a given protocol.
    @discussion The names returned are simple, short & human-readable.  e.g. the protocol kSecProtocolTypeLDAPS returns "LDAP over TLS/SSL".  The names may be localised.
    @param protocol The protocol.
    @result Returns the localised short name of the given protocol, or a localised string of the form "Unknown (XXXX)" - where XXXX is the protocol as a string (FourCharCode) value - if an unknown protocol is provided. */

NSString* shortNameOfProtocol(SecProtocolType protocol);

/*! @function longNameOfProtocol
    @abstract Returns a verbose, human-readable name of a given protocol.
    @discussion The names returned are relatively verbose, compared to those returned by @link shortNameOfProtocol shortNameOfProtocol@/link.  e.g. the protocol kSecProtocolTypeLDAPS returns "LDAP (Lightweight Directory Access Protocol) over TLS/SSL (Transport Layer Security / Secure Socket Library)".  The names may be localised.
    @param protocol The protocol.
    @result Returns the localised long name of the given protocol, or a localised string of the form "Unknown (XXXX)" - where XXXX is the protocol as a string (FourCharCode) value - if an unknown protocol is provided. */

NSString* longNameOfProtocol(SecProtocolType protocol);

/*! @function nameOfKeychainAttributeConstant
    @abstract Returns the constant corresponding to a given KeychainItem attribute type.
    @discussion The constants are defined in SecKeychainItem.h of the Security framework.
	@param attributeType The attribute type.
    @result Returns the constant corresponding to the given attribute type, or a localised string of the form "Unknown (XXXX)" - where XXXX is the attribute type as a string (FourCharCode) value - if an unknown attribute type is provided. */

NSString* nameOfKeychainAttributeConstant(SecKeychainAttrType attributeType);

/*! @function nameOfKeychainAttribute
    @abstract Returns the human-readable name of a given KeychainItem attribute type.
    @discussion The names returned are simple, short & human-readable.  e.g. the attribute type kSecAlias returns "Alias".  The names may be localised.
    @param attributeType The attribute type.
    @result Returns the localised name of the given attribute type, or a localised string of the form "Unknown (XXXX)" - where XXXX is the attribute type as a string (FourCharCode) value - if an unknown attribute type is provided. */

NSString* nameOfKeychainAttribute(SecKeychainAttrType attributeType);

/*! @function nameOfKeychainItemClassConstant
    @abstract Returns the constant corresponding to a given KeychainItem class.
    @discussion The constants are defined in SecKeychainItem.h of the Security framework.
	@param itemClass The class.
    @result Returns the constant corresponding to the given class, or a localised string of the form "Unknown (XXXX)" - where XXXX is the class as a string (FourCharCode) value - if an unknown class is provided. */

NSString* nameOfKeychainItemClassConstant(SecItemClass itemClass);

/*! @function nameOfKeychainItemClass
    @abstract Returns the human-readable name of a given KeychainItem class.
    @discussion The names returned are simple, short & human-readable.  e.g. the class kSecInternetPasswordItemClass returns "Internet password".  The names may be localised.
    @param itemClass The class.
    @result Returns the localised name of the given class, or a localised string of the form "Unknown (XXXX)" - where XXXX is the class as a string (FourCharCode) value - if an unknown class is provided. */

NSString* nameOfKeychainItemClass(SecItemClass itemClass);

/*! @function AFPServerSignatureAsString
	@abstract Returns a human-readable representation of the given SecAFPServerSignature.
	@discussion At present this function simply renders the given signature in hex form, as one long string.  This behaviour isn't strictly defined, however, and may change in future.
	@param signature The signature.  Should not be nil.
	@result Returns the given signature in a human-readable representation, or nil if nil was passed for the signature parameter. */

NSString* AFPServerSignatureAsString(SecAFPServerSignature *signature);

/*! @method nameOfExternalFormat
	@abstract Returns the human-readable name of a given external format.
    @discussion The names returned are simple, short & human-readable.  e.g. the format kSecFormatWrappedOpenSSL returns "Wrapped OpenSSL".  The names may be localised.
    @param format The format.
    @result Returns the name of the given external format, or (localised) "Unknown (X)" - where X is the format as an integer value - if an unknown format is provided. */

NSString* nameOfExternalFormat(SecExternalFormat format);

/*! @method nameOfExternalFormatConstant
	@abstract Returns the constant corresponding to the given external format.
    @discussion The constants are defined in SecImportExport.h in Apple's Security framework.
    @param format The format.
    @result Returns the constant corresponding to the given external format, or (localised) "Unknown (X)" - where X is the format as an integer value - if an unknown format is provided. */

NSString* nameOfExternalFormatConstant(SecExternalFormat format);

/*! @method nameOfExternalItemType
	@abstract Returns the human-readable name of a given external item type.
    @discussion The names returned are simple, short & human-readable.  e.g. the type kSecItemTypePrivateKey returns "Private Key".  The names may be localised.
    @param format The format.
    @result Returns the name of the given external format, or (localised) "Unknown (X)" - where X is the format as an integer value - if an unknown format is provided. */

NSString* nameOfExternalItemType(SecExternalItemType type);

/*! @method nameOfExternalItemTypeConstant
	@abstract Returns the constant corresponding to the given external item type.
    @discussion The constants are defined in SecImportExport.h in Apple's Security framework.
    @param format The format.
    @result Returns the constant corresponding to the given external format, or (localised) "Unknown (X)" - where X is the format as an integer value - if an unknown format is provided. */

NSString* nameOfExternalItemTypeConstant(SecExternalItemType type);
