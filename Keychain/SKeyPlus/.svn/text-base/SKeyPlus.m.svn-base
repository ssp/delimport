//
//  SKeyPlus.m
//  Keychain
//
//  Created by Wade Tregaskis on 26/01/05.
//
//  Copyright (c) 2005 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Keychain/SKeyPlus.h>

#import <Keychain/CSSMDefaults.h>
#import <Keychain/CSSMControl.h>
#import <Keychain/CSSMUtils.h>
#import <Keychain/CSSMTypes.h>
#import <Keychain/CSSMModule.h>

#import <Keychain/UtilitySupport.h>
#import <Keychain/Logging.h>


@implementation SKeyPlusGenerator

+ (SKeyPlusGenerator*)generatorWithPassword:(NSData*)password algorithm:(CSSM_ALGORITHMS)algorithm maximumUses:(unsigned int)maximumUses module:(CSSMModule*)CSPModule {
    return [[[[self class] alloc] initWithPassword:password algorithm:algorithm maximumUses:maximumUses module:CSPModule] autorelease];
}

- (int)generateCurrent { // FLAG - this probably shouldn't be an ObjC method.. just to make sure no one calls it manually.
    if (0 == _usesRemaining) {
        return 0;
    } else {
        CSSM_RETURN err;
        CSSM_CC_HANDLE ccHandle;
        CSSM_DATA bufferA, bufferB, *input = &bufferA, *output = &bufferB, *temp;
        unsigned int iterationsRemaining = _usesRemaining;
        
        clearCSSMData(&_current);
        
        if ((err = CSSM_CSP_CreateDigestContext([_CSPModule handle], _algorithm, &ccHandle)) == CSSM_OK) {
            resetCSSMData(&bufferA);
            
            err = copyDataToData(&_base, &bufferA); // Hope our base ain't too big.
            
            if (0 == err) {
                err = CSSM_OK; // Should be zero anyway, but just in case.
                resetCSSMData(&bufferB);

                while ((CSSM_OK == err) && (0 < iterationsRemaining)) {
                    err = CSSM_DigestData(ccHandle, input, 1, output);
                    
                    if (err == CSSM_OK) {
#ifdef ASSUME_VARIABLE_DIGEST_SIZE
                        // If we're assuming a variable size digest, we might as well save ourselves some time (and possibly memory) by reallocating the buffer each time... although, of course, this may be a case of premature optimisation; thus not enabled by default.
                        clearCSSMData(input);
#endif
                        
                        // Swap the buffers
                        temp = input;
                        input = output;
                        output = temp;
                        
                        --iterationsRemaining;
#ifndef ASSUME_VARIABLE_DIGEST_SIZE // If we're not assuming a variable buffer size, we need to handle the event nonetheless that our buffer is too small... this could happen even with a fixed buffer size if our input data is shorter than the digest size, in which case we'll get this error only once through, which isn't too bad.
                    } else if (CSSMERR_CSP_OUTPUT_LENGTH_ERROR == err) {
                        // This means our output buffer wasn't big enough, in which case we merely clear it completely (thus making the CDSA reallocate it to the required size) and loop through again.
                        clearCSSMData(output);
                        err = CSSM_OK;
#endif
                    } else {
                        PSYSLOGND(LOG_ERR, @"Unable to generate digest because of error %@.\n", CSSMErrorAsString(err));
                        PDEBUG(@"CSSM_DigestData(%"PRIccHandle", %p, 1, %p) returned error %@.\n", ccHandle, input, output, CSSMErrorAsString(err));
                    }
                }
                
                if (CSSM_OK == err) {
                    copyDataToData(input, &_current); // I know that seems backwards, using the "input", but remember that we swap these pointers after every hash function... so at the end of the loop "input" is actually input to the *next* iteration, i.e. the output of the previous one.
                }
            } else {
                PDEBUG(@"Unable to copy data to data, error #%u (%s).\n", err, strerror(err));
                err = CSSMERR_CSSM_MEMORY_ERROR; // Translate from POSIX to CSSM error codes
            }
            
            err = CSSM_DeleteContext(ccHandle);
            
            if (CSSM_OK != err) {
                PSYSLOGND(LOG_WARNING, @"Failed to destroy digest context because of error %@.\n", CSSMErrorAsString(err));
                PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
            }
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to create digest context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_CSP_CreateDigestContext(X, %@, %p [%"PRIccHandle"]) returned error %@.\n", nameOfAlgorithm(_algorithm), &ccHandle, ccHandle, CSSMErrorAsString(err));
        }
        
        return err; // This was originally a return 0... why?
    }
}

