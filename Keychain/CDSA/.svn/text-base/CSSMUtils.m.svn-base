//
//  CSSMUtils.m
//  Keychain
//
//  Created by Wade Tregaskis on Thu Mar 13 2003.
//
//  Copyright (c) 2003 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "CSSMUtils.h"

#import "Utilities/UtilitySupport.h"
#import "Utilities/Logging.h"
#import "Utilities/NSCalendarDateAdditions.h"
#import "Utilities/LocalisationUtils.h"


NSString* GUIDAsString(const CSSM_GUID *GUID) {
    if (NULL != GUID) {
        return [NSString stringWithFormat:@"%08x-%04hx%04hx-%02x%02x%02x%02x%02x%02x%02x%02x", NSSwapBigIntToHost(GUID->Data1), NSSwapBigShortToHost(GUID->Data2), NSSwapBigShortToHost(GUID->Data3), GUID->Data4[0], GUID->Data4[1], GUID->Data4[2], GUID->Data4[3], GUID->Data4[4], GUID->Data4[5], GUID->Data4[6], GUID->Data4[7]];
    } else {
        PDEBUG(@"Invalid parameter - 'GUID' is NULL.\n");
        return nil;
    }
}

NSString* OIDAsString(const CSSM_OID *OID) {
    if (NULL != OID) {
        if ((NULL == OID->Data) || (0 >= OID->Length)) {
            PDEBUG(@"Invalid parameter - 'Data' (%p) is NULL and/or 'Length' (%d) is <= 0.\n", OID->Data, OID->Length);
            return nil;
        } else {
            NSMutableString *result = [NSMutableString stringWithCapacity:(4 * OID->Length)];
            unsigned int i;
            
            for (i = 0; i < OID->Length; ++i) {
                [result appendFormat:@"%s%hhu", ((0 == i) ? "" : ", "), OID->Data[i]];
            }
            
            return result;
        }
    } else {
        PDEBUG(@"Invalid parameter - 'OID' is NULL.\n");
        return nil;
    }
}

NSString* nameOfGUID(const CSSM_GUID *GUID) {
    if (NULL != GUID) {
        return localizedStringWithFallback(GUIDAsString(GUID), @"GUID Names");
    } else {
        PDEBUG(@"Invalid parameter - 'GUID' is NULL.\n");
        return nil;
    }
}

NSString* nameOfOID(const CSSM_OID *OID) {
    if (NULL != OID) {
        if ((NULL == OID->Data) || (0 >= OID->Length)) {
            PDEBUG(@"Invalid parameter = 'Data' (%p) is NULL and/or 'Length' (%d) is <= 0.\n", OID->Data, OID->Length);
            return nil;
        } else {
            return localizedStringWithFallback(OIDAsString(OID), @"OID Names");
        }
    } else {
        PDEBUG(@"Invalid parameter - 'GUID' is NULL.\n");
        return nil;
    }
}

NSString* nameOfCertificateTypeConstant(CSSM_CERT_TYPE certificateType) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu32, certificateType], @"Certificate Type Constants");
}

NSString* nameOfCertificateType(CSSM_CERT_TYPE certificateType) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu32, certificateType], @"Certificate Type Names");
}

NSString* nameOfCertificateEncodingConstant(CSSM_CERT_ENCODING certificateEncoding) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu32, certificateEncoding], @"Certificate Encoding Constants");
}

NSString* nameOfCertificateEncoding(CSSM_CERT_ENCODING certificateEncoding) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu32, certificateEncoding], @"Certificate Encoding Names");
}

NSString* nameOfCRLTypeConstant(CSSM_CRL_TYPE type) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu32, type], @"CRL Type Constants");
}

NSString* nameOfCRLType(CSSM_CRL_TYPE type) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu32, type], @"CRL Type Names");
}

NSString* nameOfCRLEncodingConstant(CSSM_CRL_ENCODING encoding) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu32, encoding], @"CRL Encoding Constants");
}

NSString* nameOfCRLEncoding(CSSM_CRL_ENCODING encoding) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu32, encoding], @"CRL Encoding Names");
}

NSString* nameOfBERCodeConstant(CSSM_BER_TAG tag) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu8, tag], @"BER Code Constants");
}

NSString* nameOfBERCode(CSSM_BER_TAG tag) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%"PRIu8, tag], @"BER Code Names");
}

NSString* CSSMErrorName(CSSM_RETURN error) {
	return localizedStringWithFallback([NSString stringWithFormat:@"%u", error], @"CSSM Error Names");
}

NSString* CSSMErrorConstant(CSSM_RETURN error) {
	return localizedStringWithFallback([NSString stringWithFormat:@"%u", error], @"CSSM Error Constants");
}

NSString* CSSMErrorDescription(CSSM_RETURN error) {
	return localizedStringWithFallback([NSString stringWithFormat:@"%u", error], @"CSSM Error Descriptions");
}

