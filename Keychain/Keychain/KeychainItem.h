//
//  KeychainItem.h
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

#import <Keychain/NSCachedObject.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <Keychain/Access.h>


@class Certificate;
@class Keychain;


/*! @var KeychainFrameworkWarnForMissingKeychainItemAttributes
	@discussion Controls whether or not the framework logs messages for failures to retrieve an attribute of a KeychainItem because the item has no such attribute (specifically, when error errSecNoSuchAttr is returned from the Security framework when asked to retrieve the attribute in question).

				Failures due to any other error will always be logged.

				This setting applies only to getters - all methods which modify attributes will always log any errors that result in failure to modify the attribute as requested.

				The default value is NO. */

extern BOOL KeychainFrameworkWarnForMissingKeychainItemAttributes;


/*! @class KeychainItem
	@abstract Represents a password, certificate, key, or other such keychain item.
	@discussion The KeychainItem is, of course, what the Keychain centres around.  A KeychainItem is in a nutshell just some data - optionally encrypted - with various associated attributes.  Common types of keychain item are passwords (further categorised as "internet", "AppleShare" or "generic") and certificates.  There is also support for storing keys, encrypted text and more, although presently these types are not fully supported by the KeychainItem class.

				You don't usually create KeychainItem's directly, but rather acquire them (as existing items) from a keychain, or as new items created as a result of using a Keychain method such as @link addGenericPassword:onService:forAccount:replaceExisting: addGenericPassword:onService:forAccount:replaceExisting:@/link, @link addInternetPassword:onServer:forAccount:port:path:inSecurityDomain:protocol:auth:replaceExisting: addInternetPassword:onServer:forAccount:port:path:inSecurityDomain:protocol:auth:replaceExisting:@/link and @link addCertificate: addCertificate:@/link, among others.

				Although it's not usually something you need to think about, it so happens that keychains are implemented on Mac OS X as special CDSA data stores (a combined CSP/DL).  This means that Certificates are actually KeychainItems for most intents and purposes, and you can easily translate between them using the @link certificate certificate@/link and @link keychainItem keychainItem@/link methods.

				<b>Uniquing Attributes</b>

				All KeychainItems have some subset of attributes which <i>uniquely</i> identify that KeychainItem.  For example, a combination of volumen name, server address, signature and account name, for AppleShare passwords.  No two items can exist, in the same keychain, with the same values for all their uniquing attributes.  It is quite possible, however, to have two items which differ only by one unique attribute (e.g. an Internet password for the same server, path, port, etc, but with a different account name).

				The documentation for each attribute's getter and setter makes note of which types of KeychainItems it applies to (if not all), and if it is a uniquing attribute.  Alternatively, for a complete list see the description of the @link kind kind@/link method. */

@interface KeychainItem : NSCachedObject {
@protected
    SecKeychainItemRef _keychainItem;
    OSStatus _error;
}

/*! @method nameOfGetterForAttribute:
	@abstract Returns the method name of the getter corresponding to a given attribute type.
	@discussion You wouldn't typically need to use this, as it's explicitly required only for some internal workings of the Keychain framework, but it is available (and supported going forward) if you need it for some reason.
	@param type The type.
	@result Returns the method name of the getter corresponding to the given attribute type, or nil if one doesn't exist. */

+ (NSString*)nameOfGetterForAttribute:(SecKeychainAttrType)type;

/*! @method keychainItemWithKeychainItemRef:
    @abstract Creates and returns a KeychainItem instance based on a SecKeychainItemRef.
    @discussion The SecKeychainItemRef is retained by the new KeychainItem instance.  This method caches existing KeychainItem instances, such that multiple calls with the same SecKeychainItemRef will return the same unique KeychainItem instance (with its retain count suitably bumped).
    @param ke The SecKeychainItemRef.
    @result If a KeychainItem instance already for the given SecKeychainItemRef, returns that existing instance.  Otherwise, creates a new instance and returns it.  In case of error, returns nil. */

+ (KeychainItem*)keychainItemWithKeychainItemRef:(SecKeychainItemRef)keychainIt;

/*! @method initWithKeychainItemRef:
    @abstract Initiailizes the receiver with a SecKeychainItemRef.
    @discussion The SecKeychainItemRef is retained by the receiver.  Changes to the SecKeychainItemRef will reflect on the receiver, and vice versa.  Note that this method caches existing KeychainItem instances, such that calling this with a SecKeychainItemRef that has already been used will release the receiver and return the existing instance.
    @param ke The SecKeychainItemRef.
    @result If a KeychainItem instance already exists for the given SecKeychainItemRef, releases the receiver and returns the existing instance (with its retain count suitably incremented).  Otherwise, initialises the receiver with the given SecKeychainItemRef and returns it.  If an error occurs, releases the receiver and returns nil. */

- (KeychainItem*)initWithKeychainItemRef:(SecKeychainItemRef)keychainIt;

/*! @method init
    @abstract Unsupported initialiser.
    @discussion You cannot initialise a KeychainItem using "init" - use @link initWithKeychainItemRef: initWithKeychainItemRef:@/link.
    @result This method always releases the receiver and returns nil. */

- (KeychainItem*)init;

