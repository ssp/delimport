//
//  CSSMModule.m
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

#import "CSSMManagedModule.h"
#import "Utilities/MultiThreadingInternal.h"
#import "CSSMUtils.h"
#import "CSSMControl.h"
#import "Utilities/Logging.h"
#import "CSSMTypes.h"
#import "Utilities/CompilerIndependence.h"

#import <libkern/OSAtomic.h>



@implementation CSSMManagedModule

CSSM_RETURN CSSMModuleMagicGenericCallback(const CSSM_GUID *ModuleGuid __unused,
                                           void* AppNotifyCallbackCtx __unused,
                                           uint32 SubserviceId __unused,
                                           CSSM_SERVICE_TYPE ServiceType __unused,
                                           CSSM_MODULE_EVENT EventType __unused) {
    return CSSM_OK;
}

#ifdef __LP64__
static int64_t CSSMModuleMagicGenericCallbackContextNumber = 0L;
#else
static int32_t CSSMModuleMagicGenericCallbackContextNumber = 0;
#endif

typedef size_t CSSM_SIZE;	// for the 10.4 SDK

void* genericCSSMMalloc(CSSM_SIZE size, void *ref __unused) {
    return malloc(size);
}

void* genericCSSMRealloc(void *ptr, CSSM_SIZE newSize, void *ref __unused) {
    return realloc(ptr, newSize);
}

void* genericCSSMCalloc(uint32 num, CSSM_SIZE size, void *ref __unused) {
    return calloc(num, size);
}

void genericCSSMFree(void *ptr, void *ref __unused) {
    return free(ptr);
}

const CSSM_MEMORY_FUNCS internalMemoryFunctions = {genericCSSMMalloc, genericCSSMFree, genericCSSMRealloc, genericCSSMCalloc, NULL};
CSSM_MEMORY_FUNCS defaultMemoryFunctions = {genericCSSMMalloc, genericCSSMFree, genericCSSMRealloc, genericCSSMCalloc, NULL};


#pragma mark Global Configuration

+ (const CSSM_MEMORY_FUNCS*)defaultMemoryFunctions {
    return &defaultMemoryFunctions;
}

+ (void)setDefaultMemoryFunctions:(const CSSM_MEMORY_FUNCS*)functions {
    memcpy(&defaultMemoryFunctions, ((NULL == functions) ? &internalMemoryFunctions : functions), sizeof(CSSM_MEMORY_FUNCS));
}


#pragma mark Initialisers

- (CSSMModule*)initWithHandle:(CSSM_MODULE_HANDLE)handle {
    PSYSLOGND(LOG_ERR, @"initWithHandle: is not valid for CSSMManagedModule instances.\n");
    PDEBUG(@"initWithHandle:%"PRImoduleHandle" invoked on CSSMManagedModule.\n", handle);
    
    [self release];
    return nil;
}

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
        
        _GUID = GUID;
        
        _keyHierarchy = keychainFrameworkDefaultKeyHierarchy();
        
        // This is beautiful, really.... we provide a useless generic callback with a globally unique context value, which ensures our load of this GUID will be unique.  This way multiple instances of CSSMManagedModule can load the same module, and then unload it happily enough, without having to be concerned about buggering up this inferred reference counting system.
        // Unless of course the user provides their own callback & context, and do so for multiple instances.  Bad user.  We could put in junk to test for that, but I don't think it's worth it... the user should just be careful; it is noted that they cannot do that in the header documentation.
        
        _callback = &CSSMModuleMagicGenericCallback;
#ifdef __LP64__
		_callbackContext = (void *)OSAtomicIncrement64(&CSSMModuleMagicGenericCallbackContextNumber);
#else
        _callbackContext = (void*)OSAtomicIncrement32(&CSSMModuleMagicGenericCallbackContextNumber);
#endif
        
        _version = keychainFrameworkDefaultCSSMVersion();
        _memoryFunctions = *[[self class] defaultMemoryFunctions];
        _subserviceID = 0;
        _subserviceType = 0; // Should possibly try to auto-identify this based on the GUID, if it's a known GUID.
        _attachFlags = 0;
        _moduleFunctions = NULL;
        _numberOfModuleFunctions = 0;
        _reservedParameter = 0;
        
        // The Goodness
        _loaded = _attached = NO;
        _handle = 0;
        _error = 0;
        
        
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

- (CSSM_KEY_HIERARCHY)keyHierarchy {
    return _keyHierarchy;
}

