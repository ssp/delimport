//
//  UtilitySupport.m
//  Keychain
//
//  Created by Wade Tregaskis on Fri Jan 24 2003.
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "UtilitySupport.h"

#import <errno.h>

#import "Logging.h"
#import "CSSMControlInternal.h"


CSSM_DATA* allocCSSMData(void) {
    CSSM_DATA *result = (CSSM_DATA*)malloc(sizeof(CSSM_DATA));
    
    if (result) {
        result->Length = 0;
        result->Data = NULL;
    } else {
        PDEBUG(@"malloc(%d) returned NULL.\n", sizeof(CSSM_DATA));
    }
    
    return result;
}

void resetCSSMData(CSSM_DATA *data) {
    if (NULL != data) {
        data->Data = NULL;
        data->Length = 0;
    } else {
        PDEBUG(@"Invalid parameter - 'data' is NULL.\n");   
    }
}

void clearCSSMData(CSSM_DATA *data) {
    if (NULL != data) {        
        if (NULL != data->Data) {
            if (keychainFrameworkShouldZeroBuffers()) {
                memset(data->Data, 0, data->Length);
            }
            
            free(data->Data);
        }
        
        resetCSSMData(data);
    } else {
        PDEBUG(@"Missing 'data' parameter.\n");
    }
}

void freeCSSMData(CSSM_DATA *data) {
    if (NULL != data) {
        clearCSSMData(data);
        
        free(data);
    } else {
        PDEBUG(@"Missing 'data' parameter.\n");
    }
}

int copyDataToData(const CSSM_DATA *source, CSSM_DATA *destination) {
    if ((NULL != source) && (NULL != destination)) {
        clearCSSMData(destination);
        
        destination->Length = source->Length;
        
        if (0 < source->Length) {
            destination->Data = (uint8_t*)malloc(source->Length);
            
            if (destination->Data) {
                memcpy(destination->Data, source->Data, source->Length);
                
                return 0;
            } else {
                PDEBUG(@"Unable to allocate memory for destination data (%d bytes).\n", source->Length);

                destination->Length = 0;
                
                return ENOMEM;
            }
        } else {
            destination->Data = NULL;
            
            return 0;
        }
    } else {
        PDEBUG(@"Invalid parameters (source = %p, destination = %p).\n", source, destination);
        return EINVAL;
    }
}

int copyNSStringToData(NSString *source, CSSM_DATA *destination) {
    if ((nil != source) && (NULL != destination)) {
        const char *utf8String = [source UTF8String];
        
        clearCSSMData(destination);
        
        destination->Length = strlen(utf8String);
        
        if (0 < destination->Length) {
            destination->Data = (uint8_t*)malloc(destination->Length);
            
            if (destination->Data) {
                memcpy(destination->Data, utf8String, destination->Length);
            } else {
                PDEBUG(@"Unable to allocate memory for destination data (%d bytes).\n", destination->Length);
                
                destination->Length = 0;
                
                return ENOMEM;
            }
        }
        
        return 0;
    } else {
        PDEBUG(@"Invalid parameters (source = %p, destination = %p).\n", source, destination);

        return EINVAL;
    }
}