NSString* CSSMErrorAsString(CSSM_RETURN error) {
    /*if (CSSM_ERR_IS_CONVERTIBLE(error)) {
        return [NSString stringWithFormat:@"%@ %@ (%@)", localizedStringWithFallback([NSString stringWithFormat:@"%u", (uint32_t)CSSM_ERRBASE(error)], @"CSSM Error Bases"), localizedStringWithFallback([NSString stringWithFormat:@"%u", (uint32_t)CSSM_ERRCODE(error)], @"CSSM Error Codes"), localizedStringWithFallback([NSString stringWithFormat:@"%u", (uint32_t)error], @"CSSM Error Names")];
    } else {
        NSString *errorRep = [NSString stringWithFormat:@"%u", (uint32_t)error];
        
        return [NSString stringWithFormat:@"%@ (%@)", localizedStringWithFallback(errorRep, @"CSSM Errors"), localizedStringWithFallback(errorRep, @"CSSM Error Names")];
    }*/
	
	NSString *codeAsString = [NSString stringWithFormat:@"%u", error];
	NSString *errorConstant = localizedString(codeAsString, @"CSSM Error Constants");
	NSString *errorName = localizedString(codeAsString, @"CSSM Error Names");
	NSString *errorDescription = localizedString(codeAsString, @"CSSM Error Descriptions");
	
	if (nil != errorConstant) {
		if (nil != errorName) {
			if (nil != errorDescription) {
				return [NSString stringWithFormat:@"%@ (#%@) - %@ (%@)", errorConstant, codeAsString, errorName, errorDescription];
			} else {
				return [NSString stringWithFormat:@"%@ (#%@) - %@", errorConstant, codeAsString, errorName];
			}
		} else {
			if (nil != errorDescription) {
				return [NSString stringWithFormat:@"%@ (#%@) - %@", errorConstant, codeAsString, errorDescription];
			} else {
				return [NSString stringWithFormat:@"%@ (#%@)", errorConstant, codeAsString];
			}
		}
	} else {
		if (nil != errorName) {
			if (nil != errorDescription) {
				return [NSString stringWithFormat:@"(#%@) - %@ (%@)", codeAsString, errorName, errorDescription];
			} else {
				return [NSString stringWithFormat:@"#%@ - %@", codeAsString, errorName];
			}
		} else {
			if (nil != errorDescription) {
				return [NSString stringWithFormat:@"#%@ - %@", codeAsString, errorDescription];
			} else {
				return localizedStringWithFallback(codeAsString, @"--FAKE--"); // We just want the localised "Unknown (X)" string, really; we pass in a fake table name to make sure no table is found, causing the fallback to be invoked.
			}
		}
	}
}

NSString* stringRepresentationOfBEREncodedData(const CSSM_DATA *dat, CSSM_BER_TAG tag) {
    if (NULL == dat) {
        PDEBUG(@"Invalid parameter - 'dat' is NULL.\n");
        return nil;
    } else {
    	switch (tag) {
        	case BER_TAG_BOOLEAN:
                return localizedStringWithFallback((*((BOOL*)dat->Data)) ? @"YES" : @"NO", @"Misc Names"); break;
        	case BER_TAG_INTEGER:
            	return [NSString stringWithFormat:@"%d", *((int*)dat->Data)];
        	case BER_TAG_PRINTABLE_STRING:
        	case BER_TAG_PKIX_UNIVERSAL_STRING:
        	case BER_TAG_GENERAL_STRING:
        	case BER_TAG_ISO646_STRING:
        	case BER_TAG_PKIX_UTF8_STRING:
            	return [NSString stringWithCString:(char*)(dat->Data) length:dat->Length]; break;
        	case BER_TAG_NULL:
        	    return @"<NULL>"; break;
        	case BER_TAG_REAL:
            	if (dat->Length == sizeof(float)) {
                	return [NSString stringWithFormat:@"%f", *((float*)dat->Data)];
            	} else {
                	return [NSString stringWithFormat:@"%lf", *((double*)dat->Data)];
            	}

            	break;
        	case BER_TAG_UTC_TIME:
        	case BER_TAG_GENERALIZED_TIME:
            	return [calendarDateForTime((CSSM_X509_TIME_PTR)dat) description]; break;
        	default:
            	return [NSDataFromData(dat) description]; break;
    	}
    }
}

