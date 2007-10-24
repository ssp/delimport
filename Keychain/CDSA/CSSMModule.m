//
//  CSSMModule.m
//  Keychain
//
//  Created by Wade Tregaskis on 31/7/2005.
//
//  Copyright (c) 2006, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "CSSMModule.h"
#import "MultiThreadingInternal.h"
#import "CSSMUtils.h"
#import "CSSMControl.h"
#import "Logging.h"
#import "CSSMTypes.h"
#import "CompilerIndependence.h"

#import <libkern/OSAtomic.h>



@implementation CSSMModule

CSSM_RETURN CSSMModuleMagicGenericCallback(const CSSM_GUID *ModuleGuid __unused,
                                           void* AppNotifyCallbackCtx __unused,
                                           uint32 SubserviceId __unused,
                                           CSSM_SERVICE_TYPE ServiceType __unused,
                                           CSSM_MODULE_EVENT EventType __unused) {
    return CSSM_OK;
}

static int CSSMModuleMagicGenericCallbackContextNumber = 0;


void* genericCSSMMalloc(uint32 size, void *ref __unused) {
    return malloc(size);
}

void* genericCSSMRealloc(void *ptr, uint32 newSize, void *ref __unused) {
    return realloc(ptr, newSize);
}

void* genericCSSMCalloc(uint32 num, uint32 size, void *ref __unused) {
    return calloc(num, size);
}

void genericCSSMFree(void *ptr, void *ref __unused) {
    return free(ptr);
}

const CSSM_MEMORY_FUNCS internalMemoryFunctions = {genericCSSMMalloc, genericCSSMFree, genericCSSMRealloc, genericCSSMCalloc, NULL};
CSSM_MEMORY_FUNCS defaultMemoryFunctions = {genericCSSMMalloc, genericCSSMFree, genericCSSMRealloc, genericCSSMCalloc, NULL};

static CSSMModule *defaultCSP = nil, *defaultTP = nil, *defaultCL = nil;


#pragma mark Global Configuration

+ (void)initialize {
    defaultCSP = [[self alloc] initWithGUID:gGuidAppleCSP];
    [defaultCSP setSubserviceType:CSSM_SERVICE_CSP];
    
    defaultTP = [[self alloc] initWithGUID:gGuidAppleX509TP];
    [defaultTP setSubserviceType:CSSM_SERVICE_TP];
    
    defaultCL = [[self alloc] initWithGUID:gGuidAppleX509CL];
    [defaultCL setSubserviceType:CSSM_SERVICE_CL];
}

+ (const CSSM_MEMORY_FUNCS*)defaultMemoryFunctions {
    return &defaultMemoryFunctions;
}

+ (void)setDefaultMemoryFunctions:(const CSSM_MEMORY_FUNCS*)functions {
    memcpy(&defaultMemoryFunctions, ((NULL == functions) ? &internalMemoryFunctions : functions), sizeof(CSSM_MEMORY_FUNCS));
}

+ (CSSMModule*)defaultCSPModule {
    CSSMModule *result;
    
    [keychainDefaultModuleLock lock];
    
    result = [defaultCSP retain];
    
    [keychainDefaultModuleLock unlock];
    
    return [result autorelease];
}

+ (void)setDefaultCSPModule:(CSSMModule*)newDefault {
    [keychainDefaultModuleLock lock];

    if (defaultCSP != newDefault) {
        [defaultCSP release];
        defaultCSP = [newDefault retain];
    }
    
    [keychainDefaultModuleLock unlock];
}

+ (CSSMModule*)defaultTPModule {
    CSSMModule *result;
    
    [keychainDefaultModuleLock lock];
    
    result = [defaultTP retain];
    
    [keychainDefaultModuleLock unlock];
    
    return [result autorelease];
}

+ (void)setDefaultTPModule:(CSSMModule*)newDefault {
    [keychainDefaultModuleLock lock];

    if (defaultTP != newDefault) {
        [defaultTP release];
        defaultTP = [newDefault retain];
    }
    
    [keychainDefaultModuleLock unlock];
}

+ (CSSMModule*)defaultCLModule {
    CSSMModule *result;
    
    [keychainDefaultModuleLock lock];
    
    result = [defaultCL retain];
    
    [keychainDefaultModuleLock unlock];
    
    return [result autorelease];
}

+ (void)setDefaultCLModule:(CSSMModule*)newDefault {
    [keychainDefaultModuleLock lock];

    if (defaultCL != newDefault) {
        [defaultCL release];
        defaultCSP = [newDefault retain];
    }

    [keychainDefaultModuleLock unlock];
}


#pragma mark Initialisers

static NSMutableDictionary *existingModules = nil;

