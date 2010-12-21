//
//  CSSMModule.h
//  Keychain
//
//  Created by Wade Tregaskis on 13/7/2006.
//
//  Copyright (c) 2006 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>
#import <Security/Security.h>

#import <Keychain/CSSMModule.h>


/*! @class CSSMManagedModule
    @abstract Represents a particular CSSM module, such as a cryptographic module or a secure data storage system, managed by the receiver.
    @discussion This nifty little class puts a nice Cocoa interface over module management.

                <b>Very important:</b> CSSM modules managed by this class (as opposed to the base CSSMModule) are assumed to be controlled solely by this class.  This means, among other things, that they are detached and unloaded when their corresponding CSSMManagedModule instance is released.  For this reason you cannot initialise an instance of the class using an existing handle (initWithHandle: will return nil if invoked on a CSSMManagedModule), as this could result in people getting confused about who's managing the module.  If you wish to manually manage the module (calling any of the relevant CSSM module functions directly), you can no longer rely on normal behaviours of this module.  For example, if you manually detach a module, this class will still think it is attached.  You will have to call the "detach" method to get this class back up to date (ignoring the return result, which will probably be NO on account of the module not really being attached to start with).  And as for loads/unloads, etc, too.

                Note that you may have multiple CSSMManagedModule's for a given module GUID; each instance of the module is unique, in the same way they you can run multiple copies of a program simultaneously, even though they have the same name (i.e. GUID).  By default some magic will be done to ensure CSSM_ModuleLoad thinks each instance is unique, even if they're not really.  You must ensure however that if you set your own callback you don't duplicate it across two CSSMManagedModule instances for the same module - this may result in a conflict that could cause the CSSM module to be prematurely unloaded, before all related CSSMManagedModule instances have been deallocated.

                You probably don't need to explicitly call detach or unload; these will be called when the CSSMManagedModule is deallocated.  Other Keychain classes may use CSSMManagedModule instances, retaining them for some period, and may not react very well to the module suddenly disappearing. */

@interface CSSMManagedModule : CSSMModule {
    // CSSM_ModuleLoad
    CSSM_KEY_HIERARCHY _keyHierarchy;
    CSSM_API_ModuleEventHandler _callback;
    void *_callbackContext;
    
    // CSSM_ModuleAttach
    CSSM_ATTACH_FLAGS _attachFlags;
    CSSM_FUNC_NAME_ADDR *_moduleFunctions;
    uint32_t _numberOfModuleFunctions;
    void *_reservedParameter;
}

#pragma mark Global Configuration

+ (const CSSM_MEMORY_FUNCS*)defaultMemoryFunctions;
+ (void)setDefaultMemoryFunctions:(const CSSM_MEMORY_FUNCS*)functions;


#pragma mark Initialisers

/*! @method firstExistingModuleWithGUID:
    @abstract Returns the first existing CSSMModule for a given GUID.
    @discussion 'First' is arbitrary, and no ordering or other presumption should be made as to which instance is chosen.  If you have specific needs, use the existingModulesWithGUID: method instead, and select the most suitable module from the array it returns.

                As a general explanation, every CSSMModule is considered unique, even if they share the same GUID, because they may have different parameters or different states.  All are recorded when created, and can be retrieved using this method or existingModulesWithGUID:.  Not that unlike subclasses of NSCachedObject (which CSSMModule is <i>not</i>), the init methods (including moduleWithGUID:) always return a new instance; if you want an existing instance (if available), you must check for it yourself explicitly.
    @param GUID The CSSM module GUID of interest.
    @result Returns an existing CSSMModule with the given GUID, if one exists, otherwise returns nil. */

+ (CSSMModule*)firstExistingModuleWithGUID:(CSSM_GUID)GUID;

/*! @method existingModulesWithGUID:
    @abstract Returns all existing CSSMModule's with a given GUID.
    @discussion Every CSSMModule is considered unique, even if they share the same GUID, because they may have different parameters or different states.  All are recorded when created, and can be retrieved using this method or existingModulesWithGUID:.  Not that unlike subclasses of NSCachedObject (which CSSMModule is <i>not</i>), the init methods (including moduleWithGUID:) always return a new instance; if you want an existing instance (if available), you must check for it yourself explicitly.
    @param GUID The CSSM module GUID of interest.
    @result Returns an NSArray containing zero or more CSSMModule instances, or nil if an error occurs. */

+ (NSArray*)existingModulesWithGUID:(CSSM_GUID)GUID;