/*! @method kind
    @abstract Returns the kind of the receiver, e.g. key, certificate, password, etc.
    @discussion You can refer to the Apple CDSA documentation in the file <a href="file:///System/Library/Frameworks/Security.framework/Headers/SecKeychainItem.h">SecKeychainItem.h</a> for a list of 'kinds'.  At time of writing these are:

                <ul>
					<li><b>kSecInternetPasswordItemClass</b> - Internet password.  These are uniquely identified by the following attributes:
	
						<ul>
							<li>@link account account@/link</li>
							<li>@link securityDomain securityDomain@/link</li>
							<li>@link server server@/link</li>
							<li>@link protocol protocol@/link</li>
							<li>@link authenticationType authenticationType@/link</li>
							<li>@link port port@/link</li>
							<li>@link path path@/link</li>
						</ul>

						They also support the following attributes:
	
						<ul>
							<li>@link creationDate creationDate@/link</li>
							<li>@link modificationDate modificationDate@/link</li>
							<li>@link typeDescription typeDescription@/link</li>
							<li>@link comment comment@/link</li>
							<li>@link creator creator@/link</li>
							<li>@link type type@/link</li>
							<li>@link label label@/link</li>
							<li>@link alias alias@/link</li>
							<li>@link isVisible isVisible@/link</li>
							<li>@link passwordIsValid passwordIsValid@/link</li>
							<li>@link hasCustomIcon hasCustomIcon@/link</li>
						</ul>
					</li>

					<li><b>kSecGenericPasswordItemClass</b> - Generic password.  These are uniquely identified by the following attributes:
	
						<ul>
							<li>@link account account@/link</li>
							<li>@link service service@/link</li>
						</ul>

						They also support the following attributes:

						<ul>
							<li>@link creationDate creationDate@/link</li>
							<li>@link modificationDate modificationDate@/link</li>
							<li>@link typeDescription typeDescription@/link</li>
							<li>@link comment comment@/link</li>
							<li>@link creator creator@/link</li>
							<li>@link type type@/link</li>
							<li>@link label label@/link</li>
							<li>@link alias alias@/link</li>
							<li>@link isVisible isVisible@/link</li>
							<li>@link passwordIsValid passwordIsValid@/link</li>
							<li>@link hasCustomIcon hasCustomIcon@/link</li>
							<li>@link userDefinedAttribute userDefinedAttribute@/link</li>
						</ul>
					</li>

					<li><b>kSecAppleSharePasswordItemClass</b> - AppleShare password.  These are uniquely identified by the following attributes:
	
						<ul>
							<li>@link account account@/link</li>
							<li>@link appleShareVolume appleShareVolume@/link</li>
							<li>@link appleShareAddress appleShareAddress@/link</li>
							<li>@link appleShareSignature appleShareSignature@/link</li>
						</ul>

						They also support the following attributes:

						<ul>
							<li>@link creationDate creationDate@/link</li>
							<li>@link modificationDate modificationDate@/link</li>
							<li>@link typeDescription typeDescription@/link</li>
							<li>@link comment comment@/link</li>
							<li>@link creator creator@/link</li>
							<li>@link type type@/link</li>
							<li>@link label label@/link</li>
							<li>@link alias alias@/link</li>
							<li>@link isVisible isVisible@/link</li>
							<li>@link passwordIsValid passwordIsValid@/link</li>
							<li>@link hasCustomIcon hasCustomIcon@/link</li>
							<li>@link server server@/link</li>
							<li>@link protocol protocol@/link</li>
						</ul>
					</li>

					<li><b>kSecCertificateItemClass</b> - Certificate.  These are uniquely identified by the following attributes:

						<ul>
							<li>@link certificateType certificateType@/link</li>
							<li>@link issuer issuer@/link</li>
							<li>@link serialNumber serialNumber@/link</li>
						</ul>

						They also support the following attributes:

						<ul>
							<li>@link certificateEncoding certificateEncoding@/link</li>
							<li>@link label label@/link</li>
							<li>@link alias alias@/link</li>
							<li>@link subject subject@/link</li>
							<li>Subject Key Identifier</li>
							<li>Public Key Hash</li>
						</ul>
					</li>
				</ul>

				TODO: determine what this returns for other types of keychain items (e.g. keys).
    @result Returns one of the constants specified above, or -1 if an error occurs. */

- (SecItemClass)kind;

/*! @method isInternetItem
    @abstract Returns whether or not the receiver is an internet password.
    @discussion Simply a convenience method for the 'kind' method.
    @result Returns YES if the receiver is an internet password item, NO otherwise. */

- (BOOL)isInternetItem;

/*! @method isGenericItem
    @abstract Returns whether or not the receiver is a generic password.
    @discussion Simply a convenience method for the 'kind' method.
    @result Returns YES if the receiver is a generic password item, NO otherwise. */

- (BOOL)isGenericItem;

/*! @method isAppleShareItem
    @abstract Returns whether or not the receiver is an AppleShare password.
    @discussion Simply a convenience method for the 'kind' method.
    @result Returns YES if the receiver is an AppleShare password item, NO otherwise. */

- (BOOL)isAppleShareItem;

/*! @method isCertificate
    @abstract Returns whether or not the receiver is a certificate.
    @discussion Simply a convenience method for the 'kind' method.
    @result Returns YES if the receiver is a certificate item, NO otherwise. */

- (BOOL)isCertificate;

/*! @method setData:
    @abstract Sets the data of the receiver.
    @discussion The data for password items is the password itself.  For certificates, it is the raw certificate (try to avoid setting the certificate in this manner; you may add Certificate instances to keychains directly).
	
				Typically you will want to use @link setDataFromString: setDataFromString:@/link to modify passwords, as it handles the string encoding and conversion for you.

				The data may be encrypted for storage in the keychain; this method expects the plaintext.

				TODO: determine under what conditions this may fail, or prompt the user, if any.  It appears that you can always set the data, but I haven't tested extensively.
    @param data The data to set for the receiver.  Should not be nil. */

- (void)setData:(NSData*)data;

/*! @method setDataFromString:
    @abstract Sets the data (e.g. the password) of the receiver.
    @discussion The data for password items is the password itself.  For certificates, the data is the raw certificate (which should be set using @link setData: setData:@/link rather than this method, to avoid string encoding and conversion issues).
				
				The data may be encrypted for storage in the keychain; this method expects the plaintext.
				
                TODO: determine under what conditions this may fail, or prompt the user, if any.  It appears that you can always set the data, but I haven't tested extensively. 
    @param data The data to set for the receiver, replacing any and all already set for it.  Should not be nil. */

- (void)setDataFromString:(NSString*)data;

/*! @method data
    @abstract Returns the data of the receiver.
    @discussion The data for password items is the password itself.  For certificates, the data is the raw certificate (although it is recommended you obtain a Certificate instance using the @link certificate certificate@/link method, and use that to interrogate the contents).

                Note that unless your application is already in the receiver's Access with read access, the user will be prompted to enter their password and allow access to the receiver (unless of course you have disabled user interaction, in which case anything which requires user interaction will result in the operation failing).  If the user denies access nil is returned.

				The returned data is the plaintext, not the encrypted form.
    @result The data of the receiver, or nil if an error occurs (including insufficient privileges to read the receiver, or if the user denied access). */

