//
//  MDS.m
//  Keychain
//
//  Created by Wade Tregaskis on 3/8/2005.
//
//  Copyright (c) 2006, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "MDS.h"
#import "CSSMModule.h"
#import "MultiThreadingInternal.h"
#import "UtilitySupport.h"
#import "Logging.h"
#import "CSSMControl.h"
#import "CSSMUtils.h"
#import "CSSMTypes.h"


CSSM_RETURN objectifyCSSMAttribute(const CSSM_DB_ATTRIBUTE_DATA *attribute, id *result) {
    if ((nil != attribute) && (nil != result)) {
        NSMutableArray *attributeValues = [NSMutableArray arrayWithCapacity:attribute->NumberOfValues];
        CSSM_RETURN err = CSSM_OK;
        unsigned int j;
        
        for (j = 0; (CSSM_OK == err) && (j < attribute->NumberOfValues); ++j) {
            switch (attribute->Info.AttributeFormat) {
                case CSSM_DB_ATTRIBUTE_FORMAT_STRING:
                    [attributeValues addObject:[NSString stringWithCString:(char*)(attribute->Value[j].Data) length:attribute->Value[j].Length]];
                    break;
                case CSSM_DB_ATTRIBUTE_FORMAT_SINT32:
                    if (4 == attribute->Value[j].Length) {
                        if (4 == sizeof(int)) {
                            [attributeValues addObject:[NSNumber numberWithInt:*((int*)(attribute->Value[j].Data))]];
                        } else if (4 == sizeof(short)) {
                            [attributeValues addObject:[NSNumber numberWithShort:*((short*)(attribute->Value[j].Data))]];
                        } else {
                            PDEBUG(@"Unable to find a 4-byte signed integer type on the target platform.\n");
                            err = CSSMERR_DL_UNSUPPORTED_FIELD_FORMAT;
                        }
                    } else {
                        PDEBUG(@"Signed integer attribute has length %u, not 4 as expected.\n", attribute->Value[j].Length);
                        err = CSSMERR_DL_INVALID_VALUE;
                    }
                    
                    break;
                case CSSM_DB_ATTRIBUTE_FORMAT_UINT32:
                    if (4 == attribute->Value[j].Length) {
                        if (4 == sizeof(unsigned int)) {
                            [attributeValues addObject:[NSNumber numberWithUnsignedInt:*((unsigned int*)(attribute->Value[j].Data))]];
                        } else if (4 == sizeof(unsigned short)) {
                            [attributeValues addObject:[NSNumber numberWithUnsignedShort:*((unsigned short*)(attribute->Value[j].Data))]];
                        } else {
                            PDEBUG(@"Unable to find a 4-byte unsigned integer type on the target platform.\n");
                            err = CSSMERR_DL_UNSUPPORTED_FIELD_FORMAT;
                        }
                    } else {
                        PDEBUG(@"Unsigned integer attribute has length %u, not 4 as expected.\n", attribute->Value[j].Length);
                        err = CSSMERR_DL_INVALID_VALUE;
                    }
                    
                    break;
                case CSSM_DB_ATTRIBUTE_FORMAT_BIG_NUM:
                    PDEBUG(@"So-called 'BigNum' format not yet supported.\n");
                    err = CSSMERR_DL_UNSUPPORTED_FIELD_FORMAT;
                    
                    break;
                case CSSM_DB_ATTRIBUTE_FORMAT_REAL:
                    if (8 == attribute->Value[j].Length) {
                        [attributeValues addObject:[NSNumber numberWithDouble:*((double*)(attribute->Value[j].Data))]];
                    } else {
                        PDEBUG(@"Double (floating point) attribute has length %u, not 4 as expected.\n", attribute->Value[j].Length);
                        err = CSSMERR_DL_INVALID_VALUE;
                    }
                    
                    break;
                case CSSM_DB_ATTRIBUTE_FORMAT_TIME_DATE:
                {
                    CSSM_X509_TIME time;
                    NSCalendarDate *date;
                    
                    time.timeType = BER_TAG_GENERALIZED_TIME;
                    time.time = attribute->Value[j];
                    
                    date = calendarDateForTime(&time);
                    
                    if (nil != date) {
                        [attributeValues addObject:date];
                    } else {
                        PDEBUG(@"Time/date is apparently invalid.\n");
                        err = CSSMERR_DL_INVALID_VALUE;
                    }
                }
                    
                    break;
                case CSSM_DB_ATTRIBUTE_FORMAT_BLOB:
                    [attributeValues addObject:[NSData dataWithBytes:attribute->Value[j].Data length:attribute->Value[j].Length]];
                    break;
                case CSSM_DB_ATTRIBUTE_FORMAT_MULTI_UINT32:
                    if ((0 < attribute->Value[j].Length) && (0 == (attribute->Value[j].Length % 4))) {
                        unsigned int k, limit = attribute->Value[j].Length / 4;
                        NSMutableArray *moreSubvalues = [NSMutableArray arrayWithCapacity:limit];
                        
                        for (k = 0; (CSSM_OK == err) && (k < limit); ++k) {
                            if (4 == sizeof(unsigned int)) {
                                [moreSubvalues addObject:[NSNumber numberWithUnsignedInt:*((unsigned int*)(attribute->Value[j].Data) + k)]];
                            } else if (4 == sizeof(unsigned short)) {
                                [moreSubvalues addObject:[NSNumber numberWithUnsignedShort:*((unsigned short*)(attribute->Value[j].Data) + k)]];
                            } else {
                                PDEBUG(@"Unable to find a 4-byte unsigned integer type on the target platform.\n");
                                err = CSSMERR_DL_UNSUPPORTED_FIELD_FORMAT;
                            }
                        }
                        
                        if (CSSM_OK == err) {
                            [attributeValues addObject:moreSubvalues];
                        }
                    } else {
                        PDEBUG(@"Multi-unsigned-int attribute has length %u, which is not a positive multiple of four as expected.\n", attribute->Value[j].Length);
                        err = CSSMERR_DL_INVALID_VALUE;
                    }
                    
                    break;
                case CSSM_DB_ATTRIBUTE_FORMAT_COMPLEX:
                    PDEBUG(@"'Complex' format not yet supported.\n");
                    err = CSSMERR_DL_UNSUPPORTED_FIELD_FORMAT;
                    
                    break;
                default:
                    PDEBUG(@"Format %u not known.\n", attribute->Info.AttributeFormat);
                    err = CSSMERR_DL_UNSUPPORTED_FIELD_FORMAT;
            }
        }
        
        if (CSSM_OK == err) {
            unsigned int count = [attributeValues count];
            
            if (0 == count) {
                *result = nil;
            } else if (1 == count) {
                *result = [attributeValues objectAtIndex:0];
            } else {
                *result = attributeValues;
            }
        } else {
            *result = nil;
        }
        
        return err;
    } else {
        PDEBUG(@"Invalid parameters (attribute = %p, result = %p).\n", attribute, result);
        return CSSMERR_DL_INVALID_INPUT_POINTER;
    }
}


@interface ProbeDictionary : NSDictionary {
    NSMutableSet *results;
}

