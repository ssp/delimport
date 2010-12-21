//
//  TrustedApplication.m
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

#import "TrustedApplication.h"

#import <Keychain/UtilitySupport.h>
#import <Keychain/Logging.h>
#import <Keychain/SecurityUtils.h>

// For pre-10.5 SDKs:
#ifndef NSINTEGER_DEFINED
typedef int NSInteger;
typedef unsigned int NSUInteger;
#define NSINTEGER_DEFINED
#endif

@implementation TrustedApplication

+ (TrustedApplication*)trustedApplicationWithPath:(NSString*)path {
    return [[[[self class] alloc] initWithPath:path] autorelease];
}

+ (TrustedApplication*)trustedApplicationWithTrustedApplicationRef:(SecTrustedApplicationRef)trustedApp {
    return [[[[self class] alloc] initWithTrustedApplicationRef:trustedApp] autorelease];
}

- (TrustedApplication*)initWithPath:(NSString*)path {
    _error = SecTrustedApplicationCreateFromPath([path UTF8String], &_trustedApplication);

    if (noErr == _error) {
        self = [super init];
        
        return self;
    } else {
        [self release];
        
        return nil;
    }
}

- (TrustedApplication*)initWithTrustedApplicationRef:(SecTrustedApplicationRef)trustedApp {
    TrustedApplication *existingObject;
    
    if (trustedApp) {
        existingObject = [[self class] instanceWithKey:(id)trustedApp from:@selector(trustedApplicationRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            return [existingObject retain];
        } else {
            if (self = [super init]) {
                CFRetain(trustedApp);
                _trustedApplication = trustedApp;
            }

            return self;
        }
    } else {
        [self release];

        return nil;
    }
}

- (TrustedApplication*)init {
    return [self initWithPath:nil];
}

- (BOOL)setData:(NSData*)data {
    _error = SecTrustedApplicationSetData(_trustedApplication, (CFDataRef)data);
	
	if (noErr != _error) {
		PSYSLOGND(LOG_ERR, @"Unable to set data for TrustedApplication %p, error %@.\n", self, OSStatusAsString(_error));
		PDEBUG(@"SecTrustedApplicationSetData(%p, %p) returned error %@.\n", _trustedApplication, data, OSStatusAsString(_error));
	}
	
	return (noErr == _error);
}

- (NSData*)data {
    CFDataRef result;

    _error = SecTrustedApplicationCopyData(_trustedApplication, &result);

    if (noErr == _error) {
        return [(NSData*)result autorelease];
    } else {
		PSYSLOGND(LOG_ERR, @"Unable to retrieve the data of the TrustedApplication %p, error %@.\n", self, OSStatusAsString(_error));
		PDEBUG(@"SecTrustedApplicationCopyData(%p, %p) returned error %@.\n", _trustedApplication, &result, OSStatusAsString(_error));
		
        return nil;
    }
}

- (NSString*)path {
	return NSStringFromNSData([self data]);
}

- (OSStatus)lastError {
    return _error;
}

- (SecTrustedApplicationRef)trustedApplicationRef {
    return _trustedApplication;
}

- (BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[TrustedApplication class]]) {
		return ((self == object) || CFEqual([self trustedApplicationRef], [(TrustedApplication*)object trustedApplicationRef]));
	} else {
		return NO;
	}
}

- (NSUInteger)hash {
	return CFHash([self trustedApplicationRef]);
}

- (void)dealloc {
    if (_trustedApplication) {
        CFRelease(_trustedApplication);
		_trustedApplication = NULL;
    }
    
    [super dealloc];
}

@end