- (NSData*)data;

/*! @method dataAsString
    @abstract Returns the data of the receiver (e.g. the password) as a string.
    @discussion The data for password items is the password itself.  For certificates, the data is the raw certificate (which should be retrieved using @link data data@/link rather than this method, to avoid string encoding and conversion issues).

				The data is assumed to be UTF-8 encoded.  If it is not, this method may fail and return nil, or may return a string which is incorrect.

				Note that unless your application is already in the receiver's Access with read access, the user will be prompted to enter their password and allow access to the receiver (unless of course you have disabled user interaction, in which case anything which requires user interaction will result in the operation failing).  If the user denies access nil is returned.
    @result The data of the receiver, or nil if an error occurs (including insufficient privileges to read the receiver, or if the user denied access). */

- (NSString*)dataAsString;

/*! @method setCreationDate:
    @abstract Sets the creation date of the receiver.
    @discussion The creation date should reflect the date at which the receiver was created, *not* necessarily when it was first added to the keychain in which it currently resides.  This is similar to copying files between volumes; the creation date remains the same.  The creation date should be set automatically, as necessary.

                Note that Keychain Access does not follow this behaviour.  Indeed, the built-in behaviour may or may not be as described.  TODO: verify this.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is the time at which the item was created.
    @param date The new creation date for the receiver.  Should not be nil. */

- (void)setCreationDate:(NSDate*)date;

#if 0 // This doesn't work yet.
/*! @method setModificationDate:
    @abstract Sets the modification date of the receiver.
    @discussion The modification date should reflect the date at which the receiver's data or attributes were last modified (which does not include it's addition to the owning keychain).  The modification date is updated automatically when you modify the receiver's data or attributes.

                Note that Keychain Access does not follow this behaviour.  TODO: describe Keychain Access's behaviour.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).
    @param date The new modification date for the receiver.  Should not be nil. */

- (void)setModificationDate:(NSDate*)date;
#endif

/*! @method setTypeDescription:
    @abstract Sets the human-readable description of the receiver's type.
    @discussion KeychainItem's can (and 'generic' or custom types <i>should</i>) have a type description associated with them, which concisely summarises their type and purpose.  Examples include "Proteus Service Password", or "Web Forms Password", etc.

				Note that this is distinct from the item's label (@link setLabel: setLabel:@/link/@link label label@/link) and comment (@link setComment: setComment:@/link/@link comment comment@/link); it describes the <i>type</i> of item the receiver is, not the receiver specifically.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is an empty string.
    @param desc The description for the receiver.  Should not be nil. */

- (void)setTypeDescription:(NSString*)desc;

/*! @method setComment:
    @abstract Sets a human-readable comment for the receiver.
    @discussion The comment can be anything; it is intended to be end-user readable, in a similar manner to file comments in the Finder.  This attribute should be considered user-editable.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is an empty string.
    @param comment The comment.  Should not be nil. */

- (void)setComment:(NSString*)comment;

/*! @method setCreator:
    @abstract Sets the creator code of the receiver.
    @discussion The creator code is the Classic MacOS document creator code, identifying which application created (or otherwise presently "owns") a given item.
	
				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for keychain items created by this framework, is the creator code of the main bundle (i.e. your application).  This may be 0.  The default value for items created by other frameworks or means is typically 0, but is not explicitly defined.
	@param creator The creator of the receiver, which may be 0 (meaning essentially 'no creator'). */

- (void)setCreator:(FourCharCode)creator;

/*! @method setCreatorFromString:
    @abstract Sets the creator code of the receiver from the given string.
    @discussion This is a convenience method which converts the given string to a FourCharCode and passes that to @link setCreator: setCreator:@/link.  The given string should be either empty (to clear the creator code) or contain four ASCII characters.  Note that NULLs are valid in the string.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				// TODO: verify how bytes > 127 are interpretted... I suspect MacRoman, but this needs to be tested.
	@param creator The creator of the receiver, which should be either an empty string or a string containing exactly four ASCII characters. */

- (void)setCreatorFromString:(NSString*)creator;

/*! @method setType:
    @abstract Sets the type code of the receiver.
    @discussion The type code is the Classic MacOS document type code, identifying the document type of a given item.  This is very distinct from the @link kind kind@/link of a KeychainItem; the 'type' does not describe the type of KeychainItem, but rather the document type with which it is associated.  This is largely just a hang-over from Classic MacOS, and is neither commonly used nor recommended for future use.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is 0.
	@param type The type of the receiver, which may be 0 (meaning essentially 'no type'). */

- (void)setType:(FourCharCode)type;

/*! @method setTypeFromString:
    @abstract Sets the type code of the receiver from the given string.
    @discussion This is a convenience method which converts the given string to a FourCharCode and passes that to @link setType: setType:@/link.  The given string should be either empty (to clear the type code) or contain four ASCII characters.  Note that NULLs are valid in the string.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				// TODO: verify how bytes > 127 are interpretted... I suspect MacRoman, but this needs to be tested.
	@param type The type of the receiver, which should be either an empty string or a string containing exactly four ASCII characters. */

- (void)setTypeFromString:(NSString*)type;

/*! @method setLabel:
	@abstract Sets the human-readable label of the receiver.
	@discussion The label is a human-readable, brief description of the receiver.  This attribute should be considered user-editable.

				The default value, for new KeychainItems, varies; it is automatically generated based on the receiver's contents to be some suitable default.
	@param label The label for the receiver.  Should not be nil. */

- (void)setLabel:(NSString*)label;

/*! @method setIsVisible:
	@abstract Sets whether or not the receiver is visible.
	@discussion 'Visibility' applies to the end-user only, and is something that the end-developer should account for in their application; it has no bearing on how the Keychain framework works with KeychainItems.  You might desire for an item to be invisible if it is internal to your application and not something the user needs to be aware of.

				Note that in 10.4 I believe Keychain Access ignores this attribute and displays all items regardless.  TODO: verify this.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is YES.
	@param visible Whether or not the receiver should be visible to the end-user. */

