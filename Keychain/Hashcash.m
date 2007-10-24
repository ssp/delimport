//
//  Hashcash.m
//  Keychain
//
//  Created by Wade Tregaskis on 12/11/04.
//
//  Copyright (c) 2005, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "Hashcash.h"

#import "CSSMUtils.h"
#import "CSSMControl.h"
#import "CSSMTypes.h"
#import "CSSMModule.h"

#import "KeychainUtils.h"
#import "NSDataAdditions.h"

#import "Logging.h"


#ifdef USE_BIT_COUNTING
unsigned int numberOfLeadingBits(const char *string, unsigned int length, BOOL bitValue) {
    unsigned int count = 0;
    unsigned int i, j;
    char temp;
    
    for (i = 0; i < length; ++i) {
        temp = string[i];
        
        for (j = 0; j < 8; ++j) {
            if (((temp & 0x80) != 0) == bitValue) {
                ++count;
            } else {
                return count;
            }
            
            temp <<= 1;
        }
    }
    
    return count;
}
#endif


NSString *kDefaultHashcashStringFormat = @"%y%m%d%H%M%S";
const char *kValidHashcashStampCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789,./'\"[]{}\\|=+-_)(*&^%$#@!`~;<>?";


@implementation Hashcash

+ (NSCharacterSet*)stampFieldCharacterSetWithSpaces {
    static NSCharacterSet *theSet = nil;
    
    if (!theSet) {
        theSet = [[NSCharacterSet characterSetWithCharactersInString:[[NSString stringWithUTF8String:kValidHashcashStampCharacters] stringByAppendingString:@"\t "]] retain];
    }
    
    return theSet;
}

+ (NSCharacterSet*)stampFieldCharacterSet {
    static NSCharacterSet *theSet = nil;
    
    if (!theSet) {
        theSet = [[NSCharacterSet characterSetWithCharactersInString:[NSString stringWithUTF8String:kValidHashcashStampCharacters]] retain];
    }
    
    return theSet;
}

+ (NSCharacterSet*)stampDateCharacterSet {
    static NSCharacterSet *theSet = nil;
    
    if (!theSet) {
        theSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] retain];
    }
    
    return theSet;
}

+ (Hashcash*)hashcashFromStamp:(NSString*)stamp {
    return [[[[self class] alloc] initWithStamp:stamp] autorelease];
}

