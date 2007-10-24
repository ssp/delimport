//
//  TestingCommon.h
//  Keychain
//
//  Created by Wade Tregaskis on 17/5/2005.
//
//  Copyright (c) 2005, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include <stdio.h>


int totalErrors = 0;

#define START_TEST(description) \
            { \
                int errors = 0; \
                char *TEST_DESCRIPTION = description; \
                printf("Testing: %s.\n", description);

#define TEST(condition, description, ...) \
            printf("\t"); \
            printf(description, ## __VA_ARGS__); \
            printf(" - "); \
            fflush(stdout); \
            if (condition) { \
                printf("passed.\n"); \
            } else { \
                ++errors; \
                printf("FAILED (file %s, function %s, line %d).\n", __FILE__, __func__, __LINE__); \
            }

#define TEST_NOTE(description, ...) \
            printf("\t"); \
            printf(description, ## __VA_ARGS__); \
            printf("\n");

#define END_TEST() \
                totalErrors += errors; \
                if (0 < errors) { \
                    printf("%d error%s for %s.\n", errors, ((1 < errors) ? "s" : ""), TEST_DESCRIPTION); \
                } \
            }

#define FINAL_SUMMARY() \
            if (0 < totalErrors) { \
                printf("Total number of errors: %d.\n", totalErrors); \
                return -1; \
            } else { \
                return 0; \
            }
