//
//  KeychainSearchInternal.h
//  Keychain
//
//  Created by Wade Tregaskis on Sun Oct 14 2007.
//
//  Copyright (c) 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>
#import <Security/Security.h>


/*! @class SearchAttribute
    @abstract A simple class representing a single search attribute.
    @discussion You use this class to specify attributes of interest in a KeychainSearch.  This class is itself very straightforward; refer to the documentation for KeychainSearch for the details of searching.

                At present this class is used only internally within the KeychainSearch class.  An API for specifying it manually may be provided, on KeychainSearch, at a later date. */

@interface SearchAttribute : NSObject {
    SecKeychainAttribute attribute;
    BOOL freeWhenDone;
}

+ (SearchAttribute*)attributeWithTag:(SecKeychainAttrType)tag length:(size_t)length data:(void*)data freeWhenDone:(BOOL)fre;
+ (SearchAttribute*)attributeWithTag:(SecKeychainAttrType)tag length:(size_t)length data:(const void *)data;

- (SearchAttribute*)initWithTag:(SecKeychainAttrType)tag length:(size_t)length data:(void*)data freeWhenDone:(BOOL)fre;
- (SearchAttribute*)initWithTag:(SecKeychainAttrType)tag length:(size_t)length data:(const void *)data;

/*! @method init
    @abstract Reject initialiser.
    @discussion You cannot initialise a SearchAttribute using "init" - use one of the other initialisation methods.
    @result This method always releases the receiver and returns nil. */

- (SearchAttribute*)init;

- (SecKeychainAttributePtr)attributePtr;

@end
