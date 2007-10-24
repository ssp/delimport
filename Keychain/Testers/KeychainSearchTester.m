//
//  KeychainSearchTester.m
//  Keychain
//
//  Created by Wade Tregaskis on 11/6/2006.
//
//  Copyright (c) 2006, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without creation, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Keychain/Keychain.h>
#import <Keychain/KeychainSearch.h>

#import "TestingCommon.h"


void test_keychainSearchByAccount(void) {
    KeychainSearch *search;
    NSArray *results;
    
    START_TEST("KeychainSearch by account");
    
    srandom(time(NULL));
    
    search = [KeychainSearch keychainSearchWithKeychains:nil];
    
    TEST(nil != (results = [search anySearchResults]), "Able to obtain results from blanket search (i.e. list)");
    
    if (nil != results) {
        TEST(0 < [results count], "\tHave at least one result");
        
        if (0 < [results count]) {
            unsigned int randomIndex = random() % [results count];
            
            TEST_NOTE("Randomly choosing element at index %u", randomIndex);
            
            KeychainItem *selection = [results objectAtIndex:randomIndex];
            
            TEST_NOTE("\tItem is: %s", [[selection description] UTF8String]);
            
            NSString *account = [selection account];
            
            TEST_NOTE("\tItem's account is: %s", [account UTF8String]);
            
            [search setAccount:account];
            
            NSArray *refinedResults;
            
            TEST(nil != (refinedResults = [search anySearchResults]), "Able to refine search");
            
            if (nil != refinedResults) {
                TEST(0 < [refinedResults count], "There is at least one result from refined search");
                
                if (0 < [refinedResults count]) {
                    NSEnumerator *enumerator = [refinedResults objectEnumerator];
                    KeychainItem *current;
                    BOOL allHaveSame = YES;
                    BOOL amMissingResults = NO;
                    
                    while (current = [enumerator nextObject]) {
                        if (![account isEqualTo:[current account]]) {
                            allHaveSame = NO;
                            
                            TEST_NOTE("\tRefined result with different value: %s (%s)", [[current description] UTF8String], [[current account] UTF8String]);
                        }
                    }
                    
                    TEST(allHaveSame, "All results have the expected value");
                    
                    enumerator = [results objectEnumerator];
                    
                    while (current = [enumerator nextObject]) {
                        if ([account isEqualTo:[current account]]) {
                            if (![refinedResults containsObject:current]) {
                                amMissingResults = YES;
                                
                                TEST_NOTE("\tMissing result: %s", [[current description] UTF8String]);
                            }
                        }
                    }
                    
                    TEST(!amMissingResults, "All expected results were returned");
                }
            }
        }
    }
    
    END_TEST();
}

void test_keychainSearch(void) {
    KeychainSearch *search;
    NSArray *results;
    
    START_TEST("KeychainSearch");
    
    srandom(time(NULL));
    
    search = [KeychainSearch keychainSearchWithKeychains:nil];
    
    TEST(nil != (results = [search anySearchResults]), "Able to obtain results from blanket search (i.e. list)");
    
    if (nil != results) {
        TEST(0 < [results count], "\tHave at least one result");
        
        if (0 < [results count]) {
            unsigned int randomIndex = random() % [results count];
            
            TEST_NOTE("Randomly choosing element at index %u", randomIndex);
            
            KeychainItem *selection = [results objectAtIndex:randomIndex];
            
            TEST_NOTE("\tItem is: %s", [[selection description] UTF8String]);
            
            NSCalendarDate *creationDate = [selection creationDate];
            
            TEST_NOTE("\tItem's creation date is: %s (%f)", [[creationDate description] UTF8String], [creationDate timeIntervalSince1970]);
            
            [search setCreationDate:creationDate];
            
            NSArray *refinedResults;
            
            TEST(nil != (refinedResults = [search anySearchResults]), "Able to refine search based on creation date");
            
            if (nil != refinedResults) {
                TEST(0 < [refinedResults count], "There is at least one result from refined search");
                
                if (0 < [refinedResults count]) {
                    NSEnumerator *enumerator = [refinedResults objectEnumerator];
                    KeychainItem *current;
                    BOOL allHaveSameCreationDate = YES;
                    BOOL amMissingResults = NO;
                    
                    while (current = [enumerator nextObject]) {
                        if (![creationDate isEqualTo:[current creationDate]]) {
                            allHaveSameCreationDate = NO;
                            
                            TEST_NOTE("\tRefined result with different creation date: %s", [[current description] UTF8String]);
                        }
                    }
                    
                    TEST(allHaveSameCreationDate, "All results have the expected creation date");
                    
                    enumerator = [results objectEnumerator];
                    
                    while (current = [enumerator nextObject]) {
                        if ([creationDate isEqualTo:[current creationDate]]) {
                            if (![refinedResults containsObject:current]) {
                                amMissingResults = YES;
                                
                                TEST_NOTE("\tMissing result: %s", [[current description] UTF8String]);
                            }
                        }
                    }
                    
                    TEST(!amMissingResults, "All expected results were returned");
                }
            }
        }
    }
    
    END_TEST();
}

int main(int argc, char const *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    test_keychainSearchByAccount();
    test_keychainSearch();
    
    [pool release];
    
    FINAL_SUMMARY();    
}