- (void)setIsVisible:(BOOL)visible;

/*! @method setPasswordIsValid:
	@abstract Sets whether or not the receiver's data is valid.
	@discussion You may wish to add an entry to a keychain which is not actually valid, as a way of saying that you do not want to remember the real data for that item.  For example, if your application has the option to add passwords to the keychain when you first enter them, if the user decides not to do so you could add a placeholder item marked as invalid.  Then when your application, in future, searches for the password it will find the invalid item and know that it must prompt the user, and shouldn't try to store the password.

				While you could use this to require the user to always enter a password, without the option of saving it, keep in mind that they ultimately could just choose to toggle this flag themselves, manually, if so inclined.  As such, don't rely on this exclusively for setting policy.  You may also want to make the receiver invisible (@link setIsVisible: setIsVisible:@/link), if it is invalid, to discourage user manipulation.

				Note that as an end-developer you are responsible for handling validity appropriately; the setting of this attribute does not influence how the Keychain framework operates.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is YES.
	@param valid Whether or not the receiver's content (@link data data@/link) is valid. */

- (void)setPasswordIsValid:(BOOL)valid;

/*! @method setHasCustomIcon:
	@abstract Sets whether or not the receiver has a custom icon.
	@discussion Custom icons are a hang-over from the Classic MacOS Keychain Manager.  In a nutshell, if this attribute is set to YES, then a custom icon should be displayed (if available) by searching for the document icon corresponding to the receiver's @link creator creator@/link and @link type type@/link codes.

				This attribute is more or less deprecated, and not recommended for future use.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is NO.
	@param icon Whether or not the receiver has a custom icon. */

- (void)setHasCustomIcon:(BOOL)icon;

/*! @method setAccount:
	@abstract Sets the account of the receiver.
	@discussion The account is the login name or similar of a password.  It is not encrypted when stored in the keychain.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).  It is a uniquing attribute for all three types.

				The default value for new KeychainItems, if not otherwise defined at creation time, is an empty string.
	@param account The account for the receiver.  Should not be nil (but may be an empty string). */

- (void)setAccount:(NSString*)account;

/*! @method setService:
	@abstract Sets the 'service' of the receiver.
	@discussion i.e. the type of thing it is a password for.  e.g. ".Mac".
	
				This attribute applies only to Generic passwords (kSecGenericPasswordItemClass), where it is a uniquing attribute.

				The default value for new KeychainItems, if not otherwise defined at creation time, is an empty string.
	@param service The service for the receiver.  Should not be nil (but may be an empty string). */

- (void)setService:(NSString*)service;

/*! @method setUserDefinedAttribute:
	@abstract Sets the user-defined attribute of the receiver.
	@discussion This attribute is only available on generic password (kSecGenericPasswordItemClass) KeychainItems, and is simply a blob of arbitrary data.  It is up to the end-developer to define what this attribute is, and the structure of it.  In the interest of compatibility and openness the use of this attribute is discouraged.  If you do use it, it's recommended you publish a description of its purpose and structure so that others may interoperate.

				The default value, for new KeychainItems, is an empty NSData.
	@param attribute The attribute value.  Should not be nil (but may be empty). */

- (void)setUserDefinedAttribute:(NSData*)attribute;

/*! @method setSecurityDomain:
	@abstract Sets the security domain of the receiver.
	@discussion The security domain (also know as a realm) is a way of identifying a subsection of a website which uses the same login.  For example, on www.example.com there may be a "PHPmyAdmin" domain and a "User" domain.  Where you have knowledge of the domain of a password, it is wise to reference the domain in preference to a particular path, as the user should not be prompted multiple times for the same login, for the same domain.

				This attribute applies only to Internet passwords (kSecInternetPasswordItemClass, @link isInternetItem isInternetItem@/link), where is is a uniquing attribute.

				The default for new KeychainItems, if not otherwise defined at creation time, is an empty string.
	@param securityDomain The security domain for the receiver.  Should not be nil (but may be an empty string). */

- (void)setSecurityDomain:(NSString*)securityDomain;

/*! @method setServer:
	@abstract Sets the server of the receiver.
	@discussion The server is just the domain name or IP address of the server, e.g. "www.google.com" or "192.168.0.1".

				This attribute applies only to AppleShare passwords (kSecAppleSharePasswordItemClass, @link isAppleShareItem isAppleShareItem@/link) and Internet passwords (kSecInternetPasswordItemClass, @link isInternetItem isInternetItem@/link).  It is a uniquing attribute for Internet passwords.

				The default for new KeychainItems, if not otherwise defined at creation time, is an empty string.
	@param server The server.  Should not be nil (but may be an empty string). */

- (void)setServer:(NSString*)server;

/*! @method setAuthenticationType:
	@abstract Sets the authentication type to which the receiver applies.
	@discussion It is possible to have two otherwise-identical passwords with different authentication types.  e.g. one for HTTP basic and one for HTTP digest.  If the authentication type is irrelevant, use kSecAuthenticationTypeDefault.
				
				This attribute applies only to Internet passwords (kSecInternetPasswordItemClass, @link isInternetItem isInternetItem@/link), where is is a uniquing attribute.
	@param authType The authentication type of the receiver. */

- (void)setAuthenticationType:(SecAuthenticationType)authType;

/*! @method setPort:
	@abstract Sets the port of the receiver.
	@discussion This attribute applies only to Internet passwords (kSecInternetPasswordItemClass, @link isInternetItem isInternetItem@/link), where is is a uniquing attribute.

				The default for new KeychainItems, if not otherwise defined at creation time, is 0.
	@param port The port. */

- (void)setPort:(uint32_t)port;

/*! @method setPath:
	@abstract Sets the path of the reciever.
	@discussion e.g. the path of "http://www.example.com/cgi/query.c" is "/cgi/query.c".
	
				This attribute applies only to Internet passwords (kSecInternetPasswordItemClass, @link isInternetItem isInternetItem@/link), where is is a uniquing attribute.

				The default for new KeychainItems, if not otherwise defined at creation time, is an empty string.
	@param path The path.  Should not be nil (but may be an empty string). */