- (SKeyPlusGenerator*)initWithPassword:(NSData*)password algorithm:(CSSM_ALGORITHMS)algorithm maximumUses:(unsigned int)maximumUses module:(CSSMModule*)CSPModule {
    if (password && (0 < maximumUses) && (UINT_MAX > maximumUses)) {
        if (self = [super init]) {
            int err;
            
            copyNSDataToData(password, &_base);

            _usesRemaining = _maximumUses = maximumUses;
            _algorithm = algorithm;
            
            resetCSSMData(&_current);
            
            if (nil == CSPModule) {
                _CSPModule = [[CSSMModule defaultCSPModule] retain];
            } else {
                _CSPModule = [CSPModule retain];
            }
            
            err = [self generateCurrent];
            
            if (0 != err) {
                [self release];
                self = nil;
            }
        }
    } else {
        PDEBUG(@"Invalid parameters (password = %p, maximumUses = %u).\n", password, maximumUses);
        
        [self release];
        self = nil;
    }
    
    return self;
}

- (unsigned int)usesRemaining {
    return _usesRemaining;
}

- (NSData*)seed {
    unsigned int temp = _usesRemaining;
    NSData *result;
    CSSM_RETURN err;
    
    _usesRemaining = _maximumUses + 1;
    
    err = [self generateCurrent];
    
    if (CSSM_OK == err) {
        result = NSDataFromData(&_current);
    } else {
        PDEBUG(@"Unable to obtain seed, error %@.\n", CSSMErrorAsString(err));
        result = nil;
    }
    
    _usesRemaining = temp;
    
    err = [self generateCurrent];
    
    if (CSSM_OK != err) {
        PDEBUG(@"Unable to re-generate current password, error %@.\n", CSSMErrorAsString(err));
    }
    
    return result;
}

- (NSData*)currentPassword {
    if (0 == _usesRemaining) {
        return nil;
    } else {
        return NSDataFromData(&_current);
    }
}

- (NSData*)nextPassword {
    if (0 == _usesRemaining) {
        return nil;
    } else {
        --_usesRemaining;

        if (0 == _usesRemaining) {
            clearCSSMData(&_current);
            return nil;
        } else {
            int err = [self generateCurrent];
            
            if (0 != err) {
                PDEBUG(@"Unable to generate current password, error %@.\n", CSSMErrorAsString(err));
                return nil;
            } else {
                return NSDataFromData(&_current);
            }
        }
    }
}

- (CSSM_ALGORITHMS)algorithm {
    return _algorithm;
}

- (void)dealloc {
    if (nil != _CSPModule) {
        [_CSPModule release];
        _CSPModule = nil;
    }
    
    clearCSSMData(&_base);
    clearCSSMData(&_current);
    
    [super dealloc];
}

@end


@implementation SKeyPlusVerifier

+ (SKeyPlusVerifier*)verifierWithSeed:(NSData*)seed algorithm:(CSSM_ALGORITHMS)algorithm maximumUses:(unsigned int)maximumUses module:(CSSMModule*)CSPModule {
    return [[[[self class] alloc] initWithSeed:seed algorithm:algorithm maximumUses:maximumUses module:CSPModule] autorelease];
}

- (SKeyPlusVerifier*)initWithSeed:(NSData*)seed algorithm:(CSSM_ALGORITHMS)algorithm maximumUses:(unsigned int)maximumUses module:(CSSMModule*)CSPModule {
    if (seed && (0 < maximumUses)) {
        if (self = [super init]) {
            copyNSDataToData(seed, &_lastPassword);
            _usesRemaining = maximumUses;
            _algorithm = algorithm;
            
            [self setMaximumNumberOfSkips:0];
            
            if (nil == CSPModule) {
                _CSPModule = [[CSSMModule defaultCSPModule] retain];
            } else {
                _CSPModule = [CSPModule retain];
            }
        }
    } else {
        PDEBUG(@"Invalid parameters (seed:%p algorithm:%@ maximumUses:%u).\n", seed, nameOfAlgorithm(algorithm), maximumUses);
        
        [self release];
        self = nil;
    }
    
    return self;
}

