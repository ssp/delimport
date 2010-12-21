//
//  FileUtilities.m
//  Keychain
//
//  Created by Wade Tregaskis on Sun Jan 25 2004.
//  
//  Copyright (c) 2004 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "FileUtilities.h"

#import <sys/types.h>
#import <sys/uio.h>
#import <unistd.h>
#import <sys/stat.h>
#import <fcntl.h>

#import "CDSA/CSSMUtils.h"
#import "CDSA/CSSMControl.h"
#import "CDSA/CSSMTypes.h"
#import "CDSA/CSSMModule.h"

#import "Utilities/UtilitySupport.h"
#import "Utilities/Logging.h"


NSData* digestOfPath(NSString* path, CSSM_ALGORITHMS algorithm, CSSMModule *CSPModule) {
    CSSM_RETURN err;
    CSSM_CC_HANDLE ccHandle;
    CSSM_DATA result, original;
    NSData *finalResult = nil;
    int theFile;
    const size_t BUFFER_SIZE = 262144;
    size_t bufferSize;
    struct stat fileStats;
    
    if (nil == CSPModule) {
        CSPModule = [CSSMModule defaultCSPModule];
    }
    
    if ((err = CSSM_CSP_CreateDigestContext([CSPModule handle], algorithm, &ccHandle)) == CSSM_OK) {
        if ((err = CSSM_DigestDataInit(ccHandle)) == CSSM_OK) {
            theFile = open([path fileSystemRepresentation], O_RDONLY, 0);
            
            if (theFile >= 0) {
                if (0 == fstat(theFile, &fileStats)) {
                    if ((size_t)fileStats.st_size < BUFFER_SIZE) {
                        bufferSize = (size_t)fileStats.st_size;
                    } else if (((size_t)fileStats.st_size / 2) < BUFFER_SIZE) {
                        bufferSize = (size_t)fileStats.st_size / 2;
                    } else if (((size_t)fileStats.st_size / 3) < BUFFER_SIZE) {
                        bufferSize = (size_t)fileStats.st_size / 3;
                    } else {
                        bufferSize = BUFFER_SIZE; // 1/4 mibibyte at a time
                    }
                    
                    original.Data = malloc(bufferSize);
                    
                    while ((original.Length = (uint32_t)read(theFile, original.Data, bufferSize)) > 0) {
                        if ((err = CSSM_DigestDataUpdate(ccHandle, &original, 1)) != CSSM_OK) {
                            PSYSLOGND(LOG_ERR, @"Unable to generate digest because of error %@.\n", CSSMErrorAsString(err));
                            PDEBUG(@"CSSM_DigestDataUpdate(%"PRIccHandle", %p, 1) returned error %@.\n", ccHandle, &original, CSSMErrorAsString(err));
                            
                            free(original.Data);
                            
                            return nil;
                        }
                    }
                    
                    if (original.Length >= 0) {
                        result.Length = 0;
                        result.Data = NULL;
                        
                        if ((err = CSSM_DigestDataFinal(ccHandle, &result)) == CSSM_OK) {
                            finalResult = NSDataFromDataNoCopy(&result, YES);
                        } else {
                            PSYSLOGND(LOG_ERR, @"Unable to retrieve final digest because of error %@.\n", CSSMErrorAsString(err));
                            PDEBUG(@"CSSM_DigestDataFinal(%"PRIccHandle", %p) returned error %@.\n", ccHandle, &result, CSSMErrorAsString(err));
                        }
                        
                        if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
                            PSYSLOGND(LOG_WARNING, @"Failed to destroy digest context because of error %@.\n", CSSMErrorAsString(err));
                            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
                        }
                    } else {
                        PSYSLOGND(LOG_ERR, @"Unable to read from file because of error #%d (%s).\n", errno, strerror(errno));
                        PDEBUG(@"read(%d, %p, %d) returned error #%d (%s).\n", theFile, original.Data, bufferSize, errno, strerror(errno));
                    }
                    
                    free(original.Data);
                } else {
                    PSYSLOGND(LOG_ERR, @"Unable to stat file to determine length because of error #%d (%s).\n", errno, strerror(errno));
                    PDEBUG(@"fstat(%d, %p) returned error #%d (%s).\n", theFile, &fileStats, errno, strerror(errno));
                }
            } else {
                PSYSLOGND(LOG_ERR, @"Unable to calculate digest of file \"%@\" because it does not exist or is not readable (error #%d (%s)).\n", path, errno, strerror(errno));
                PDEBUG(@"open(\"%@\", O_RDONLY, 0) returned error #%d (%s).\n", path, errno, strerror(errno));
            }
        } else {
            PSYSLOGND(LOG_ERR, @"Unable to initialise digest because of error %@.\n", CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DigestDataInit(%"PRIccHandle") returned error %@.\n", ccHandle, CSSMErrorAsString(err));
        }
    } else {
        PSYSLOGND(LOG_ERR, @"Unable to create digest context because of error %@.\n", CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateDigestContext(X, %d, %p [%"PRIccHandle"]) returned error %@.\n", algorithm, &ccHandle, ccHandle, CSSMErrorAsString(err));
    }
    
    return finalResult;
}
