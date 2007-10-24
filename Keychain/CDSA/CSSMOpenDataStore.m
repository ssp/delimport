//
//  CSSMOpenDataStore.m
//  Keychain
//
//  Created by Wade Tregaskis on 30/7/2005.
//
//  Copyright (c) 2006, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "CSSMOpenDataStore.h"
#import "Logging.h"
#import "CSSMUtils.h"
#import "UtilitySupport.h"
#import "CSSMTypes.h"

#import <Security/cssmapi.h>


@implementation CSSMOpenDataStore

+ (CSSMOpenDataStore*)openDataStoreWithHandle:(CSSM_DL_DB_HANDLE)handle {
    return [[[[self class] alloc] initWithHandle:handle] autorelease];
}

- (CSSMOpenDataStore*)initWithHandle:(CSSM_DL_DB_HANDLE)handle {
    if (self = [super init]) {
        myHandle = handle;
    }
    
    return self;
}

- (id)init {
    PDEBUG(@"Must use designated initialiser, initWithHandle:, to initialise a CSSMOpenDataStore.\n");
    
    [self release];
    return nil;
}

- (CSSM_RETURN)authenticateFor:(CSSM_DB_ACCESS_TYPE)access withCredentials:(const CSSM_ACCESS_CREDENTIALS*)credentials {
    CSSM_RETURN result = CSSM_DL_Authenticate(myHandle, access, credentials);
    
    if (CSSM_OK != result) {
        PDEBUG(@"CSSM_DL_Authenticate({%"PRIdlHandle", %"PRIdbHandle"}, 0x%x, %p) failed with error #%u - %@.\n", myHandle.DLHandle, myHandle.DBHandle, access, credentials, result, CSSMErrorAsString(result));
        return NO;
    } else {
        return YES;
    }
}

- (NSArray*)ACLEntriesWithTag:(NSString*)tag {
    CSSM_STRING theTag;
    uint32_t numberOfEntries;
    CSSM_ACL_ENTRY_INFO *result;
    CSSM_RETURN err;
    
    if (nil != tag) {
        copyNSStringToString(tag, &theTag);
    }

    err = CSSM_DL_GetDbAcl(myHandle, (const CSSM_STRING*)((nil != tag) ? &theTag : NULL), (uint32*)&numberOfEntries, &result);
    
    if (CSSM_OK == err) {
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:numberOfEntries];
        uint32_t i;
        
        for (i = 0; i < numberOfEntries; ++i) {
            [result addObject:[CSSMACLEntry entryWithEntry:&(result[i])]];
        }
        
        return result;
    } else {
        PDEBUG(@"CSSM_DL_GetDbAcl({%"PRIdlHandle", %"PRIdbHandle"}, %p, %p [%d], %p [%"PRIdbHandle"]) returned error #%u - %@.\n", myHandle.DLHandle, myHandle.DBHandle, ((nil != tag) ? &theTag : NULL), &numberOfEntries, numberOfEntries, &result, result);
        return nil;
    }
}

- (NSArray*)ACLEntries {
    return [self ACLEntriesWithTag:nil];
}

/*CSSM_RETURN CSSMAPI CSSM_DL_ChangeDbAcl
(CSSM_DL_DB_HANDLE DLDBHandle,
 const CSSM_ACCESS_CREDENTIALS *AccessCred,
 const CSSM_ACL_EDIT *AclEdit)*/

- (CSSM_DL_DB_HANDLE)handle {
    return myHandle;
}

@end