- (void)setMaximumNumberOfSkips:(unsigned int)maximumNumberOfSkips {
    _maximumNumberOfSkips = maximumNumberOfSkips;
}

- (unsigned int)maximumNumberOfSkips {
    return _maximumNumberOfSkips;
}

- (BOOL)verify:(NSData*)password andUpdate:(BOOL)update {
    if (password && (0 < _usesRemaining)) {
        CSSM_RETURN err;
        CSSM_CC_HANDLE ccHandle;
    
#ifndef ASSUME_VARIABLE_DIGEST_SIZE
        if (_lastPassword.Length != [password length]) {
            return NO;
        }
#endif
        
        if ((err = CSSM_CSP_CreateDigestContext([_CSPModule handle], _algorithm, &ccHandle)) == CSSM_OK) {
            unsigned int iterations = 0;
            CSSM_DATA bufferA, bufferB, *input = &bufferA, *output = &bufferB, *temp;
            BOOL haveMatch = NO;
            
            resetCSSMData(&bufferA);
            resetCSSMData(&bufferB);

            copyNSDataToData(password, &bufferA); // Hope our password ain't too big.
            
            do {                
                err = CSSM_DigestData(ccHandle, input, 1, output);
                
                if (CSSM_OK == err) {
#ifdef ASSUME_VARIABLE_DIGEST_SIZE
                    // If we're assuming a variable size digest, we might as well save ourselves some time (and possibly memory) by reallocating the buffer each time... although, of course, this may be a case of premature optimisation; thus not enabled by default.
                    clearCSSMData(input);
                    
                    if ((output->Length == _lastPassword.Length) && (0 == memcmp(output->Data, _lastPassword.Data, _lastPassword.Length))) {
#else
                    if (0 == memcmp(output->Data, _lastPassword.Data, _lastPassword.Length)) {
#endif
                        haveMatch = YES;
                    } else {
                        // Swap the buffers
                        temp = input;
                        input = output;
                        output = temp;
                    }
                    
#ifndef ASSUME_VARIABLE_DIGEST_SIZE // If we're not assuming a variable buffer size, we need to handle the event that our buffer is too small... this could happen even with a fixed buffer size if our input data is shorter than the digest size, in which case we'll get this error only once through, which isn't too bad.
                } else if (CSSMERR_CSP_OUTPUT_LENGTH_ERROR == err) {
                    // This means our output buffer wasn't big enough, in which case we merely clear it completely (thus making the CDSA reallocate it to the required size) and loop through again.
                    clearCSSMData(output);
                    err = CSSM_OK;
#endif
                } else {
                    PSYSLOGND(LOG_ERR, @"Unable to generate digest because of error %@.\n", CSSMErrorAsString(err));
                    PDEBUG(@"CSSM_DigestData(%"PRIccHandle", %p, 1, %p) returned error %@.\n", ccHandle, input, output, CSSMErrorAsString(err));
                }
            } while (!haveMatch && (CSSM_OK == err) && (((_maximumNumberOfSkips < _usesRemaining) ? _maximumNumberOfSkips : _usesRemaining) > iterations++));
            
            if (haveMatch && update) {
                --_usesRemaining;
                copyNSDataToData(password, &_lastPassword);
                
                if (_usesRemaining > iterations) {
                    _usesRemaining -= iterations;
                } else {
                    _usesRemaining = 0;
                }
            }
            
            err = CSSM_DeleteContext(ccHandle);
            
            if (CSSM_OK != err) {
                PSYSLOGND(LOG_WARNING, @"Failed to destroy digest context because of error %@.\n", CSSMErrorAsString(err));
                PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
            }
            
            return haveMatch;
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to create digest context because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_CSP_CreateDigestContext(X, %@, %p [%"PRIccHandle"]) returned error %@.\n", nameOfAlgorithm(_algorithm), &ccHandle, ccHandle, CSSMErrorAsString(err));
        }
    }
    
    return NO;
}

- (unsigned int)usesRemaining {
    return _usesRemaining;
}

- (void)dealloc {
    if (nil != _CSPModule) {
        [_CSPModule release];
        _CSPModule = nil;
    }
    
    clearCSSMData(&_lastPassword);
    
    [super dealloc];
}

@end
