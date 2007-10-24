//
//  MultiThreading.m
//  Keychain
//
//  Created by Wade Tregaskis on Mon May 26 2003.
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "MultiThreading.h"

//#import "Logging.h"


NSLock *keychainCachedObjectLock = nil;
NSLock *keychainCachedModuleLock = nil;
NSLock *keychainDefaultModuleLock = nil;
NSLock *keychainSingletonLock = nil;


@implementation KeychainThreadController

+ (KeychainThreadController*)defaultController {
    static KeychainThreadController *controller;

    if (!controller) {
        controller = [[KeychainThreadController alloc] init];
    }

    return controller;
}

- (KeychainThreadController*)init {
    return (self = [super init]);
}

- (void)taskNowMultiThreaded:(NSNotification*)event {
    //PDEBUG(@"Keychain framework operating in thread-safe mode.\n");
    
    if (!keychainCachedObjectLock) {
        keychainCachedObjectLock = [[NSLock alloc] init];
        keychainCachedModuleLock = [[NSLock alloc] init];
        keychainDefaultModuleLock = [[NSLock alloc] init];
        keychainSingletonLock = [[NSLock alloc] init];
    }
}

- (void)activateThreadSafety {
    //PDEBUG(@"Keychain framework told to be thread safe if necessary.\n");
    
    if ([NSThread isMultiThreaded]) {
        [self taskNowMultiThreaded:nil];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskNowMultiThreaded:) name:NSWillBecomeMultiThreadedNotification object:nil];
    }
}

- (void)deactivateThreadSafety {
    [[NSNotificationCenter defaultCenter] removeObserver:[KeychainThreadController defaultController]];
}

@end
