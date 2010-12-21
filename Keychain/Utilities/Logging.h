//  
//  Logging.h
//  Keychain
//  
//  Created by Wade Tregaskis on Wed Jan 26 2005.
//
//  Copyright (c) 2005 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/*! @header Logging
    @abstract Defines various macro's for logging output to various places.
    @discussion To make the Keychain framework suitable for many uses, it must be able to configure it's logging in various ways.  These included turning it on/off at compile time, and determining where debug output goes (either the syslog, standard out or standard error, for example).

                The default behaviours are:

                    <li>PDEBUG/PDEBUGC -> System log</li>
                    <li>PSTDERR/PSTDERRC -> Standard error</li>
                    <li>PSTDOUT/PSTDOUTC -> Standard output</li>
                    <li>PSYSLOG/PSYSLOGC -> System log</li>

                There are various compile-time flags which change how these macro's are defined.  They are:

                    <li>NO_PSYSLOG - If defined and true, output from PSYSLOG/PSYSLOGC will be surpressed.</li>
                    <li>NO_PSTDERR - If defined and true, output from PSTDERR/PSTDERRC will be surpressed.</li>
                    <li>NO_PSTDOUT - If defined and true, output from PSTDOUT/PSTDOUTC will be surpressed.</li>
                    <li>NDEBUG or NO_PDEBUG - If either is defined and true, output from PDEBUG/PDEBUGC will be surpressed.  Note: NDEBUG is a generic definition usually set by the compiler (or Xcode) based on your compile preferences.</li>

                    <li>PDEBUG_TO_STDOUT - If defined and true all output via PDEBUG/PDEBUGC will go to standard out.  The behaviour is undefined if DEBUG_TO_STDERR is also defined and true.</li>
                    <li>PDEBUG_TO_STDERR - If defined and true all output via PDEBUG/PDEBUGC will go to standard error.  The behaviour is undefined if DEBUG_TO_STDOUT is also defined and true.</li>

                    <li>PSTDERR_TO_SYSLOG - If defined and true all output via PSTDERR/PSTDERRC will be instead routed to the syslog.  The result is undefined if PSTDERR_TO_STDOUT is also defined and true.</li>
                    <li>PSTDERR_TO_STDOUT - If defined and true all output via PSTDERR/PSTDERRC will be instead routed to standard out.  The result is undefined if PSTDERR_TO_SYSLOG is also defined and true.</li>

                    <li>PSTDOUT_TO_SYSLOG - If defined and true all output via PSTDOUT/PSTDOUTC will be instead routed to the syslog.  The result is undefined if PSTDOUT_TO_STDERR is also defined and true.</li>
                    <li>PSTDOUT_TO_STDERR - If defined and true all output via PSTDOUT/PSTDOUTC will be instead routed to standard error.  The result is undefined if PSTDOUT_TO_SYSLOG is also defined and true.</li>

                    <li>PSYSLOG_TO_STDOUT - If defined and true all output via PSYSLOG/PSYSLOGC will be instead routed to standard out.  The result is undefined if PSYSLOG_TO_STDERR is also defined and true.</li>
                    <li>PSYSLOG_TO_STDERR - If defined and true all output via PSYSLOG/PSYSLOGC will be instead routed to standard error.  The result is undefined if PSYSLOG_TO_STDOUT is also defined and true.</li>

					<li>TAG_SYSLOG_MESSAGES - If undefined or true then [at least] the function name and line number will be prefixed to syslog messages.  If INCLUDE_FILE_IN_LOG_TAGS is defined and true the file name will also be logged.</li>
					<li>TAG_STDOUT_MESSAGES - If undefined or true then [at least] the function name and line number will be prefixed to stdout messages.  If INCLUDE_FILE_IN_LOG_TAGS is defined and true the file name will also be logged.</li>
					<li>TAG_STDERR_MESSAGES - If undefined or true then [at least] the function name and line number will be prefixed to stderr messages.  If INCLUDE_FILE_IN_LOG_TAGS is defined and true the file name will also be logged.</li>

					<li>INCLUDE_FILE_IN_LOG_TAGS - If defined and true the file name will be included in the tags (if any) added to logging messages - whether these tags are included at all is controlled by TAG_SYSLOG_MESSAGES, TAG_STDOUT_MESSAGES and TAG_STDERR_MESSAGES.

                The macro's which you can use for output are documented (as function calls) individually.  Refer to the appropriate documentation (which should be accessible via the index for this, the Logging, header file).  These macro's will only be defined if they have not already been defined.  In this way you can override them with your own custom versions by simply defining them before you import this header file.

                Note that while the details of the implementations may vary, you can consider these macros as independent of each other.  That is, if you reroute PDEBUG to stderr by defining PDEBUG_TO_STDERR, and also define PSTDERR_TO_SYSLOG, the result is that that calls to PDEBUG go to standard error, and calls to PSTDERR go to the syslog.  This is the defined behaviour that will remain unchanged regardless of the exact implementation. */

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif

#include <syslog.h>
#include <stdarg.h>


#pragma mark **** Internal Functions ****

// The following really aren't intended for direct use outside of the higher-level macros in this file... while you *could* call them directly, you'd best have a bloody good reason to, as I'm purposely not documenting their intended behaviour, and could happily change it in future.

#ifdef __OBJC__
	void _PSYSLOG(const char *FILE, int LINE, const char *func, int priority, NSString *format, ...);
	void _PSTDERR(const char *FILE, int LINE, const char *func, int priority, NSString *format, ...);
	void _PSTDOUT(const char *FILE, int LINE, const char *func, int priority, NSString *format, ...);
#else
	#define _PSYSLOG #error PSYSLOG not supported in non-Objective-C source.
	#define _PSTDERR #error PSTDERR not supported in non-Objective-C source.
	#define _PSTDOUT #error PSTDOUT not supported in non-Objective-C source.
#endif

void _PSYSLOGC(const char *FILE, int LINE, const char *func, int priority, const char *format, ...) __attribute__ ((format (printf, 5, 6)));
void _PSTDERRC(const char *FILE, int LINE, const char *func, int priority, const char *format, ...) __attribute__ ((format (printf, 5, 6)));
void _PSTDOUTC(const char *FILE, int LINE, const char *func, int priority, const char *format, ...) __attribute__ ((format (printf, 5, 6)));


#pragma mark 
#pragma mark **** Public Functions ****


/*! @function PSYSLOG
    @abstract Logs NSString-style formatted output to the syslog.
    @discussion PSYSLOG assumes the format string is NSString-style, meaning it supports all the printf-style arguments as well as %\@ for Objective-C objects.

                You may use PSYSLOG for any user-orientated messages in a GUI application, where PSTDOUT/PSTDERR may not produce user-visible output, or may produce output that you don't wish to cloud with certain messages.

                PSYSLOG is only defined for Objective-C sources, obviously.  For other languages, you need to use PSYSLOGC.
	@param priority The priority at which to log, as a standard syslog(3) value.
    @param format The format string (as an NSString, not a C string).  Should not be nil.
    @param args A variable number of arguments suitable for the given 'format' string. */

#ifdef __OBJC__
    #ifndef PSYSLOG
        #if NO_PSYSLOG
            #define PSYSLOG(priority, format, ...) /* Do nothing */
        #elif PSYSLOG_TO_STDOUT
            #define PSYSLOG(priority, format, ...) _PSTDOUT(__FILE__, __LINE__, __func__, priority, format, ## __VA_ARGS__)
        #elif PSYSLOG_TO_STDERR
            #define PSYSLOG(priority, format, ...) _PSTDERR(__FILE__, __LINE__, __func__, priority, format, ## __VA_ARGS__)
        #else
            #define PSYSLOG(priority, format, ...) _PSYSLOG(__FILE__, __LINE__, __func__, priority, format, ## __VA_ARGS__)
        #endif
    #endif
#endif

/*! @function PSYSLOGC
    @abstract Logs printf-style formatted output to the syslog.
    @discussion PSYSLOGC is a C-style version of PSYSLOG.  That is, it takes a C string instead of an NSString as the argument, and is guaranteed only to support printf-style format strings - NSString extensions may or may not be supported, and should not be relied upon.

                You may use PSYSLOG for any user-orientated messages in a GUI application, where PSTDOUT/PSTDERR may not produce user-visible output, or may produce output that you don't wish to cloud with certain messages.
	@param priority The priority at which to log, as a standard syslog(3) value.
    @param format The format string (as a C string, not an NSString).  Should not be NULL.
    @param args A variable number of arguments suitable for the given 'format' string. */

#ifndef PSYSLOGC
    #if NO_PSYSLOG
        #define PSYSLOGC(priority, format, ...) /* Do nothing */
    #elif PSYSLOG_TO_STDOUT
        #define PSYSLOGC(priority, format, ...) _PSTDOUTC(__FILE__, __LINE__, __func__, priority, format, ## __VA_ARGS__)
    #elif PSYSLOG_TO_STDERR
        #define PSYSLOGC(priority, format, ...) _PSTDERRC(__FILE__, __LINE__, __func__, priority, format, ## __VA_ARGS__)
    #else
        #define PSYSLOGC(priority, format, ...) _PSYSLOGC(__FILE__, __LINE__, __func__, priority, format, ## __VA_ARGS__)
    #endif
