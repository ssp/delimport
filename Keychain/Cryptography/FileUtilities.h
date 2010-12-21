//
//  FileUtilities.h
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

/*! @header FileUtilities
	@abstract Misc utility functions for working with files. */

#import <Foundation/Foundation.h>
#import <Security/Security.h>

#import <Keychain/CSSMModule.h>


/*! @function digestOfPath
    @abstract Calculates the digest of a file.
    @discussion This method is more efficient than reading in all the file's data at once, then using the NSData extensions provided by this framework.  It reads the file in relatively small blocks (presently a quarter of a mibibyte at most, although this is an implementation detail and should not be relied upon - it has changed in past and may change again).  Note that this method may take quite some time for large files.

                You may alternatively wish to use the various NSOutputStream subclasses - e.g. HashOutputStream - instead, as these provide more fine-grained control over the reading process.
    @param path The path to the file to digest.  Should not be nil.
    @param algorithm The digest algorithm to use.
    @param CSPModule The CSP module to use to perform the digest.
    @result Returns the digest of the entire file, or nil if an error occurs. */

NSData* digestOfPath(NSString* path, CSSM_ALGORITHMS algorithm, CSSMModule *CSPModule);