- (void)setPath:(NSString*)path;

/*! @method setAppleShareVolume:
	@abstract Sets the AppleShare volume name of the receiver.
	@discussion This attribute applies only to AppleShare passwords (kSecAppleSharePasswordItemClass, @link isAppleShareItem isAppleShareItem@/link), where it is a uniquing attribute.

				The default for new KeychainItems, if not otherwise defined at creation time, is an empty string.
	@param volume The volume name.  Should not be nil (but may be an empty string). */

- (void)setAppleShareVolume:(NSString*)volume;

/*! @method setAppleShareAddress:
	@abstract Sets the AppleShare address of the receiver.
	@discussion This attribute applies only to AppleShare passwords (kSecAppleSharePasswordItemClass, @link isAppleShareItem isAppleShareItem@/link), where it is a uniquing attribute.

				The default for new KeychainItems, if not otherwise defined at creation time, is an empty string.
	@param address The address.  Should not be nil (but may be an empty string). */

- (void)setAppleShareAddress:(NSString*)address;

/*! @method setAppleShareSignature:
	@abstract Sets the AppleShare signature of the receiver.
	@discussion This attribute applies only to AppleShare passwords (kSecAppleSharePasswordItemClass, @link isAppleShareItem isAppleShareItem@/link), where it is a uniquing attribute.
	@param sig The signature.  Should not be NULL. */

- (void)setAppleShareSignature:(SecAFPServerSignature*)sig;

/*! @method setProtocol:
	@abstract Sets the protocol of the receiver.
	@discussion This attribute applies only for internet passwords (kSecInternetPasswordItemClass, @link isInternetItem isInternetItem@/link) and AppleShare passwords (kSecAppleSharePasswordItemClass, @link isAppleShareItem isAppleShareItem@/link).  For Internet passwords it is a uniquing attribute.

				There is no "default" or "generic" protocol.  If you cannot find a value the applies for your use, make up your own.
	@param protocol The protocol. */

- (void)setProtocol:(SecProtocolType)protocol;

/*! @method setCertificateType:
	@abstract Sets the certificate type of the receiver.
	@discussion This attribute applies only to certificates (kSecCertificateItemClass, @link isCertificate isCertificate@/link), where it is a uniquing attribute.

				// TODO: should this be settable?  Shouldn't we ensure this is in sync with the actual certificate data, automatically?
	@param certType The certificate type. */

- (void)setCertificateType:(CSSM_CERT_TYPE)certType;

/*! @method setCertificateEncoding:
	@abstract Sets the certificate encoding of the receiver.
	@discussion This attribute applies only to certificates (kSecCertificateItemClass, @link isCertificate isCertificate@/link).

				// TODO: should this be settable?  Shouldn't we ensure this is in sync with the actual certificate data, automatically?
	@param certEncoding The certificate encoding. */

- (void)setCertificateEncoding:(CSSM_CERT_ENCODING)certEncoding;

/*! @method setCRLType:
	@abstract Sets the CRL type of the receiver.
	@discussion This attribute applies only to CRLs (Certificate Revocation Lists).  (TODO: how does one identify a KeychainItem as such?)

				// TODO: should this be settable?  Shouldn't we ensure this is in sync with the actual CRL data, automatically?
	@param type The CRL type. */

- (void)setCRLType:(CSSM_CRL_TYPE)type;

/*! @method setCRLEncoding:
	@abstract Sets the CRL encoding of the receiver.
	@discussion This attribute applies only to CRLs (Certificate Revocation Lists).  (TODO: how does one identify a KeychainItem as such?)

				// TODO: should this be settable?  Shouldn't we ensure this is in sync with the actual CRL data, automatically?
	@param encoding The CRL encoding. */

- (void)setCRLEncoding:(CSSM_CRL_ENCODING)encoding;

/*! @method setAlias:
	@abstract Sets the alias of the receiver.
	@discussion The alias is typically used for certificates as a convenient way of identifying the key attribute of the item, e.g. the email address the certificate applies to (which may in turn be useful for looking up related AddressBook entries, for example).
	@param alias The alias.  Should not be nil (but may be an empty string). */

- (void)setAlias:(NSString*)alias;

/*! @method creationDate
	@abstract Returns the creation date of the receiver.
	@discussion The creation date is the time at which the receiver was added to the keychain.  If an item is moved between two keychains, the new copy will have its creation date set to the present (this is contrary to typical creation date behaviour, such as in the file system, and may change in future).

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				You can modify this attribute using @link setCreationDate: setCreationDate:@/link.
	@result Returns the creation date (time at which the receiver was added to the keychain), or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSCalendarDate*)creationDate;

/*! @method modificationDate
	@abstract Returns the time of the most recent modification to the receiver.
	@discussion The modification date is automatically updated to the present date and time whenever the receivers data (e.g. password) or attributes are modified.
	
				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				At present it cannot be set explicitly using this framework, although it is possible to do so - you should not rely on the modification date to be truthful.
	@result Returns the time of the most recent modification to the receiver, or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSCalendarDate*)modificationDate;

/*! @method typeDescription
	@abstract Returns the human-readable description of the receiver's type.
	@discussion KeychainItem's can (and 'generic' or custom types <i>should</i>) have a type description associated with them, which concisely summarises their type and purpose.  Examples include "Proteus Service Password", or "Web Forms Password", etc.

				Note that this is distinct from the item's label (@link setLabel: setLabel:@/link/@link label label@/link) and comment (@link setComment: setComment:@/link/@link comment comment@/link); it describes the <i>type</i> of item the receiver is, not the receiver specifically.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is an empty string.

				You can modify this attribute using @link setTypeDescription: setTypeDescription:@/link.
	@result Returns the description of the receiver's type (which may be an empty string), or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSString*)typeDescription;

/*! @method comment
	@abstract Returns a human-readable comment for the receiver.
	@discussion The comment can be anything; it is intended to be end-user readable, in a similar manner to file comments in the Finder.  This attribute should be considered user-editable.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is an empty string.

				You can modify this attribute using @link setComment: setComment:@/link.
	@result Returns the comment for the receiver (which may be an empty string), or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSString*)comment;

/*! @method creator
	@abstract Returns the creator code of the receiver.
	@discussion The creator code is the Classic MacOS document creator code, identifying which application created (or otherwise presently "owns") a given item.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for keychain items created by this framework, is the creator code of the main bundle (i.e. your application).  This may be 0.  The default value for items created by other frameworks or means is typically 0, but is not explicitly defined.

				You can modify this attribute using @link setCreator: setCreator:@/link.  You may also wish to retrieve this value as a string, using @link creatorAsString creatorAsString@/link.
	@result Returns the creator code of the receiver, or 0 if one is not set or an error occurs (e.g. this attribute does not apply to the receiver). */

