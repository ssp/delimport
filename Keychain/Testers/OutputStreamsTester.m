//
//  OutputStreamsTester.m
//  Keychain
//
//  Created by Wade Tregaskis on 23/5/2005.
//
//  Copyright (c) 2005, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Keychain/DigestOutputStream.h>
#import <Keychain/CSSMUtils.h>
#import <Keychain/FileUtilities.h>
#import <Keychain/NSDataAdditions.h>

#import "TestingCommon.h"


void test_digestOutputStream(void) {
    DigestOutputStream *stream;
    NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"digestOutputStreamTest"];
    //id tempObject;
    BOOL tempBool;
    int tempInt;
    
    START_TEST("DigestOutputStream");
    
    TEST_NOTE("Temporary file used for testing: %s", [tempFile UTF8String]);
    
    stream = [DigestOutputStream outputStreamToFileAtPath:tempFile append:NO];
    
    TEST(nil != stream, "+ outputStreamToFileAtPath:append: returns something");
    
    if (nil != stream) {
        tempBool = [stream isKindOfClass:[DigestOutputStream class]];
        
        TEST(tempBool, "\tResult is of class DigestOutputStream");
        
        if (tempBool) {
            [stream open];
            
            tempInt = [stream streamStatus];
                        
            TEST(NSStreamStatusError != tempInt, "\tResult is error-free after open");
            
            if (NSStreamStatusError != tempInt) {
                const int BUFFER_SIZE = sizeof(long) * 1024, ITERATIONS = 1024;
                uint8_t buffer[BUFFER_SIZE];
                int i, j, result;
                BOOL allGood = YES;
                CSSM_ALGORITHMS algorithm = [stream algorithm];
                NSData *digest;
                
                TEST_NOTE("\tResult's algorithm is %s", [nameOfAlgorithm(algorithm) UTF8String]);
                
                srandom(time(NULL));
                
                for (i = 0; allGood && (i < ITERATIONS); ++i) {
                    for (j = 0; j < (int)(BUFFER_SIZE / sizeof(long)); ++j) {
                        ((long*)buffer)[j] = random();
                    }
                    
                    result = [stream write:buffer maxLength:BUFFER_SIZE];
                    
                    if (BUFFER_SIZE != result) {
                        TEST(NO, "\tResult can be written to");
                        allGood = NO;
                    }
                }
                
                if (allGood) {
                    digest = [stream currentDigestValue];
                    
                    TEST(nil != digest, "\tCan retrieve result's final digest value");
                    
                    if (nil != digest) {
                        NSData *secondDigest, *tempData;
                        
                        TEST_NOTE("\t\tDigest is %s", [[digest description] UTF8String]);
                        
                        secondDigest = digestOfPath(tempFile, algorithm);
                        
                        TEST(nil != secondDigest, "\tdigestOfPath(%s, %u) returns a digest value", [tempFile UTF8String], (unsigned)algorithm);
                        
                        if (nil != secondDigest) {
                            TEST_NOTE("\t\t\tDigest is %s", [[digest description] UTF8String]);
                            
                            TEST([secondDigest isEqual:digest], "\t\tDigestes concur");
                        }
                        
                        tempData = [[NSFileManager defaultManager] contentsAtPath:tempFile];
                        
                        TEST(nil != tempData, "\tCan load file data manually");
                        
                        if (nil != tempData) {
                            secondDigest = [tempData digestUsingAlgorithm:algorithm];
                            
                            TEST(nil != secondDigest, "\t\tCan obtain digest using digestUsingAlgorithm:");
                            
                            if (nil != secondDigest) {
                                TEST_NOTE("\t\t\tDigest is %s", [[secondDigest description] UTF8String]);
                                
                                TEST([secondDigest isEqual:digest], "\t\tDigestes concur");
                            }
                        }
                    }
                }
            } else {
                TEST_NOTE("\t\tError: %s", [[[stream streamError] description] UTF8String]);
            }
        }
    }

    END_TEST();
}

int main(int argc, char const *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    test_digestOutputStream();
    
    [pool release];

    FINAL_SUMMARY();    
}
