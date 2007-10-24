//
//  NSCalendarDateAdditions.m
//  Keychain
//
//  Created by Wade Tregaskis on 16/5/2005.
//
//  Copyright (c) 2005, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "NSCalendarDateAdditions.h"


@implementation NSCalendarDate (KeychainAdditions)

+ (id)dateWithYear:(int)year month:(unsigned)month day:(unsigned)day hour:(unsigned)hour minute:(unsigned)minute second:(unsigned)second fractionalSecond:(double)fractionalSecond timeZone:(NSTimeZone*)aTimeZone {
    return [[[[self class] alloc] initWithYear:year month:month day:day hour:hour minute:minute second:second fractionalSecond:fractionalSecond timeZone:aTimeZone] autorelease];
}

- (id)initWithYear:(int)year month:(unsigned)month day:(unsigned)day hour:(unsigned)hour minute:(unsigned)minute second:(unsigned)second fractionalSecond:(double)fractionalSecond timeZone:(NSTimeZone*)aTimeZone {
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

- (NSCalendarDate*)dateByAddingYears:(int)year months:(int)month days:(int)day hours:(int)hour minutes:(int)minute seconds:(int)second fractionalSeconds:(double)fractionalSecond {
    return [[self dateByAddingYears:year months:month days:day hours:hour minutes:minute seconds:second] addTimeInterval:fractionalSecond];
}

- (void)years:(int*)yearsPointer months:(int*)monthsPointer days:(int*)daysPointer hours:(int*)hoursPointer minutes:(int*)minutesPointer seconds:(int*)secondsPointer fractionalSeconds:(double*)fractionalSecondsPointer sinceDate:(NSCalendarDate*)date {    
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

@end
