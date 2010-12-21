//
//  LocalisationUtils.m
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

#import "LocalisationUtils.h"

#import "Logging.h"


NSString* KEYCHAIN_BUNDLE_IDENTIFIER = @"Keychain.framework";


#define UNKNOWN (NSLocalizedStringFromTableInBundle(@"Unknown", @"Misc Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil))


NSString* localizedString(NSString *key, NSString *table) {
    /* I assume NSLocalizedStringFromTableInBundle can handle a nil key or table name, so that we don't have to explicitly; a nil result is of course perfectly fine for us. */
    NSString *sentinel = @"\r\n";
    NSString *result = [[NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER] localizedStringForKey:key value:sentinel table:table];
    
    if (!result || (result == sentinel) /*|| [result isEqualToString:sentinel]*/) {
        result = nil;
    }
    
    return result;
}

NSString* localizedStringWithFallback(NSString *key, NSString *table) {
    NSString *result = localizedString(key, table);
    
    if (!result) {
        /* If we can't obtain a match, we lookup a localized "unknown" string.  This is actually a format string, into which we will provide the parameters of this function for use as desired.  In addition, we'll PDEBUG here so that these problems can be more directly noticed & diagnosed by the developer. */
        
        //PDEBUG(@"Could not find key \"%@\" in/or table \"%@\".\n", key, table);
        
        result = UNKNOWN;
        
        if (!result) { /* At this point things are getting silly. */
            result = @"Unknown (%@)";
        }
        
        result = [NSString stringWithFormat:result, key, table];
    }

    return result;
}
