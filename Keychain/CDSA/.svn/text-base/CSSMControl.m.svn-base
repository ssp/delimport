//
//  CSSMControl.m
//  Keychain
//
//  Created by Wade Tregaskis on Sat Mar 15 2003.
//
//  Copyright (c) 2003 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "CSSMControl.h"

#import "CSSMDefaults.h"
#import "CSSMUtils.h"
#import "CSSMTypes.h"

#import "Utilities/Logging.h"


CSSM_VERSION defaultVersion = {2, 0};
CSSM_GUID defaultGUID;
CSSM_PRIVILEGE_SCOPE defaultScope = CSSM_PRIVILEGE_SCOPE_PROCESS;
CSSM_ACCESS_CREDENTIALS defaultCredentials;
CSSM_KEY_HIERARCHY defaultHierarchy = CSSM_KEY_HIERARCHY_NONE;
CSSM_PVC_MODE defaultPVCPolicy = CSSM_PVC_NONE;

bool cssmReady = false;


BOOL zeroBuffers = YES;


void keychainInit(void) {
    static BOOL haveDoneInit = NO;
    
    if (!haveDoneInit) {
		int i;
		
		haveDoneInit = YES;
		
		memset(&defaultCredentials, 0, sizeof(CSSM_ACCESS_CREDENTIALS));
		
#if __DARWIN_UNIX03
		srandom((unsigned int)time(NULL));
#else
		srandom(time(NULL));
#endif
		
		defaultGUID.Data1 = (uint32_t)random();
		defaultGUID.Data2 = (uint32_t)random();
		defaultGUID.Data3 = (uint32_t)random();
		
		for (i = 0; i < 16; i += 4) {
			*((uint32_t*)(&(keychainFrameworkInitVector[i]))) = (uint32_t)random();
		}
    }
}


CSSM_VERSION keychainFrameworkDefaultCSSMVersion(void) {
    return defaultVersion;
}

const CSSM_GUID* keychainFrameworkDefaultGUID(void) {
    keychainInit();

    return &defaultGUID;
}

CSSM_KEY_HIERARCHY keychainFrameworkDefaultKeyHierarchy(void) {
    return defaultHierarchy;
}

CSSM_PVC_MODE keychainFrameworkDefaultPVCPolicy(void) {
    return defaultPVCPolicy;
}

CSSM_PRIVILEGE_SCOPE keychainFrameworkDefaultPrivilegeScope(void) {
    return defaultScope;
}

CSSM_ACCESS_CREDENTIALS* keychainFrameworkDefaultCredentials(void) {
    keychainInit();
    
    return &defaultCredentials;
}

bool cssmInit(const CSSM_VERSION *customVersion, CSSM_PRIVILEGE_SCOPE customScope, const CSSM_GUID *customGUID, CSSM_KEY_HIERARCHY customHierarchy, CSSM_PVC_MODE customPolicy, const void *customReserved) {
    CSSM_RETURN err;
    
    if (!cssmReady) {
        keychainInit();
        
        if (CSSM_OK == (err = CSSM_Init((NULL == customVersion) ? &defaultVersion : customVersion,
                                        customScope,
                                        (NULL == customGUID) ? &defaultGUID : customGUID,
                                        customHierarchy,
                                        &customPolicy,
                                        customReserved))) {
            cssmReady = true;
        } else {
			// We can't use any Cocoa stuff here (including CSSMErrorAsString, GUIDAsString, etc) because we explicitly allow this function to be called prior to initialisation of Foundation et al.
			
            PSYSLOGCND(LOG_ERR, "Unable to initialize CSSM because of error #%"PRIu32".\n", (uint32_t)err);
            PDEBUGC("CSSM_Init({%"PRIu32", %"PRIu32"}, %"PRIu32", ?, %"PRIu32", %p (%"PRIu32"), %p) returned error #%"PRIu32".\n",
                   (uint32_t)((NULL == customVersion) ? defaultVersion.Major : customVersion->Major),
                   (uint32_t)((NULL == customVersion) ? defaultVersion.Minor : customVersion->Minor),
                   (uint32_t)customScope,
                   /*GUIDAsString((NULL == customGUID) ? &defaultGUID : customGUID),*/
                   (uint32_t)customHierarchy,
                   &customPolicy,
                   (uint32_t)customPolicy,
                   customReserved,
                   (uint32_t)err);
        }
    }
    
    return cssmReady;
}

void cssmEnd(void) {
    if (cssmReady) {
        cssmReady = false;
        CSSM_Terminate();
    }
}

void setKeychainFrameworkShouldZeroBuffersBeforeFree(bool shouldZeroBuffers) {
    zeroBuffers = shouldZeroBuffers;
}