- (Hashcash*)initWithStamp:(NSString*)stamp {
    if (self = [super init]) {
        BOOL allGood = YES;
        
        if (stamp) {
            NSScanner *scanner = [NSScanner scannerWithString:stamp];
            int tempInt;
            
            [scanner setCaseSensitive:YES];
            [scanner setCharactersToBeSkipped:nil]; // [NSCharacterSet characterSetWithRange:NSMakeRange(0, 0)]];
            
            // 0:time:resource:trial // 0
            // 1:bits:date:resource:ext:salt:suffix // 1
            
            if ([scanner scanInt:&tempInt] && (tempInt >= 0) && (tempInt <= 1)) {
                version = (unsigned int)tempInt;
                
                if ([scanner scanString:@":" intoString:nil]) {
                    // time:resource:trial // 0
                    // bits:date:resource:ext:salt:suffix // 1
                    
                    if (1 == version) {
                        // bits:date:resource:ext:salt:suffix // 1

                        if ([scanner scanInt:&tempInt] && (tempInt >= 0) && (tempInt <= 160)) {
                            bits = (unsigned int)tempInt;
                        } else {
                            allGood = NO;
                            PDEBUG(@"Unable to determine work size (number of leading 0 bits), or number is invalid (e.g. > 160).\n");
                        }

                        if (allGood && ![scanner scanString:@":" intoString:nil]) {
                            allGood = NO;
                            PDEBUG(@"Did not find ':' after stamp work size (number of bits).\n");
                        }
                    }
                    
                    if (allGood) {
                        // time:resource:trial // 0
                        // date:resource:ext:salt:suffix // 1
                        
                        NSString *dateString;

                        if ([scanner scanUpToString:@":" intoString:&dateString] && dateString) {                            
                            if ([dateString rangeOfCharacterFromSet:[[[self class] stampDateCharacterSet] invertedSet]].location == NSNotFound) {
                                unsigned int theLength = strlen([dateString UTF8String]);
                                
                                if ((theLength > 0) && (theLength <= strlen([kDefaultHashcashStringFormat UTF8String])) && ((theLength % 2) == 0)) {
                                    date = [[NSCalendarDate alloc] initWithString:dateString calendarFormat:[kDefaultHashcashStringFormat substringToIndex:theLength]];
                                    
                                    if (date) {
                                        if ([scanner scanString:@":" intoString:nil]) {
                                            // resource:trial // 0
                                            // resource:ext:salt:suffix // 1
                                            
                                            if ([scanner scanUpToString:@":" intoString:&resource] && resource) {
                                                [resource retain];

                                                if ([resource rangeOfCharacterFromSet:[[[self class] stampFieldCharacterSetWithSpaces] invertedSet]].location == NSNotFound) {
                                                    if ([scanner scanString:@":" intoString:nil]) {
                                                        // trial // 0
                                                        // ext:salt:suffix // 1
                                                        
                                                        if (1 == version) {
                                                            // ext:salt:suffix // 1
                                                            
                                                            [scanner scanUpToString:@":" intoString:&extensions];

                                                            if (extensions && ([extensions rangeOfCharacterFromSet:[[[self class] stampFieldCharacterSetWithSpaces] invertedSet]].location != NSNotFound)) {
                                                                extensions = nil;
                                                                allGood = NO;
                                                                PDEBUG(@"Found invalid character(s) in the stamp extensions field.\n");
                                                            } else {
                                                                if (extensions) {
                                                                    [extensions retain];
                                                                } else {
                                                                    extensions = [[NSString alloc] init];
                                                                }
                                                                
                                                                if ([scanner scanString:@":" intoString:nil]) {
                                                                    // salt:suffix // 1
                                                                    
                                                                    if ([scanner scanUpToString:@":" intoString:&salt] && salt) {
                                                                        [salt retain];
                                                                        
                                                                        if ([salt rangeOfCharacterFromSet:[[[self class] stampFieldCharacterSet] invertedSet]].location != NSNotFound) {
                                                                            allGood = NO;
                                                                            PDEBUG(@"Found invalid characters in salt stamp field.\n");
                                                                        } else {
                                                                            if (![scanner scanString:@":" intoString:nil]) {
                                                                                allGood = NO;
                                                                                PDEBUG(@"Did not find ':' after stamp salt.\n");
                                                                            }
                                                                        }
                                                                    } else {
                                                                        allGood = NO;
                                                                        PDEBUG(@"Could not read stamp salt.\n");
                                                                    }
                                                                } else {
                                                                    allGood = NO;
                                                                    PDEBUG(@"Did not find ':' after stamp extensions.\n");
                                                                }
                                                            }
                                                        }
                                                        
                                                        if (allGood) {
                                                            // trial // 0
                                                            // suffix // 1
                                                            
                                                            if ([scanner scanUpToString:@":" intoString:&suffix] && suffix) {
                                                                [suffix retain];
                                                                
                                                                if ([suffix rangeOfCharacterFromSet:[[[self class] stampFieldCharacterSet] invertedSet]].location != NSNotFound) {
                                                                    allGood = NO;
                                                                    PDEBUG(@"Suffix contains invalid character(s).\n");
                                                                }
                                                            } else {
                                                                suffix = nil;
                                                                allGood = NO;
                                                                PDEBUG(@"Missing suffix.\n");
                                                            }
                                                        }
                                                    } else {
                                                        allGood = NO;
                                                        PDEBUG(@"Did not find ':' after stamp resource.\n");
                                                    }
                                                } else {
                                                    allGood = NO;
                                                    PDEBUG(@"Resource field of stamp contains invalid characters.\n");
                                                }
                                            } else {
                                                resource = nil;
                                                allGood = NO;
                                                PDEBUG(@"Apparently empty resource string.\n");
                                            }
                                        } else {
                                            allGood = NO;
                                            PDEBUG(@"Did not find ':' after stamp date.\n");
                                        }
                                    } else {
                                        allGood = NO;
                                        PDEBUG(@"Invalid time in stamp (NSCalendarDate problem; most likely an invalid value for one or more fields - e.g. 13 for the month).\n");
                                    }
                                } else {
                                    allGood = NO;
                                    PDEBUG(@"Invalid time in stamp (bad length).\n");
                                }
                            } else {
                                allGood = NO;
                                PDEBUG(@"Invalid time in stamp (bad contents).\n");
                            }
                        } else {
                            allGood = NO;
                            PDEBUG(@"Could not parse time correctly (NSScanner error).\n");
                        }
                    }
                } else {
                    allGood = NO;
                    PDEBUG(@"Did not find ':' after stamp version.\n");
                }
            } else {
                allGood = NO;
                PDEBUG(@"Unable to determine version, or version is unsupported.\n");
            }
        } else {
            allGood = NO;
        }
        
        if (!allGood) {
            [self release];
            self = nil;
        }
    }
    
    return self;
}

