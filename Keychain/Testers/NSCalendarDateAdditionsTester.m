//
//  NSCalendarDateAdditionsTester.m
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

#import <Keychain/NSCalendarDateAdditions.h>

#import "TestingCommon.h"


#define EPSILON 0.000001


void test_NSCalendarDateAdditions(void) {
    NSCalendarDate *date, *reference;
    int years, months, days, hours, minutes, seconds;
    double fractionalSeconds;
    
    START_TEST("NSCalendarDate (KeychainAdditions)");
    
    date = [NSCalendarDate dateWithYear:2005 month:5 day:17 hour:15 minute:26 second:11 fractionalSecond:0.0 timeZone:nil];
    
    TEST(nil != date, "+ dateWithYear:month:day:hour:minute:second:fractionalSecond:timeZone: for 3:26:11.0 17/5/2005 (no timezone) returns non-nil");
    
    if (date) {
        TEST(EPSILON > fabs([date fractionalSecond]), "\tResult has fractional second of 0.0");
        
        reference = [NSCalendarDate dateWithYear:2005 month:5 day:17 hour:15 minute:26 second:11 timeZone:nil];

        TEST([reference isEqualToDate:date], "\tResult matches reference NSCalendarDate for 3:26:11 17/5/2005 (no timezone)");
        
        [date years:&years months:&months days:&days hours:&hours minutes:&minutes seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
        
        TEST((0 == years) && (0 == months) && (0 == days) && (0 == hours) && (0 == minutes) && (0 == seconds) && (EPSILON > fabs(fractionalSeconds)), "\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with all fields) returns correct result");
        
        [date years:NULL months:NULL days:NULL hours:NULL minutes:NULL seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
        
        TEST((0 == seconds) && (EPSILON > fabs(fractionalSeconds)), "\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with only seconds & fractional seconds) returns correct result");
        
        date = [date dateByAddingYears:1 months:0 days:0 hours:0 minutes:0 seconds:0 fractionalSeconds:0.0];
        
        TEST(nil != date, "\t- dateByAddingYears:months:days:hours:minutes:seconds:fractionalSeconds: for one year ahead returns valid result");
        
        if (date) {
            TEST(![reference isEqualToDate:date], "\t\tResult does not match reference (original date)");
            
            [date years:&years months:&months days:&days hours:&hours minutes:&minutes seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
            
            TEST((1 == years) && (0 == months) && (0 == days) && (0 == hours) && (0 == minutes) && (0 == seconds) && (EPSILON > fabs(fractionalSeconds)), "\t\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with all fields) returns correct result");
        }
    }
    
    date = [NSCalendarDate dateWithYear:2005 month:5 day:17 hour:15 minute:26 second:11 fractionalSecond:0.0 timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    TEST(nil != date, "+ dateWithYear:month:day:hour:minute:second:fractionalSecond:timeZone: for 3:26:11.0 17/5/2005 GMT returns non-nil");
    
    if (date) {
        TEST(EPSILON > fabs([date fractionalSecond]), "\tResult has fractional second of 0.0");

        reference = [NSCalendarDate dateWithYear:2005 month:5 day:17 hour:15 minute:26 second:11 timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        TEST([reference isEqualToDate:date], "\tResult matches reference NSCalendarDate for 3:26:11 17/5/2005 GMT");
        
        [date years:&years months:&months days:&days hours:&hours minutes:&minutes seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
        
        TEST((0 == years) && (0 == months) && (0 == days) && (0 == hours) && (0 == minutes) && (0 == seconds) && (EPSILON > fabs(fractionalSeconds)), "\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with all fields) returns correct result");
        
        [date years:NULL months:NULL days:NULL hours:NULL minutes:NULL seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
        
        TEST((0 == seconds) && (EPSILON > fabs(fractionalSeconds)), "\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with only seconds & fractional seconds) returns correct result");
        
        date = [date dateByAddingYears:0 months:0 days:0 hours:0 minutes:0 seconds:0 fractionalSeconds:0.23];
        
        TEST(nil != date, "\t- dateByAddingYears:months:days:hours:minutes:seconds:fractionalSeconds: for 0.23 seconds ahead returns valid result");
        
        if (date) {
            TEST(![reference isEqualToDate:date], "\t\tResult does not match reference (original date)");
            
            [date years:&years months:&months days:&days hours:&hours minutes:&minutes seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
            
            TEST((0 == years) && (0 == months) && (0 == days) && (0 == hours) && (0 == minutes) && (0 == seconds) && (EPSILON > fabs(fractionalSeconds - 0.23)), "\t\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with all fields) returns correct result");
        }
    }
    
    date = [NSCalendarDate dateWithYear:2005 month:5 day:17 hour:15 minute:26 second:11 fractionalSecond:0.23 timeZone:nil];
    
    TEST(nil != date, "+ dateWithYear:month:day:hour:minute:second:fractionalSecond:timeZone: for 3:26:11.23 17/5/2005 (no timezone) returns non-nil");
    
    if (date) {
        TEST(EPSILON > (fabs([date fractionalSecond] - 0.23)), "\tResult has fractional second of 0.23");

        reference = [NSCalendarDate dateWithYear:2005 month:5 day:17 hour:15 minute:26 second:11 timeZone:nil];
        
        TEST(![reference isEqualToDate:date], "\tResult does not match reference NSCalendarDate for 3:26:11 17/5/2005 (no timezone)");
        
        [date years:&years months:&months days:&days hours:&hours minutes:&minutes seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
        
        TEST((0 == years) && (0 == months) && (0 == days) && (0 == hours) && (0 == minutes) && (0 == seconds) && (EPSILON > fabs(fractionalSeconds - 0.23)), "\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with all fields) returns correct result");
        
        [date years:NULL months:NULL days:NULL hours:NULL minutes:NULL seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
        
        TEST((0 == seconds) && (EPSILON > fabs(fractionalSeconds - 0.23)), "\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with only seconds & fractional seconds) returns correct result");
        
        reference = [reference addTimeInterval:0.23];
        
        TEST([reference isEqualToDate:date], "\tResult matches reference NSCalendarDate for 3:26:11.23 17/5/2005 (no timezone)");
        
        [date years:&years months:&months days:&days hours:&hours minutes:&minutes seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
        
        TEST((0 == years) && (0 == months) && (0 == days) && (0 == hours) && (0 == minutes) && (0 == seconds) && (EPSILON > fabs(fractionalSeconds)), "\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with all fields) returns correct result");
        
        [date years:NULL months:NULL days:NULL hours:NULL minutes:NULL seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
        
        TEST((0 == seconds) && (EPSILON > fabs(fractionalSeconds)), "\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with only seconds & fractional seconds) returns correct result");
        
        date = [date dateByAddingYears:0 months:0 days:0 hours:0 minutes:0 seconds:-5 fractionalSeconds:0.0];
        
        TEST(nil != date, "\t- dateByAddingYears:months:days:hours:minutes:seconds:fractionalSeconds: for 5 seconds behind returns valid result");
        
        if (date) {
            TEST(![reference isEqualToDate:date], "\t\tResult does not match reference (original date)");
            
            [date years:&years months:&months days:&days hours:&hours minutes:&minutes seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
            
            TEST((0 == years) && (0 == months) && (0 == days) && (0 == hours) && (0 == minutes) && (-5 == seconds) && (EPSILON > fabs(fractionalSeconds)), "\t\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with all fields) returns correct result");
            
            [date years:NULL months:NULL days:NULL hours:NULL minutes:NULL seconds:NULL fractionalSeconds:&fractionalSeconds sinceDate:reference];
            
            printf("result = %f\n", fractionalSeconds);
            
            TEST(EPSILON > fabs(fractionalSeconds + 5.0), "\t\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with only fractional seconds) returns correct result");
        }
    }
    
    date = [NSCalendarDate dateWithYear:2005 month:5 day:17 hour:15 minute:26 second:11 fractionalSecond:0.23 timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    TEST(nil != date, "+ dateWithYear:month:day:hour:minute:second:fractionalSecond:timeZone: for 3:26:11.23 17/5/2005 GMT returns non-nil");
    
    if (date) {
        TEST(EPSILON > (fabs([date fractionalSecond] - 0.23)), "\tResult has fractional second of 0.23");

        reference = [NSCalendarDate dateWithYear:2005 month:5 day:17 hour:15 minute:26 second:11 timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        TEST(![reference isEqualToDate:date], "\tResult does not match reference NSCalendarDate for 3:26:11 17/5/2005 GMT");
        
        [date years:&years months:&months days:&days hours:&hours minutes:&minutes seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
        
        TEST((0 == years) && (0 == months) && (0 == days) && (0 == hours) && (0 == minutes) && (0 == seconds) && (EPSILON > fabs(fractionalSeconds - 0.23)), "\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with all fields) returns correct result");
        
        [date years:NULL months:NULL days:NULL hours:NULL minutes:NULL seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
        
        TEST((0 == years) && (0 == months) && (0 == days) && (0 == hours) && (0 == minutes) && (0 == seconds) && (EPSILON > fabs(fractionalSeconds - 0.23)), "\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with only seconds & fractional seconds) returns correct result");
        
        reference = [reference addTimeInterval:0.23];
        
        TEST([reference isEqualToDate:date], "\tResult matches reference NSCalendarDate for 3:26:11.23 17/5/2005 GMT");
        
        [date years:&years months:&months days:&days hours:&hours minutes:&minutes seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
        
        TEST((0 == years) && (0 == months) && (0 == days) && (0 == hours) && (0 == minutes) && (0 == seconds) && (EPSILON > fabs(fractionalSeconds)), "\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with all fields) returns correct result");
        
        [date years:NULL months:NULL days:NULL hours:NULL minutes:NULL seconds:&seconds fractionalSeconds:&fractionalSeconds sinceDate:reference];
        
        TEST((0 == years) && (0 == months) && (0 == days) && (0 == hours) && (0 == minutes) && (0 == seconds) && (EPSILON > fabs(fractionalSeconds)), "\t- years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate: (with only seconds & fractional seconds) returns correct result");
    }

    reference = [NSCalendarDate dateWithYear:2005 month:5 day:17 hour:15 minute:26 second:11 timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    date = [reference dateByAddingYears:5 months:3 days:15 hours:-6 minutes:-54 seconds:0 fractionalSeconds:0.0];
    reference = [reference dateByAddingYears:5 months:3 days:15 hours:-6 minutes:-54 seconds:0];
    
    TEST([date isEqualToDate:reference], "dateByAddingYears:months:days:hours:minutes:seconds:fractionalSeconds: is equivalent to dateByAddingYears:months:days:hours:minutes:seconds: when fractionalSeconds argument is 0.0");
    
    END_TEST();
}

int main(int argc, char const *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    test_NSCalendarDateAdditions();
    
    [pool release];

    FINAL_SUMMARY();    
}
