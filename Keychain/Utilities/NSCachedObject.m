//
//  NSCachedObject.m
//  Keychain
//
//  Created by Wade Tregaskis on Sun Feb 16 2003.
//
//  Copyright (c) 2003 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "NSCachedObject.h"

#import "MultiThreadingInternal.h"
#import "Logging.h"


@implementation NSCachedObject


static NSMutableDictionary *objectDictionary = nil;


// TODO: make this actually thread-safe.  As it stands there's an easy race condition - in between invoking one of the class methods to check for an existing instance and initialising the receiver, one could be added.  There needs to be an atomic check-and-add-if-no-existing-instance method.


// As you can see, the methods below are designed to be thread safe, if keychainCachedObjectLock exists.  In this particular implementation, keychainCachedObjectLock is defined in MultiThreading.h.  If you wish to maintain thread safe code while using this class in your own project, simply copy the keychainCachedObjectLock definition from MultiThreading.h into this file.  Remember if you do this that you will have to initialize this lock prior to your application becoming multi-threaded (e.g. prior to executing any run loops, or when you receive a NSWillBecomeMultiThreadedNotification notification, etc).

+ (id)instanceWithKey:(id)key from:(SEL)selector simpleKey:(BOOL)simpleKey {
    id finalResult = nil;
    
    if (objectDictionary) {
        CFMutableArrayRef objectArray;

        [keychainCachedObjectLock lock];

        objectArray = (CFMutableArrayRef)[objectDictionary objectForKey:[self class]];

        if (objectArray) {
            id current;
            CFIndex count = CFArrayGetCount(objectArray), i;
            
            // Note that the following does duplicate a lot of code, having two near-identical loops side by side.  But the point is to make sure only one branch is done on simpleKey, rather than once for each entry in the object cache, of which there may be many.  Although I suppose even a braindead branch predictor should be able to figure out the pattern... hmmm.

            if (simpleKey) {
                for (i = 0; (nil == finalResult) && (i < count); ++i) {
                    current = (id)CFArrayGetValueAtIndex(objectArray, i);
                    
                    if ([current respondsToSelector:selector]) {
                        if ([current performSelector:selector] == key) {
                            finalResult = current;
                        }
                    }
                }
            } else {
                for (i = 0; (nil == finalResult) && (i < count); ++i) {
                    current = (id)CFArrayGetValueAtIndex(objectArray, i);
                    
                    if ([current respondsToSelector:selector]) {
                        if ([key isEqual:[current performSelector:selector]]) {
                            finalResult = current;
                        }
                    }
                }
            }
        }

        [finalResult retain];
        
        [keychainCachedObjectLock unlock];
    }

    return [finalResult autorelease];
}

+ (id)instanceForSelector:(SEL)selector with:(id)key {
    id finalResult = nil;

    if (objectDictionary) {
        CFMutableArrayRef objectArray;

        [keychainCachedObjectLock lock];

        objectArray = (CFMutableArrayRef)[objectDictionary objectForKey:[self class]];

        if (objectArray) {
            id current;
            CFIndex count = CFArrayGetCount(objectArray), i;
            
            for (i = 0; (nil == finalResult) && (i < count); ++i) {
                current = (id)CFArrayGetValueAtIndex(objectArray, i);
                
                if ([current respondsToSelector:selector]) {
                    if ([current performSelector:selector withObject:key]) {
                        finalResult = current;
                    }
                }
            }
        }
        
        [finalResult retain];
        
        [keychainCachedObjectLock unlock];
    }
    
    return [finalResult autorelease];
}

- (id)init {    
    if (self = [super init]) {
        CFMutableArrayRef objectArray;

        [keychainCachedObjectLock lock];

        if (!objectDictionary) {
            objectDictionary = [[NSMutableDictionary dictionaryWithCapacity:5] retain];
        }

        objectArray = (CFMutableArrayRef)[objectDictionary objectForKey:[self class]];
        
        if (!objectArray) {
            static CFArrayCallBacks callbacks = {0, NULL, NULL, NULL, NULL};
            
            objectArray = CFArrayCreateMutable(kCFAllocatorDefault, 0, &callbacks);
            
            [objectDictionary setObject:(id)objectArray forKey:[self class]];
        }

        CFArrayAppendValue(objectArray, self);
        
        [keychainCachedObjectLock unlock];
    }

    return self;
}

- (void)dealloc {
    CFMutableArrayRef objectArray = (CFMutableArrayRef)[objectDictionary objectForKey:[self class]];
    
    if (objectArray) {
        [keychainCachedObjectLock lock];

        CFIndex meInArray = CFArrayGetFirstIndexOfValue(objectArray, CFRangeMake(0, CFArrayGetCount(objectArray)), self);
        
        if (0 <= meInArray) {
            CFArrayRemoveValueAtIndex(objectArray, meInArray);
        /*} else {
            PDEBUG(@"Didn't find myself in the objectArray... someone's not calling init, naughty naughty.\n");*/
        }
        
        [keychainCachedObjectLock unlock];
    /*} else {
        PDEBUG(@"Didn't find an object array for my class (%@)... someone's not calling init.  Not good.\n", NSStringFromClass([self class]));*/
    }
    
    [super dealloc];
}

@end