- (BOOL)setKeyHierarchy:(CSSM_KEY_HIERARCHY)keyHierarchy {
    if (_loaded || _attached) {
        return NO;
    } else {
        _keyHierarchy = keyHierarchy;
        return YES;
    }
}

- (CSSM_API_ModuleEventHandler)callback {
    return _callback;
}

- (BOOL)setCallback:(CSSM_API_ModuleEventHandler)callback {
    if (_loaded) {
        return NO;
    } else {
        _callback = callback;
        return YES;
    }
}

- (void*)callbackContext {
    return _callbackContext;
}

- (BOOL)setCallbackContext:(void*)callbackContext {
    if (_loaded) {
        return NO;
    } else {
        _callbackContext = callbackContext;
        return YES;
    }
}

- (BOOL)setVersion:(CSSM_VERSION)version {
    if (_attached) {
        return NO;
    } else {
        _version = version;
        return YES;
    }
}

- (BOOL)setMemoryFunctions:(const CSSM_API_MEMORY_FUNCS*)memoryFunctions {
    if (_attached) {
        return NO;
    } else {
        _memoryFunctions = *memoryFunctions;
        return YES;
    }
}

- (BOOL)setSubserviceID:(uint32_t)subserviceID {
    if (_attached) {
        return NO;
    } else {
        _subserviceID = subserviceID;
        return YES;
    }
}

- (BOOL)setSubserviceType:(CSSM_SERVICE_TYPE)subserviceType {
    if (_attached) {
        return NO;
    } else {
        _subserviceType = subserviceType;
        return YES;
    }
}

- (CSSM_ATTACH_FLAGS)attachFlags {
    return _attachFlags;
}

- (BOOL)setAttachFlags:(CSSM_ATTACH_FLAGS)attachFlags {
    if (_attached) {
        return NO;
    } else {
        _attachFlags = attachFlags;
        return YES;
    }
}

- (const CSSM_FUNC_NAME_ADDR*)moduleFunctions {
    return _moduleFunctions;
}

- (uint32_t)numberOfModuleFunctions {
    return _numberOfModuleFunctions;
}

- (BOOL)setModuleFunctions:(CSSM_FUNC_NAME_ADDR*)moduleFunctions count:(uint32_t)numberOfModuleFunctions {
    if (_attached) {
        return NO;
    } else {
        if ((NULL != _moduleFunctions) && (0 < _numberOfModuleFunctions)) {
            free(_moduleFunctions);
        }
        
        if ((NULL != moduleFunctions) && (0 < numberOfModuleFunctions)) {
            _moduleFunctions = (CSSM_FUNC_NAME_ADDR*)malloc(numberOfModuleFunctions * sizeof(CSSM_FUNC_NAME_ADDR));
            
            if (NULL == _moduleFunctions) {
                PDEBUG(@"Unable to allocate %u bytes of memory for %u module function thingies.\n", numberOfModuleFunctions * sizeof(CSSM_FUNC_NAME_ADDR), numberOfModuleFunctions);
                _numberOfModuleFunctions = 0;
                return NO;
            } else {
                memcpy(_moduleFunctions, moduleFunctions, numberOfModuleFunctions * sizeof(CSSM_FUNC_NAME_ADDR));
            }
        } else {
            _moduleFunctions = NULL;
            _numberOfModuleFunctions = 0;
        }
        
        return YES;
    }
}

- (BOOL)addModuleFunction:(CSSM_FUNC_NAME_ADDR)moduleFunction {
    if (_attached) {
        return NO;
    } else {
        if ((NULL != _moduleFunctions) && (0 < _numberOfModuleFunctions)) {
            ++_numberOfModuleFunctions;
            
            _moduleFunctions = realloc(_moduleFunctions, _numberOfModuleFunctions * sizeof(CSSM_FUNC_NAME_ADDR));
            
            if (NULL == _moduleFunctions) {
                PDEBUG(@"Unable to reallocate space for %u module functions (%u bytes).\n", _numberOfModuleFunctions, _numberOfModuleFunctions * sizeof(CSSM_FUNC_NAME_ADDR));
                
                _numberOfModuleFunctions = 0;
                return NO;
            }
        } else {
            _numberOfModuleFunctions = 1;
            _moduleFunctions = (CSSM_FUNC_NAME_ADDR*)malloc(sizeof(CSSM_FUNC_NAME_ADDR));
        }
        
        memcpy(&(_moduleFunctions[_numberOfModuleFunctions - 1]), &moduleFunction, sizeof(CSSM_FUNC_NAME_ADDR));
        
        return YES;
    }
}

- (void*)reservedParameter {
    return _reservedParameter;
}