- (NSSet*)results;

@end

@implementation ProbeDictionary

+ (id)dictionary {
    return [[[[self class] alloc] init] autorelease];
}

+ (id)dictionaryWithContentsOfFile:(NSString*)path {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithContentsOfURL:(NSURL*)aURL {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithDictionary:(NSDictionary*)otherDictionary {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithObject:(id)anObject forKey:(id)aKey {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithObjects:(NSArray*)objects forKeys:(NSArray*)keys {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithObjects:(id*)objects forKeys:(id*)keys count:(unsigned)count {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithObjectsAndKeys:(id)firstObject, ... {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithContentsOfFile:(NSString*)path {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithContentsOfURL:(NSURL*)aURL {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithDictionary:(NSDictionary*)otherDictionary {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithDictionary:(NSDictionary*)otherDictionary copyItems:(BOOL)flag {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithObjects:(NSArray*)objects forKeys:(NSArray*)keys {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithObjects:(id*)objects forKeys:(id*)keys count:(unsigned)count {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithObjectsAndKeys:(id)firstObject, ... {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)init {
    id result = [super init];
    
    if (self != result) {
        results = nil;
        [result release];
        
        [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s ([super init] did not return self).", NSStringFromClass([self class]), __func__];
        return nil;
    } else {
        results = [[NSMutableSet alloc] init];
        
        return self;
    }
}

- (id)objectForKey:(id)key {
    PDEBUG(@"objectForKey:%@\n", [key description]);
    
    [results addObject:key];
    return nil;
}

- (id)valueForKey:(NSString*)key {
    PDEBUG(@"valueForKey:%@\n", key);
    
    [results addObject:key];
    return nil;
}

- (NSSet*)results {
    return results;
}

- (void)dealloc {
    [results release];
    
    [super dealloc];
}

@end


@interface CSSMDLDictionary : NSDictionary {
    CSSM_DL_DB_HANDLE myHandle;
    CSSM_DB_RECORDTYPE myRecordType;
    const CSSM_DB_UNIQUE_RECORD *myRecordID;
    
    CSSM_RETURN (*DataGetFromUniqueRecordId)(MDS_DB_HANDLE,
                                             const CSSM_DB_UNIQUE_RECORD*,
                                             CSSM_DB_RECORD_ATTRIBUTE_DATA_PTR,
                                             CSSM_DATA_PTR);
    
    const CSSM_MEMORY_FUNCS *myMemoryFunctions;
}

+ (CSSMDLDictionary*)dictionaryWithHandle:(CSSM_DL_DB_HANDLE)handle forRecords:(CSSM_DB_RECORDTYPE)recordType initialRecordID:(const CSSM_DB_UNIQUE_RECORD*)recordID memoryFunctions:(const CSSM_MEMORY_FUNCS*)memoryFunctions;

- (CSSMDLDictionary*)initWithHandle:(CSSM_DL_DB_HANDLE)handle forRecords:(CSSM_DB_RECORDTYPE)recordType initialRecordID:(const CSSM_DB_UNIQUE_RECORD*)recordID memoryFunctions:(const CSSM_MEMORY_FUNCS*)memoryFunctions;

- (void)setRecordID:(const CSSM_DB_UNIQUE_RECORD*)recordID;
- (const CSSM_DB_UNIQUE_RECORD*)recordID;

- (void)setQueryFunction:(CSSM_RETURN (*)(MDS_DB_HANDLE, const CSSM_DB_UNIQUE_RECORD*, CSSM_DB_RECORD_ATTRIBUTE_DATA_PTR, CSSM_DATA_PTR))function;

@end

@implementation CSSMDLDictionary

+ (CSSMDLDictionary*)dictionaryWithHandle:(CSSM_DL_DB_HANDLE)handle forRecords:(CSSM_DB_RECORDTYPE)recordType initialRecordID:(const CSSM_DB_UNIQUE_RECORD*)recordID memoryFunctions:(const CSSM_MEMORY_FUNCS*)memoryFunctions {
    return [[[[self class] alloc] initWithHandle:handle forRecords:recordType initialRecordID:recordID memoryFunctions:memoryFunctions] autorelease];
}

+ (id)dictionary {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithContentsOfFile:(NSString*)path {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithContentsOfURL:(NSURL*)aURL {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithDictionary:(NSDictionary*)otherDictionary {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithObject:(id)anObject forKey:(id)aKey {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithObjects:(NSArray*)objects forKeys:(NSArray*)keys {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithObjects:(id*)objects forKeys:(id*)keys count:(unsigned)count {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

+ (id)dictionaryWithObjectsAndKeys:(id)firstObject, ... {
    [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithContentsOfFile:(NSString*)path {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithContentsOfURL:(NSURL*)aURL {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithDictionary:(NSDictionary*)otherDictionary {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithDictionary:(NSDictionary*)otherDictionary copyItems:(BOOL)flag {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithObjects:(NSArray*)objects forKeys:(NSArray*)keys {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithObjects:(id*)objects forKeys:(id*)keys count:(unsigned)count {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)initWithObjectsAndKeys:(id)firstObject, ... {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (id)init {
    [NSException raise:@"Unsupported Initialiser" format:@"%@ does not support the initialiser %s.", NSStringFromClass([self class]), __func__];
    return nil;
}

- (CSSMDLDictionary*)initWithHandle:(CSSM_DL_DB_HANDLE)handle forRecords:(CSSM_DB_RECORDTYPE)recordType initialRecordID:(const CSSM_DB_UNIQUE_RECORD*)recordID memoryFunctions:(const CSSM_MEMORY_FUNCS*)memoryFunctions {
    id result = [super init];
    
    if (result != self) {
        [result release];
        
        [NSException raise:@"Unsupported Constructor" format:@"%@ does not support the constructor %s ([super init] did not return self).", NSStringFromClass([self class]), __func__];
        return nil;
    } else {
        myHandle = handle;
        myRecordType = recordType;
        myRecordID = recordID;
        DataGetFromUniqueRecordId = CSSM_DL_DataGetFromUniqueRecordId;
        myMemoryFunctions = memoryFunctions;
        
        return self;
    }
}

- (void)setQueryFunction:(CSSM_RETURN (*)(MDS_DB_HANDLE, const CSSM_DB_UNIQUE_RECORD*, CSSM_DB_RECORD_ATTRIBUTE_DATA_PTR, CSSM_DATA_PTR))function {
    DataGetFromUniqueRecordId = function;
}

- (id)objectForKey:(id)key {
    return [self valueForKey:key];
}

- (void)setRecordID:(const CSSM_DB_UNIQUE_RECORD*)recordID {
    myRecordID = recordID;
}

- (const CSSM_DB_UNIQUE_RECORD*)recordID {
    return myRecordID;
}

- (id)valueForKey:(NSString*)key {
    CSSM_RETURN err;
    CSSM_DB_RECORD_ATTRIBUTE_DATA attributes;
    CSSM_DB_ATTRIBUTE_DATA attribute;
    
    attributes.NumberOfAttributes = 1;
    attributes.SemanticInformation = 0;
    attributes.DataRecordType = myRecordType;
    attributes.AttributeData = &attribute;
    
    attribute.Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
    attribute.Info.Label.AttributeName = (char*)[key UTF8String];
        
    err = DataGetFromUniqueRecordId(myHandle, myRecordID, &attributes, NULL);
    
    if (CSSM_OK == err) {
        id output;
        unsigned int i;
        
        err = objectifyCSSMAttribute(&attribute, &output);
        
        for (i = 0; i < attribute.NumberOfValues; ++i) {
            myMemoryFunctions->free_func(attribute.Value[i].Data, myMemoryFunctions->AllocRef);
        }
        
        myMemoryFunctions->free_func(attribute.Value, myMemoryFunctions->AllocRef);
        
        if (CSSM_OK == err) {
            return output;
        } else {
            PDEBUG(@"objectifyCSSMAttribute(%p, %p) returned error #%u - %@.\n", &attribute, &output, err, CSSMErrorAsString(err));
            return nil;
        }
    } else {
        PDEBUG(@"DataGetFromUniqueRecordId[%p](%"PRIdldbHandle", %p, %p, %p) returned error #%u - %@.\n", DataGetFromUniqueRecordId, myHandle, myRecordID, &attributes, NULL, err, CSSMErrorAsString(err));
        return nil;
    }
}

@end


@implementation MDS

+ (MDS*)defaultMDS {
    static MDS *singleton = nil;
    
    if (!singleton) {
        [keychainSingletonLock lock];
        
        if (!singleton) {
            singleton = [[[self class] alloc] init];
        }
        
        [keychainSingletonLock unlock];
    }
    
    return singleton;
}

/*- (MDS*)initWithGUID:(const CSSM_GUID*)GUID manifest:(const CSSM_DATA*)manifest memoryFunctions:(const CSSM_MEMORY_FUNCS*)memoryFunctions {
    if (((NULL != GUID) || (NULL != manifest)) && (NULL != memoryFunctions)) {
        if (self = [super init]) {
            if (NULL != GUID) {
                memcpy(&myGUID, GUID, sizeof(CSSM_GUID));
            } else {
                memset(&myGUID, 0, sizeof(CSSM_GUID));
            }
            
            resetCSSMData(&myManifest);
            
            if (NULL != manifest) {
                copyDataToData(manifest, &myManifest);
            }
            
            memcpy(&myMemoryFunctions, memoryFunctions, sizeof(CSSM_MEMORY_FUNCS));
            
            lastError = MDS_Initialize(GUID, manifest, &myMemoryFunctions, &mdsFunctions, &myHandle);
            
            if (CSSM_OK != lastError) {
                PCONSOLE(@"Unable to initialise MDS (Module Directory Service), error #%u - %@.\n", lastError, CSSMErrorAsString(lastError));
                PDEBUG(@"MDS_Initialize(%p, %p, %p, %p, %p) failed with error #%u - %@.\n", GUID, manifest, &myMemoryFunctions, &mdsFunctions, &myHandle, lastError, CSSMErrorAsString(lastError));
                
                [self release];
                self = nil;
            }
        }
    } else {
        PDEBUG(@"Invalid parameters (GUID = %p, manifest = %p, memoryFunctions = %p).\n", GUID, manifest, memoryFunctions);
        
        [self release];
        self = nil;
    }
    
    return self;
}

- (MDS*)initWithManifest:(const CSSM_DATA*)manifest memoryFunctions:(const CSSM_MEMORY_FUNCS*)memoryFunctions {
    return [self initWithGUID:NULL manifest:manifest memoryFunctions:memoryFunctions];
}

- (MDS*)initWithGUID:(const CSSM_GUID*)GUID memoryFunctions:(const CSSM_MEMORY_FUNCS*)memoryFunctions {
    return [self initWithGUID:GUID manifest:NULL memoryFunctions:memoryFunctions];
}

- (MDS*)init {
    return [self initWithGUID:keychainFrameworkDefaultGUID() manifest:NULL memoryFunctions:[CSSMModule defaultMemoryFunctions]];
}*/

- (MDS*)initWithGUID:(const CSSM_GUID*)GUID memoryFunctions:(const CSSM_MEMORY_FUNCS*)memoryFunctions {
    if (NULL != GUID) {
        if (self = [super init]) {
            if (NULL != GUID) {
                memcpy(&myGUID, GUID, sizeof(CSSM_GUID));
            } else {
                memset(&myGUID, 0, sizeof(CSSM_GUID));
            }
            
            if (NULL != memoryFunctions) {
                memcpy(&myMemoryFunctions, memoryFunctions, sizeof(CSSM_MEMORY_FUNCS));
            } else {
                memcpy(&myMemoryFunctions, [CSSMModule defaultMemoryFunctions], sizeof(CSSM_MEMORY_FUNCS));
            }
            
            lastError = MDS_Initialize(GUID, &myMemoryFunctions, &mdsFunctions, &myHandle);
            
            if (CSSM_OK != lastError) {
                PCONSOLE(@"Unable to initialise MDS (Module Directory Service), error #%u - %@.\n", lastError, CSSMErrorAsString(lastError));
                PDEBUG(@"MDS_Initialize(%p, %p, %p, %p) failed with error #%u - %@.\n", GUID, &myMemoryFunctions, &mdsFunctions, &myHandle, lastError, CSSMErrorAsString(lastError));
                
                [self release];
                self = nil;
            } else {
                myCredentials = NULL;
                myOpenParameters = NULL;
            }
        }
    } else {
        PDEBUG(@"Invalid parameters (GUID = %p, memoryFunctions = %p).\n", GUID, memoryFunctions);
        
        [self release];
        self = nil;
    }
    
    return self;
}

- (MDS*)init {
    return [self initWithGUID:keychainFrameworkDefaultGUID() memoryFunctions:[CSSMModule defaultMemoryFunctions]];
}

- (NSArray*)databases {
    if (NULL != mdsFunctions.GetDbNames) {
        /* CSSM_RETURN (CSSMAPI *GetDbNames) (MDS_HANDLE MdsHandle,
                                              CSSM_NAME_LIST_PTR *NameList); */
        
        CSSM_NAME_LIST *nameList = NULL;
        
        lastError = mdsFunctions.GetDbNames(myHandle, &nameList);
        
        if (CSSM_OK == lastError) {
            NSMutableArray *result = [NSMutableArray arrayWithCapacity:nameList->NumStrings];
            uint32_t i;
            
            for (i = 0; i < nameList->NumStrings; ++i) {
                [result addObject:[NSString stringWithCString:(nameList->String[i])]];
            }
            
            if (NULL != mdsFunctions.FreeNameList) {
                /* CSSM_RETURN (CSSMAPI *FreeNameList) (MDS_HANDLE MdsHandle,
                                                        CSSM_NAME_LIST_PTR NameList); */
                
                lastError = mdsFunctions.FreeNameList(myHandle, nameList);
                
                if (CSSM_OK != lastError) {
                    PCONSOLE(@"Unable to free database names list, error #%u - %@.\n", lastError, CSSMErrorAsString(lastError));
                    PDEBUG(@"mdsFunctions.FreeNameList(%"PRImdsHandle", %p) [at address %p] returned error #%u - %@.\n", myHandle, nameList, mdsFunctions.FreeNameList, lastError, CSSMErrorAsString(lastError));
                }
            } else {
                PCONSOLE(@"Unable to free database names list - free function is missing.\n");
                PDEBUG(@"FreeNameList function missing from MDS functions list (%p) - non-fatal, but leaking.\n", &mdsFunctions);
            }
            
            return result;
        } else {
            PCONSOLE(@"Unable to obtain database names from MDS, error #%u - %@.\n", lastError, CSSMErrorAsString(lastError));
            PDEBUG(@"mdsFunctions.GetDbNames(%"PRImdsHandle", %p) [at address %p] returned error #%u - %@.\n", myHandle, &nameList, mdsFunctions.GetDbNames, lastError, CSSMErrorAsString(lastError));
        }
    } else {
        PCONSOLE(@"MDS does not provide facility for listing available databases.\n");
        PDEBUG(@"GetDbNames function missing from MDS functions list (%p).\n", &mdsFunctions);
        
        lastError = CSSMERR_CSSM_SERVICE_NOT_AVAILABLE;
    }
    
    return nil;
}

- (BOOL)open:(NSString*)database access:(CSSM_DB_ACCESS_TYPE)access handle:(MDS_DB_HANDLE*)handle {
    if (NULL != handle) {
        if (NULL != mdsFunctions.DbOpen) {
            /* CSSM_RETURN (CSSMAPI *DbOpen) (MDS_HANDLE MdsHandle,
                                              const char *DbName,
                                              const CSSM_NET_ADDRESS *DbLocation,
                                              CSSM_DB_ACCESS_TYPE AccessRequest,
                                              const CSSM_ACCESS_CREDENTIALS *AccessCred,
                                              const void *OpenParameters,
                                              CSSM_DB_HANDLE *hMds); */
            
            const char *databaseName = [database UTF8String];
            CSSM_DB_HANDLE dbHandle;
            
            lastError = mdsFunctions.DbOpen(myHandle, databaseName, NULL, access, myCredentials, myOpenParameters, &dbHandle);
            
            if (CSSM_OK != lastError) {
                PCONSOLE(@"Unable to open MDS database, error #%u - %@.\n", lastError, CSSMErrorAsString(lastError));
                PDEBUG(@"mdsFunctions.DbOpen(%"PRImdsHandle", \"%s\", %p, 0x%x, %p, %p, %p) [at address %p] returned error #%u - %@.\n", myHandle, databaseName, NULL, access, myCredentials, myOpenParameters, handle, mdsFunctions.DbOpen, lastError, CSSMErrorAsString(lastError));
            } else {
                handle->DLHandle = myHandle;
                handle->DBHandle = dbHandle;
                
                return YES;
            }
        } else {
            PCONSOLE(@"MDS does not provide a DbOpen function.\n");
            PDEBUG(@"DbOpen function missing from MDS functions list (%p).\n", &mdsFunctions);
            
            lastError = CSSMERR_CSSM_SERVICE_NOT_AVAILABLE;
        }
    } else {
        PDEBUG(@"Invalid parameters - handle is NULL.\n");
        lastError = CSSMERR_CSSM_INVALID_INPUT_POINTER;
    }
    
    return NO;
}

- (NSString*)databaseNameOfHandle:(MDS_DB_HANDLE)handle {
    if (NULL != mdsFunctions.GetDbNameFromHandle) {
        /* CSSM_RETURN (CSSMAPI *GetDbNameFromHandle) (MDS_DB_HANDLE MdsDbHandle,
                                                       char **DbName); */
        
        char *name = NULL;
        
        lastError = mdsFunctions.GetDbNameFromHandle(handle, &name);
        
        if (CSSM_OK == lastError) {
            NSString *result = [NSString stringWithCString:name];
            
            if (NULL != myMemoryFunctions.free_func) {
                myMemoryFunctions.free_func(name, myMemoryFunctions.AllocRef);
            } else {
                PCONSOLE(@"Memory functions do not provide a free function - leaking.\n");
                PDEBUG(@"myMemoryFunctions.free_func is NULL (myMemoryFunctions is at %p).  Not fatal, but leaking.\n", &myMemoryFunctions);
            }
            
            return result;
        } else {
            PCONSOLE(@"Unable to obtain database name from MDS, error #%u - %@.\n", lastError, CSSMErrorAsString(lastError));
            PDEBUG(@"mdsFunctions.GetDbNameFromHandle(%"PRImdsdbHandle", %p) [at address %p] returned error #%u - %@.\n", handle, &name, mdsFunctions.GetDbNameFromHandle, lastError, CSSMErrorAsString(lastError));
        }
    } else {
        PCONSOLE(@"MDS does not provide a GetDbNameFromHandle function.\n");
        PDEBUG(@"GetDbNameFromHandle function missing from MDS functions list (%p).\n", &mdsFunctions);
        
        lastError = CSSMERR_CSSM_SERVICE_NOT_AVAILABLE;
    }
    
    return nil;
}

/*BOOL copyNSComparisonPredicateIntoCSSMSelectionPredicate(NSComparisonPredicate *predicate, unsigned int *numberOfPredicates, CSSM_SELECTION_PREDICATE *destination[]) {
    if ((nil != predicate) && (NULL != numberOfPredicates) && (NULL != destination)) {
        if (NSDirectPredicateModifier == [predicate comparisonPredicateModifier]) {
            // We can only handle direct predicates at the moment; they're a lot easier to handle than to-many relationships.
            
            if (0 == [predicate options]) {
                // And same argument here - CSSM doesn't provide for case-insensitive or diacritic-insensitive comparisons... don't know how we'd work around that, aside from doing the querying manually... ick.
                
                switch ([predicate predicateOperatorType]) {
                    case NSLessThanPredicateOperatorType: // CSSM_DB_LESS_THAN
                        
                    case NSGreaterThanPredicateOperatorType: // CSSM_DB_GREATER_THAN
                    case NSEqualToPredicateOperatorType: // CSSM_DB_EQUAL
                    case NSNotEqualToPredicateOperatorType: // CSSM_DB_NOT_EQUAL
                    case NSMatchesPredicateOperatorType: // CSSM_DB_CONTAINS
                    case NSLikePredicateOperatorType: // CSSM_DB_CONTAINS
                    case NSBeginsWithPredicateOperatorType: // CSSM_DB_CONTAINS_INITIAL_SUBSTRING
                    case NSEndsWithPredicateOperatorType: // CSSM_DB_CONTAINS_FINAL_SUBSTRING
                    case NSInPredicateOperatorType: // CSSM_DB_CONTAINS
                        
                    case NSLessThanOrEqualToPredicateOperatorType: // Can't do; would need to generate two CSSM_SELECTION_PREDICATEs
                    case NSGreaterThanOrEqualToPredicateOperatorType: // Can't do; would need to generate two CSSM_SELECTION_PREDICATEs
                        
                    default:
                        PDEBUG(@"Unknown comparison operator, %u.\n", [predicate predicateOperatorType]);
                        return NO;
                }
            } else {
                PDEBUG(@"Comparison predicate's options are 0x%x - can't handle any options yet.\n", [predicate options]);
                return NO;
            }
        } else {
            PDEBUG(@"Comparison predicate has modifier of %d, which cannot be handled.\n", [predicate comparisonPredicateModifier]);
            return NO;
        }
    } else {
        PDEBUG(@"Invalid parameters (predicate = %p, destination = %p).\n", predicate, destination);
        return NO;
    }
}*/

/* BOOL copyNSPredicateIntoCSSMQuery(NSPredicate *predicate, CSSM_QUERY *query) {
    if (NULL != query) {
        if (nil != predicate) {
            if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
                NSCompoundPredicate *compoundPredicate = (NSCompoundPredicate*)predicate;
                NSArray *subpredicates;
                
                switch ([compoundPredicate compoundPredicateType]) {
                    case NSAndPredicateType:
                        query->Conjunctive = CSSM_DB_AND;
                        break;
                    case NSOrPredicateType:
                        query->Conjunctive = CSSM_DB_OR;
                        break;
                    default:
                        PDEBUG(@"Unsupported compound predicate type, %u.\n", [compoundPredicate compoundPredicateType]);
                        return NO;
                }
                
                subpredicates = [compoundPredicate subpredicates];
                
                if (nil != subpredicates) {
                    NSEnumerator *subpredicateEnumerator = [subpredicates objectEnumerator];
                    
                    if (nil != subpredicateEnumerator) {
                        id current;
                        NSPredicate *currentSubpredicate;
                        
                        while (current = [subpredicateEnumerator nextObject]) {
                            if ([current isKindOfClass:[NSPredicate class]]) {
                                currentSubpredicate = (NSPredicate*)current;
                                
                                if ([currentSubpredicate isKindOfClass:[NSComparisonPredicate class]]) {
                                    
                                } else {
                                    PDEBUG(@"Predicate (%p) is of class %@, which is not an NSComparisonPredicate, which is required for all subpredicates.\n", currentSubpredicate, NSStringFromClass([currentSubpredicate class]));
                                    return NO;
                                }
                            } else {
                                PDEBUG(@"Object (%p) is of class %@, which is not of kind NSPredicate, and cannot be parsed.\n", current, NSStringFromClass([current class]));
                                return NO;
                            }
                        }
                    } else {
                        PDEBUG(@"Unable to obtain object enumerator over subpredicates.\n");
                        return NO;
                    }
                } else {
                    PDEBUG(@"Unable to obtain subpredicates from NSCompoundPredicate.\n");
                    return NO;
                }
            } else if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
                
            } else {
                PCONSOLE(@"Predicate is not an NSCompoundPredicate or NSComparisonPredicate (it is a %@) - don't know how to convert it to a CSSM DL query predicate.\n", NSStringFromClass([predicate class]));
                PDEBUG(@"Predicate (0x%x, class %@) is not a supported type for conversion to a CSSM DL query predicate.\n", predicate, NSStringFromClass([predicate class]));
                return NO;
            }
        } else {
            query->Conjunctive = CSSM_DB_NONE;
            query->NumSelectionPredicates = 0;
            query->SelectionPredicate = 0;
        }
    } else {
        PDEBUG(@"Invalid paramaters, 'query' is NULL.\n");
    }
}*/

- (NSArray*)query:(MDS_DB_HANDLE)handle attributes:(NSArray*)attributes forAllRecordsOfType:(CSSM_DB_RECORDTYPE)recordType usingPredicate:(NSPredicate*)predicate withTimeLimit:(unsigned int)seconds andSizeLimit:(unsigned int)records {
    /* // This just tells you what properties the predicate tried to retrieve from the dictionary.  Note that because predicates are evaluated opportunistically, not all values referred to in the predicate will be requested - i.e. if you have a predicate (A > 3) AND (B < 2), and A is 2 for example, then B will never be asked for, because if one element in a logical AND is false, the whole expression evaluates to false.  Yes, this ain't brain surgery, but, just so everyone knows why I bothered testing this to start with.. :)
    
    ProbeDictionary *predicateProbe = [ProbeDictionary dictionary];
    
    [predicate evaluateWithObject:predicateProbe];
    
    PDEBUG(@"Result of probe is %@\n", [[predicateProbe results] description]);
    
    return nil;*/
    
    NSMutableArray *result = nil;
    
    if (NULL != mdsFunctions.DataGetFirst) {
        CSSM_QUERY myQuery;
        unsigned int count = ((nil != attributes) ? [attributes count] : 0);
        CSSM_DB_RECORD_ATTRIBUTE_DATA rawAttributes;
        
        myQuery.RecordType = recordType;
        myQuery.Conjunctive = CSSM_DB_NONE;
        myQuery.NumSelectionPredicates = 0;
        myQuery.SelectionPredicate = NULL;
        myQuery.QueryLimits.TimeLimit = seconds;
        myQuery.QueryLimits.SizeLimit = records;
        myQuery.QueryFlags = 0;
        
        rawAttributes.DataRecordType = recordType;
        rawAttributes.SemanticInformation = 0;
        rawAttributes.NumberOfAttributes = count;
        
        if (0 < count) {
            rawAttributes.AttributeData = myMemoryFunctions.malloc_func(sizeof(CSSM_DB_ATTRIBUTE_DATA) * count, myMemoryFunctions.AllocRef);
        } else {
            rawAttributes.AttributeData = NULL;
        }
        
        if ((0 == count) || (NULL != rawAttributes.AttributeData)) {
            CSSM_HANDLE resultsHandle;
            NSMutableDictionary *currentResult;
            NSMutableArray *currentAttributeValues;
            CSSM_DB_UNIQUE_RECORD *uniqueID;
            unsigned int i, j;
            CSSM_DATA data;
            NSString *current;
            NSEnumerator *attributesEnumerator = ((nil != attributes) ? [attributes objectEnumerator] : nil);
            
            result = [NSMutableArray array];
            
            for (i = 0;
                 (i < count) && (current = [attributesEnumerator nextObject]);
                 ++i) {
                rawAttributes.AttributeData[i].Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
                rawAttributes.AttributeData[i].Info.Label.AttributeName = (char*)[current UTF8String];
            }
            
            resetCSSMData(&data);
            
            lastError = mdsFunctions.DataGetFirst(handle, &myQuery, &resultsHandle, &rawAttributes, &data, &uniqueID);
            
            if (CSSM_OK == lastError) {
                CSSMDLDictionary *feedback;
                
                if (nil != predicate) {
                    feedback = [CSSMDLDictionary dictionaryWithHandle:handle forRecords:recordType initialRecordID:uniqueID memoryFunctions:&myMemoryFunctions];
                    
                    if (nil != feedback) {
                        if (NULL != mdsFunctions.DataGetFromUniqueRecordId) {
                            [feedback setQueryFunction:mdsFunctions.DataGetFromUniqueRecordId];
                        } else {
                            PCONSOLE(@"MDS does not implement DataGetFromUniqueRecordId, which is required for predicate support.\n");
                            PDEBUG(@"DataGetFromUniqueRecordId function missing from MDS functions list (%p).\n", &mdsFunctions);
                            
                            lastError = CSSMERR_CSSM_SERVICE_NOT_AVAILABLE;
                        }
                    } else {
                        PCONSOLE(@"Unable to create super-secret-happy-feedback-dictionary.  D'oh.\n");
                        PDEBUG(@"Unable to create CSSMDLDictionary for predicate feedback (handle = %"PRIdldbHandle", recordType = %u, initialRecordID = %p, memoryFunctions = %p).\n", handle, recordType, &uniqueID, myMemoryFunctions);
                        
                        lastError = CSSMERR_DL_INTERNAL_ERROR;
                    }
                } else {
                    feedback = nil;
                }
                
                while (CSSM_OK == lastError) {
                    currentResult = [NSMutableDictionary dictionaryWithCapacity:count];
                    
                    if (nil != predicate) {
                        if (![predicate evaluateWithObject:feedback]) {
                            currentResult = nil;
                        }
                    }
                    
                    if (nil != currentResult) {
                        for (i = 0; (CSSM_OK == lastError) && (i < count); ++i) {
                            lastError = objectifyCSSMAttribute(&(rawAttributes.AttributeData[i]), &currentAttributeValues);
                            
                            if (CSSM_OK == lastError) {
                                [currentResult setObject:currentAttributeValues forKey:[NSString stringWithUTF8String:rawAttributes.AttributeData[i].Info.Label.AttributeName]];
                            }
                        }
                        
                        for (i = 0; i < count; ++i) {
                            if (NULL != rawAttributes.AttributeData) {
                                for (j = 0; j < rawAttributes.AttributeData[i].NumberOfValues; ++j) {
                                    if (NULL != rawAttributes.AttributeData[i].Value[j].Data) {
                                        myMemoryFunctions.free_func(rawAttributes.AttributeData[i].Value[j].Data, myMemoryFunctions.AllocRef);
                                    }
                                }
                                
                                myMemoryFunctions.free_func(rawAttributes.AttributeData[i].Value, myMemoryFunctions.AllocRef);
                            }
                        }
                    }
                    
                    if (CSSM_OK == lastError) {
                        if ((nil != currentResult) && (nil == [currentResult objectForKey:@"Record ID"])) {
                            [currentResult setObject:[NSValue valueWithPointer:uniqueID] forKey:@"Record ID"];
                        } else {
                            if (NULL != mdsFunctions.FreeUniqueRecord) {
                                lastError = mdsFunctions.FreeUniqueRecord(handle, uniqueID);
                                
                                if (CSSM_OK != lastError) {
                                    PDEBUG(@"Unable to free unique record ID, error #%u - %@.  This is not a fatal error, but memory may be leaking.\n", lastError, CSSMErrorAsString(lastError));
                                    lastError = CSSM_OK; // We don't want to break code that checks lastError after each call, even if a non-nil result is provided.
                                }
                            } else {
                                PCONSOLE(@"MDS does not provide a FreeUniqueRecord function.\n");
                                PDEBUG(@"FreeUniqueRecord function missing from MDS functions list (%p).\n", &mdsFunctions);
                                
                                lastError = CSSMERR_CSSM_SERVICE_NOT_AVAILABLE;
                            }
                        }
                        
                        if ((nil != currentResult) && (nil == [currentResult objectForKey:@"Data"]) && (0 < data.Length)) {
                            [currentResult setObject:NSDataFromData(&data) forKey:@"Data"];
                        }
                    }
                    
                    if (NULL != data.Data) {
                        myMemoryFunctions.free_func(data.Data, myMemoryFunctions.AllocRef);
                    }
                    
                    resetCSSMData(&data);
                    
                    if (CSSM_OK == lastError) {
                        if (nil != currentResult) {
                            [result addObject:currentResult];
                        }
                        
                        if (NULL != mdsFunctions.DataGetNext) {
                            /* CSSM_RETURN CSSMAPI CSSM_DL_DataGetNext (CSSM_DL_DB_HANDLE DLDBHandle,
                                                                        CSSM_HANDLE ResultsHandle,
                                                                        CSSM_DB_RECORD_ATTRIBUTE_DATA_PTR Attributes,
                                                                        CSSM_DATA_PTR Data,
                                                                        CSSM_DB_UNIQUE_RECORD_PTR *UniqueId) */
                            
                            lastError = mdsFunctions.DataGetNext(handle, resultsHandle, &rawAttributes, &data, &uniqueID);
                            
                            if ((nil != feedback) && (CSSM_OK == lastError)) {
                                [feedback setRecordID:uniqueID];
                            }
                        } else {
                            PCONSOLE(@"MDS does not provide a DataGetNext function.\n");
                            PDEBUG(@"DataGetNext function missing from MDS functions list (%p).\n", &mdsFunctions);
                            
                            lastError = CSSMERR_DL_ENDOFDATA; /* Should we be returning CSSMERR_CSSM_SERVICE_NOT_AVAILABLE instead?  What is the service provider really doesn't need a DataGetNext, i.e. it only ever returns one result per query? */
                        }
                    }
                }
                
                if (CSSMERR_DL_ENDOFDATA == lastError) {
                    lastError = CSSM_OK;
                } else if (CSSM_OK != lastError) {
                    result = nil;
                }
            } else if (CSSMERR_DL_ENDOFDATA == lastError) {
                lastError = CSSM_OK;
            } else {
                PCONSOLE(@"Unable to perform query of MDS, error #%u - %@.\n", lastError, CSSMErrorAsString(lastError));
                PDEBUG(@"mdsFunctions.DataGetFirst(%"PRImdsdbHandle", %p, %p, %p, %p, %p) [at address %p] returned error #%u - %@.\n", handle, &myQuery, &resultsHandle, &attributes, &data, &uniqueID, mdsFunctions.DataGetFirst, lastError, CSSMErrorAsString(lastError));
                
                result = nil;
                lastError = CSSMERR_CSSM_SERVICE_NOT_AVAILABLE;
            }
            
            if (NULL != rawAttributes.AttributeData) {
                myMemoryFunctions.free_func(rawAttributes.AttributeData, myMemoryFunctions.AllocRef);
            }
        } else {
            lastError = CSSMERR_DL_MEMORY_ERROR;
            PDEBUG(@"Unable to allocate %u bytes of memory for %u CSSM_DB_ATTRIBUTE_DATA structures.\n", sizeof(CSSM_DB_RECORD_ATTRIBUTE_DATA) * count, count);
        }
    } else {
        PCONSOLE(@"MDS does not provide a DataGetFirst function.\n");
        PDEBUG(@"DataGetFirst function missing from MDS functions list (%p).\n", &mdsFunctions);
        
        lastError = CSSMERR_CSSM_SERVICE_NOT_AVAILABLE;
    }
    
    return result;
}

- (NSArray*)query:(MDS_DB_HANDLE)handle attributes:(NSArray*)attributes forAllRecordsOfType:(CSSM_DB_RECORDTYPE)recordType withTimeLimit:(unsigned int)seconds andSizeLimit:(unsigned int)records {
    NSMutableArray *result = nil;
    
    if ((nil != attributes) && (0 < [attributes count])) {
        if (NULL != mdsFunctions.DataGetFirst) {
            CSSM_QUERY myQuery;
            unsigned int count = [attributes count];
            CSSM_DB_RECORD_ATTRIBUTE_DATA rawAttributes;
            
            myQuery.RecordType = recordType;
            myQuery.Conjunctive = CSSM_DB_NONE;
            myQuery.NumSelectionPredicates = 0;
            myQuery.SelectionPredicate = NULL;
            myQuery.QueryLimits.TimeLimit = seconds;
            myQuery.QueryLimits.SizeLimit = records;
            myQuery.QueryFlags = 0;
            
            rawAttributes.DataRecordType = recordType;
            rawAttributes.SemanticInformation = 0;
            rawAttributes.NumberOfAttributes = count;
            rawAttributes.AttributeData = myMemoryFunctions.malloc_func(sizeof(CSSM_DB_ATTRIBUTE_DATA) * count, myMemoryFunctions.AllocRef);
            
            if (NULL != rawAttributes.AttributeData) {
                CSSM_HANDLE resultsHandle;
                NSMutableDictionary *currentResult;
                NSMutableArray *currentAttributeValues;
                CSSM_DB_UNIQUE_RECORD *uniqueID;
                unsigned int i, j;
                CSSM_DATA data;
                NSString *current;
                NSEnumerator *attributesEnumerator = [attributes objectEnumerator];

                result = [NSMutableArray array];

                for (i = 0;
                     (i < count) && (current = [attributesEnumerator nextObject]);
                     ++i) {
                    rawAttributes.AttributeData[i].Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;
                    rawAttributes.AttributeData[i].Info.Label.AttributeName = (char*)[current UTF8String];
                }
                
                resetCSSMData(&data);
                
                lastError = mdsFunctions.DataGetFirst(handle, &myQuery, &resultsHandle, &rawAttributes, &data, &uniqueID);
                
                if (CSSM_OK == lastError) {
                    do {
                        currentResult = [NSMutableDictionary dictionaryWithCapacity:count];
                        
                        for (i = 0; (CSSM_OK == lastError) && (i < count); ++i) {
                            lastError = objectifyCSSMAttribute(&(rawAttributes.AttributeData[i]), &currentAttributeValues);
                            
                            if ((CSSM_OK == lastError) && (nil != currentAttributeValues)) {
                                [currentResult setObject:currentAttributeValues forKey:[NSString stringWithUTF8String:rawAttributes.AttributeData[i].Info.Label.AttributeName]];
                            }
                        }
                        
                        for (i = 0; i < count; ++i) {
                            if (NULL != rawAttributes.AttributeData) {
                                for (j = 0; j < rawAttributes.AttributeData[i].NumberOfValues; ++j) {
                                    if (NULL != rawAttributes.AttributeData[i].Value[j].Data) {
                                        myMemoryFunctions.free_func(rawAttributes.AttributeData[i].Value[j].Data, myMemoryFunctions.AllocRef);
                                    }
                                }
                                
                                myMemoryFunctions.free_func(rawAttributes.AttributeData[i].Value, myMemoryFunctions.AllocRef);
                            }
                        }
                        
                        if (CSSM_OK == lastError) {
                            if (nil == [currentResult objectForKey:@"Record ID"]) {
                                [currentResult setObject:[NSValue valueWithPointer:uniqueID] forKey:@"Record ID"];
                            } else {
                                if (NULL != mdsFunctions.FreeUniqueRecord) {
                                    lastError = mdsFunctions.FreeUniqueRecord(handle, uniqueID);
                                    
                                    if (CSSM_OK != lastError) {
                                        PDEBUG(@"Unable to free unique record ID, error #%u - %@.  This is not a fatal error, but memory may be leaking.\n", lastError, CSSMErrorAsString(lastError));
                                        lastError = CSSM_OK; // We don't want to break code that checks lastError after each call, even if a non-nil result is provided.
                                    }
                                } else {
                                    PCONSOLE(@"MDS does not provide a FreeUniqueRecord function.\n");
                                    PDEBUG(@"FreeUniqueRecord function missing from MDS functions list (%p).\n", &mdsFunctions);
                                }
                            }
                            
                            if ((nil == [currentResult objectForKey:@"Data"]) && (0 < data.Length)) {
                                [currentResult setObject:NSDataFromData(&data) forKey:@"Data"];
                            }
                        }
                        
                        if (NULL != data.Data) {
                            myMemoryFunctions.free_func(data.Data, myMemoryFunctions.AllocRef);
                        }
                        
                        resetCSSMData(&data);
                        
                        if (CSSM_OK == lastError) {
                            [result addObject:currentResult];
                            
                            if (NULL != mdsFunctions.DataGetNext) {
                                /* CSSM_RETURN CSSMAPI CSSM_DL_DataGetNext (CSSM_DL_DB_HANDLE DLDBHandle,
                                                                            CSSM_HANDLE ResultsHandle,
                                                                            CSSM_DB_RECORD_ATTRIBUTE_DATA_PTR Attributes,
                                                                            CSSM_DATA_PTR Data,
                                                                            CSSM_DB_UNIQUE_RECORD_PTR *UniqueId) */
                                
                                lastError = mdsFunctions.DataGetNext(handle, resultsHandle, &rawAttributes, &data, &uniqueID);
                            } else {
                                PCONSOLE(@"MDS does not provide a DataGetNext function.\n");
                                PDEBUG(@"DataGetNext function missing from MDS functions list (%p).\n", &mdsFunctions);
                                
                                lastError = CSSMERR_DL_ENDOFDATA;
                            }
                        }
                    } while (CSSM_OK == lastError);
                    
                    if (CSSMERR_DL_ENDOFDATA == lastError) {
                        lastError = CSSM_OK;
                    } else if (CSSM_OK != lastError) {
                        result = nil;
                    }
                } else if (CSSMERR_DL_ENDOFDATA == lastError) {
                    lastError = CSSM_OK;
                } else {
                    PCONSOLE(@"Unable to perform query of MDS, error #%u - %@.\n", lastError, CSSMErrorAsString(lastError));
                    PDEBUG(@"mdsFunctions.DataGetFirst(%"PRImdsdbHandle", %p, %p, %p, %p, %p) [at address %p] returned error #%u - %@.\n", handle, &myQuery, &resultsHandle, &attributes, &data, &uniqueID, mdsFunctions.DataGetFirst, lastError, CSSMErrorAsString(lastError));
                    
                    result = nil;
                }
                
                myMemoryFunctions.free_func(rawAttributes.AttributeData, myMemoryFunctions.AllocRef);
            } else {
                lastError = CSSMERR_DL_MEMORY_ERROR;
                PDEBUG(@"Unable to allocate %u bytes of memory for %u CSSM_DB_ATTRIBUTE_DATA structures.\n", sizeof(CSSM_DB_RECORD_ATTRIBUTE_DATA) * count, count);
            }
        } else {
            PCONSOLE(@"MDS does not provide a DataGetFirst function.\n");
            PDEBUG(@"DataGetFirst function missing from MDS functions list (%p).\n", &mdsFunctions);
            
            lastError = CSSMERR_CSSM_SERVICE_NOT_AVAILABLE;
        }
    } else {
        lastError = CSSMERR_DL_INVALID_INPUT_POINTER;
        PDEBUG(@"Invalid parameters - 'attributes' is nil or empty.\n");
    }
    
    return result;
}

/*- (NSArray*)query:(MDS_DB_HANDLE)handle forRecordsOfType:(CSSM_DB_RECORDTYPE)recordType usingPredicate:(NSPredicate*)predicate withTimeLimit:(unsigned int)seconds andSizeLimit:(unsigned int)records {
    CSSM_QUERY myQuery;
    NSMutableArray *result = nil;
    
    myQuery.RecordType = recordType;
    
    
    
    return result;
}*/

- (BOOL)testQuery:(MDS_DB_HANDLE)handle {
    if (NULL != mdsFunctions.DataGetFirst) {
        /* CSSM_RETURN (CSSMAPI *DataGetFirst) (MDS_DB_HANDLE MdsDbHandle,
                                                const CSSM_QUERY *Query,
                                                CSSM_HANDLE_PTR ResultsHandle,
                                                CSSM_DB_RECORD_ATTRIBUTE_DATA_PTR Attributes,
                                                CSSM_DATA_PTR Data,
                                                CSSM_DB_UNIQUE_RECORD_PTR *UniqueId); */
        
        CSSM_QUERY myQuery;
        CSSM_HANDLE resultsHandle;
        CSSM_DB_RECORD_ATTRIBUTE_DATA attributes;
        CSSM_DB_UNIQUE_RECORD *uniqueID;
        CSSM_DATA data;
        
        resetCSSMData(&data); // Technically unnecessary, according to the CDSA spec, but good form nonetheless.
        
        myQuery.RecordType = MDS_CDSADIR_CSP_PRIMARY_RECORDTYPE;
        myQuery.Conjunctive = CSSM_DB_NONE;
        myQuery.NumSelectionPredicates = 0;
        myQuery.SelectionPredicate = NULL;
        myQuery.QueryLimits.TimeLimit = CSSM_QUERY_TIMELIMIT_NONE;
        myQuery.QueryLimits.SizeLimit = CSSM_QUERY_SIZELIMIT_NONE;
        myQuery.QueryFlags = 0;
        
        attributes.DataRecordType = myQuery.RecordType;
        attributes.SemanticInformation = 0;
        attributes.NumberOfAttributes = 1;
        attributes.AttributeData = myMemoryFunctions.malloc_func(sizeof(CSSM_DB_ATTRIBUTE_DATA), myMemoryFunctions.AllocRef);
        
        //attributes.AttributeData[0].Info.Label.AttributeID = MDS_CDSAATTR_MODULE_NAME;
        attributes.AttributeData[0].Info.Label.AttributeName = "ModuleName";
        //attributes.AttributeData[0].Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_INTEGER;
        attributes.AttributeData[0].Info.AttributeNameFormat = CSSM_DB_ATTRIBUTE_NAME_AS_STRING;

        lastError = mdsFunctions.DataGetFirst(handle, &myQuery, &resultsHandle, &attributes, &data, &uniqueID);
        
        if (CSSM_OK != lastError) {
            PCONSOLE(@"Unable to perform query of MDS, error #%u - %@.\n", lastError, CSSMErrorAsString(lastError));
            PDEBUG(@"mdsFunctions.DataGetFirst(%"PRImdsdbHandle", %p, %p, %p, %p, %p) [at address %p] returned error #%u - %@.\n", handle, &myQuery, &resultsHandle, &attributes, &data, &uniqueID, mdsFunctions.DataGetFirst, lastError, CSSMErrorAsString(lastError));
        } else {
            PDEBUG(@"data length = %u, pointer to value = %p.\n", data.Length, data.Data);
            printf("Attributes.DataRecordType = %u\n          .SemanticInformation = %u\n          .NumberOfAttributes = %u\n          .AttributeData = %p\n", (unsigned int)(attributes.DataRecordType), (unsigned int)(attributes.SemanticInformation), (unsigned int)(attributes.NumberOfAttributes), attributes.AttributeData);
            
            if (NULL != attributes.AttributeData) {
                unsigned int i, j;
                
                for (i = 0; i < attributes.NumberOfAttributes; ++i) {
                    printf("          .AttributeData[%u].Info.AttributeNameFormat = %u\n                           .NumberOfValues = %u\n                           .Value = %p\n", i, (unsigned int)(attributes.AttributeData[i].Info.AttributeNameFormat), (unsigned int)(attributes.AttributeData[i].NumberOfValues), attributes.AttributeData[i].Value);
                    
                    for (j = 0; j < attributes.AttributeData[i].NumberOfValues; ++j) {
                        printf("                           .Value[%u].Length = %u\n                           .Value[%u].Data = (%p) %s\n", j, (unsigned int)(attributes.AttributeData[i].Value[j].Length), j, attributes.AttributeData[i].Value[j].Data, attributes.AttributeData[i].Value[j].Data);
                    }
                }
            }
            
            return YES;
        }
    } else {
        PCONSOLE(@"MDS does not provide a DataGetFirst function.\n");
        PDEBUG(@"DataGetFirst function missing from MDS functions list (%p).\n", &mdsFunctions);
        
        lastError = CSSMERR_CSSM_SERVICE_NOT_AVAILABLE;
    }
    
    return NO;
}

- (CSSM_RETURN)lastError {
    return lastError;
}

- (BOOL)close:(MDS_DB_HANDLE)handle {
    if (NULL != mdsFunctions.DbClose) {
        /*  CSSM_RETURN (CSSMAPI *DbClose) (MDS_DB_HANDLE MdsDbHandle); */
        
        lastError = mdsFunctions.DbClose(handle);
        
        if (CSSM_OK != lastError) {
            PCONSOLE(@"Unable to close MDS database, error #%u - %@.\n", lastError, CSSMErrorAsString(lastError));
            PDEBUG(@"mdsFunctions.DbClose(%"PRImdsdbHandle") [at address %p] returned error #%u - %@.\n", handle, mdsFunctions.DbClose, lastError, CSSMErrorAsString(lastError));
        } else {
            return YES;
        }
    } else {
        PCONSOLE(@"MDS does not provide a DbClose function.\n");
        PDEBUG(@"DbClose function missing from MDS functions list (%p).\n", &mdsFunctions);
        
        lastError = CSSMERR_CSSM_SERVICE_NOT_AVAILABLE;
    }
    
    return NO;
}

- (void)dealloc {
    lastError = MDS_Terminate(myHandle);
    
    if ((CSSM_OK != lastError) && (CSSMERR_DL_INVALID_DL_HANDLE != lastError)) {
        PCONSOLE(@"Unable to terminate MDS, error #%u - %@.\n", lastError, CSSMErrorAsString(lastError));
        PDEBUG(@"MDS_Terminate(%"PRImdsHandle") returned error #%u - %@.\n", lastError, CSSMErrorAsString(lastError));
    }
    
    [super dealloc];
}

@end