#endif

/*! @function PSYSLOGND
    @abstract Logs NSString-style formatted output to syslog iff debugging is not enabled.
    @discussion PSYSLOGND assumes the format string is an NSString containing NSString-style formatting, meaning it supports both printf-style arguments and the %\@ for Objective-C objects.

                Use PSYSLOGND for any syslog messages that you <i>don't</i> want to be visible during debugging.

                PSYSLOGND is only defined when compiling as Objective-C.  For other languages, you may need to use PSYSLOGCND.
	@param priority The priority at which to log, as a standard syslog(3) value.
    @param format The format string (as an NSString, not a C string).  Should not be nil.
    @param args A variable number of arguments suitable for the given 'format' string. */

#ifdef __OBJC__
    #ifndef PSYSLOGND
		#if NDEBUG
			#define PSYSLOGND PSYSLOG
		#else
			#define PSYSLOGND(priority, format, ...) /* Do nothing */
		#endif
    #endif
#endif

/*! @function PSYSLOGCND
    @abstract Logs printf-style formatted output to syslog iff debugging is not enabled.
    @discussion PSYSLOGCND assumes the format string is printf-style, meaning it is a C string (not an NSString) and supports only printf-style arguments, not the %\@ for Objective-C objects.

                Use PSYSLOGCND for any syslog messages that you <i>don't</i> want to be visible during debugging.
	@param priority The priority at which to log, as a standard syslog(3) value.
	@param format The format string (as a C string, not an NSString).  Should not be NULL.
    @param args A variable number of arguments suitable for the given 'format' string. */

#ifndef PSYSLOGCND
	#if NDEBUG
		#define PSYSLOGCND PSYSLOGC
	#else
		#define PSYSLOGCND(priority, format, ...) /* Do nothing */
	#endif
#endif


/*! @function PSTDERRC
    @abstract Logs printf-style formatted output to standard error.
    @discussion PSTDERRC assumes the format string is printf-style, meaning it is a C string (not an NSString) and supports only printf-style arguments, not the %\@ for Objective-C objects.

                Use PSTDERRC for any user-orientated error messages.  Remember, though, that GUI applications may not have a user-visible standard error, and so the messages may be lost.  Best to only use this macro in CLI programs, or with PSTDERR_TO_SYSLOG defined.
    @param format The format string (as a C string, not an NSString).  Should not be NULL.
    @param args A variable number of arguments suitable for the given 'format' string. */

#ifndef PSTDERRC
    #if NO_PSTDERR
        #define PSTDERRC(format, ...) /* Do nothing */
    #elif PSTDERR_TO_SYSLOG
        #define PSTDERRC(format, ...) _PSYSLOGC(__FILE__, __LINE__, __func__, LOG_ERR, format, ## __VA_ARGS__)
    #elif PSTDERR_TO_STDOUT
        #define PSTDERRC(format, ...) _PSTDOUTC(__FILE__, __LINE__, __func__, LOG_ERR, format, ## __VA_ARGS__)
    #else
        #define PSTDERRC(format, ...) _PSTDERRC(__FILE__, __LINE__, __func__, LOG_ERR, format, ## __VA_ARGS__)
    #endif
#endif

/*! @function PSTDERRCND
    @abstract Logs printf-style formatted output to standard error iff debugging is not enabled.
    @discussion PSTDERRCND assumes the format string is printf-style, meaning it is a C string (not an NSString) and supports only printf-style arguments, not the %\@ for Objective-C objects.

                Use PSTDERRCND for any user-orientated error messages.  Remember, though, that GUI applications may not have a user-visible standard error, and so the messages may be lost.  Best to only use this macro in CLI programs, or with PSTDERR_TO_SYSLOG defined.
    @param format The format string (as a C string, not an NSString).  Should not be NULL.
    @param args A variable number of arguments suitable for the given 'format' string. */

#ifndef PSTDERRCND
	#if NDEBUG
		#define PSTDERRCND PSTDERRC
	#else
		#define PSTDERRCND(format, ...) /* Do nothing */
	#endif
#endif