- (Hashcash*)init {
    if (self = [super init]) {
        char *sample;
        char seedScratch[kHashcashDefaultSeedLength];
        NSCharacterSet *theSet = [[self class] stampFieldCharacterSet];
        unsigned int i = 0, j;
        
        bits = 20;
        version = 1;
        
        [self setDate:[NSCalendarDate calendarDate] usingDefaultFormat:YES];
                
        while (i < kHashcashDefaultSeedLength) {
            sample = generateGenericRandomData(kHashcashDefaultSeedLength);
            
            for (j = 0; (i < kHashcashDefaultSeedLength) && (j < kHashcashDefaultSeedLength); ++j) {
                if ([theSet characterIsMember:(unichar)sample[j]]) {
                    seedScratch[i] = sample[j];
                    ++i;
                }
            }
        }
        
        salt = [[NSString alloc] initWithCString:seedScratch length:kHashcashDefaultSeedLength];
    }
    
    return self;
}

- (unsigned int)version {
    return version;
}

- (int)setVersion:(unsigned int)newVersion {
    if ((0 == version) || (1 == version)) {
        version = newVersion;

        return 0;
    } else {
        return EINVAL;
    }
}

- (unsigned int)bits {
    return bits;
}

- (int)setBits:(unsigned int)newBits {
    if (newBits <= 160) {
        bits = newBits;
        
        return 0;
    } else {
        return EINVAL;
    }
}

- (NSCalendarDate*)date {
    return date; 
}