CSSM_DATE CSSMDateForCalendarDate(NSCalendarDate *date) {
    CSSM_DATE result;
    NSInteger temp;
    
    if (date) {
        NSCalendarDate *dateGMT = [date copy];
        
        [dateGMT setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        temp = [dateGMT yearOfCommonEra];
        
        if ((0 > temp) || (9999 < temp)) {
            PDEBUG(@"Year of date %@ is out of range 0-9999 (inclusive) - cannot represent as a CSSM_DATE.\n", dateGMT);
            memset(&result, 0, sizeof(result));
        } else {
            /* I'm guessing this is not much bigger than a 4-iteration loop, and should be faster due to the absence of branches. */
            result.Year[0] = '0' + (temp / 1000);
            temp %= 1000;
            result.Year[1] = '0' + (temp / 100);
            temp %= 100;
            result.Year[2] = '0' + (temp / 10);
            result.Year[3] = '0' + (temp % 10);
            
            temp = [dateGMT monthOfYear];
            result.Month[0] = '0' + (temp / 10);
            result.Month[1] = '0' + (temp % 10);
            
            temp = [dateGMT dayOfMonth];
            result.Day[0] = '0' + (temp / 10);
            result.Day[1] = '0' + (temp % 10);
            
            //PDEBUG(@"CSSMDateForCalendarDate(%@) -> %s.\n", dateGMT, [[dateGMT descriptionWithCalendarFormat:@"%Y%m%d"] cString]);
            //PDEBUG(@"result == %c%c%c%c%c%c%c%c.\n", result->Year[0], result->Year[1], result->Year[2], result->Year[3], result->Month[0], result->Month[1], result->Day[0], result->Day[1]);
        }
        
        [dateGMT release];
    } else {
        PDEBUG(@"Invalid parameter - 'date' is nil.\n");
        memset(&result, 0, sizeof(result));
    }

    return result;
}

NSCalendarDate* calendarDateForCSSMDate(const CSSM_DATE *date) {
    if (NULL == date) {
        PDEBUG(@"Invalid parameter - 'date' is nil.\n");
        return nil;
    } else {
        unsigned int day, month, year, i;
        uint8_t *rawBytesOfDate = (uint8_t*)date;
        
        //PDEBUG(@"calendarDateForCSSMDate() given: %c%c%c%c%c%c%c%c.\n", date->Year[0], date->Year[1], date->Year[2], date->Year[3], date->Month[0], date->Month[1], date->Day[0], date->Day[1]);
        
        for (i = 0; i < sizeof(CSSM_DATE); ++i) {
            if (('0' > rawBytesOfDate[i]) || ('9' < rawBytesOfDate[i])) {
                if (0 == rawBytesOfDate[i]) {
                    PDEBUG(@"Digit %d of the given date is NULL, indicating an invalid date.\n", i);
                } else {
                    PDEBUG(@"Digit %d (value %hhu) of the given date is outside the valid range of ASCII decimal values ('0' to '9' inclusive).\n", i, rawBytesOfDate[i]);
                }
                
                return nil;
            }
        }
        
        day = ((date->Day[0] - '0') * 10) + (date->Day[1] - '0');
        month = ((date->Month[0] - '0') * 10) + (date->Month[1] - '0');
        year = ((date->Year[0] - '0') * 1000) + ((date->Year[1] - '0') * 100) + ((date->Year[2] - '0') * 10) + (date->Year[3] - '0');
        
        //PDEBUG(@"day = %d, month = %d, year = %d.\n", day, month, year);
        //PDEBUG(@"result == %@.\n", [NSCalendarDate dateWithYear:year month:month day:day hour:0 minute:0 second:0 timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]]);
        
        NSCalendarDate *result = [NSCalendarDate dateWithYear:year month:month day:day hour:0 minute:0 second:0 timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        if (month != (unsigned)[result monthOfYear]) {
            PDEBUG(@"Given CSSM_DATE has a month of year of %u, but constructed NSCalendarDate has a month of year of %d.  This probably indicates the original CSSM_DATE was invalid.", month, [result monthOfYear]);
            result = nil;
        } else if (day != (unsigned)[result dayOfMonth]) {
            PDEBUG(@"Given CSSM_DATE has a day of month of %u, but constructed NSCalendarDate has a day of month of %d.  This probably indicates the original CSSM_DATE was invalid.", day, [result dayOfMonth]);
            result = nil;
        }
        
        if (nil != result) {
            [result setTimeZone:[NSTimeZone defaultTimeZone]];
            [result setCalendarFormat:nil];
        }
        
        return result;
        
        //return [NSString stringWithFormat:@"%c%c/%c%c/%c%c%c%c", date->Day[0], date->Day[1], date->Month[0], date->Month[1], date->Year[0], date->Year[1], date->Year[2], date->Year[3]];
    }
}

NSCalendarDate* calendarDateForTime(const CSSM_X509_TIME *time) {
    NSCalendarDate *result = nil;
    
    if (NULL == time) {
        PDEBUG(@"Argument (time) is NULL.\n");
    } else if ((NULL == time->time.Data) || (0 >= time->time.Length)) {
        PDEBUG(@"Argument (time) has a NULL data field (== %p), or length less than or equal to zero (== %d).\n", time->time.Data, time->time.Length);
    } else {
        NSString *format = nil;
        
    	NSString *timeString = [NSString stringWithCString:(char*)(time->time.Data) length:time->time.Length];

    	/* PDEBUG(@"time == \"%@\" (%p), length %d.\n", timeString, time->time.Data, time->time.Length); */
    
    	if (time->timeType == BER_TAG_UTC_TIME) {
            switch (time->time.Length) {
                case 11: /* yymmddHHMMZ */
                    format = @"%y%m%d%H%M%z";
                    timeString = [[timeString substringToIndex:10] stringByAppendingString:@"0"];
                    break;
                case 13: /* yymmddHHMMSSZ */
                    format = @"%y%m%d%H%M%S%z";
                    timeString = [[timeString substringToIndex:12] stringByAppendingString:@"0"];
                    break;
                case 15: /* yymmddHHMMsHHMM */
                    format = @"%y%m%d%H%M%z";
                    break;
                case 17: /* yymmddHHMMSSsHHMM */
                    format = @"%y%m%d%H%M%S%z";
                    break;
                default:
                    PDEBUG(@"Time \"%@\" is BER UTC format, but length of %d does not imply a known format (any of {11, 13, 15, 17}).\n", timeString, time->time.Length);
            }
            
            if (format) {
                NSInteger year;
                
                result = [NSCalendarDate dateWithString:timeString calendarFormat:format];
                
                year = [result yearOfCommonEra];
                
                if (year < 1950) {
                    result = [result dateByAddingYears:100 months:0 days:0 hours:0 minutes:0 seconds:0];
                } else if (year > 2049) {
                    result = [result dateByAddingYears:-100 months:0 days:0 hours:0 minutes:0 seconds:0];
                }
                
                [result setTimeZone:[NSTimeZone defaultTimeZone]];
                [result setCalendarFormat:nil];
            }
    	} else if (time->timeType == BER_TAG_GENERALIZED_TIME) {
            /* We cannot imply the format from the length, since yyyymmddHHMMsHHMM has the same length as yyyymmddHHMMSS.UZ, among others. */
            
            if (12 > time->time.Length) {
                PDEBUG(@"Date \"%@\" is %d characters long, too short to be a BER Generalized time (minimum 12).\n", timeString, time->time.Length);
            } else {
                result = [NSCalendarDate dateWithString:[[timeString substringToIndex:12] stringByAppendingString:@"0"] calendarFormat:@"%Y%m%d%H%M%z"];
                
                if (!result) {
                    PDEBUG(@"Unable to read first part of \"%@\" - expecting yyyymmddHHMM.\n", timeString);
                } else {
                    NSUInteger seconds = 0;
                    NSInteger offsetHours = 0, offsetMinutes = 0;
                    double fractionalSeconds = 0.0;
                    NSUInteger index = 12;
                    char temp[5], *check, sign;
                    BOOL haveSeconds = NO, haveFractionalSeconds = NO, haveTimezone = NO, allGood = YES;

#define min(a, b) (((a) < (b)) ? (a) : (b))

#define RANGE_CHECK(size) ((index + size) <= time->time.Length)
                    
#define READ_NEXT_FIELD(size, strict) \
                    if ((!strict && (index < time->time.Length)) || RANGE_CHECK(size)) { \
                        NSInteger actualSize = min(time->time.Length - index, size); \
                        memcpy(temp, time->time.Data + index, actualSize); \
                        index += actualSize; \
                        temp[actualSize] = 0; \
                    } else { \
                        temp[0] = 0; \
                    }
                    
#define STRTOUL_VERIFY ((temp != check) && (0 == *check))
                    
                    /* Possible formats, afaik:
                        
                        yyyymmddHHMM[SS][.U][Z]
                        yyyymmddHHMM[SS][.U]sHHMM
                    
                       There's some argument as to how strict the parsing should be... I figure the stricter the better, within reason... best to barf and generate a false negative than carry on haphazardly and generate a false positive. */
                    
                    while (RANGE_CHECK(1) && !haveTimezone && allGood) {
                        switch (time->time.Data[index]) {
                            case '.':
                            case ',':
                                if (haveFractionalSeconds) {
                                    PDEBUG(@"Encountered fractional seconds part twice in \"%@\".\n", timeString);
                                    allGood = NO;
                                } else {
                                    ++index;
                                    
                                    READ_NEXT_FIELD(1, 1);
                                    
                                    fractionalSeconds = strtoul(temp, &check, 10);
                                    
                                    if (STRTOUL_VERIFY) {
                                        fractionalSeconds /= 10;
                                        haveFractionalSeconds = YES;
                                    } else {
                                        PDEBUG(@"Didn't find fractional seconds value as expected in \"%@\".\n", timeString);
                                        allGood = NO;
                                    }
                                }
                                
                                break;
                            case '+':
                            case '-':
                                sign = time->time.Data[index];
                                ++index;
                                
                                READ_NEXT_FIELD(2, 0);
                                
                                offsetHours = strtoul(temp, &check, 10);
                                
                                if (STRTOUL_VERIFY) {
                                    READ_NEXT_FIELD(2, 0);
                                    
                                    offsetMinutes = strtoul(temp, &check, 10);
                                    
                                    if ((0 == temp[0]) || STRTOUL_VERIFY) {
                                        if ('+' == sign) {
                                            offsetHours = -offsetHours;
                                            offsetMinutes = -offsetMinutes;
                                        }
                                        
                                        haveTimezone = YES;
                                    } else {
                                        PDEBUG(@"Unable to read minutes offset in timezone information, in \"%@\".\n", timeString);
                                        allGood = NO;
                                    }
                                } else {
                                    PDEBUG(@"Unable to read hours offset in timezone information, in \"%@\".\n", timeString);
                                    allGood = NO;
                                }
                                
                                break;
                            case 'Z':
                                haveTimezone = YES;
                                break;
                            default:
                                if (haveFractionalSeconds) {
                                    PDEBUG(@"Unknown value at end of time \"%@\".\n", timeString);
                                    allGood = NO;
                                } else {
                                    if (haveSeconds) {
                                        PDEBUG(@"Seconds part encountered twice in time \"%@\".\n", timeString);
                                        allGood = NO;
                                    } else {
                                        READ_NEXT_FIELD(2, 0);
                                        
                                        seconds = strtoul(temp, &check, 10);
                                        
                                        if (STRTOUL_VERIFY) {
                                            haveSeconds = YES;
                                        } else {
                                            allGood = NO;
                                            PDEBUG(@"Unable to read seconds from BER generalized time \"%@\".\n", timeString);
                                        }
                                    }
                                }
                        }
                    }
                    
                    if (allGood) {
                        if ((0 != offsetHours) || (0 != offsetMinutes) || (0 != seconds) || (0.0 != fractionalSeconds)) {
                            result = [result dateByAddingYears:0 months:0 days:0 hours:offsetHours minutes:offsetMinutes seconds:seconds fractionalSeconds:fractionalSeconds];
                        }
                    }
                
                    [result setTimeZone:[NSTimeZone defaultTimeZone]];
                    [result setCalendarFormat:nil];
                }
            }
    	} else {
        	result = nil;
        	PDEBUG(@"Time (%p) is in a format (%d) I don't understand.\n", time, time->timeType);
    	}
    }
    
    return result;
}

CSSM_X509_TIME timeForNSCalendarDate(NSCalendarDate *date, CSSM_BER_TAG format) {
    CSSM_X509_TIME result;
    
    result.timeType = format;
    result.time.Data = NULL;
    result.time.Length = 0;
    
    if (date) {
        NSCalendarDate *dateGMT = [date copy];
        
        [dateGMT setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        /* Note that the documentation for NSString getCString:maxLength:encoding: is wrong as of time of writing (16th of May, 2005) - it states that te maxLength argument doesn't include the NULL terminator, but it does. */
        
        switch (format) {
            case BER_TAG_UTC_TIME:
                /* RFC 2549:
                
                    4.1.2.5.1  UTCTime
                    
                    The universal time type, UTCTime, is a standard ASN.1 type intended
                    for international applications where local time alone is not
                    adequate.  UTCTime specifies the year through the two low order
                    digits and time is specified to the precision of one minute or one
                    second.  UTCTime includes either Z (for Zulu, or Greenwich Mean Time)
                    or a time differential.
                    
                    For the purposes of this profile, UTCTime values MUST be expressed
                    Greenwich Mean Time (Zulu) and MUST include seconds (i.e., times are
                    YYMMDDHHMMSSZ), even where the number of seconds is zero.  Conforming
                    systems MUST interpret the year field (YY) as follows:
                    
                        Where YY is greater than or equal to 50, the year shall be
                        interpreted as 19YY; and
                        
                        Where YY is less than 50, the year shall be interpreted as 20YY. */
                
            {
                NSInteger year = [dateGMT yearOfCommonEra];

                if (1950 > year) {
                    PDEBUG(@"Date %@ cannot be represented in UTC time because the year is too early (must be at least 1950).\n", dateGMT);
                } else if (2050 <= year) {
                    PDEBUG(@"Date %@ cannot be represented in UTC time because the year is too late (must be no latter than 2049).\n", dateGMT);
                } else {
                    result.time.Length = 13;
                    result.time.Data = malloc(14);
                    
                    [[dateGMT descriptionWithCalendarFormat:@"%y%m%d%H%M%SZ"] getCString:(char*)(result.time.Data) maxLength:14 encoding:NSASCIIStringEncoding];
                }
            }
                
                break;
            case BER_TAG_GENERALIZED_TIME:
                /* RFC 2549:
                
                    4.1.2.5.2  GeneralizedTime
                    
                    The generalized time type, GeneralizedTime, is a standard ASN.1 type
                    for variable precision representation of time.  Optionally, the
                    GeneralizedTime field can include a representation of the time
                    differential between local and Greenwich Mean Time.
                    
                    For the purposes of this profile, GeneralizedTime values MUST be
                    expressed Greenwich Mean Time (Zulu) and MUST include seconds (i.e.,
                    times are YYYYMMDDHHMMSSZ), even where the number of seconds is zero.
                    GeneralizedTime values MUST NOT include fractional seconds. */
                
                result.time.Length = 15;
                result.time.Data = malloc(16);
                    
                [[dateGMT descriptionWithCalendarFormat:@"%Y%m%d%H%M%SZ"] getCString:(char*)(result.time.Data) maxLength:16 encoding:NSASCIIStringEncoding];
                
                break;
            default:
                PDEBUG(@"Told to convert to a format (%d) I don't understand.\n", format);
        }
        
        [dateGMT release];
    } else {
        PDEBUG(@"Invalid parameter - 'date' is nil.\n");
    }
    
    return result;
}

NSString* nameOfKeyblobTypeConstant(CSSM_KEYBLOB_TYPE type) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", type], @"Keyblob Type Constants");
}

NSString* nameOfKeyblobType(CSSM_KEYBLOB_TYPE type) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", type], @"Keyblob Type Names");
}

NSString* nameOfTypedFormat(CSSM_KEYBLOB_FORMAT format, CSSM_KEYBLOB_TYPE type) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u-%u", type, format], @"Keyblob Formats");
}