+ (CSSMModule*)firstExistingModuleWithGUID:(CSSM_GUID)GUID {
    NSArray *objects;
    CSSMModule *result = nil;
    
    [keychainCachedModuleLock lock];
    
    if (existingModules) {
        objects = [existingModules objectForKey:GUIDAsString(&GUID)];
        
        if ((nil != objects) && (0 < [objects count])) {
            result = [[objects objectAtIndex:0] retain];
        }
    }
    
    [keychainCachedModuleLock unlock];
    
    return [result autorelease];
}

+ (NSArray*)existingModulesWithGUID:(CSSM_GUID)GUID {
    NSArray *result = nil;
    
    [keychainCachedModuleLock lock];
    
    if (nil != existingModules) {
        result = [[existingModules objectForKey:GUIDAsString(&GUID)] copy];
    }
    
    if (nil == result) {
        result = [[NSArray alloc] init];
    }
    
    [keychainCachedModuleLock unlock];
    
    return [result autorelease];
}

+ (CSSMModule*)moduleWithGUID:(CSSM_GUID)GUID {
    return [[[[self class] alloc] initWithGUID:GUID] autorelease];
}

- (CSSMModule*)initWithGUID:(CSSM_GUID)GUID {
    if (self = [super init]) {
        NSMutableArray *cacheList;
        NSString *GUIDString = GUIDAsString(&GUID);
        
        myGUID = GUID;
        
        myKeyHierarchy = keychainFrameworkDefaultKeyHierarchy();
        
        // This is beautiful, really.... we provide a useless generic callback with a globally unique context value, which ensures our load of this GUID will be unique.  This way multiple instances of CSSMModule can load the same module, and then unload it happily enough, without having to be concerned about buggering up this inferred reference counting system.
        // Unless of course the user provides their own callback & context, and do so for multiple instances.  Bad user.  We could put in junk to test for that, but I don't think it's worth it... the user should just be careful; it is noted that they cannot do that in the header documentation.
        
        myCallback = &CSSMModuleMagicGenericCallback;
        myCallbackContext = (void*)OSAtomicIncrement32(&CSSMModuleMagicGenericCallbackContextNumber);
        
        myVersion = keychainFrameworkDefaultCSSMVersion();
        myMemoryFunctions = [[self class] defaultMemoryFunctions];
        mySubserviceID = 0;
        mySubserviceType = 0; // Should possibly try to auto-identify this based on the GUID, if it's a known GUID.
        myAttachFlags = 0;
        myModuleFunctions = NULL;
        myNumberOfModuleFunctions = 0;
        myReservedParameter = 0;
        
        // The Goodness
        amLoaded = amAttached = NO;
        myHandle = 0;
        lastError = 0;
        
        
        [keychainCachedModuleLock lock];
        
        if (!existingModules) {
            existingModules = [[NSMutableDictionary alloc] init];
        }
        
        cacheList = [existingModules objectForKey:GUIDString];
        
        if (!cacheList) {
            [existingModules setObject:[NSMutableArray arrayWithObject:self] forKey:GUIDString];
        } else {
            [cacheList addObject:self];
        }
        
        [keychainCachedModuleLock unlock];
    } else {
        [self release];
        self = nil;
    }
    
    return self;
}

#pragma mark Getters & Setters

- (CSSM_GUID)GUID {
    return myGUID;
}

- (CSSM_KEY_HIERARCHY)keyHierarchy {
    return myKeyHierarchy;
}

- (BOOL)setKeyHierarchy:(CSSM_KEY_HIERARCHY)keyHierarchy {
    if (amLoaded || amAttached) {
        return NO;
    } else {
        myKeyHierarchy = keyHierarchy;
        return YES;
    }
}

- (CSSM_API_ModuleEventHandler)callback {
    return myCallback;
}

- (BOOL)setCallback:(CSSM_API_ModuleEventHandler)callback {
    if (amLoaded) {
        return NO;
    } else {
        myCallback = callback;
        return YES;
    }
}

- (void*)callbackContext {
    return myCallbackContext;
}

- (BOOL)setCallbackContext:(void*)callbackContext {
    if (amLoaded) {
        return NO;
    } else {
        myCallbackContext = callbackContext;
        return YES;
    }
}

- (CSSM_VERSION)version {
    return myVersion;
}

- (BOOL)setVersion:(CSSM_VERSION)version {
    if (amAttached) {
        return NO;
    } else {
        myVersion = version;
        return YES;
    }
}

- (const CSSM_API_MEMORY_FUNCS*)memoryFunctions {
    return myMemoryFunctions;
}

- (BOOL)setMemoryFunctions:(const CSSM_API_MEMORY_FUNCS*)memoryFunctions {
    if (amAttached) {
        return NO;
    } else {
        myMemoryFunctions = memoryFunctions;
        return YES;
    }
}

- (uint32_t)subserviceID {
    return mySubserviceID;
}