int copyNSStringToString(NSString *source, CSSM_STRING *destination) {
    if ((nil != source) && (NULL != destination)) {
        unsigned int stringLength = [source lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        
        if (stringLength < sizeof(CSSM_STRING)) {
            const char *original = [source cStringUsingEncoding:NSUTF8StringEncoding];
            
            memcpy(destination, original, stringLength + 1);
            
            if (stringLength < (sizeof(CSSM_STRING) - 1)) {
                memset(destination + stringLength + 1, 0, sizeof(CSSM_STRING) - stringLength - 1);
            }
            
            return 0;
        } else {
            PDEBUG(@"String \"%@\" is too big to fit into a CSSM_STRING (maximum length %u bytes, excluding NULL terminator).\n", source, sizeof(CSSM_STRING) - 1);
            
            return ERANGE;
        }
    } else {
        PDEBUG(@"Invalid parameters (source = %p, destination = %p).\n", source, destination);
        
        return EINVAL;
    }
}

CSSM_DATA* dataFromNSString(NSString *string) {
    CSSM_DATA *result = NULL;
    
    if (string) {
        int err;
        
        result = allocCSSMData();
        
        err = copyNSStringToData(string, result);
        
        if (0 != err) {
            free(result);
            result = NULL;
        }
        
        /*result->Length = [string cStringLength];
        result->Data = (uint8*)malloc(result->Length + 1);
        [string getCString:(char*)(result->Data)];*/
    }
    
    return result;
}

void copyNSDataToData(NSData *source, CSSM_DATA *destination) {
    clearCSSMData(destination);
    
    destination->Length = [source length];
    destination->Data = (uint8*)malloc(destination->Length);
    
    [source getBytes:(char*)(destination->Data)];
}

// Be very careful using the following function - lots of stuff goes on inside the Keychain & Security frameworks, and the CDSA itself, even for simple requests.  If you get malloc errors or BAD_ACCESS faults, you might want to check over any code which uses this method

// P.S. Yes I know the function name contradicts itself.  I'm lazy and it's consistent.

void copyNSDataToDataNoCopy(NSData *source, CSSM_DATA *destination) {
    clearCSSMData(destination);
    
    destination->Length = [source length];
    destination->Data = (uint8*)[source bytes];
}

CSSM_DATA* dataFromNSData(NSData *data) {
    CSSM_DATA *result = NULL;
    
    if (data) {
        result = allocCSSMData();
        
        result->Length = [data length];
        result->Data = (uint8*)malloc(result->Length);
        [data getBytes:(char*)(result->Data)];
    }
    
    return result;
}

NSString* NSStringFromData(const CSSM_DATA *data) {
    if (data) {
        return [NSString stringWithCString:(const char*)(data->Data) length:data->Length];
    } else {
        return nil;
    }
}

NSString* NSStringFromNSData(NSData *data) {
    if (data) {
        return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    } else {
        return nil;
    }
}

NSData* NSDataFromNSString(NSString *string) {
    if (string) {
        return [string dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

NSData* NSDataFromData(const CSSM_DATA *data) {
    if (data) {
        return [NSData dataWithBytes:data->Data length:data->Length];
    } else {
        return nil;
    }
}

// Be very careful using the following function - lots of stuff goes on inside the Keychain & Security frameworks, and the CDSA itself, even for simple requests.  If you get malloc errors or BAD_ACCESS faults, you might want to check over any code which uses this method

NSData* NSDataFromDataNoCopy(const CSSM_DATA *data, BOOL freeWhenDone) {
    if (data) {
        return [NSData dataWithBytesNoCopy:data->Data length:data->Length freeWhenDone:freeWhenDone];
    } else {
        return nil;
    }
}

BOOL OIDsAreEqual(const CSSM_OID *a, const CSSM_OID *b) {
    if ((NULL != a) && (NULL != b)) {
        if (a == b) {
            return YES;
        } else if (a->Length != b->Length) {
            return NO;
        } else {
            return (memcmp(a->Data, b->Data, a->Length) == 0);
        }
    } else {
        PDEBUG(@"Invalid parameters (a = %p, b = %p).\n", a, b);
        return NO;
    }
}

NSData* NSDataFromHumanNSString(NSString *string) {
    NSScanner *scanner;
    unsigned intValue;
    NSMutableData *theData;

    scanner = [[NSScanner scannerWithString:string] retain];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\t\r\n <>"]];

    theData = [[NSMutableData alloc] initWithCapacity:25];

    while ([scanner scanHexInt:(&intValue)]) {
        if (intValue >> 8) {
            if (intValue >> 16) {
                if (intValue >> 24) {
                    [theData appendBytes:(void*)(&intValue) length:sizeof(unsigned)];
                } else {
                    [theData appendBytes:(void*)((char*)(&intValue) + 1) length:(sizeof(unsigned) - 1)];
                }
            } else {
                [theData appendBytes:(void*)((char*)(&intValue) + 2) length:(sizeof(unsigned) - 2)];
            }
        } else {
            [theData appendBytes:(void*)((char*)(&intValue) + 3) length:(sizeof(unsigned) - 3)];
        }
    }

    if (![scanner isAtEnd]) {
        [theData release];
        theData = nil;
    } else {
        [theData autorelease];
    }

    [scanner release];

    return theData;
}
