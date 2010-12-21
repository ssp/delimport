//
//  AccessControlList.h
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
#import <Security/SecACL.h>
#import <Keychain/TrustedApplication.h>

// We're inherited by the Access class, yet we use it ourselves, so we need to forward declare it.  We still get warnings, unfortunately.  Just ignore these.
@class Access;


/*! @class AccessControlList
    @abstract Defines a set of authorizations for a set of applications
    @discussion An AccessControlList contains a list of authorizations, of various pre-defined types, and a list of TrustedApplication's to which these authorizations apply.  AccessControlList's are usually grouped together, as appropriate, under an Access instance.
				
				<b>Typical ACLs</b>
				
				Typically each password in a keychain has three ACLs in its Access initially.  One provides encrypt authorisation to any and all applications.  A second provides permission to change the ACL, but specifies no applications by default.  A third allows for decryption, key derivation, clear & wrapped export, MAC generation and signing.  In a nutshell this provides read access to the keychain item's content.

				The explanation for this is a little odd but fairly straightforward - every password in a keychain is composed of two parts - one is the actual data itself, encrypted, and the other is the key for that data.  The Security framework, and the Keychain framework (typically), represent this pair of items as a single item, a KeychainItem.  But the access permissions are with respect to the key.  So, having encryption permission means you can encrypt data and thus modify the content.  Conversely, having decrypt permission means you can access the password.  Strictly speaking decrypt permission is all you need to do this.  However, it is wise to follow the convention and also add the additional permissions when creating or modifying "read access" ACLs. */

@interface AccessControlList : NSCachedObject {
    SecACLRef _ACL;
    OSStatus _error;
}

/*! @method accessControlListNamed:fromAccess:forApplications:requiringPassphrase:
    @abstract Creates and returns a named AccessControlList as a member of the provided Access instance, for the list of TrustedApplication's provided.
    @discussion It may seem a tad inflexible to require an AccessControlList to be created for an already-existing Access instance.  I totally agree - email the developers at Apple for writing their underlying Security framework in this way.
    @param name The name of the resulting AccessControlList.  This may be changed at a later date, and should not necessarily be used to uniquely identify an instance.
    @param acc The Access to which the resulting AccessControlList will automatically be added.  This cannot be nil.
	@param applications A list of trusted applications to which the receiver will apply, as any mixture of TrustedApplications, SecTrustedApplicationRefs and NSStrings (specifying the path to the application).  This argument may be empty, in which case no applications are trusted, or nil, in which case the receiver will trust all applications.
    @param requiringPassphrase If YES, the current users keychain passphrase must be provided to apply the authorizations in this list.  If NO, the authorizations are always available and in effect.
    @result Returns the newly created AccessControlList instance, or nil if an error occurs. */

+ (AccessControlList*)accessControlListNamed:(NSString*)name fromAccess:(Access*)acc forApplications:(NSArray*)applications requiringPassphrase:(BOOL)reqPass;

/*! @method accessControlListWithACLRef:
    @abstract Creates and returns an AccessControlList derived from the SecACLRef provided
    @discussion The returned instance acts as a wrapper around the SecACLRef.  Any changes to the SecACLRef will reflect in the AccessControlList instance, and vice versa.  The returned instance retains a copy of the SecACLRef for the duration of it's life.

                Note that this method caches each unique object, such that additional calls with the same SecACLRef will return the existing AccessControlList for that particular SecACLRef, not new instances
    @param AC The SecACLRef from which to derive the result
    @result An AccessControlList representing and wrapping around the SecACLRef provided. */

+ (AccessControlList*)accessControlListWithACLRef:(SecACLRef)AC;

/*! @method initWithName:fromAccess:forApplications:requiringPassphrase:
    @abstract Initializes an AccessControlList with the provided name, representing the supplied TrustedApplication's (if any), and added automatically to the Access instance provided.
    @discussion It may seem a tad inflexible to always require an AccessControlList to be added to an already-existing Access instance.  I totally agree - email the developers at Apple for writing their underlying Security framework in this way.
    @param name The name to be given to the receiver.  This may be changed at a later date, and should not necessarily be used to uniquely identify an instance.  XXX: should we allow this to be nil?
    @param acc The Access to which the receiver will automatically be added.  This cannot be nil.
    @param applications A list of trusted applications to which the receiver will apply, as any mixture of TrustedApplications, SecTrustedApplicationRefs and NSStrings (specifying the path to the application).  This argument may be empty, in which case no applications are trusted, or nil, in which case the receiver will trust all applications.
    @param requiringPassphrase If YES, the current users keychain passphrase must be provided to apply the authorizations in this list.  If NO, the authorizations are always available and in effect.
    @result Returns the initialized receiver, or nil if an error occurs. */