- (BOOL)setSubserviceID:(uint32_t)subserviceID {
    if (amAttached) {
        return NO;
    } else {
        mySubserviceID = subserviceID;
        return YES;
    }
}

- (CSSM_SERVICE_TYPE)subserviceType {
    return mySubserviceType;
}

- (BOOL)setSubserviceType:(CSSM_SERVICE_TYPE)subserviceType {
    if (amAttached) {
        return NO;
    } else {
        mySubserviceType = subserviceType;
        return YES;
    }
}

- (CSSM_ATTACH_FLAGS)attachFlags {
    return myAttachFlags;
}

- (BOOL)setAttachFlags:(CSSM_ATTACH_FLAGS)attachFlags {
    if (amAttached) {
        return NO;
    } else {
        myAttachFlags = attachFlags;
        return YES;
    }
}

- (const CSSM_FUNC_NAME_ADDR*)moduleFunctions {
    return myModuleFunctions;
}

- (uint32_t)numberOfModuleFunctions {
    return myNumberOfModuleFunctions;
}

- (BOOL)setModuleFunctions:(CSSM_FUNC_NAME_ADDR*)moduleFunctions count:(uint32_t)numberOfModuleFunctions {
    if (amAttached) {
        return NO;
    } else {
        if ((NULL != myModuleFunctions) && (0 < myNumberOfModuleFunctions)) {
            free(myModuleFunctions);
        }
        
        if ((NULL != moduleFunctions) && (0 < numberOfModuleFunctions)) {
            myModuleFunctions = (CSSM_FUNC_NAME_ADDR*)malloc(numberOfModuleFunctions * sizeof(CSSM_FUNC_NAME_ADDR));
            
            if (NULL == myModuleFunctions) {
                PDEBUG(@"Unable to allocate %u bytes of memory for %u module function thingies.\n", numberOfModuleFunctions * sizeof(CSSM_FUNC_NAME_ADDR), numberOfModuleFunctions);
                myNumberOfModuleFunctions = 0;
                return NO;
            } else {
                memcpy(myModuleFunctions, moduleFunctions, numberOfModuleFunctions * sizeof(CSSM_FUNC_NAME_ADDR));
            }
        } else {
            myModuleFunctions = NULL;
            myNumberOfModuleFunctions = 0;
        }
        
        return YES;
    }
}

- (BOOL)addModuleFunction:(CSSM_FUNC_NAME_ADDR)moduleFunction {
    if (amAttached) {
        return NO;
    } else {
        if ((NULL != myModuleFunctions) && (0 < myNumberOfModuleFunctions)) {
            ++myNumberOfModuleFunctions;
            
            myModuleFunctions = realloc(myModuleFunctions, myNumberOfModuleFunctions * sizeof(CSSM_FUNC_NAME_ADDR));
            
            if (NULL == myModuleFunctions) {
                PDEBUG(@"Unable to reallocate space for %u module functions (%u bytes).\n", myNumberOfModuleFunctions, myNumberOfModuleFunctions * sizeof(CSSM_FUNC_NAME_ADDR));
                
                myNumberOfModuleFunctions = 0;
                return NO;
            }
        } else {
            myNumberOfModuleFunctions = 1;
            myModuleFunctions = (CSSM_FUNC_NAME_ADDR*)malloc(sizeof(CSSM_FUNC_NAME_ADDR));
        }
        
        memcpy(&(myModuleFunctions[myNumberOfModuleFunctions - 1]), &moduleFunction, sizeof(CSSM_FUNC_NAME_ADDR));
        
        return YES;
    }
}

- (void*)reservedParameter {
    return myReservedParameter;
}

- (BOOL)setReservedParameter:(void*)reservedParameter {
    if (amAttached) {
        return NO;
    } else {
        myReservedParameter = reservedParameter;
        return YES;
    }
}

#pragma mark Managers

- (BOOL)load {
    if (amLoaded) {
        return YES;
    } else {
        if (cssmInit(NULL, keychainFrameworkDefaultPrivilegeScope(), NULL, keychainFrameworkDefaultKeyHierarchy(), keychainFrameworkDefaultPVCPolicy(), NULL)) {
            lastError = CSSM_ModuleLoad(&myGUID, myKeyHierarchy, myCallback, myCallbackContext);
            
            amLoaded = (CSSM_OK == lastError);
            
#ifndef NDEBUG
            if (!amLoaded) {
                PCONSOLE(@"Unable to load module (with GUID %@) because of error #%u - %@.\n", GUIDAsString(&myGUID), lastError, CSSMErrorAsString(lastError));
                PDEBUG(@"CSSM_ModuleLoad(%p [%@], %d, %p, %p) returned error #%u - %@.\n", &myGUID, GUIDAsString(&myGUID), myKeyHierarchy, myCallback, myCallbackContext, lastError, CSSMErrorAsString(lastError));
            }
#endif
            
            return amLoaded;
        } else {
            PDEBUG(@"Unable to initialise the CSSM.\n");
            return NO;
        }
    }
}

