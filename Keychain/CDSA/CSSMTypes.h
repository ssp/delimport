//
//  CSSMTypes.h
//  Keychain
//
//  Created by Wade Tregaskis on 23/5/2005.
//
//  Copyright (c) 2005 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/*! @header CSSMTypes
    @abstract Provides various facilities for working with fundamental CSSM types.
    @discussion This is really just a bridge between the Keychain framework and Apple's Security framework - it does things like provide local defines for the printf format of CSSM_CC_HANDLE, for example, so that changes to the implementation won't require a number of hardcoded PRIu64's to be modified. */

#import <inttypes.h>


/*! @constant PRImoduleHandle
	@abstract Format string specifier for the CSSM_MODULE_HANDLE type. */

#define PRImoduleHandle PRIu32

/*! @constant PRIccHandle
	@abstract Format string specifier for the CSSM_CC_HANDLE type. */

#define PRIccHandle PRIu64

/*! @constant PRIcspHandle
	@abstract Format string specifier for the CSSM_CSP_HANDLE type. */

#define PRIcspHandle PRIu32

/*! @constant PRItpHandle
	@abstract Format string specifier for the CSSM_TP_HANDLE type. */

#define PRItpHandle PRIu32

/*! @constant PRIacHandle
	@abstract Format string specifier for the CSSM_AC_HANDLE type. */

#define PRIacHandle PRIu32

/*! @constant PRIclHandle
	@abstract Format string specifier for the CSSM_CL_HANDLE type. */

#define PRIclHandle PRIu32

/*! @constant PRIdlHandle
	@abstract Format string specifier for the CSSM_DL_HANDLE type. */

#define PRIdlHandle PRIu32

/*! @constant PRIdbHandle
	@abstract Format string specifier for the CSSM_DB_HANDLE type. */

#define PRIdbHandle PRIu32

/*! @constant PRIdldbHandle
	@abstract Format string specifier for the CSSM_DL_DB_HANDLE type. */

#define PRIdldbHandle PRIdlHandle"-%"PRIdbHandle // Should work, kinda sneaky though.
//#define PRIdldbHandle "#llx"

/*! @constant PRImdsHandle
	@abstract Format string specifier for the MDS_HANDLE type. */

#define PRImdsHandle PRIdlHandle

/*! @constant PRImdsdbHandle
	@abstract Format string specifier for the MDS_DB_HANDLE type. */

#define PRImdsdbHandle PRIdldbHandle