- (FourCharCode)creator;

/*! @method creatorAsString
	@abstract Returns the creator code of the receiver.
	@discussion This is a convenience method which converts the result of @link creator creator@/link into an NSString.  Since creator codes are ultimately just 32-bit integers, this is not guaranteed to result in a human-readable string (although by convention most creator codes use ASCII alphanumerics only, making them human-readable for convenience).

				You can modify this attribute using @link setCreatorFromString: setCreatorFromString:@/link.
	@result Returns the receiver's creator code converted to an NSString, or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSString*)creatorAsString;

/*! @method type
	@abstract 
	@discussion The type code is the Classic MacOS document type code, identifying the document type of a given item.  This is very distinct from the @link kind kind@/link of a KeychainItem; the 'type' does not describe the type of KeychainItem, but rather the document type with which it is associated.  This is largely just a hang-over from Classic MacOS, and is neither commonly used nor recommended for future use.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is 0.

				You can modify this attribute using @link setType: setType:@/link.  You may also wish to retrieve this value as a string, using @link typeAsString typeAsString@/link.
	@result Returns the type of the receiver, which may be 0 (meaning essentially 'no type') if no value is set, or an error occurs (e.g. this attribute does not apply to the receiver). */

- (FourCharCode)type;

/*! @method typeAsString
	@abstract Returns the type code of the receiver.
	@discussion This is a convenience method which converts the result of @link type type@/link into an NSString.  Since type codes are ultimately just 32-bit integers, this is not guaranteed to result in a human-readable string (although by convention most type codes use ASCII alphanumerics only, making them human-readable for convenience).

				You can modify this attribute using @link setTypeFromString: setTypeFromString:@/link.
	@result Returns the receiver's type code converted to an NSString, or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSString*)typeAsString;

/*! @method label
	@abstract Returns the human-readable label of the receiver.
	@discussion The label is a human-readable, brief description of the receiver.  This attribute should be considered user-editable.

				The default value, for new KeychainItems, varies; it is automatically generated based on the receiver's contents to be some suitable default.

				You may modify this attribute using @link setLabel: setLabel:@/link.
	@result Returns the label for the receiver (which may be an empty string), or nil if an error occurs. */

- (NSString*)label;

/*! @method isVisible
	@abstract Returns whether the receiver is visible or not.
	@discussion 'Visibility' applies to the end-user only, and is something that the end-developer should account for in their application; it has no bearing on how the Keychain framework works with KeychainItems.  You might desire for an item to be invisible if it is internal to your application and not something the user needs to be aware of.

				Note that in 10.4 I believe Keychain Access ignores this attribute and displays all items regardless.  TODO: verify this.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is YES.

				You may modify this attribute using @link setIsVisible: setIsVisible:@/link.
	@result Returns whether or not the receiver should be visible to the end-user, or NO if an error occurs (e.g. this attribute does not apply to the receiver). */

- (BOOL)isVisible;

/*! @method passwordIsValid
	@abstract Returns whether the receiver's content (e.g. password) is valid.
	@discussion You may wish to add an entry to a keychain which is not actually valid, as a way of saying that you do not want to remember the real data for that item.  For example, if your application has the option to add passwords to the keychain when you first enter them, if the user decides not to do so you could add a placeholder item marked as invalid.  Then when your application, in future, searches for the password it will find the invalid item and know that it must prompt the user, and shouldn't try to store the password.

				While you could use this to require the user to always enter a password, without the option of saving it, keep in mind that they ultimately could just choose to toggle this flag themselves, manually, if so inclined.  As such, don't rely on this exclusively for setting policy.  You may also want to make the receiver invisible (@link setIsVisible: setIsVisible:@/link), if it is invalid, to discourage user manipulation.

				Note that as an end-developer you are responsible for handling validity appropriately; the setting of this attribute does not influence how the Keychain framework operates.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is YES.

				You may modify this attribute using @link setPasswordIsValid: setPasswordIsValid:@/link.
	@result Returns whether or not the receiver's content (@link data data@/link) is valid, or NO if an error occurs (e.g. this attribute does not apply to the receiver). */

- (BOOL)passwordIsValid;

/*! @method hasCustomIcon
	@abstract Returns whether or not the receiver has a custom icon associated with it.
	@discussion Custom icons are a hang-over from the Classic MacOS Keychain Manager.  In a nutshell, if this attribute is set to YES, then a custom icon should be displayed (if available) by searching for the document icon corresponding to the receiver's @link creator creator@/link and @link type type@/link codes.

				This attribute is more or less deprecated, and not recommended for future use.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).

				The default value, for new KeychainItems, is NO.

				You may modify this attribute using @link setHasCustomIcon: setHasCustomIcon:@/link.
	@result Returns whether or not the receiver has a custom icon, or NO if an error occurs (e.g. this attribute does not apply to the receiver). */

- (BOOL)hasCustomIcon;

