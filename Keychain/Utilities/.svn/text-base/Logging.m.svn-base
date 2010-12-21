//  
//  Logging.m
//  Keychain
//  
//  Created by Wade Tregaskis on Sun Sep 23 2007.
//
//  Copyright (c) 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import <Foundation/Foundation.h>
#include <syslog.h>
#include <stdarg.h>


const char* _nameOfSyslogPriority(int priority) __attribute__ ((pure));

const char* _nameOfSyslogPriority(int priority) {
	switch (priority) {
		case LOG_EMERG:
			return "Emergency"; break;
		case LOG_ALERT:
			return "Alert"; break;
		case LOG_CRIT:
			return "Critical"; break;
		case LOG_ERR:
			return "Error"; break;
		case LOG_WARNING:
			return "Warning"; break;
		case LOG_NOTICE:
			return "Notice"; break;
		case LOG_INFO:
			return "Info"; break;
		case LOG_DEBUG:
			return "Debug"; break;
		default:
			return "Unknown";
	}
}

NSString* _prepareLogMessage(const char *FILE, int LINE, const char *func, BOOL tag, int priority, BOOL includePriority, NSString *format, va_list vargs) {
	NSMutableString *string = [[NSMutableString alloc] initWithFormat:format arguments:vargs];
	
	if (nil == string) {
		string = @"Error logging error message (unable to render log message).";
	} else {
		if ('\n' != [string characterAtIndex:([string length] - 1)]) {
			[string appendString:@"\n"];
		}
		
		if (tag) {
			NSString *prefix;
			
#if INCLUDE_FILE_IN_LOG_TAGS
			if (includePriority) {
				prefix = [[NSString alloc] initWithFormat:@"[%s] %s (%s:%d): ", _nameOfSyslogPriority(priority), func, FILE, LINE];
			} else {
				prefix = [[NSString alloc] initWithFormat:@"%s (%s:%d): ", func, FILE, LINE];
			}
#else
#pragma unused(FILE)
			if (includePriority) {
				prefix = [[NSString alloc] initWithFormat:@"[%s] %s:%d: ", _nameOfSyslogPriority(priority), func, LINE];
			} else {
				prefix = [[NSString alloc] initWithFormat:@"%s:%d: ", func, LINE];
			}
#endif
	
			if (nil == prefix) {
				// We've got the actual log message, so, we'll just not have a prefix... nothing we can really do about that.
			} else {
				[string insertString:prefix atIndex:0];
				[prefix release];
			}
		}
	}
	
	return string;
}

char* _prepareLogMessageC(const char *FILE, int LINE, const char *func, int tag, int priority, int includePriority, const char *format, va_list vargs) {
	char *string = NULL;
	int err;
	
	err = vasprintf(&string, format, vargs);
	
	if (0 > err) {
		string = "Error logging error message (unable to render log message).";
	} else {
		if (0 != tag) {
			char *prefix;
		
#if INCLUDE_FILE_IN_LOG_TAGS
			if (0 != includePriority) {
				err = asprintf(&prefix, "[%s] %s (%s:%d): ", _nameOfSyslogPriority(priority), func, FILE, LINE);
			} else {
				err = asprintf(&prefix, "%s (%s:%d): ", func, FILE, LINE);
			}
#else
#pragma unused(FILE)
			if (0 != includePriority) {
				err = asprintf(&prefix, "[%s] %s:%d: ", _nameOfSyslogPriority(priority), func, LINE);
			} else {
				err = asprintf(&prefix, "%s:%d: ", func, LINE);
			}
#endif
		
			if (0 > err) {
				// We've got the actual log message, so, we'll just not have a prefix... nothing we can really do about that.
			} else {
				char *oldString = string;
				
				err = asprintf(&string, "%s%s", prefix, string);
				
				if (0 > err) {
					// We've got the actual log message, so, we'll just not have a prefix... nothing we can really do about that.
					string = oldString;
				} else {
					free(oldString);
				}
				
				free(prefix);
			}
		}
	}
	
	return string;
}


void _PSYSLOG(const char *FILE, int LINE, const char *func, int priority, NSString *format, ...) {
	va_list vargs;
	va_start(vargs, format);

	NSString *string = _prepareLogMessage(FILE,
										  LINE,
										  func,
#if !defined(TAG_SYSLOG_MESSAGES) || TAG_SYSLOG_MESSAGES
										  YES,
#else
										  NO,
#endif
										  priority,
										  NO,
										  format,
										  vargs);
	
	va_end(vargs);
	
	if (nil == string) {
		string = @"Error logging error message (no, really :/ ).";
	}
	
	syslog(priority, "%s", [string UTF8String]);
	
	[string release];
}

