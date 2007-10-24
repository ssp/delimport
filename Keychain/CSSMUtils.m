//
//  CSSMUtils.m
//  Keychain
//
//  Created by Wade Tregaskis on Thu Mar 13 2003.
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "CSSMUtils.h"

#import "UtilitySupport.h"
#import "Logging.h"
#import "NSCalendarDateAdditions.h"


NSString* KEYCHAIN_BUNDLE_IDENTIFIER = @"Keychain.framework";

#define UNKNOWN (NSLocalizedStringFromTableInBundle(@"Unknown", @"Misc Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil))


NSString* GUIDAsString(const CSSM_GUID *GUID) {
    if (NULL != GUID) {
        return [NSString stringWithFormat:@"%08x-%04hx%04hx-%08x%08x", GUID->Data1, GUID->Data2, GUID->Data3, *((uint32_t*)(GUID->Data4)), *((uint32_t*)(GUID->Data4) + 1)];
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
        
        PDEBUG(@"Could not find key \"%@\" in/or table \"%@\".\n", key, table);
        
        result = UNKNOWN;
        
        if (!result) { /* At this point things are getting silly. */
            result = @"Unknown (%@)";
        }
        
        result = [NSString stringWithFormat:result, key, table];
    }
    
    return result;
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

NSString* nameOfCertificateType(CSSM_CERT_TYPE certificateType) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", certificateType], @"Certificate Types");
}

NSString* nameOfCertificateEncoding(CSSM_CERT_ENCODING certificateEncoding) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", certificateEncoding], @"Certificate Encodings");
}

NSString* nameOfBERCode(CSSM_BER_TAG tag) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%hhu", tag], @"BER Names");
}

NSString* CSSMErrorAsString(CSSM_RETURN error) {
    if (CSSM_ERR_IS_CONVERTIBLE(error)) {
        return [NSString stringWithFormat:@"%@ %@ (%@)", localizedStringWithFallback([NSString stringWithFormat:@"%u", (uint32_t)CSSM_ERRBASE(error)], @"CSSM Error Bases"), localizedStringWithFallback([NSString stringWithFormat:@"%u", (uint32_t)CSSM_ERRCODE(error)], @"CSSM Error Codes"), localizedStringWithFallback([NSString stringWithFormat:@"%u", (uint32_t)error], @"CSSM Error Names")];
    } else {
        NSString *errorRep = [NSString stringWithFormat:@"%u", (uint32_t)error];
        
        return [NSString stringWithFormat:@"%@ (%@)", localizedStringWithFallback(errorRep, @"CSSM Errors"), localizedStringWithFallback(errorRep, @"CSSM Error Names")];
    }
}