- (BOOL)unload {
    if (amLoaded) { // Implies CSSM is initialised
        lastError = CSSM_ModuleUnload(&myGUID, myCallback, myCallbackContext);
        
        amLoaded = !((CSSMERR_CSSM_ADDIN_UNLOAD_FAILED != lastError) && (CSSMERR_CSSM_EMM_UNLOAD_FAILED != lastError));
        
#ifndef NDEBUG
        if (CSSM_OK != lastError) {
            PCONSOLE(@"Unable to unload module (with GUID %@) because of error #%u - %@.\n", GUIDAsString(&myGUID), lastError, CSSMErrorAsString(lastError));
            PDEBUG(@"CSSM_ModuleUnload(%p [%@], %p, %p) returned error #%u - %@.\n", &myGUID, GUIDAsString(&myGUID), myCallback, myCallbackContext, lastError, CSSMErrorAsString(lastError));
        }
#endif
        
        return (CSSM_OK == lastError);
    } else {
        return YES;
    }
}

- (BOOL)isLoaded {
    return amLoaded;
}

- (BOOL)attach {
    if (amAttached) {
        return YES;
    } else {
        if (cssmInit(NULL, keychainFrameworkDefaultPrivilegeScope(), NULL, keychainFrameworkDefaultKeyHierarchy(), keychainFrameworkDefaultPVCPolicy(), NULL)) {
            lastError = CSSM_ModuleAttach(&myGUID, &myVersion, myMemoryFunctions, mySubserviceID, mySubserviceType, myAttachFlags, myKeyHierarchy, myModuleFunctions, myNumberOfModuleFunctions, myReservedParameter, &myHandle);

            amAttached = (CSSM_OK == lastError);
            
#ifndef NDEBUG
            if (!amAttached) {
                PCONSOLE(@"Unable to attach module (with GUID %@) because of error #%u - %@.\n", GUIDAsString(&myGUID), lastError, CSSMErrorAsString(lastError));
                PDEBUG(@"CSSM_ModuleAttach(%p [%@], %p ({%u, %u}), %p, %d, %d, 0x%x, %d, %p, %u, %p, %p [%"PRIclHandle"]) returned error #%u - %@.\n", &myGUID, GUIDAsString(&myGUID), &myVersion, myVersion.Major, myVersion.Minor, myMemoryFunctions, mySubserviceID, mySubserviceType, myAttachFlags, myKeyHierarchy, myModuleFunctions, myNumberOfModuleFunctions, myReservedParameter, &myHandle, myHandle, lastError, CSSMErrorAsString(lastError));
            }
#endif
            
            return amAttached;
        } else {
            PDEBUG(@"Unable to initialise the CSSM.\n");
            return NO;
        }
    }
}

- (BOOL)detach {
    if (amAttached) { // Implies CSSM is initialised
        lastError = CSSM_ModuleDetach(myHandle);
        
        amAttached = NO; // Assume it always detaches one way or another... really should figure out possible errors and treat them appropriately.

#ifndef NDEBUG
        if (CSSM_OK != lastError) {
            PCONSOLE(@"Unable to detach module (with GUID %@) because of error #%u - %@.\n", GUIDAsString(&myGUID), lastError, CSSMErrorAsString(lastError));
            PDEBUG(@"CSSM_ModuleDetach(%"PRIclHandle") returned error #%u (%@), using module GUID %@.\n", myHandle, lastError, CSSMErrorAsString(lastError), GUIDAsString(&myGUID));
        }
#endif
        
        return (CSSM_OK == lastError);
    } else {
        return YES;
    }
}

- (BOOL)isAttached {
    return amAttached;
}

- (BOOL)isReady {
    return (amLoaded && amAttached);
}

- (CSSM_MODULE_HANDLE)handle {
    if ((amLoaded || [self load]) && (amAttached || [self attach])) {
        return myHandle;
    } else {
        return 0;
    }
}

- (CSSM_RETURN)error {
    return lastError;
}

- (void)dealloc {
    if (![self detach]) {
        PDEBUG(@"Unable to detach module (with GUID %@) in dealloc (of %p), error #%u - %@.\n", GUIDAsString(&myGUID), self, lastError, CSSMErrorAsString(lastError));
    }
    
    if (![self unload]) {
        PDEBUG(@"Unable to unload module (with GUID %@) in dealloc (of %p), error #%u - %@.\n", GUIDAsString(&myGUID), self, lastError, CSSMErrorAsString(lastError));
    }
    
    if (NULL != myModuleFunctions) {
        free(myModuleFunctions);
    }
    
    [super dealloc];
}

@end
