//
//  NSCalendarDateAdditions.m
//  Keychain
//
//  Created by Wade Tregaskis on 16/5/2005.
//
//  Copyright (c) 2005 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "NSCalendarDateAdditions.h"


@implementation NSCalendarDate (KeychainFramework)

+ (id)dateWithYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second fractionalSecond:(double)fractionalSecond timeZone:(NSTimeZone*)aTimeZone {
    return [[[[self class] alloc] initWithYear:year month:month day:day hour:hour minute:minute second:second fractionalSecond:fractionalSecond timeZone:aTimeZone] autorelease];
}

- (id)initWithYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second fractionalSecond:(double)fractionalSecond timeZone:(NSTimeZone*)aTimeZone {
    id temp = [self initWithYear:year month:month day:day hour:hour minute:minute second:second timeZone:aTimeZone];
    
    if (temp) {
        id result = [[temp addTimeInterval:fractionalSecond] retain];
        
        [temp release];
        
        return result;
    } else {
        return nil;
    }
}

- (double)fractionalSecond {
    double wasted;
    
    return modf([self timeIntervalSinceReferenceDate], &wasted);
}

- (NSCalendarDate*)dateByAddingYears:(NSInteger)year months:(NSInteger)month days:(NSInteger)day hours:(NSInteger)hour minutes:(NSInteger)minute seconds:(NSInteger)second fractionalSeconds:(double)fractionalSecond {
    return [[self dateByAddingYears:year months:month days:day hours:hour minutes:minute seconds:second] addTimeInterval:fractionalSecond];
}

- (void)years:(NSInteger *)yearsPointer months:(NSInteger *)monthsPointer days:(NSInteger *)daysPointer hours:(NSInteger *)hoursPointer minutes:(NSInteger *)minutesPointer seconds:(NSInteger *)secondsPointer fractionalSeconds:(double*)fractionalSecondsPointer sinceDate:(NSCalendarDate*)date {    
    [self years:yearsPointer months:monthsPointer days:daysPointer hours:hoursPointer minutes:minutesPointer seconds:secondsPointer sinceDate:date];
    
    if (fractionalSecondsPointer) {        
        *fractionalSecondsPointer = [[self dateByAddingYears:(yearsPointer ? -(*yearsPointer) : 0)
                                                      months:(monthsPointer ? -(*monthsPointer) : 0)
                                                        days:(daysPointer ? -(*daysPointer) : 0)
                                                       hours:(hoursPointer ? -(*hoursPointer) : 0)
                                                     minutes:(minutesPointer ? -(*minutesPointer) : 0)
                                                     seconds:(secondsPointer ? -(*secondsPointer) : 0)] timeIntervalSinceDate:date];
    }
}

+ (NSCalendarDate*)dateWithClassicMacLongDateTime:(int64_t)date timeZone:(NSTimeZone*)timeZone {	
	CFAbsoluteTime absoluteTime = (CFAbsoluteTime)date - kCFAbsoluteTimeIntervalSince1904;
	
	if (nil != timeZone) {
		absoluteTime -= CFTimeZoneGetSecondsFromGMT((CFTimeZoneRef)timeZone, absoluteTime);
		// The above could be wrong, I think.  We're giving it the absoluteTime pretending it's really an absolute time, but it's not - it's offset by some amount.  If that offset crosses a daylight-savings boundary, we could read the wrong offset.  That would put us off by +/- 1 hour.  This needs to be proven, one way or another, experimentally.
	}
	
	NSCalendarDate *result = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:absoluteTime];
	
	return result;
}

+ (NSCalendarDate*)dateWithClassicMacDateTime:(uint32_t)date timeZone:(NSTimeZone*)timeZone {
	return [self dateWithClassicMacLongDateTime:(int64_t)date timeZone:timeZone];
}

- (int64_t)classicMacLongDateTimeForTimeZone:(NSTimeZone*)timeZone {
	int64_t absoluteTime = [self timeIntervalSinceReferenceDate];
	int64_t result = (absoluteTime + kCFAbsoluteTimeIntervalSince1904);
	
	if (nil != timeZone) {
		result += CFTimeZoneGetSecondsFromGMT((CFTimeZoneRef)timeZone, absoluteTime);
	}
    
    return result;
}

- (uint32_t)classicMacDateTimeForTimeZone:(NSTimeZone*)timeZone {
    int64_t longDateTime = [self classicMacLongDateTimeForTimeZone:timeZone];
    
    if (0 > longDateTime) {
        [NSException raise:NSRangeException format:@"Cannot represent the date \"%@\" in Classic MacOS date/time format (uint32_t), because it is negative (i.e. before January 1st, 1904).", [self description]];
        return 0; // Won't be reached
    } else if (UINT32_MAX < longDateTime) {
        [NSException raise:NSRangeException format:@"Cannot represent the date \"%@\" in Classic MacOS date/time format (uint32_t), because it is too large (i.e. on or after February 6th, 2040).", [self description]];
        return UINT32_MAX; // Won't be reached
    } else {
        return (uint32_t)longDateTime;
    }
}

@end