NSString* nameOfAlgorithm(CSSM_ALGORITHMS algo) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", algo], @"Algorithm Names");
}

NSString* nameOfAlgorithmConstant(CSSM_ALGORITHMS algo) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", algo], @"Algorithm Constants");
}

NSString* nameOfKeyClassConstant(CSSM_KEYCLASS keyClass) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", keyClass], @"Key Class Constants");
}

NSString* nameOfKeyClass(CSSM_KEYCLASS keyClass) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", keyClass], @"Key Class Names");
}

NSString* localizedNameOfBitMapValue(uint32_t value, NSString *table, NSString *prefix, NSString *suffix, NSString *separator, NSString *unknownBitFormat) {
    BOOL firstItem = YES;
    NSMutableString *result = [NSMutableString stringWithCapacity:50];
	int i;
	NSString *currentBit;
	
	if (nil != prefix) {
		[result appendString:prefix];
    }
	
    for (i = 0; i < 32; ++i) {
        if (value & (1 << i)) {
            if (!firstItem) {
                [result appendString:separator];
			}
            
            firstItem = NO;
            
			currentBit = localizedString([NSString stringWithFormat:@"0x%08x", (1 << i)], table);
			
			if (nil == currentBit) {
				currentBit = [NSString stringWithFormat:unknownBitFormat, (1 << i)];
			}
			
            [result appendString:currentBit];
        }
    }
    
    //if (firstItem) { // i.e. if no items
    //    [result appendString:@"None"]; // TODO - localise
    //}
    
	if (nil != suffix) {
		[result appendString:suffix];
	}

    return result;
}