void _PSYSLOGC(const char *FILE, int LINE, const char *func, int priority, const char *format, ...) {
	va_list vargs;
	va_start(vargs, format);
	
	char *string = _prepareLogMessageC(FILE,
									   LINE,
									   func,
#if !defined(TAG_SYSLOG_MESSAGES) || TAG_SYSLOG_MESSAGES
									   1,
#else
									   0,
#endif
									   priority,
									   0,
									   format,
									   vargs);
	
	va_end(vargs);
	
	if (NULL == string) {
		string = "Error logging error message (no, really :/ ).";
	}
	
	syslog(priority, "%s", string);
	
	free(string);
}


void _PSTDERR(const char *FILE, int LINE, const char *func, int priority, NSString *format, ...) {
	va_list vargs;
	va_start(vargs, format);
	
	NSString *string = _prepareLogMessage(FILE,
										  LINE,
										  func,
#if !defined(TAG_STDERR_MESSAGES) || TAG_STDERR_MESSAGES
										  YES,
#else
										  NO,
#endif
										  priority,
										  (LOG_ERR != priority),
										  format,
										  vargs);
	
	va_end(vargs);
	
	if (nil == string) {
		string = @"Error logging error message (no, really :/ ).";
	}

	const char *stringUTF8String = [string UTF8String];
	
	int err = fprintf(stderr, "%s", stringUTF8String);

	if (0 > err) {
		// If we couldn't write to stderr it may be because we don't have one; try syslog as a last resort.  This is the same behaviour as NSLog, so I guess it's appropriate.
		syslog(priority, "%s", stringUTF8String);
	}
	
	[string release];
}

void _PSTDERRC(const char *FILE, int LINE, const char *func, int priority, const char *format, ...) {
	va_list vargs;
	va_start(vargs, format);
	
	char *string = _prepareLogMessageC(FILE,
									   LINE,
									   func,
#if !defined(TAG_STDERR_MESSAGES) || TAG_STDERR_MESSAGES
									   1,
#else
									   0,
#endif
									   priority,
									   ((LOG_ERR != priority) ? 1 : 0),
									   format,
									   vargs);
	
	va_end(vargs);
	
	if (NULL == string) {
		string = "Error logging error message (no, really :/ ).";
	}
	
	int err = fprintf(stderr, "%s", string);
	
	if (0 > err) {
		// If we couldn't write to stderr it may be because we don't have one; try syslog as a last resort.  This is the same behaviour as NSLog, so I guess it's appropriate.
		syslog(priority, "%s", string);
	}
	
	free(string);
}


void _PSTDOUT(const char *FILE, int LINE, const char *func, int priority, NSString *format, ...) {
	va_list vargs;
	va_start(vargs, format);
	
	NSString *string = _prepareLogMessage(FILE,
										  LINE,
										  func,
#if !defined(TAG_STDOUT_MESSAGES) || TAG_STDOUT_MESSAGES
										  YES,
#else
										  NO,
#endif
										  priority,
										  (LOG_INFO != priority),
										  format,
										  vargs);
	
	va_end(vargs);
	
	if (nil == string) {
		string = @"Error logging error message (no, really :/ ).";
	}

	const char *stringUTF8String = [string UTF8String];
	
	int err = fprintf(stdout, "%s", stringUTF8String);

	if (0 > err) {
		// We *could* write to syslog, but I don't think it's typical for stdout to go there when stdout is unavailable (in contrast to NSLogs behaviour with stderr, for example).
		//syslog(priority, "%s", stringUTF8String);
	}
	
	[string release];
}

void _PSTDOUTC(const char *FILE, int LINE, const char *func, int priority, const char *format, ...) {
	va_list vargs;
	va_start(vargs, format);
	
	char *string = _prepareLogMessageC(FILE,
									   LINE,
									   func,
#if !defined(TAG_STDOUT_MESSAGES) || TAG_STDOUT_MESSAGES
									   1,
#else
									   0,
#endif
									   priority,
									   ((LOG_INFO != priority) ? 1 : 0),
									   format,
									   vargs);
	
	va_end(vargs);
	
	if (NULL == string) {
		string = "Error logging error message (no, really :/ ).";
	}
	
	int err = fprintf(stdout, "%s", string);
	
	if (0 > err) {
		// We *could* write to syslog, but I don't think it's typical for stdout to go there when stdout is unavailable (in contrast to NSLogs behaviour with stderr, for example).
		//syslog(priority, "%s", string);
	}
	
	free(string);
}