/*! @method account
	@abstract Returns the account of the receiver.
	@discussion The account is the login name or similar of a password.  It is not encrypted when stored in the keychain.

				This attribute applies only to password items (kSecInternetPasswordItemClass, kSecAppleSharePasswordItemClass and kSecGenericPasswordItemClass).  It is a uniquing attribute for all three types.

				The default value for new KeychainItems, if not otherwise defined at creation time, is an empty string.

				You may modify this attribute using @link setAccount: setAccount:@/link.
	@result Returns the account for the receiver (which may be an empty string), or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSString*)account;

/*! @method service
	@abstract Returns the 'service' of the receiver.
	@discussion i.e. the type of thing it is a password for.  e.g. ".Mac".

				This attribute applies only to Generic passwords (kSecGenericPasswordItemClass), where it is a uniquing attribute.

				The default value for new KeychainItems, if not otherwise defined at creation time, is an empty string.

				You may modify this attribute using @link setService: setService:@/link.
	@result Returns the service for the receiver (which may be an empty string), or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSString*)service;

/*! @method userDefinedAttribute
	@abstract Returns the user-defined attribute of the receiver.
	@discussion This attribute is only available on generic password (kSecGenericPasswordItemClass) KeychainItems, and is simply a blob of arbitrary data.  It is up to the end-developer to define what this attribute is, and the structure of it.  In the interest of compatibility and openness the use of this attribute is discouraged.  If you do use it, it's recommended you publish a description of its purpose and structure so that others may interoperate.

				The default value, for new KeychainItems, is an empty NSData.

				You may modify this attribute using @link setUserDefinedAttribute: setUserDefinedAttribute:@/link.
	@result Returns the attribute value (which may be an empty NSData), or nil if an error occurs. */

- (NSData*)userDefinedAttribute;

/*! @method securityDomain
	@abstract Returns the security domain of the receiver.
	@discussion The security domain (also know as a realm) is a way of identifying a subsection of a website which uses the same login.  For example, on www.example.com there may be a "PHPmyAdmin" domain and a "User" domain.  Where you have knowledge of the domain of a password, it is wise to reference the domain in preference to a particular path, as the user should not be prompted multiple times for the same login, for the same domain.

				This attribute applies only to Internet passwords (kSecInternetPasswordItemClass, @link isInternetItem isInternetItem@/link), where is is a uniquing attribute.

				The default for new KeychainItems, if not otherwise defined at creation time, is an empty string.

				You may modify this attribute using @link setSecurityDomain: setSecurityDomain:@/link.
	@result Returns the security domain for the receiver (which may be an empty string), or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSString*)securityDomain;

/*! @method server
	@abstract Returns the server of the receiver.
	@discussion The server is just the domain name or IP address of the server, e.g. "www.google.com" or "192.168.0.1".

				This attribute applies only to AppleShare passwords (kSecAppleSharePasswordItemClass, @link isAppleShareItem isAppleShareItem@/link) and Internet passwords (kSecInternetPasswordItemClass, @link isInternetItem isInternetItem@/link).  It is a uniquing attribute for Internet passwords.

				The default for new KeychainItems, if not otherwise defined at creation time, is an empty string.

				You may modify this attribute using @link setServer: setServer:@/link.
	@result Returns the server (which may be an empty string), or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSString*)server;

/*! @method authenticationType
	@abstract Returns the authentication type of the receiver.
	@discussion It is possible to have two otherwise-identical passwords with different authentication types.  e.g. one for HTTP basic and one for HTTP digest.  If the authentication type is irrelevant, use kSecAuthenticationTypeDefault.

				This attribute applies only to Internet passwords (kSecInternetPasswordItemClass, @link isInternetItem isInternetItem@/link), where is is a uniquing attribute.

				You may modify this attribute using @link setAuthenticationType: setAuthenticationType:@/link.
	@result Returns the authentication type of the receiver. */

- (SecAuthenticationType)authenticationType;

/*! @method port
	@abstract Returns the port of the receiver.
	@discussion This attribute applies only to Internet passwords (kSecInternetPasswordItemClass, @link isInternetItem isInternetItem@/link), where is is a uniquing attribute.

				The default for new KeychainItems, if not otherwise defined at creation time, is 0.

				You may modify this attribute using @link setPort: setPort:@/link.
	@param port The port (which may be 0 if unspecified), or 0 if an error occurs (e.g. this attribute does not apply to the receiver). */

- (uint32_t)port;

/*! @method path
	@abstract Returns the path of the receiver.
	@discussion e.g. the path of "http://www.example.com/cgi/query.c" is "/cgi/query.c".

				This attribute applies only to Internet passwords (kSecInternetPasswordItemClass, @link isInternetItem isInternetItem@/link), where is is a uniquing attribute.

				The default for new KeychainItems, if not otherwise defined at creation time, is an empty string.

				You may modify this attribute using @link setPath: setPath:@/link.
	@result Returns the path (which may be an empty string), or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSString*)path;

/*! @method appleShareVolume
	@abstract Returns the AppleShare volume name of the receiver.
	@discussion This attribute applies only to AppleShare passwords (kSecAppleSharePasswordItemClass, @link isAppleShareItem isAppleShareItem@/link), where it is a uniquing attribute.

				The default for new KeychainItems, if not otherwise defined at creation time, is an empty string.

				You may modify this attribute using @link setAppleShareVolume: setAppleShareVolume:@/link.
	@result Returns the volume name (which may be an empty string), or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSString*)appleShareVolume;

/*! @method appleShareAddress
	@abstract Returns the AppleShare address of the receiver.
	@discussion This attribute applies only to AppleShare passwords (kSecAppleSharePasswordItemClass, @link isAppleShareItem isAppleShareItem@/link), where it is a uniquing attribute.

				The default for new KeychainItems, if not otherwise defined at creation time, is an empty string.

				You may modify this attribute using @link setAppleShareAddress: setAppleShareAddress:@/link.
	@result Returns the address (which may be an empty string), or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSString*)appleShareAddress;

/*! @method appleShareSignature
	@abstract Returns the AppleShare signature of the receiver.
	@discussion This attribute applies only to AppleShare passwords (kSecAppleSharePasswordItemClass, @link isAppleShareItem isAppleShareItem@/link), where it is a uniquing attribute.

				You may modify this attribute using @link setAppleShareSignature: setAppleShareSignature:@/link.
	@result Returns the signature, or NULL if an error occurs (e.g. this attribute does not apply to the receiver). */

- (SecAFPServerSignature*)appleShareSignature;

/*! @method appleShareSignatureData
	@abstract Returns the AppleShare signature of the receiver as an NSData.
	@discussion This is a convenience method which wraps the result from @link appleShareSignature appleShareSignature@/link in an NSData.
	@result Returns the AppleShare signature of the receiver, or nil if an error occurs (e.g. this attribute does not apply to the receiver). */

