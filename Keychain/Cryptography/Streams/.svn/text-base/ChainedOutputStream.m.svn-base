//
//  ChainedOutputStream.m
//  Keychain
//
//  Created by Wade Tregaskis on Wed Jun 29 2005.
//
//  Copyright (c) 2005 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "ChainedOutputStream.h"

#import "Utilities/Logging.h"


@implementation ChainedOutputStream

/* Inherited from NSStream. */

- (void)open {
    if (stream) {
        [stream open];
    } else {
        [super open];
    }
}

- (void)close {
    if (stream) {
        [stream close];
    } else {
        [super close];
    }
}

- (id)delegate {
    if (outputIsExplicit || !stream) {
        return [super delegate];
    } else {
        return [stream delegate];
    }
}

- (void)setDelegate:(id)newDelegate {
    if (outputIsExplicit || !stream) {
        [super setDelegate:newDelegate];
    } else {
        [stream setDelegate:newDelegate];
    }
}

- (void)scheduleInRunLoop:(NSRunLoop*)aRunLoop forMode:(NSString*)mode {
    if (outputIsExplicit || !stream) {
        [super scheduleInRunLoop:aRunLoop forMode:mode];
    } else {
        [stream scheduleInRunLoop:aRunLoop forMode:mode];
    }
}

- (void)removeFromRunLoop:(NSRunLoop*)aRunLoop forMode:(NSString*)mode {
    if (outputIsExplicit || !stream) {
        [super removeFromRunLoop:aRunLoop forMode:mode];
    } else {
        [stream removeFromRunLoop:aRunLoop forMode:mode];
    }
}

- (id)propertyForKey:(NSString*)key {
    if (outputIsExplicit || !stream) {
        return [super propertyForKey:key];
    } else {
        return [stream propertyForKey:key];
    }
}

- (BOOL)setProperty:(id)property forKey:(NSString*)key {
    if (outputIsExplicit || !stream) {
        return [super setProperty:property forKey:key];
    } else {
        return [stream setProperty:property forKey:key];
    }
}

- (NSError*)streamError {
    if (0 != err) {
        return [NSError errorWithDomain:nil code:err userInfo:nil];
    } else {
        if (outputIsExplicit || !stream) {
            return [super streamError];
        } else {
            return [stream streamError];
        }
    }
}

- (NSStreamStatus)streamStatus {
    if (0 != err) {
        return NSStreamStatusError;
    } else {
        if (outputIsExplicit || !stream) {
            return [super streamStatus];
        } else {
            return [stream streamStatus];
        }
    }
}

/* Inherited from NSOutputStream. */

+ (id)outputStreamToMemory {
    return [[[[self class] alloc] initToMemory] autorelease];
}

+ (id)outputStreamToBuffer:(uint8_t*)buffer capacity:(unsigned int)capacity {
    return [[[[self class] alloc] initToBuffer:buffer capacity:capacity] autorelease];
}

+ (id)outputStreamToFileAtPath:(NSString*)path append:(BOOL)shouldAppend {
    return [[[[self class] alloc] initToFileAtPath:path append:shouldAppend] autorelease];
}

+ (id)outputStreamToOutputStream:(NSOutputStream*)otherStream {
    return [[[[self class] alloc] initToOutputStream:otherStream] autorelease];
}

- (id)initToMemory {
    if (self = [super init]) {
        stream = [[NSOutputStream outputStreamToMemory] retain];
        
        if (stream) {
            outputIsExplicit = NO;
            err = 0;
        } else {
            PDEBUG(@"Unable to create new output stream to memory.\n");
            [self release];
            self = nil;
        }
    }
    
    return self;
}

- (id)initToBuffer:(uint8_t*)buffer capacity:(NSUInteger)capacity {
    if (self = [super init]) {
        stream = [[NSOutputStream outputStreamToBuffer:buffer capacity:capacity] retain];
        
        if (stream) {
            outputIsExplicit = NO;
            err = 0;
        } else {
            PDEBUG(@"Unable to create new output stream to buffer.\n");
            [self release];
            self = nil;
        }
    }
    
    return self;
}

- (id)initToFileAtPath:(NSString*)path append:(BOOL)shouldAppend {
    if (self = [super init]) {
        stream = [[NSOutputStream outputStreamToFileAtPath:path append:shouldAppend] retain];

        if (stream) {
            outputIsExplicit = NO;
            err = 0;
        } else {
            PDEBUG(@"Unable to create new output stream to file.\n");
            [self release];
            self = nil;
        }
    }
    
    return self;
}

- (id)initToOutputStream:(NSOutputStream*)otherStream {
    if (self = [super init]) {
        if (otherStream) {
            stream = [otherStream retain];
            
            if (!stream) {
                PDEBUG(@"Unable to retain existing stream (retain returned nil).\n");
                [self release];
                return nil;
            }
        } else {
            stream = nil;
        }
        
        outputIsExplicit = YES;
        err = 0;
    }
            
    return self;
}

- (NSInteger)write:(const uint8_t*)buffer maxLength:(NSUInteger)len {
    NSInteger result;
    
    if (stream) {
        result = [stream write:buffer maxLength:len];
    } else {
        result = len;
    }
    
    return result;
}

- (BOOL)hasSpaceAvailable {
    if (stream) {
        return [stream hasSpaceAvailable];
    } else {
        return YES;
    }
}

/* Our additions. */

- (id)init {
    [self release];
    return nil;
}

- (void)dealloc {
    if (stream) {
        [stream release];
    }
    
    [super dealloc];
}

- (NSOutputStream*)destination {
    return stream;
}

@end
