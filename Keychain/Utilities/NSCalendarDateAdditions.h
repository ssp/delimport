//
//  NSCalendarDateAdditions.h
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

#import <Cocoa/Cocoa.h>

// For pre-10.5 SDKs:
#ifndef NSINTEGER_DEFINED
typedef int NSInteger;
typedef unsigned int NSUInteger;
#define NSINTEGER_DEFINED
#endif

/*! @category NSCalendarDate (KeychainFramework)
    @abstract Extends NSCalendarDate to support fractions of a second.
    @discussion This category adds methods to NSCalendarDate to support fractions of a second.  Note that this support does not extend to format strings (yet, at least), so methods such as description, descriptionWithCalendarFormat:, dateWithString:calendarFormat: etc will not benefit. */

@interface NSCalendarDate (KeychainFramework)

/*! @method dateWithClassicMacLongDateTime:timeZone:
	@abstract Creates a new NSCalendarDate with the given Classic Mac LongDateTime and timezone.
	@discussion For a very poor description of LongDateTimes, refer to <a href="http://developer.apple.com/documentation/Carbon/Reference/Date_Time_an_nt_Utilities/Reference/reference.html">http://developer.apple.com/documentation/Carbon/Reference/Date_Time_an_nt_Utilities/Reference/reference.html</a>.  In a nutshell, it's the number of seconds from the start of January 1st, 1904, <i>in an undefined time zone</i>.  Which is to say, the timezone information is not encoded into the time itself, nor are they standardised to GMT time or similar.  In fact, the default behaviour with most MacOS X functions that deal with these is to assume they are in the default time zone for the current application.  As such, they are not easily portable.

				So, typically if you have a LongDateTime and you're not sure what time zone its in, use +[NSTimeZone defaultTimeZone].

				There may be some issues around changes in daylight savings time.  Dates are complicated beasties.
	@param date The date as a Classic Mac LongDateTime.
	@param timeZone The time zone of the given date.  If not provided, GMT is assumed.
	@result Returns a new NSCalendarDate representing the given time, or nil if an error occurs. */

+ (NSCalendarDate*)dateWithClassicMacLongDateTime:(int64_t)date timeZone:(NSTimeZone*)timeZone;

/*! @method dateWithClassicMacDateTime:timeZone:
	@abstract Creates a new NSCalendarDate with the given Classic Mac DateTime and timezone.
	@discussion For a very poor description of DateTimes, refer to <a href="http://developer.apple.com/documentation/Carbon/Reference/Date_Time_an_nt_Utilities/Reference/reference.html">http://developer.apple.com/documentation/Carbon/Reference/Date_Time_an_nt_Utilities/Reference/reference.html</a>.  In a nutshell, it's the number of seconds from the start of January 1st, 1904, <i>in an undefined time zone</i>.  Which is to say, the timezone information is not encoded into the time itself, nor are they standardised to GMT time or similar.  In fact, the default behaviour with most MacOS X functions that deal with these is to assume they are in the default time zone for the current application.  As such, they are not easily portable.

				So, typically if you have a DateTime and you're not sure what time zone its in, use +[NSTimeZone defaultTimeZone].

				There may be some issues around changes in daylight savings time.  Dates are complicated beasties.
	@param date The date as a Classic Mac DateTime.
	@param timeZone The time zone of the given date.  If not provided, GMT is assumed.
	@result Returns a new NSCalendarDate representing the given time, or nil if an error occurs. */

+ (NSCalendarDate*)dateWithClassicMacDateTime:(uint32_t)date timeZone:(NSTimeZone*)timeZone;

/*! @method dateWithYear:month:day:hour:minute:second:fractionalSecond:timeZone:
    @abstract Returns an NSCalendarDate with the given time.
    @discussion Works identically to NSCalendarDate's dateWithYear:month:day:hour:minute:second:timeZone: method, except for the extra sub-second precision.
    @param year The year for the date.
    @param month The month for the date.
    @param day The day for the date.
    @param hour The hour for the date.
    @param minute The minute for the date.
    @param second The second for the date.
    @param fractionalSecond The fractional second for the date.
    @param aTimeZone The time zone the date exists in.
    @result Returns an appropriate NSCalendarDate, or nil if an error occurs. */

+ (id)dateWithYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second fractionalSecond:(double)fractionalSecond timeZone:(NSTimeZone*)aTimeZone;

/*! @method initWithYear:month:day:hour:minute:second:fractionalSecond:timeZone:
    @abstract Initialises the receiver with the given time values.
    @discussion Works identically to NSCalendarDate's initWithYear:month:day:hour:minute:second:fractionalSecond:timeZone:, except for the extra sub-second precision.
    @param year The year for the date.
    @param month The month for the date.
    @param day The day for the date.
    @param hour The hour for the date.
    @param minute The minute for the date.
    @param second The second for the date.
    @param fractionalSecond The fractional second for the date.
    @param aTimeZone The time zone the date exists in.
    @result Returns an appropriately initialised NSCalendarDate (which may not necessarily be the receiver), or nil if an error occurs (in which case the receiver is automatically released). */