/*! @function PSTDERR
    @abstract Logs NSString-style formatted output to standard error.
    @discussion PSTDERR assumes the format string is an NSString containing NSString-style formatting, meaning it supports both printf-style arguments and the %\@ for Objective-C objects.

                Use PSTDERR for any user-orientated error messages.  Remember, though, that GUI applications may not have a user-visible standard error, and so the messages may be lost.  Best to only use this macro in CLI programs, or when the PSTDERR_TO_SYSLOG compile-time flag is defined.

                PSTDERR is only defined when compiling as Objective-C.  For other languages, you may need to use PSTDERRC.
    @param format The format string (as an NSString, not a C string).  Should not be nil.
    @param args A variable number of arguments suitable for the given 'format' string. */

#ifdef __OBJC__
    #ifndef PSTDERR
        #if NO_PSTDERR
            #define PSTDERR(format, ...) /* Do nothing */
        #elif PSTDERR_TO_SYSLOG
            #define PSTDERR(format, ...) _PSYSLOG(__FILE__, __LINE__, __func__, LOG_ERR, format, ## __VA_ARGS__)
        #elif PSTDERR_TO_STDOUT
            #define PSTDERR(format, ...) _PSTDOUT(__FILE__, __LINE__, __func__, LOG_ERR, format, ## __VA_ARGS__)
        #else
            #define PSTDERR(format, ...) _PSTDERR(__FILE__, __LINE__, __func__, LOG_ERR, format, ## __VA_ARGS__)
        #endif
    #endif
#endif

/*! @function PSTDERRND
    @abstract Logs NSString-style formatted output to standard error iff debugging is not enabled.
    @discussion PSTDERRND assumes the format string is an NSString containing NSString-style formatting, meaning it supports both printf-style arguments and the %\@ for Objective-C objects.

                Use PSTDERRND for any user-orientated error messages that you <i>don't</i> want to be visible during debugging.  Remember, though, that GUI applications may not have a user-visible standard error, and so the messages may be lost.  Best to only use this macro in CLI programs, or when the PSTDERR_TO_SYSLOG compile-time flag is defined.

                PSTDERRND is only defined when compiling as Objective-C.  For other languages, you may need to use PSTDERRCND.
    @param format The format string (as an NSString, not a C string).  Should not be nil.
    @param args A variable number of arguments suitable for the given 'format' string. */

#ifdef __OBJC__
    #ifndef PSTDERRND
		#if NDEBUG
			#define PSTDERRND PSTDERR
		#else
			#define PSTDERRND(format, ...) /* Do nothing */
		#endif
    #endif
#endif

/*! @function PSTDOUTC
    @abstract Logs printf-style formatted output to standard output.
    @discussion PSTDOUTC assumes the format string is printf-style, meaning it supports only printf-style arguments, not the %\@ for Objective-C objects.

                Use PSTDOUTC for any user-orientated messages that don't explicitly relate to an error.  You might use it to print status indications, general information, or similar such purposes.  Remember that in GUI programs there may not be a user-visible standard out, and so these messages will be lost.  Best to only use this macro in CLI programs, or when the PSTDOUT_TO_SYSLOG compile-time flag is defined.
    @param format The format string (as a C string, not an NSString).  Should not be NULL.
    @param args A variable number of arguments suitable for the given 'format' string. */

#ifndef PSTDOUTC
    #if NO_PSTDOUT
        #define PSTDOUTC(format, ...) /* Do nothing */
    #elif PSTDOUT_TO_SYSLOG
        #define PSTDOUTC(format, ...) _PSYSLOGC(__FILE__, __LINE__, __func__, LOG_INFO, format, ## __VA_ARGS__)
    #elif PSTDOUT_TO_STDERR
        #define PSTDOUTC(format, ...) _PSTDERRC(__FILE__, __LINE__, __func__, LOG_INFO, format, ## __VA_ARGS__)
    #else
        #define PSTDOUTC(format, ...) _PSTDOUTC(__FILE__, __LINE__, __func__, LOG_INFO, format, ## __VA_ARGS__)
    #endif
#endif

/*! @function PSTDOUT
    @abstract Logs NSString-style formatted output to standard output.
    @discussion PSTDOUT assumes the format string is an NSString in NSString-style, meaning it supports both printf-style arguments and the %\@ for Objective-C objects.

                Use PSTDOUT for any user-orientated messages that don't explicitly relate to an error.  You might use it to print status indications, general information, or similar such purposes.  Remember that in GUI programs there may not be a user-visible standard out, and so these messages will be lost.  Best to only use this macro in CLI programs, or when the PSTDOUT_TO_SYSLOG compile-time flag is defined.

                Note that PSTDOUT is only defined for Objective-C sources.  For other languages, you may need to use PSTDOUTC.
    @param format The format string (as an NSString, not a C string).  Should not be nil.
    @param args A variable number of arguments suitable for the given 'format' string. */