- (NSData*)appleShareSignatureData;

/*! @method protocol
	@abstract Returns the protocol of the receiver.
	@discussion This attribute applies only for internet passwords (kSecInternetPasswordItemClass, @link isInternetItem isInternetItem@/link) and AppleShare passwords (kSecAppleSharePasswordItemClass, @link isAppleShareItem isAppleShareItem@/link).  For Internet passwords it is a uniquing attribute.

				There is no "default" or "generic" protocol.  If you cannot find a value the applies for your use, make up your own.

				You may modify this attribute using @link setProtocol: setProtocol:@/link.
	@result Returns the protocol, or 0 if an error occurs (e.g. this attribute does not apply to the receiver). */

- (SecProtocolType)protocol;

/*! @method certificateType
	@abstract Returns the certificate type of the receiver.
	@discussion This attribute applies only to certificates (kSecCertificateItemClass, @link isCertificate isCertificate@/link), where it is a uniquing attribute.

				You may modify this attribute using @link setCertificateType: setCertificateType:@/link.
	@result Returns the certificate type, or 0 if an error occurs (e.g. this attribute does not apply to the receiver). */

- (CSSM_CERT_TYPE)certificateType;

/*! @method certificateEncoding
	@abstract Returns the certificate encoding of the receiver.
	@discussion This attribute applies only to certificates (kSecCertificateItemClass, @link isCertificate isCertificate@/link).

				You may modify this attribute using @link setCertificateEncoding: setCertificateEncoding:@/link.
	@result Returns the certificate encoding, or 0 if an error occurs (e.g. this attribute does not apply to the receiver). */

- (CSSM_CERT_ENCODING)certificateEncoding;

/*! @method CRLType
	@abstract Returns the CRL type of the receiver.
	@discussion This attribute applies only to CRLs (Certificate Revocation Lists).  (TODO: how does one identify a KeychainItem as such?)

				You may modify this attribute using @link setCRLType: setCRLType:@/link.
	@result Returns the CRL type, or 0 if an error occurs (e.g. this attribute does not apply to the receiver). */

- (CSSM_CRL_TYPE)CRLType;

/*! @method CRLEncoding
	@abstract Returns the CRL encoding of the receiver.
	@discussion This attribute applies only to CRLs (Certificate Revocation Lists).  (TODO: how does one identify a KeychainItem as such?)

				You may modify this attribute using @link setCRLEncoding: setCRLEncoding:@/link.
	@result Returns the CRL encoding. */

- (CSSM_CRL_ENCODING)CRLEncoding;

/*! @method alias
	@abstract Returns the alias of the receiver.
	@discussion The alias is typically used for certificates as a convenient way of identifying the key attribute of the item, e.g. the email address the certificate applies to (which may in turn be useful for looking up related AddressBook entries, for example).

				You may modify this attribute using @link setAlias: setAlias:@/link.
	@result Returns the alias (which may be an empty string), or nil if an error occurs. */

- (NSString*)alias;

/*! @method setAccess:
	@abstract Sets the Access of the receiver.
	@discussion The Access associated with a KeychainItem controls how the item may be accessed by applications.  See the documentation for @link Access Access@/link for more information.
	@param acc The Access to set.  Should not be nil. */

- (void)setAccess:(Access*)acc;

/*! @method access
	@abstract Returns the Access of the receiver.
	@discussion The Access associated with a KeychainItem controls how the item may be accessed by applications.  See the documentation for @link Access Access@/link for more information.

				While you typically modify the existing Access, if available, you may replace the receiver's access entirely using @link setAccess: setAccess:@/link.
	@result Returns the receiver's access, or nil if an error occurs. */

- (Access*)access;

/*! @method keychain
	@abstract Returns the Keychain in which the receiver resides.
	@discussion In most circumstances all KeychainItems are contained within a Keychain, although this is not guaranteed.
	@result Returns the receiver's Keychain, if any, or nil if an error occurs. */

- (Keychain*)keychain;

//- (KeychainItem*)createDuplicate; // Not exposed yet because I'm pretty sure it doesn't work.

/*! @method certificate
	@abstract Returns the Certificate for the receiver, if possible.
	@discussion If the receiver is a certificate, you may get an actual Certificate instance (that allows you to fully access and use the certificate) using this method.

				This only applies to certificate (@link isCertificate isCertificate@/link) items, naturally.
	@result Returns the Certificate for the receiver, or nil if an error occurs (e.g. the receiver is not a certificate). */

- (Certificate*)certificate;

/*! @method deleteCompletely
	@abstract Deletes the receiver from its keychain.
	@discussion The lifetime of a KeychainItem instance isn't linked to the actual record in the keychain, naturaly - the KeychainItem may be deallocated and go away without affecting the item it represents.  So if you actually want to delete an item, use this method.

				Once you have invoked this method, the receiver is no longer valid and cannot be used (all methods will fail). */

- (void)deleteCompletely;

/*! @method lastError
    @abstract Returns the last error that occured for the receiver.
    @discussion The set of error codes encompasses those returned by Sec* functions - refer to the Security framework documentation for a list - and the CDSA error codes.

              Please note that this error code is local to the receiver only, and not any sort of shared global value.
    @result The last error that occured, or zero if the last operation was successful. */

- (OSStatus)lastError;

/*! @method keychainItemRef
	@abstract Returns the receiver's underlying SecKeychainItemRef.
	@discussion Each KeychainItem wraps a SecKeychainItemRef, which is the Security-framework representation of keychain items.  You may use this method to retrieve this low-level reference.

				The SecKeychainItemRef returned will be retained for at least the lifetime of the receiver, but you should of course CFRetain (and, later, CFRelease) it if you wish to keep the reference around.

				While there aren't typically any issues with this reference being used directly alongside the use of the receiver, you should be aware that there is a potential for conflict.
	@result Returns the receiver's SecKeychainItemRef. */

- (SecKeychainItemRef)keychainItemRef;

@end


@interface NSArray (KeychainFrameworkPredicateSupport)

- (NSArray*)filteredArrayUsingKeychainPredicate:(NSPredicate*)predicate;

@end