- (id)initWithYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second fractionalSecond:(double)fractionalSecond timeZone:(NSTimeZone*)aTimeZone;

/*! @method fractionalSecond
    @abstract Returns the fractional second part of the date.
    @discussion Returns any fractional second part of the date, as a number equal to or greater than 0.0 and less than 1.0.
    @result Returns the fractional seconds part of the receiver. */

- (double)fractionalSecond;

/*! @method dateByAddingYears:months:days:hours:minutes:seconds:fractionalSeconds:
    @abstract Returns a new date by adding the given time intervals to the receiver.
    @discussion Works identically to NSCalendarDate's dateByAddingYears:months:days:hours:minutes:seconds: method, except it adds on any fractionalSeconds component you supply.
    @param year Number of years to add (or subtract, if negative).
    @param month Number of months to add (or subtract, if negative).
    @param days Number of days to add (or subtract, if negative).
    @param hours Number of hours to add (or subtract, if negative).
    @param minutes Number of minutes to add (or subtract, if negative).
    @param seconds Number of seconds to add (or subtract, if negative).
    @param fractionalSeconds Number of fractional seconds to add (or subtract, if negative).
    @result Returns the resulting NSCalendarDate, or nil if an error occurs. */

- (NSCalendarDate*)dateByAddingYears:(NSInteger)year months:(NSInteger)month days:(NSInteger)day hours:(NSInteger)hour minutes:(NSInteger)minute seconds:(NSInteger)second fractionalSeconds:(double)fractionalSecond;

/*! @method years:months:days:hours:minutes:seconds:fractionalSeconds:sinceDate:
    @abstract Returns the difference between the receiver and a given reference date, broken down into years, months, etc.
    @discussion Works exactly the same as NSCalendarDate's years:months:days:hours:minutes:seconds:sinceDate: method, except for the extra sub-second precision.  See the relevant documentation for details. */

- (void)years:(NSInteger *)yearsPointer months:(NSInteger *)monthsPointer days:(NSInteger *)daysPointer hours:(NSInteger *)hoursPointer minutes:(NSInteger *)minutesPointer seconds:(NSInteger *)secondsPointer fractionalSeconds:(double*)fractionalSecondsPointer sinceDate:(NSCalendarDate*)date;

/*! @method classicMacLongDateTimeForTimeZone:
    @abstract Returns a Classic Mac LongDateTime, in the given timezone, representing the receiver.
    @discussion For a very poor description of LongDateTimes, refer to <a href="http://developer.apple.com/documentation/Carbon/Reference/Date_Time_an_nt_Utilities/Reference/reference.html">http://developer.apple.com/documentation/Carbon/Reference/Date_Time_an_nt_Utilities/Reference/reference.html</a>.  In a nutshell, it's the number of seconds from the start of January 1st, 1904, <i>in an undefined time zone</i>.  Which is to say, the timezone information is not encoded into the time itself, nor are they standardised to GMT time or similar.  In fact, the default behaviour with most MacOS X functions that deal with these is to assume they are in the default time zone for the current application.  As such, they are not easily portable.
	
				This was originally only necessary because Keychain searches could seemingly only specify creation and modification dates in this form, an issue which I believe was officially acknowlegded (although I don't have the email handy - check the apple-cdsa mailing list archives if you're eager) as due to an implementation oversight in the Security framework.  In future the Security framework will hopefully support more common date formats, but for now this function must remain to fill that gap.
	@param timeZone The time zone that the result will be treated as being in.  If nil, GMT is assumed.
    @result Returns the Classic Mac LongDateTime, for the given timezone, corresponding to the receiver. */

- (int64_t)classicMacLongDateTimeForTimeZone:(NSTimeZone*)timeZone;

/*! @method classicMacDateTimeForTimeZone:
    @abstract Returns a Classic Mac DateTime, in the given timezone, representing the receiver.
    @discussion For a very poor description of DateTimes, refer to <a href="http://developer.apple.com/documentation/Carbon/Reference/Date_Time_an_nt_Utilities/Reference/reference.html">http://developer.apple.com/documentation/Carbon/Reference/Date_Time_an_nt_Utilities/Reference/reference.html</a>.  In a nutshell, it's the number of seconds from the start of January 1st, 1904, <i>in an undefined time zone</i>.  Which is to say, the timezone information is not encoded into the time itself, nor are they standardised to GMT time or similar.  In fact, the default behaviour with most MacOS X functions that deal with these is to assume they are in the default time zone for the current application.  As such, they are not easily portable.
	
				This was originally only necessary because Keychain searches could seemingly only specify creation and modification dates in this form, an issue which I believe was officially acknowlegded (although I don't have the email handy - check the apple-cdsa mailing list archives if you're eager) as due to an implementation oversight in the Security framework.  In future the Security framework will hopefully support more common date formats, but for now this function must remain to fill that gap.
	@param timeZone The time zone that the result will be treated as being in.  If nil, GMT is assumed.
    @result Returns the Classic Mac DateTime, for the given timezone, corresponding to the receiver. */

- (uint32_t)classicMacDateTimeForTimeZone:(NSTimeZone*)timeZone;

@end