- (AccessControlList*)initWithName:(NSString*)name fromAccess:(Access*)acc forApplications:(NSArray*)applications requiringPassphrase:(BOOL)reqPass;

/*! @method initWithACLRef:
    @abstract Initializes the receiver around the SecACLRef provided.
    @discussion This initializer keeps a cache of each unique instance it creates, so that initializing several objects using the same SecAccessRef will return the same unique instance.  Thus, it may not return itself.  If an error occurs, nil is returned.
    @param AC The SecACLRef to wrap around.
    @result If an instance already exists for the provided SecACLRef, the receiver is released and the existing instance returned.  Otherwise, the receiver is initialized appropriate.  Returns nil if an error occurs. */

- (AccessControlList*)initWithACLRef:(SecACLRef)AC;

/*! @method init
    @abstract Reject initialiser.
    @discussion You cannot initialise an AccessControlList using "init" - use one of the other initialisation methods.
    @result This method always releases the receiver and returns nil. */

- (AccessControlList*)init;

/*! @method setApplications:
    @abstract Sets the list of trusted applications the receiver governs.  If "applications" is nil, all applications will be trusted.  If it is an empty array, no applications will be trusted.
    @param applications An NSArray containing any mix of TrustedApplications, SecTrustedApplicationRefs or NSStrings (specifying a path to an application).  May be nil, in which case any and all applications may use the receiver's permissions.
	@result Returns YES if the list was successfully set, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setApplications:(NSArray*)applications;

/*! @method addApplication:
    @abstract Adds the given application to the list of trusted applications the receiver governs.
	@discussion If the receiver applies to all applications (i.e. its applications list is not nil but empty) then this has no effect, as the given application already has access, implicitly.  Otherwise, the given application is added to the list.  This may require user authorisation, via a modal dialog or similar.  If the user refuses access NO will be returned.
    @param application An instance of a TrustedApplications, a SecTrustedApplicationRef or an NSString (specifying a path to an application).  Should not be nil.
	@result Returns YES if the application was successfully added, NO otherwise (including if 'application' is nil).  You can retrieve an error code using lastError. */

- (BOOL)addApplication:(id)application;

/*! @method removeApplication:
    @abstract Removes the given application from the list of trusted applications the receiver governs.
	@discussion The behaviour of this method is a little complex, so read the following carefully:
	
				1) If the receiver's application list is nil - meaning all applications are allowed by default - this method adds an empty list.  <i>This means that not only is the given application no longer able to access the item, but no applications are</i>.
				2) If the receiver's application list is not nil, the given application is removed (if present).

				Often you don't actually intend the behaviour of point 1, above.  In that case, use @link removeApplicationIfPresent: removeApplicationIfPresent:@/link, which will only perform point 2, if anything.
    @param application An instance of a TrustedApplications, a SecTrustedApplicationRef or an NSString (specifying a path to an application).  Should not be nil.
	@result Returns YES if the given application is no longer given implicit or explicit access to the item, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)removeApplication:(id)application;

/*! @method removeApplicationIfPresent:
    @abstract Removes the given application, if present, from the list of trusted applications the receiver governs.
	@discussion 1) If the receiver's application list is not nil, the given application is removed from the list, if present, and YES is returned.
				2) If the receiver's application list is nil - meaning all applications are allowed by default - then <i>this method does nothing</i>, but returns YES.

				i.e. this method does not remove implicit access, only explicit.  If your intention is to completely remove access by the given application (potentially at the expense of all other applications), use @link removeApplication: removeApplication:@/link.
    @param application An instance of a TrustedApplications, a SecTrustedApplicationRef or an NSString (specifying a path to an application).  Should not be nil.
	@result Returns YES if the given application is no longer given explicit access to the item, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)removeApplicationIfPresent:(id)application;

/*! @method setName:
    @abstract Sets the name of the receiver to the value given.
    @param name The new name to be given to the receiver.  May be an empty string, but should not be nil.
	@result Returns YES if the name was successfully changed, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setName:(NSString*)name;

/*! @method setRequiresPassphrase:
    @abstract Sets whether or not the receiver requires the user's authorization to be used.
    @discussion If this is set to YES, the user must provided their authorization (by entering their keychain password) in order to the receiver's authorizations to be applied.  This applies even if your application is in the ACL.
    @param reqPass Whether or not the user's authorization is required.
	@result Returns YES if the setting was applied successfully, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setRequiresPassphrase:(BOOL)reqPass;

/*! @method applications
    @abstract Returns the list of trusted applications the receiver governs.
	@discussion The returned list is not mutable.  If you wish to change it, you can use either the @link addApplication: addApplication:@/link/@link removeApplication: removeApplication:@/link methods, or create a mutable copy, change it as desired, and then apply it using @link setApplications: setApplications:@/link.
    @result An NSArray containing 0 or more TrustedApplication's.  If empty (but not nil), no applications are trusted.  If nil is returned, check if an error occurred using @link lastError lastError@/link - if it did not, the receiver applies to any and all applications.  You may also wish to use the convenience method @link allowsAnyApplication allowsAnyApplication@/link. */