NSString* stringRepresentationOfBEREncodedData(const CSSM_DATA *dat, CSSM_BER_TAG tag) {
    if (NULL == dat) {
        PDEBUG(@"Invalid parameter - 'dat' is NULL.\n");
        return nil;
    } else {
    	switch (tag) {
        	case BER_TAG_BOOLEAN:
            	if (*((BOOL*)dat->Data)) {
                	return NSLocalizedStringFromTableInBundle(@"YES", @"Misc Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil);
            	} else {
                	return NSLocalizedStringFromTableInBundle(@"NO", @"Misc Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil);
            	}

            	break;
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
    int temp;
    
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
                result = [NSCalendarDate dateWithString:timeString calendarFormat:format];
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
                    unsigned int seconds = 0;
                    int offsetHours = 0, offsetMinutes = 0;
                    double fractionalSeconds = 0.0;
                    unsigned int index = 12;
                    char temp[5], *check, sign;
                    BOOL haveSeconds = NO, haveFractionalSeconds = NO, haveTimezone = NO, allGood = YES;

#define min(a, b) (((a) < (b)) ? (a) : (b))

#define RANGE_CHECK(size) ((index + size) <= time->time.Length)
                    
#define READ_NEXT_FIELD(size, strict) \
                    if ((!strict && (index < time->time.Length)) || RANGE_CHECK(size)) { \
                        int actualSize = min(time->time.Length - index, size); \
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
        double fractionalSeconds;
        
        [dateGMT setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        /* Note that the documentation for NSString getCString:maxLength:encoding: is wrong as of time of writing (16th of May, 2005) - it states that te maxLength argument doesn't include the NULL terminator, but it does. */
        
        switch (format) {
            case BER_TAG_UTC_TIME:
                if (0 == [dateGMT secondOfMinute]) {
                    result.time.Length = 11;
                    result.time.Data = malloc(12);
                    
                    [[dateGMT descriptionWithCalendarFormat:@"%y%m%d%H%MZ"] getCString:(char*)(result.time.Data) maxLength:12 encoding:NSASCIIStringEncoding];
                } else {
                    result.time.Length = 13;
                    result.time.Data = malloc(14);
                    
                    [[dateGMT descriptionWithCalendarFormat:@"%y%m%d%H%M%SZ"] getCString:(char*)(result.time.Data) maxLength:14 encoding:NSASCIIStringEncoding];
                }
                
                break;
            case BER_TAG_GENERALIZED_TIME:
                fractionalSeconds = [dateGMT fractionalSecond] * 10.0;
                
                if (1.0 <= fractionalSeconds) {
                    result.time.Length = 16;
                    result.time.Data = malloc(17);
                    
                    [[[dateGMT descriptionWithCalendarFormat:@"%Y%m%d%H%M%S"] stringByAppendingFormat:@".%01.1d", (int)floor(fractionalSeconds)] getCString:(char*)(result.time.Data) maxLength:17 encoding:NSASCIIStringEncoding];
                } else if (0 != [dateGMT secondOfMinute]) {
                    result.time.Length = 14;
                    result.time.Data = malloc(15);
                    
                    [[dateGMT descriptionWithCalendarFormat:@"%Y%m%d%H%M%S"] getCString:(char*)(result.time.Data) maxLength:15 encoding:NSASCIIStringEncoding];
                } else {
                    result.time.Length = 12;
                    result.time.Data = malloc(13);
                    
                    [[dateGMT descriptionWithCalendarFormat:@"%Y%m%d%H%M"] getCString:(char*)(result.time.Data) maxLength:13 encoding:NSASCIIStringEncoding];
                }
                    
                    break;
            default:
                PDEBUG(@"Told to convert to a format (%d) I don't understand.\n", format);
        }
        
        [dateGMT release];
    } else {
        PDEBUG(@"Invalid parameter - 'date' is nil.\n");
        
        result.time.Length = 0;
        result.time.Data = NULL;
    }
    
    return result;
}

NSString* nameOfKeyBlob(CSSM_KEYBLOB_TYPE type) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", type], @"Keyblob Types");
}

NSString* nameOfTypedFormat(CSSM_KEYBLOB_FORMAT format, CSSM_KEYBLOB_TYPE type) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u-%u", type, format], @"Keyblob Formats");
}

NSString* nameOfAlgorithm(CSSM_ALGORITHMS algo) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", algo], @"Algorithms");
}

NSString* nameOfKeyClass(CSSM_KEYCLASS keyClass) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", keyClass], @"Key Classes");
}

NSString* localizedNameOfBitMapValue(uint32_t value, NSString *table) {
    BOOL firstItem = YES;
    NSMutableString *result = [NSMutableString stringWithCapacity:50];
	int i;
    
    for (i = 0; i < 32; ++i) {
        if (value & (1 << i)) {
            if (!firstItem) {
                [result appendString:@", "];
			}
            
            firstItem = NO;
            
            [result appendString:localizedStringWithFallback([NSString stringWithFormat:@"0x%08x", (1 << i)], table)];
        }
    }
    
    if (firstItem) { // i.e. if no items
        [result appendString:@"None"]; /* TODO - localise */
    }
    
    return result;
}

NSString* namesOfAttributes(CSSM_KEYATTR_FLAGS attr) {
    return localizedNameOfBitMapValue(attr, @"Key Attributes");
}

NSString* namesOfUsages(CSSM_KEYUSE use) {
    return localizedNameOfBitMapValue(use, @"Key Usage");
}

NSString* nameOfAlgorithmMode(CSSM_ENCRYPT_MODE mode) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%u", mode], @"Algorithm Modes");
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
                
                [result appendString:nameOfOIDAttribute(&currentPair->type)];
                
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

NSString* nameOfExtensionFormat(CSSM_X509EXT_DATA_FORMAT format) {
    return localizedStringWithFallback([NSString stringWithFormat:@"%d", format], @"Extension Formats");
}

NSString* extensionAsString(const CSSM_X509_EXTENSION *ext) {
    if (NULL != ext) {
        NSMutableString *result = [NSMutableString stringWithCapacity:100];
        
        [result appendString:@"Extension ID: "];
        [result appendString:nameOfOID(&ext->extnId)];
        
        [result appendString:@"\n\tCritical: "];
        
        if (ext->critical) {
            [result appendString:NSLocalizedStringFromTableInBundle(@"YES", @"Misc Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil)];
        } else {
            [result appendString:NSLocalizedStringFromTableInBundle(@"NO", @"Misc Names", [NSBundle bundleWithIdentifier:KEYCHAIN_BUNDLE_IDENTIFIER], nil)];
        }
        
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
            data->Data = (uint8*)malloc(1);
            
            if (NULL != data->Data) {
                data->Length = 1;

                data->Data[0] = (unsigned char)(theInt);
            }
        } else if (theInt < 0x10000) {
            data->Data = (uint8*)malloc(2);
            
            if (NULL != data->Data) {
                data->Length = 2;

                data->Data[0] = (unsigned char)(theInt >> 8);
                data->Data[1] = (unsigned char)(theInt);
            }
        } else if (theInt < 0x1000000) {
            data->Data = (uint8*)malloc(3);
            
            if (NULL != data->Data) {
                data->Length = 3;

                data->Data[0] = (unsigned char)(theInt >> 16);
                data->Data[1] = (unsigned char)(theInt >> 8);
                data->Data[2] = (unsigned char)(theInt);
            }
        } else {
            data->Data = (uint8*)malloc(4);
            
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
            uint8 *bp = data->Data;
            
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