- (int)setDate:(NSDate*)newDate usingDefaultFormat:(BOOL)useDefaultFormat {
    int err = 0;
    
    if (date != newDate) {
        id old = date;
        
        if (newDate) {
            if ([newDate isKindOfClass:[NSCalendarDate class]]) {
                date = [newDate copy];
                
                if (useDefaultFormat) {
                    [date setCalendarFormat:kDefaultHashcashStringFormat];
                } else {
                    if ([[date timeZone] secondsFromGMT] != 0) {
                        err = EINVAL;
                    } else {
                        NSString *customFormat = [date calendarFormat];
                        
                        if (0 != strncmp([kDefaultHashcashStringFormat UTF8String], [customFormat UTF8String], strlen([customFormat UTF8String]))) {
                            err = EINVAL;
                        }
                    }
                    
                    if (err != 0) {
                        id old2 = date;
                        
                        date = nil;
                        [old2 release];
                    }
                }
            } else {
                date = [[newDate dateWithCalendarFormat:kDefaultHashcashStringFormat timeZone:nil] retain];
            }
            
            [date setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        } else {
            date = nil;
        }
        
        [old release];
    }
    
    return err;
}

- (NSString*)resource {
    return resource; 
}

- (int)setResource:(NSString*)newResource {
    if (resource != newResource) {
        id old = resource;
        
        resource = [newResource copy];
        [old release];
    }
    
    return 0;
}

- (NSString*)extensions {
    return extensions; 
}

- (int)setExtensions:(NSString*)newExtensions {
    if (1 == version) {
        if (extensions != newExtensions) {
            id old = extensions;
            
            extensions = [newExtensions copy];
            [old release];
        }
        
        return 0;
    } else {
        return EBADF;
    }
}

- (NSString*)salt {
    return salt; 
}

- (int)setSalt:(NSString*)newSalt {
    if (1 == version) {
        if (salt != newSalt) {
            id old = salt;
            
            salt = [newSalt copy];
            [old release];
        }
        
        return 0;
    } else {
        return EBADF;
    }
}

- (NSString*)suffix {
    return suffix; 
}

- (int)setSuffix:(NSString*)newSuffix {
    if (suffix != newSuffix) {
        id old = suffix;
        
        suffix = [newSuffix copy];
        [old release];
    }
    
    return 0;
}

BOOL findSuffixRecursively(CSSM_DATA buffers[3], unsigned int currentDepth, unsigned int bits, CSSM_CC_HANDLE handle) {
    CSSM_RETURN err;
    unsigned int i;
    
    assert(0 < buffers[1].Length);
    
    if (currentDepth == (buffers[1].Length - 1)) {
        unsigned int bitsRemaining;
        unsigned int index;
        BOOL didMatch = YES;
        
        for (i = strlen(kValidHashcashStampCharacters) - 1; i >= 0; --i) {
            buffers[1].Data[currentDepth] = kValidHashcashStampCharacters[i];

            if ((err = CSSM_DigestData(handle, buffers, 2, &(buffers[2]))) == CSSM_OK) {
                bitsRemaining = bits;
                index = 0;
                
#ifndef USE_BIT_COUNTING
                /* This optimisation *should* be [in theory] much faster than counting the number of leading zero's iteratively, since in principle it takes only a a few instructions to setup and compare the first 32 bits (times however many times necessary), then only a few more to generate a mask and compare the remaining N (0 <= N <= 32) bits.  Hopefully the overhead of the extra compares and setup costs are well outweighed by the performance gain (remembering that we no longer need to call a relatively expensive function, either). */
                
                while ((32 < bitsRemaining) && didMatch && ((index + 4) <= buffers[2].Length)) {
                    if (0 != *((uint32_t*)(buffers[2].Data + index))) {
                        didMatch = NO;
                    } else {
                        index += 4;
                        bitsRemaining -= 32;
                    }
                }
                
                if (didMatch) {
                    if ((index + 4) < buffers[2].Length) {
                        if (0 == ((uint32_t)(0xffffffff << (32 - bitsRemaining)) & *((uint32_t*)(buffers[2].Data + index)))) {
                            return YES;
                        }
                    } else {
                        while (didMatch && (index < buffers[2].Length)) {
                            if (8 < bitsRemaining) {
                                if (0 != buffers[2].Data[index]) {
                                    didMatch = NO;
                                } else {
                                    bitsRemaining -= 8;
                                    ++index;
                                }
                            } else {
                                if (0 == ((uint8_t)(0xff << (8 - bitsRemaining)) & buffers[2].Data[index])) {
                                    return YES;
                                }
                            }
                        }
                        
                        if (didMatch) {
                            return YES;
                        }
                    }
                }
#else
                if (bits <= numberOfLeadingBits(buffers[2].Data, buffers[2].Length, NO)) {
                    return YES;
                }
#endif
            } else {
                PCONSOLE(@"Unable to generate digest because of error #%u - %@.\n", err, CSSMErrorAsString(err));
                PDEBUG(@"CSSM_DigestData(%"PRIccHandle", %p, 2, %p) returned error #%u (%@).\n", handle, buffers, &(buffers[2]), err, CSSMErrorAsString(err));
            }
        }
        
        return NO;
    } else {
        for (i = strlen(kValidHashcashStampCharacters) - 1; i >= 0; --i) {
            buffers[1].Data[currentDepth] = kValidHashcashStampCharacters[i];
            
            if (findSuffixRecursively(buffers, currentDepth + 1, bits, handle)) {
                return YES;
            }
        }
        
        return NO;
    }
}

- (int)findSuffix {
    int err = 0;
    
    if (![self valid]) {
        switch (version) {
            case 0:
                if (!date || !resource || (strlen([resource UTF8String]) == 0)) {
                    err = ENXIO;
                }
                
                break;
            case 1:
                if (!date || !resource || (strlen([resource UTF8String]) == 0)) {
                    err = ENXIO;
                }
                
                break;
            default:
                err = EBADF;
        }
        
        if (0 == err) {
            NSMutableString *scratch = nil;
            CSSM_CC_HANDLE ccHandle;
            CSSM_DATA buffers[3];
            BOOL found = NO;
            
            if (suffix) {
                id old = suffix;
                
                suffix = nil;
                [old release];
            }
            
            switch (version) {
                case 0:
                    scratch = [NSMutableString stringWithFormat:@"0:%s:%s:", [[date description] UTF8String], [resource UTF8String]]; break;
                case 1:
                    scratch = [NSMutableString stringWithFormat:@"1:%u:%s:%s:%s:%s:", bits, [[date description] UTF8String], [resource UTF8String], (extensions ? [extensions UTF8String] : ""), (salt ? [salt UTF8String] : "")]; break;
            }
            
            if ((err = CSSM_CSP_CreateDigestContext([[CSSMModule defaultCSPModule] handle], CSSM_ALGID_SHA1, &ccHandle)) == CSSM_OK) {
                char hashBuf[20];
                
                buffers[0].Data = (uint8*)[scratch UTF8String];
                buffers[0].Length = strlen((char*)(buffers[0].Data));
                
                buffers[1].Length = 0;
                buffers[1].Data = NULL;
                
                buffers[2].Length = 20;
                buffers[2].Data = (uint8*)&hashBuf;
                
                while (!found && (buffers[1].Length <= kHashcashSuffixLengthLimit)) {
                    ++(buffers[1].Length);
                    
                    free(buffers[1].Data);
                    buffers[1].Data = (uint8_t*)malloc(buffers[1].Length);
                    
                    found = findSuffixRecursively(buffers, 0, bits, ccHandle);
                }

                if (found) {
                    suffix = [[NSString stringWithCString:(char*)(buffers[1].Data) length:buffers[1].Length] retain];
                } else {
                    err = EDEADLK;
                    PDEBUG(@"Could not find suitable suffix.\n");
                }
            } else {
                PCONSOLE(@"Unable to create digest context, error #%u - %@.\n", err, CSSMErrorAsString(err));
                PDEBUG(@"CSSM_CSP_CreateDigestContext(X, CSSM_ALGID_SHA1, %p [%"PRIccHandle"]) returned error #%u (%@).\n", &ccHandle, ccHandle, err, CSSMErrorAsString(err));
            }
        }
    }
    
    return err;
}

- (NSString*)stamp {
    NSString *result = nil;
    
    if (date && resource && suffix) {                
        switch (version) {
            case 0:
                result = [NSString stringWithFormat:@"0:%s:%s:%s", [[date description] UTF8String], [resource UTF8String], [suffix UTF8String]];
                
                break;
            case 1:
                result = [NSString stringWithFormat:@"1:%u:%s:%s:%s:%s:%s", bits, [[date description] UTF8String], [resource UTF8String], (extensions ? [extensions UTF8String] : ""), (salt ? [salt UTF8String] : ""), [suffix UTF8String]];
                
                break;
        }
    }
    
    return result;
}

- (BOOL)valid {
    NSString *scratch = [self stamp];
    BOOL result;
    
    if (scratch) {
        NSData *digest = [[scratch dataUsingEncoding:NSUTF8StringEncoding] digestUsingAlgorithm:CSSM_ALGID_SHA1]; // This version is correct, according to the reference - the trailing NULL character is expected
        
        //NSData *digest = [[[scratch substringToIndex:([scratch length] - 1)] dataUsingEncoding:NSUTF8StringEncoding] digestUsingAlgorithm:CSSM_ALGID_SHA1]; // This version excludes the trailing NULL character... while it is arguably logically correct, it does not comply with the reference implementation
        
#ifndef USE_BIT_COUNTING
        if (digest) {
            const uint8_t *data = [digest bytes];
            int length = [digest length];
            int bitsRemaining = bits;
            int index = 0;
            
            result = YES; /* Innocent till proven otherwise. */
            
            while ((8 < bitsRemaining) && (index < length)) {
                if (0 != data[index]) {
                    result = NO;
                    break;
                } else {
                    bitsRemaining -= 8;
                    ++index;
                }
            }
            
            if (result) {
                if (index < length) {
                    if (0 != ((uint8_t)(0xff << (8 - bitsRemaining)) & data[index])) {
                        result = NO;
                    }
                }
            }
        } else {
            result = NO;
        }
#else
        result = (digest && (numberOfLeadingBits([digest bytes], [digest length], NO) >= bits));
#endif
    } else {
        result = NO;
    }
    
    return result;
}

- (void)dealloc {
    if (date) {
        [date release];
    }
    
    if (resource) {
        [resource release];
    }
    
    if (extensions) {
        [extensions release];
    }
    
    if (salt) {
        [salt release];
    }
    
    if (suffix) {
        [suffix release];
    }
    
    [super dealloc];
}

@end