#ifdef __OBJC__
    #ifndef PSTDOUT
        #if NO_STANDARD_OUTPUT
            #define PSTDOUT(format, ...) /* Do nothing */
        #elif PSTDOUT_TO_SYSLOG
            #define PSTDOUT(format, ...) _PSYSLOG(__FILE__, __LINE__, __func__, LOG_INFO, format, ## __VA_ARGS__)
        #elif PSTDOUT_TO_STDERR
            #define PSTDOUT(format, ...) _PSTDERR(__FILE__, __LINE__, __func__, LOG_INFO, format, ## __VA_ARGS__)
        #else
            #define PSTDOUT(format, ...) _PSTDOUT(__FILE__, __LINE__, __func__, LOG_INFO, format, ## __VA_ARGS__)
        #endif
    #endif
#endif

/*! @function PDEBUG
    @abstract Logs NSString-style formatted output to an appropriate place (e.g. the syslog, standard err, etc).
    @discussion PDEBUG is intended for outputing debug information that the end user need not see in normal operation.  Indeed, by default all calls to PDEBUG/PDEBUGC are stripped at compile time in release builds.

                You should use PDEBUG for any messages which meet any of the following criteria:

                    <li>They contain only programmer-centric data which will be meaningless to an end user.</li>
                    <li>They may be printed very frequently.</li>
                    <li>They indicate events or information not necessary for normal program operation.<li>

                If necessary, use a PDEBUG and PSTDERR/PSTDOUT pair; the PSTDERR/PSTDOUT to convey user-orientated messages (e.g. "Certificate generation failed due to invalid parameters") and the PDEBUG to list the parameters and their actual values.

                Note that PDEBUG is only supported for Objective-C sources.  For other languages, you may need to use PDEBUGC.
    @param format The format string (as an NSString, not a C string).  Should not be nil.
    @param args A variable number of arguments suitable for the given 'format' string. */

#ifdef __OBJC__
    #ifndef PDEBUG
        #if NDEBUG || NO_PDEBUG
            #define PDEBUG(format, ...) /* Do nothing */
        #elif PDEBUG_TO_STDOUT
			#define PDEBUG(format, ...) _PSTDOUT(__FILE__, __LINE__, __func__, LOG_DEBUG, format, ## __VA_ARGS__)
        #elif PDEBUG_TO_STDERR
			#define PDEBUG(format, ...) _PSTDERR(__FILE__, __LINE__, __func__, LOG_DEBUG, format, ## __VA_ARGS__)
        #else
			#define PDEBUG(format, ...) _PSYSLOG(__FILE__, __LINE__, __func__, LOG_DEBUG, format, ## __VA_ARGS__)
        #endif
    #endif
#endif

/*! @function PDEBUGC
    @abstract Logs printf-style formatted output to an appropriate place (e.g. the syslog, standard err, etc).
    @discussion PDEBUGC is intended for outputing debug information that the end user need not see in normal operation.  Indeed, by default all calls to PDEBUG/PDEBUGC are stripped at compile time in release builds.

                You should use PDEBUGC for any messages which meet any of the following criteria:

                    <li>They contain only programmer-centric data which will be meaningless to an end user.</li>
                    <li>They may be printed very frequently.</li>
                    <li>They indicate events or information not necessary for normal program operation.<li>

                If necessary, use a PDEBUGC and PSTDERRC/PSTDOUTC pair; the PSTDERRC/PSTDOUTC to convey user-orientated messages (e.g. "Certificate generation failed due to invalid parameters") and the PDEBUGC to list the parameters and their actual values.
    @param format The format string (as a C string, not an NSString).  Should not be NULL.
    @param args A variable number of arguments suitable for the given 'format' string. */

#ifndef PDEBUGC
    #if NDEBUG || NO_PDEBUG
        #define PDEBUGC(format, ...) /* Do nothing */
    #elif PDEBUG_TO_STDOUT
		#define PDEBUGC(format, ...) _PSTDOUTC(__FILE__, __LINE__, __func__, LOG_DEBUG, format, ## __VA_ARGS__)
    #elif PDEBUG_TO_STDERR
		#define PDEBUGC(format, ...) _PSTDERRC(__FILE__, __LINE__, __func__, LOG_DEBUG, format, ## __VA_ARGS__)
    #else
		#define PDEBUGC(format, ...) _PSYSLOGC(__FILE__, __LINE__, __func__, LOG_DEBUG, format, ## __VA_ARGS__)
    #endif
#endif
