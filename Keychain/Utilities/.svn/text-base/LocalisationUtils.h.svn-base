//
//  LocalisationUtils.h
//  Keychain
//
//  Created by Wade Tregaskis on Fri Jun 30 2006.
//
//  Copyright (c) 2006 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/*! @header LocalisationUtils
	@abstract Functions for working with localised strings and localisation issues in general. */

#include <Foundation/Foundation.h>


/*! @function localizedStringWithFallback
	@abstract Returns a localised string for the given key in a given table, or a placeholder string if no such key is found in the table.
	@discussion This is the preferred method for acquiring localised strings.  If the desired string cannot be found, a string of the format "Unknown (ARG)" is returned, where ARG is the key provided to this function.  This fallback string may be localised.
	@param key The key to lookup.  Should not be nil.
	@param table The name of the table to look in.  Should not be nil.
	@result Returns the localised string for the given key in the given table, or if it doesn't exist a localised string of the format "Unknown (ARG)" where ARG is the key argument provided. */

NSString* localizedStringWithFallback(NSString *key, NSString *table);

/*! @function localizedString
	@abstract Returns a localised string for the given key in a given table, or nil if no such key is found in the table.
	@discussion If the desired string cannot be found, nil is returned.  You may, in some circumstances, wish to use @link localizedStringWithFallback localizedStringWithFallback@/link instead.
	@param key The key to lookup.  Should not be nil.
	@param table The name of the table to look in.  Should not be nil.
	@result Returns the localised string for the given key in the given table, or nil if it doesn't exist. */

NSString* localizedString(NSString *key, NSString *table);