- (NSArray*)applications;

/*! @method allowsAnyApplication
	@abstract Returns whether or not any and all applications may use the receiver's permissions.
	@discussion This is a convenience method over @link applications applications@/link.
	@result Returns YES if the receiver allows any application to use its permissions, NO otherwise. */

- (BOOL)allowsAnyApplication;

/*! @method name
    @abstract Returns the name of the receiver.
    @discussion An AccessControlList's name is not inherantly a unique identifier of that particular instance.  Be aware of this, and avoid making such dangerous assumptions.
    @result The name of the receiver (which may be an empty string if it has no name), or nil if an error occurs.  You can retrieve an error code using lastError. */

- (NSString*)name;

/*! @method requiresPassphrase
    @abstract Returns whether or not the current user's permission is required in order for the receiver to apply it's authorizations.
    @discussion If this is YES, the user must provided their permission (and authenticate against their keychain password) before the receiver can apply it's authorizations.
    @result Whether or not the user's permission is currently required.  In the case of an error, returns NO - check lastError to determine if an error occurred. */

- (BOOL)requiresPassphrase;

/*! @method setAuthorizations:
	@abstract Sets the authorizations the receiver provides.
	@discussion While there are many scenarios where you may want to use this (in particular, if you want to clear all authorisations), if you can you should use more specific methods (such as setAuthorizesAction:to:, or one of the many related convenience methods).  This is simply to aid future proofing.
	@param authorizations An array of zero or more NSNumbers, who's value is an CSSM_ACL_AUTHORIZATION_TAG.
	@result Returns YES if the operation was successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizations:(NSArray*)authorizations;

/*! @method setAuthorizesAction:to
    @abstract Sets whether or not the receiver authorizes a particular action.
    @param action The action type.
    @param to Whether or not the receiver should authorize the action.
	@result Returns YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesAction:(CSSM_ACL_AUTHORIZATION_TAG)action to:(BOOL)value;

/*! @method setAuthorizesEverything
    @abstract Sets whether the receiver authorizes Everything.
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.  Note that 'Everything' here is a separate and distinct action in it's own right - it is not an encompassing set of all available actions.
    @param value Whether or not the receiver should authorize Everything. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesEverything:(BOOL)value;

/*! @method setAuthorizesLogin
    @abstract Sets whether the receiver authorizes login operations and usage.
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.
    @param value Whether or not the receiver should authorize login operations and usage. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesLogin:(BOOL)value;

/*! @method setAuthorizesGeneratingKeys
    @abstract Sets whether the receiver authorizes key generation.
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.
    @param value Whether or not the receiver should authorize key generation. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesGeneratingKeys:(BOOL)value;

/*! @method setAuthorizesDeletion
    @abstract Sets whether the receiver authorizes deletion and removal operations.
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.
    @param value Whether or not the receiver should authorize deletion and removal. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesDeletion:(BOOL)value;

/*! @method setAuthorizesExportingWrapped
    @abstract Sets whether the receiver authorizes exporting keys wrapped with other keys.
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.  Note that this is a distinct authorization to allowing clear (null wrapped) keys.
    @param value Whether or not the receiver should authorize exporting wrapped keys. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesExportingWrapped:(BOOL)value;

/*! @method setAuthorizesExportingClear
    @abstract Sets whether the receiver authorizes exporting keys in the clear (null wrapped).
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.  Note that this is a separate and distinct authorization to exporting keys wrapped with other keys.
    @param value Whether or not the receiver should authorize exporting keys in the clear. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesExportingClear:(BOOL)value;

/*! @method setAuthorizesImportingWrapped
    @abstract Sets whether the receiver authorizes importing keys wrapped with other keys.
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.  Note that this authorization does not allow importing clear (null wrapped) keys.
    @param value Whether or not the receiver should authorize importing keys wrapped with other keys. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesImportingWrapped:(BOOL)value;

/*! @method setAuthorizesImportingClear
    @abstract Sets whether the receiver authorizes importing keys in the clear (null wrapped).
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.  Note that this is a distinct and separate authorization to importing keys wrapped with other keys.
    @param value Whether or not the receiver should authorize importing keys in the clear. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesImportingClear:(BOOL)value;

/*! @method setAuthorizesSigning
    @abstract Sets whether the receiver authorizes signing and verification operations.
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.
    @param value Whether or not the receiver should authorize signing and verification operations. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesSigning:(BOOL)value;

/*! @method setAuthorizesEncrypting
    @abstract Sets whether the receiver authorizes encryption operations.
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.
    @param value Whether or not the receiver should authorize encryption operations. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesEncrypting:(BOOL)value;

/*! @method setAuthorizesDecrypting
    @abstract Sets whether the receiver authorizes decryption operations.
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.
    @param value Whether or not the receiver should authorize decryption operations. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesDecrypting:(BOOL)value;

/*! @method setAuthorizesMACGeneration
    @abstract Sets whether the receiver authorizes MAC generation and verification.
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.
    @param value Whether or not the receiver should authorize MAC generation and verification. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesMACGeneration:(BOOL)value;

/*! @method setAuthorizesDerivingKeys
    @abstract Sets whether the receiver authorizes key derivation.
    @discussion This is merely a convenience method, which itself calls setAuthorizesAction:to:.
    @param value Whether or not the receiver should authorize key derivation. 
	@result Returnes YES if successful, NO otherwise.  You can retrieve an error code using lastError. */