NSString* descriptionOfKeyAttributesUsingConstants(CSSM_KEYATTR_FLAGS attr) {
    return localizedNameOfBitMapValue(attr, @"Key Attribute Constants", @"(", @")", @" | ", @"0x%08x");
}

NSString* descriptionOfKeyAttributes(CSSM_KEYATTR_FLAGS attr) {
    return localizedNameOfBitMapValue(attr, @"Key Attribute Names", nil, nil, @", ", @"Unknown (0x%08x)");
}

NSString* descriptionOfKeyUsageUsingConstants(CSSM_KEYUSE use) {
    return localizedNameOfBitMapValue(use, @"Key Usage Constants", @"(", @")", @" | ", @"0x%08x");
}

NSString* descriptionOfKeyUsage(CSSM_KEYUSE use) {
    return localizedNameOfBitMapValue(use, @"Key Usage Names", nil, nil, @", ", @"Unknown (0x%08x)");
}

NSString* descriptionOfAuthorizations(NSArray *authorizations) {
	NSMutableString *result = [NSMutableString string];
	NSUInteger authorizationsCount = [authorizations count];
	NSUInteger i;
	
	if (0 < authorizationsCount) {
		[result appendString:nameOfAuthorization((CSSM_ACL_AUTHORIZATION_TAG)[[authorizations objectAtIndex:0] intValue])];
		
		if (1 < authorizationsCount) {
			for (i = 1; i < (authorizationsCount - 1); ++i) {
				[result appendString:@", "];
				[result appendString:nameOfAuthorization((CSSM_ACL_AUTHORIZATION_TAG)[[authorizations objectAtIndex:i] intValue])];
			}
			
			[result appendString:@" & "];
			[result appendString:nameOfAuthorization((CSSM_ACL_AUTHORIZATION_TAG)[[authorizations objectAtIndex:(authorizationsCount - 1)] intValue])];
		}
	}
	
	return result;
}

