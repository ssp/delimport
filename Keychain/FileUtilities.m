//
//  FileUtilities.m
//  Keychain
//
//  Created by Wade Tregaskis on Sun Jan 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "FileUtilities.h"

#import <sys/types.h>
#import <sys/uio.h>
#import <unistd.h>
#import <sys/stat.h>
#import <fcntl.h>

#import "CSSMUtils.h"
#import "CSSMControl.h"
#import "CSSMTypes.h"
#import "CSSMModule.h"

#import "UtilitySupport.h"
#import "Logging.h"


NSData* digestOfPath(NSString* path, CSSM_ALGORITHMS algorithm) {
    CSSM_RETURN err;
    CSSM_CC_HANDLE ccHandle;
    CSSM_DATA result, original;
    NSData *finalResult = nil;
    int theFile;
    const unsigned long BUFFER_SIZE = 262144;
    unsigned long bufferSize;
    struct stat fileStats;
    
    if ((err = CSSM_CSP_CreateDigestContext([[CSSMModule defaultCSPModule] handle], algorithm, &ccHandle)) == CSSM_OK) {
        if ((err = CSSM_DigestDataInit(ccHandle)) == CSSM_OK) {
            theFile = open([path UTF8String], O_RDONLY, 0);
            
            if (theFile >= 0) {
                if (0 == fstat(theFile, &fileStats)) {
                    if (fileStats.st_size < BUFFER_SIZE) {
                        bufferSize = fileStats.st_size;
                    } else if ((fileStats.st_size / 2) < BUFFER_SIZE) {
                        bufferSize = fileStats.st_size / 2;
                    } else if ((fileStats.st_size / 3) < BUFFER_SIZE) {
                        bufferSize = fileStats.st_size / 3;
                    } else {
                        bufferSize = BUFFER_SIZE; // 1/4 mibibyte at a time
                    }
                    
                    original.Data = malloc(bufferSize);
                    
                    while ((original.Length = read(theFile, original.Data, bufferSize)) > 0) {
                        if ((err = CSSM_DigestDataUpdate(ccHandle, &original, 1)) != CSSM_OK) {
                            PCONSOLE(@"Unable to generate digest because of error #%u - %@.\n", err, CSSMErrorAsString(err));
                            PDEBUG(@"CSSM_DigestDataUpdate(%"PRIccHandle", %p, 1) returned error #%u (%@).\n", ccHandle, &original, err, CSSMErrorAsString(err));
                            
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
                            PCONSOLE(@"Unable to retrieve final digest because of error #%u - %@.\n", err, CSSMErrorAsString(err));
                            PDEBUG(@"CSSM_DigestDataFinal(%"PRIccHandle", %p) returned error #%u (%@).\n", ccHandle, &result, err, CSSMErrorAsString(err));
                        }
                        
                        if ((err = CSSM_DeleteContext(ccHandle)) != CSSM_OK) {
                            PCONSOLE(@"Warning: Failed to destroy digest context because of error #%u - %@.\n", err, CSSMErrorAsString(err));
                            PDEBUG(@"CSSM_DeleteContext(%"PRIccHandle") returned error #%u (%@).\n", ccHandle, err, CSSMErrorAsString(err));
                        }
                    } else {
                        PCONSOLE(@"Unable to read from file because of error #%d (%s).\n", errno, strerror(errno));
                        PDEBUG(@"read(%d, %p, %d) returned error #%d (%s).\n", theFile, original.Data, bufferSize, errno, strerror(errno));
                    }
                    
                    free(original.Data);
                } else {
                    PCONSOLE(@"Unable to stat file to determine length because of error #%d (%s).\n", errno, strerror(errno));
                    PDEBUG(@"fstat(%d, %p) returned error #%d (%s).\n", theFile, &fileStats, errno, strerror(errno));
                }
            } else {
                PCONSOLE(@"Unable to calculate digest of file \"%@\" because it does not exist or is not readable (error #%d (%s)).\n", path, errno, strerror(errno));
                PDEBUG(@"open(\"%@\", O_RDONLY, 0) returned error #%d (%s).\n", path, errno, strerror(errno));
            }
        } else {
            PCONSOLE(@"Unable to initialise digest because of error #%u - %@.\n", err, CSSMErrorAsString(err));
            PDEBUG(@"CSSM_DigestDataInit(%"PRIccHandle") returned error #%u (%@).\n", ccHandle, err, CSSMErrorAsString(err));
        }
    } else {
        PCONSOLE(@"Unable to create digest context because of error #%u - %@.\n", err, CSSMErrorAsString(err));
        PDEBUG(@"CSSM_CSP_CreateDigestContext(X, %d, %p [%"PRIccHandle"]) returned error #%u (%@).\n", algorithm, &ccHandle, ccHandle, err, CSSMErrorAsString(err));
    }
    
    return finalResult;
}
