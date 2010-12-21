//
//  MultiThreadingInternal.h
//  Keychain
//
//  Created by Wade Tregaskis on Wed Aug 3 2005.
//
//  Copyright (c) 2005 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/*! @header MultiThreadingInternal
    @abstract Defines internal stuff related to thread safety in the framework.
    @discussion This file basically just exports the numerous locks used for thread-safety.  It should not be publically available to avoid the temptation of poking around with them, by 3rd parties. */

#import <Foundation/Foundation.h>


/*! @var keychainCachedObjectLock Represents the global lock used by NSCachedObject to avoid race conditions in multi-threaded programs.  (NSCachedObject.h/m) */

extern NSLock *keychainCachedObjectLock;

/*! @var keychainCachedModuleLock Similar to keychainCachedObjectLock, but applies specifically to the CSSMModule class.  (CSSMModule.h/m) */

extern NSLock *keychainCachedModuleLock;

/*! @var keychainDefaultModuleLock Used to ensure coherency when manipulating the default modules for CSP, TP, CL, etc, operations.  (CSSMModule.h/m) */

extern NSLock *keychainDefaultModuleLock;

/*! @var keychainSingletonLock Used to ensure no race conditions arise when managing singleton creation.  Applies to any class which provides a singleton or singletons.  (MDS.h) */

extern NSLock *keychainSingletonLock;