NSString* descriptionOfAuthorizationsUsingConstants(NSArray *authorizations) {
	NSMutableString *result = [NSMutableString string];
	NSUInteger authorizationsCount = [authorizations count];
	NSUInteger i;
	
	if (0 < authorizationsCount) {
		[result appendString:nameOfAuthorizationConstant((CSSM_ACL_AUTHORIZATION_TAG)[[authorizations objectAtIndex:0] intValue])];
		
		if (1 < authorizationsCount) {
			for (i = 1; i < (authorizationsCount - 1); ++i) {
				[result appendString:@", "];
				[result appendString:nameOfAuthorizationConstant((CSSM_ACL_AUTHORIZATION_TAG)[[authorizations objectAtIndex:i] intValue])];
			}
			
			[result appendString:@" & "];
			[result appendString:nameOfAuthorizationConstant((CSSM_ACL_AUTHORIZATION_TAG)[[authorizations objectAtIndex:(authorizationsCount - 1)] intValue])];
		}
	}
	
	return result;
}

NSString* nameOfAuthorization(CSSM_ACL_AUTHORIZATION_TAG authorization) {
	return localizedStringWithFallback([NSString stringWithFormat:@"%d", (int)authorization], @"Authorization Tag Names");
}

NSString* nameOfAuthorizationConstant(CSSM_ACL_AUTHORIZATION_TAG authorization) {
	return localizedStringWithFallback([NSString stringWithFormat:@"%d", (int)authorization], @"Authorization Tag Constants");
}