- (BOOL)setReservedParameter:(void*)reservedParameter {
    if (_attached) {
        return NO;
    } else {
        _reservedParameter = reservedParameter;
        return YES;
    }
}

#pragma mark Managers

- (BOOL)load {
    if (_loaded) {
        return YES;
    } else {
        if (cssmInit(NULL, keychainFrameworkDefaultPrivilegeScope(), NULL, keychainFrameworkDefaultKeyHierarchy(), keychainFrameworkDefaultPVCPolicy(), NULL)) {
            _error = CSSM_ModuleLoad(&_GUID, _keyHierarchy, _callback, _callbackContext);
            
            _loaded = (CSSM_OK == _error);
            
            if (!_loaded) {
                PSYSLOGND(LOG_NOTICE, @"Unable to load module (with GUID %@) because of error %@.\n", GUIDAsString(&_GUID), CSSMErrorAsString(_error));
                PDEBUG(@"CSSM_ModuleLoad(%p [%@], %d, %p, %p) returned error %@.\n", &_GUID, GUIDAsString(&_GUID), _keyHierarchy, _callback, _callbackContext, CSSMErrorAsString(_error));
            }
            
            return _loaded;
        } else {
            PDEBUG(@"Unable to initialise the CSSM.\n");
            return NO;
        }
    }
}

- (BOOL)unload {
    if (_loaded) { // Implies CSSM is initialised
        _error = CSSM_ModuleUnload(&_GUID, _callback, _callbackContext);
        
        _loaded = !((CSSMERR_CSSM_ADDIN_UNLOAD_FAILED != _error) && (CSSMERR_CSSM_EMM_UNLOAD_FAILED != _error));
        
        if (CSSM_OK != _error) {
            PSYSLOGND(LOG_NOTICE, @"Unable to unload module (with GUID %@) because of error %@.\n", GUIDAsString(&_GUID), CSSMErrorAsString(_error));
            PDEBUG(@"CSSM_ModuleUnload(%p [%@], %p, %p) returned error %@.\n", &_GUID, GUIDAsString(&_GUID), _callback, _callbackContext, CSSMErrorAsString(_error));
        }
        
        return (CSSM_OK == _error);
    } else {
        return YES;
    }
}

- (BOOL)isLoaded {
    return _loaded;
}

- (BOOL)attach {
    if (_attached) {
        return YES;
    } else {
        if (cssmInit(NULL, keychainFrameworkDefaultPrivilegeScope(), NULL, keychainFrameworkDefaultKeyHierarchy(), keychainFrameworkDefaultPVCPolicy(), NULL)) {
            _error = CSSM_ModuleAttach(&_GUID, &_version, &_memoryFunctions, _subserviceID, _subserviceType, _attachFlags, _keyHierarchy, _moduleFunctions, _numberOfModuleFunctions, _reservedParameter, &_handle);

            _attached = (CSSM_OK == _error);
            
            if (!_attached) {
                PSYSLOGND(LOG_NOTICE, @"Unable to attach module (with GUID %@) because of error %@.\n", GUIDAsString(&_GUID), CSSMErrorAsString(_error));
                PDEBUG(@"CSSM_ModuleAttach(%p [%@], %p ({%u, %u}), %p, %d, %d, 0x%x, %d, %p, %u, %p, %p [%"PRIclHandle"]) returned error %@.\n", &_GUID, GUIDAsString(&_GUID), &_version, _version.Major, _version.Minor, _memoryFunctions, _subserviceID, _subserviceType, _attachFlags, _keyHierarchy, _moduleFunctions, _numberOfModuleFunctions, _reservedParameter, &_handle, _handle, CSSMErrorAsString(_error));
            }
            
            return _attached;
        } else {
            PDEBUG(@"Unable to initialise the CSSM.\n");
            return NO;
        }
    }
}

- (BOOL)isAttached {
    return _attached;
}

- (CSSM_MODULE_HANDLE)handle {
    if ([self load] && [self attach]) {
        return _handle;
    } else {
        return 0;
    }
}

- (CSSM_RETURN)error {
    return _error;
}

- (void)dealloc {
    if (![self detach]) {
        PDEBUG(@"Unable to detach module (with GUID %@) in dealloc (of %p), error %@.\n", GUIDAsString(&_GUID), self, CSSMErrorAsString(_error));
    }
    
    if (![self unload]) {
        PDEBUG(@"Unable to unload module (with GUID %@) in dealloc (of %p), error %@.\n", GUIDAsString(&_GUID), self, CSSMErrorAsString(_error));
    }
    
    [super dealloc];
}

@end