- (BOOL)setAuthorizesDerivingKeys:(BOOL)value;

/*! @method authorizations
	@abstract Returns the authorizations the receiver provides.
	@discussion While there are legitimate scenarios where you would need this method (e.g. you want to get an exhaustive list of the authorisations, whatever they are), if you have a more specific need that permits the use of authorizesAction: or any of its convenience methods, you should use those - simply to aid future proofing.
	@result Returns an NSArray containing zero or more NSNumbers, where each NSNumber contains a CSSM_ACL_AUTHORIZATION_TAG as its integer value.  Returns nil if an error occurs (you can retrieve the corresponding error code in this case using lastError). */

- (NSArray*)authorizations;

/*! @method authorizesAction:
    @abstract Returns whether or not the receiver provides authorization for a particular action.
    @param action The action in question.
    @result Whether or not the receiver authorizes the action provided.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesAction:(CSSM_ACL_AUTHORIZATION_TAG)action;

/*! @method authorizesEverything
    @abstract Returns whether or not the receiver provides authorization for Everything.
    @discussion This is merely a convenience method, which itself calls authorizesAction:.  Note that 'Everything' is a specific and distinct action in itself, not merely a grouping of all available actions.
    @result Whether or not the receiver provides authorization for Everything.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesEverything;

/*! @method authorizesLogin
    @abstract Returns whether or not the receiver provides authorization for login operations and usage.
    @discussion This is merely a convenience method, which itself calls authorizesAction:.
    @result Whether or not the receiver provides authorization for login operations and usage.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesLogin;

/*! @method authorizesGeneratingKeys
    @abstract Returns whether or not the receiver provides authorization for key generation.
    @discussion This is merely a convenience method, which itself calls authorizesAction:.
    @result Whether or not the receiver provides authorization for key generation.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesGeneratingKeys;

/*! @method authorizesDeletion
    @abstract Returns whether or not the receiver provides authorization for deletion and removal operations.
    @discussion This is merely a convenience method, which itself calls authorizesAction:.
    @result Whether or not the receiver provides authorization for deletion and removal operations.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesDeletion;

/*! @method authorizesExportingWrapped
    @abstract Returns whether or not the receiver provides authorization for exporting keys wrapped with other keys.
    @discussion This is merely a convenience method, which itself calls authorizesAction:.  Note that being able to export keys wrapped with other keys does not imply being able to export clear (null wrapped) keys.
    @result Whether or not the receiver provides authorization for exporting keys wrapped with other keys.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesExportingWrapped;

/*! @method authorizesExportingClear
    @abstract Returns whether or not the receiver provides authorization for exporting keys in the clear (null wrapped).
    @discussion This is merely a convenience method, which itself calls authorizesAction:.  Note that being able to export keys in the clear (null wrapped) does not imply being able to export keys wrapped with other keys.
    @result Whether or not the receiver provides authorization for exporting keys in the clear.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesExportingClear;

/*! @method authorizesImportingWrapped
    @abstract Returns whether or not the receiver provides authorization for importing keys wrapped with other keys.
    @discussion This is merely a convenience method, which itself calls authorizesAction:.  Note that being able to import keys wrapped with other keys does not imply being able to import clear (null wrapped) keys.
    @result Whether or not the receiver provides authorization for importing keys wrapped with other keys.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesImportingWrapped;

/*! @method authorizesImportingClear
    @abstract Returns whether or not the receiver provides authorization for importing keys in the clear (null wrapped).
    @discussion This is merely a convenience method, which itself calls authorizesAction:.  Note that being able to import keys in the clear (null wrapped) does not imply being able to import keys wrapped with other keys.
    @result Whether or not the receiver provides authorization for importing keys in the clear.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesImportingClear;

/*! @method authorizesSigning
    @abstract Returns whether or not the receiver provides authorization for signing and verification operations.
    @discussion This is merely a convenience method, which itself calls authorizesAction:.
    @result Whether or not the receiver provides authorization for signing and verification operations.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesSigning;

/*! @method authorizesEncrypting
    @abstract Returns whether or not the receiver provides authorization for encryption operations.
    @discussion This is merely a convenience method, which itself calls authorizesAction:.
    @result Whether or not the receiver provides authorization for encryption operations.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesEncrypting;

/*! @method authorizesDecrypting
    @abstract Returns whether or not the receiver provides authorization for decryption operations.
    @discussion This is merely a convenience method, which itself calls authorizesAction:.
    @result Whether or not the receiver provides authorization for decryption operations.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesDecrypting;

/*! @method authorizesMACGeneration
    @abstract Returns whether or not the receiver provides authorization for MAC generation and verification.
    @discussion This is merely a convenience method, which itself calls authorizesAction:.
    @result Whether or not the receiver provides authorization for MAC generation and verification.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesMACGeneration;

/*! @method authorizesDerivingKeys
    @abstract Returns whether or not the receiver provides authorization for key derivation.
    @discussion This is merely a convenience method, which itself calls authorizesAction:.
    @result Whether or not the receiver provides authorization for key derivation.  Returns NO if an error occurs - you can check for this case using lastError; it will be 0 (CSSM_OK/noErr) if the operation was successful. */

- (BOOL)authorizesDerivingKeys;

/*! @method deleteAccessControlList
    @abstract Removes the receiver from it's owning Access instance
    @discussion I believe this is the behaviour.  However, it may not be correct - the Security framework documentation is extremely sparse. */

- (void)deleteAccessControlList;

/*! @method lastError
    @abstract Returns the last error that occured for the receiver.
    @discussion The set of error codes encompasses those returned by Sec* functions - typically OSStatus'; refer to the Security framework documentation for a list - which also includes standard Mac errors (see MacErrors.h) and CDSA error codes.

                Please note that this error code is local to the receiver only, and not any sort of shared global value.
    @result The last error that occured, or zero (CSSM_OK/noErr) if the last operation was successful. */

- (OSStatus)lastError;

/*! @method accessRef
    @abstract Returns the SecAccessRef the receiver is based on.
    @discussion If the receiver was created from a SecACLRef, it is this original reference that is returned.  Otherwise, a SecACLRef is created and returned.
    @result The SecACLRef for the receiver.  You should retain this if you wish to use it beyond the lifetime of the receiver.  Returns NULL if an error occurs. */

- (SecACLRef)ACLRef;

@end