NSString* nameOfAlgorithmMode(CSSM_ENCRYPT_MODE mode) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", mode], @"Algorithm Mode Names");
}

NSString* nameOfAlgorithmModeConstant(CSSM_ENCRYPT_MODE mode) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", mode], @"Algorithm Mode Constants");
}

NSString* x509AlgorithmAsString(const CSSM_X509_ALGORITHM_IDENTIFIER *algo) {
    if (NULL != algo) {
        return [NSString stringWithFormat:@"Algorithm: %@\tParameters: %@", nameOfOID(&algo->algorithm), [NSDataFromData(&algo->parameters) description]];
    } else {
        PDEBUG(@"Invalid parameter - 'algo' is NULL.\n");
        return nil;
    }
}

NSString* subjectPublicKeyAsString(const CSSM_X509_SUBJECT_PUBLIC_KEY_INFO *key) {
    if (NULL != key) {
        return [NSString stringWithFormat:@"Algorithm:\n\t%@\n\tData: %@", x509AlgorithmAsString(&key->algorithm), NSDataFromData(&key->subjectPublicKey)];
    } else {
        PDEBUG(@"Invalid parameters - 'key' is NULL.\n");
        return nil;
    }
}

NSString* x509NameAsString(const CSSM_X509_NAME *name) {
    if (NULL != name) {
        unsigned int i, j;
        CSSM_X509_RDN_PTR currentRDN;
        CSSM_X509_TYPE_VALUE_PAIR_PTR currentPair;
        NSMutableString *result = [NSMutableString stringWithCapacity:100];
        
        for (i = 0; i < name->numberOfRDNs; ++i) {
            currentRDN = &name->RelativeDistinguishedName[i];
            
            for (j = 0; j < currentRDN->numberOfPairs; ++j) {
                currentPair = &currentRDN->AttributeTypeAndValue[j];
                
                [result appendString:nameOfOID(&currentPair->type)];
                
                if (currentPair->valueType == BER_TAG_PRINTABLE_STRING) {
                    [result appendString:[NSString stringWithFormat:@": %@\n", [[[NSString alloc] initWithData:NSDataFromData(&currentPair->value) encoding:NSASCIIStringEncoding] autorelease]]];
                } else {
                    [result appendString:[NSString stringWithFormat:@": (%@) %@\n", nameOfBERCode(currentPair->valueType), NSDataFromData(&currentPair->value)]];
                }
            }
        }
        
        return result;
    } else {
        PDEBUG(@"Invalid parameters - 'name' is NULL.\n");
        return nil;
    }
}

NSString* nameOfExtensionFormatConstant(CSSM_X509EXT_DATA_FORMAT format) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%d", format], @"Extension Format Constants");
}

NSString* nameOfExtensionFormat(CSSM_X509EXT_DATA_FORMAT format) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%d", format], @"Extension Format Names");
}