/*! @method moduleWithGUID:
    @abstract Returns a <b>new</b> CSSMModule instance for the module with a given GUID.
    @discussion This method creates and initialises a new CSSMModule instance for the module with the given GUID.  It does not check if any existing CSSMModule's exist for the GUID; use the firstExistingModuleWithGUID: or existingModulesWithGUID: class methods if you wish to do this.
    @param GUID The CSSM module GUID of interest.
    @result Returns a new CSSMModule instance for the given GUID, or nil if an error occurs. */

+ (CSSMModule*)moduleWithGUID:(CSSM_GUID)GUID;

/*! @method initWithGUID:
    @abstract Initialises the receiver to work with the module identified by the specified GUID.
    @discussion Initialisation is actually performed lazily - the module will not be loaded, attached or otherwise used until you invoke "load", "attach" and/or "handle", as appropriate.  This of course is to allow you time to configure the receiver with any custom values you might like to provide, for the various parameters used in the loading and attaching.

                Note that this initialiser permits multiple instances of CSSMModule per module GUID.  If you want the existing CSSMModule instance for a given GUID, use the firstExistingModuleWithGUID: or existingModulesWithGUID: class methods.

                Also, review the class description before playing with CSSMModule - it notes the cavaets that come with using it.
    @result Returns an CSSMModule (which may not be the receiver) initialised for the given GUID. */

- (CSSMModule*)initWithGUID:(CSSM_GUID)GUID;


#pragma mark Getters & setters

// Yeah, I should document these, but... god... so lazy...

- (CSSM_KEY_HIERARCHY)keyHierarchy;
- (BOOL)setKeyHierarchy:(CSSM_KEY_HIERARCHY)keyHierarchy;

- (CSSM_API_ModuleEventHandler)callback;
- (BOOL)setCallback:(CSSM_API_ModuleEventHandler)callback;

- (void*)callbackContext;
- (BOOL)setCallbackContext:(void*)callbackContext;

- (BOOL)setVersion:(CSSM_VERSION)version;

- (BOOL)setMemoryFunctions:(const CSSM_API_MEMORY_FUNCS*)memoryFunctions;

- (BOOL)setSubserviceID:(uint32_t)subserviceID;

- (BOOL)setSubserviceType:(CSSM_SERVICE_TYPE)subserviceType;

- (CSSM_ATTACH_FLAGS)attachFlags;
- (BOOL)setAttachFlags:(CSSM_ATTACH_FLAGS)attachFlags;

- (const CSSM_FUNC_NAME_ADDR*)moduleFunctions;
- (uint32_t)numberOfModuleFunctions;
- (BOOL)setModuleFunctions:(CSSM_FUNC_NAME_ADDR*)moduleFunctions count:(uint32_t)numberOfModuleFunctions;
- (BOOL)addModuleFunction:(CSSM_FUNC_NAME_ADDR)moduleFunction;

- (void*)reservedParameter;
- (BOOL)setReservedParameter:(void*)reservedParameter;


#pragma mark Managers

/*! @method load
    @abstract Attempts to load the module.
    @discussion You must load a module before you can attach it, which you must do before you can use it.  This method only loads the module - once that is done, you should attach it using the attach method.

                Note that the "handle" method will automatically load & attach the module if necessary (for CSSMManagedModule instances only; generic CSSMModule's of course don't implement load or attach).  You may wish to call load manually, however, if you wish to be a good citizen and verify that the load was successful.  You may also check if the module is loaded at a later date using the "isLoaded" method.

                You can find more information about why a load failed using the "error" method.
    @result Returns YES if the module was loaded successful, NO otherwise.  If this method returns NO, you can obtain the exact error that occured using the "error" method. */

- (BOOL)load;

/*! @method unload
    @abstract Attempts to unload the module.
    @discussion You must dettach the receiver before you may unload it, which this method <b>does not</b> do for you.  Unloading may fail for any number of other reasons as well, such as the module still being in use, etc.

                The module is automatically unloaded when the receiver is deallocated.
    @result Returns YES if the module was successfully unloaded (or was already unloaded), NO otherwise.  If this method returns NO, you can obtain the exact error that occured using the "error" method. */

- (BOOL)unload;

/*! @method attach
    @abstract Attempts to attach the receiver.
    @discussion You must attach a module before you can use it.  This method <b>does not</b> attempt to laod the module first; if you call it when the module is not loaded, the attach will most certainly fail.

                Note that the "handle" method will automatically load & attach the module if necessary.  You may wish to call attach manually, however, if you wish to be a good citizen and verify that the attach was successful.

                You can find more information about why an attachment failed using the "error" method.
    @result Returns YES if the module was attached successful, NO otherwise.  If this method returns NO, you can obtain the exact error that occured using the "error" method. */

- (BOOL)attach;

@end