NSString* extensionAsString(const CSSM_X509_EXTENSION *ext) {
    if (NULL != ext) {
        NSMutableString *result = [NSMutableString stringWithCapacity:100];
        
        [result appendString:@"Extension ID: "];
        [result appendString:nameOfOID(&ext->extnId)];
        
        [result appendString:@"\n\tCritical: "];
        
        [result appendString:localizedStringWithFallback(ext->critical ? @"YES" : @"NO", @"Misc Names")];
        
        [result appendString:@"\n\tData Format: "];
        [result appendString:nameOfExtensionFormat(ext->format)];
        
        [result appendString:@"\n\tData:\n\t\t"];
        
        switch (ext->format) {
            case CSSM_X509_DATAFORMAT_ENCODED:
                [result appendString:@"Data Format: "];
                [result appendString:nameOfBERCode(ext->value.tagAndValue->type)];
                [result appendString:@"\n\tData: "];
                [result appendString:stringRepresentationOfBEREncodedData(&ext->value.tagAndValue->value, ext->value.tagAndValue->type)];
                break;
            case CSSM_X509_DATAFORMAT_PARSED:
                [result appendString:[[NSData dataWithBytes:ext->value.parsedValue length:strlen(ext->value.parsedValue)] description]]; break;
            case CSSM_X509_DATAFORMAT_PAIR:
                [result appendString:@"Data Format: "];
                [result appendString:nameOfBERCode(ext->value.valuePair->tagAndValue.type)];
                [result appendString:@"\n\tData: "];
                [result appendString:stringRepresentationOfBEREncodedData(&ext->value.valuePair->tagAndValue.value, ext->value.valuePair->tagAndValue.type)];
                [result appendString:[[NSData dataWithBytes:ext->value.valuePair->parsedValue length:strlen(ext->value.valuePair->parsedValue)] description]]; break;
            default:
                [result appendString:@"<Unreadable>"];
        }
        
        return result;
    } else {
        PDEBUG(@"Invalid parameter - 'ext' is NULL.\n");
        return nil;
    }
}

NSString* extensionsAsString(const CSSM_X509_EXTENSIONS *ext) {
    if (NULL != ext) {
        unsigned int i;
        NSMutableString *result = [NSMutableString stringWithCapacity:100];
        
        for (i = 0; i < ext->numberOfExtensions; ++i) {
            [result appendString:@"\n"];
            [result appendString:extensionAsString(&ext->extensions[i])];
        }
        
        return result;
    } else {
        PDEBUG(@"Invalid parameter - 'ext' is NULL.\n");
        return nil;
    }
}

NSString* signatureAsString(const CSSM_X509_SIGNATURE *sig) {
    if (NULL != sig) {
        return [NSString stringWithFormat:@"Algorithm: %@\nSignature: %@", x509AlgorithmAsString(&sig->algorithmIdentifier), NSDataFromData(&sig->encrypted)];
    } else {
        PDEBUG(@"Invalid parameter - 'sig' is NULL.\n");
        return nil;
    }
}

// The following two functions, inToDER and DERToInt, were taken from Apple's TP module
// They have been modified to be generic standalone functions and observe aesthetically pleasing
// coding style

BOOL intToDER(uint32_t theInt, CSSM_DATA *data) {
    if (NULL != data) {
        data->Length = 0;
        
        if (theInt < 0x100) {
            data->Data = (uint8_t*)malloc(1);
            
            if (NULL != data->Data) {
                data->Length = 1;

                data->Data[0] = (unsigned char)(theInt);
            }
        } else if (theInt < 0x10000) {
            data->Data = (uint8_t*)malloc(2);
            
            if (NULL != data->Data) {
                data->Length = 2;

                data->Data[0] = (unsigned char)(theInt >> 8);
                data->Data[1] = (unsigned char)(theInt);
            }
        } else if (theInt < 0x1000000) {
            data->Data = (uint8_t*)malloc(3);
            
            if (NULL != data->Data) {
                data->Length = 3;

                data->Data[0] = (unsigned char)(theInt >> 16);
                data->Data[1] = (unsigned char)(theInt >> 8);
                data->Data[2] = (unsigned char)(theInt);
            }
        } else {
            data->Data = (uint8_t*)malloc(4);
            
            if (NULL != data->Data) {
                data->Length = 4;

                data->Data[0] = (unsigned char)(theInt >> 24);
                data->Data[1] = (unsigned char)(theInt >> 16);
                data->Data[2] = (unsigned char)(theInt >> 8);
                data->Data[3] = (unsigned char)(theInt);
            }
        }
        
        return (NULL != data->Data);
    } else {
        PDEBUG(@"Invalid parameters - 'data' is NULL.\n");
        return NO;
    }
}

BOOL DERToInt(const CSSM_DATA *data, uint32_t *result) {
    if ((NULL != data) && (NULL != result)) {
        if (4 >= data->Length) {
            unsigned int dex;
            uint8_t *bp = data->Data;
            
            *result = 0;
            
            for (dex = 0; dex < data->Length; ++dex) {
                *result <<= 8;
                *result |= *bp;
                ++bp;
            }
            
            return YES;
        } else {
            PDEBUG(@"DER form is %d bytes long, which would overflow a 4-byte integer.\n", data->Length);
            return NO;
        }
    } else {
        PDEBUG(@"Invalid parameter(s) = 'data' (%p) and/or 'result' (%p) is/are NULL.\n", data, result);
        return NO;
    }
}

NSData* NSDataForDERFormattedInteger(uint32_t value) {
    CSSM_DATA theData;
    NSData *result;
    
    if (intToDER(value, &theData)) {
        result = NSDataFromData(&theData);
        free(theData.Data);
    } else {
        PDEBUG(@"Unable to convert uint32_t value (%u) to CSSM_DATA.\n", value);
        result = nil;
    }
    
    return result;
}
