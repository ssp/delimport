//
//  UtilitySupport.h
//  Keychain
//
//  Created by Wade Tregaskis on Fri Jan 24 2003.
//
//  Copyright (c) 2003 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/*! @header UtilitySupport
    @abstract Provides various basic support functions, primarily for interfacing between the Cocoa world and the CDSA.
    @discussion The CDSA of course uses all it's preferred basic types, CSSM_GUID's, CSSM_DATA's, CSSM_STRING's, etc... all good and fuzzy, but useless to your average Cocoa coder.  Thus, these functions are provided for performing conversions.  In many cases the guts of the implementation is just a single line which you <i>could</i> do yourself, except by using these functions you a) abstract away the details of how to do the conversions, and b) get some sanity checking as all arguments must be valid, helping you catch NULLs/nils sooner.

                Make sure to read the documentation for each function carefully before using it.  Improper use of many of these functions can result in corruption, leaks, or worse.  Of particular note are the copyNSDataToDataNoCopy() and NSDataFromDataNoCopy() functions. */

#import <Foundation/Foundation.h>
#import <Security/Security.h>

#import <errno.h>


/*! @function allocCSSMData
    @abstract Allocates a new CSSM_DATA structure.
    @discussion This convenience function simply allocates and initialises (to an empty state) a CSSM_DATA structure.  You could probably achieve the same effect with a simple call to calloc, but this way is more future compatible by virtue of it's abstraction.  Consequently it should play a key role in maximizing shareholder value for the succeeding quarter looking forward.

                The returned CSSM_DATA is guaranteed to be in the same state as would be returned by a call to clearCSSMData - i.e. it's Data pointer is NULL and it's Length is 0.

				To deallocate the CSSM_DATA and its contents, when you're finished with it, use @link freeCSSMData freeCSSMData@/link.
    @result Returns a new empty CSSM_DATA if successful, NULL otherwise (which most likely indicates a memory allocation error). */

CSSM_DATA* allocCSSMData(void);

/*! @function resetCSSMData
    @abstract 'Resets' a CSSM_DATA structure to an empty state.
    @discussion Resetting a CSSM_DATA is similar to clearing it (using clearCSSMData), except that any existing values within it are ignored.  Thus, you should use resetCSSMData (and definitely <i>not</i> clearCSSMData) to prepare any CSSM_DATA structure prior to use.
    @param data The CSSM_DATA to reset.  Should not be NULL. */

void resetCSSMData(CSSM_DATA *data);

/*! @function clearCSSMData
    @abstract Clears a CSSM_DATA structure back to it's default, empty state.
    @discussion This function releases the memory allocated to the data within the CSSM_DATA, and sets all other appropriate fields to 0 or similar.  It does not free the memory used for the CSSM_DATA structure itself.

                The CSSM_DATA after calling is guaranteed to be in the same state as it would have been when first created using allocCSSMData.
    @param data The CSSM_DATA to return to the default, empty state.  Should not be NULL. */

void clearCSSMData(CSSM_DATA *data);

/*! @function freeCSSMData
    @abstract Frees all memory associated with a CSSM_DATA structure, including that of the structure itself.
    @discussion This function is similar to the clearCSSMData function, except it goes the extra step of freeing the CSSM_DATA structure itself, in addition to it's contents.

                The passed parameter will always be invalid after a call to this function.  Note that you should always consider it invalid from the *start* of the call, if your application is multithreaded; it will most certainly pass through at least one invalid state during the function, which could create all kinds of havoc if another thread tries to use it.

				Typically you would only use this function on CSSM_DATAs that were created using allocCSSMData() (or equivalent, if you create them yourself).  If you only wish to free the contents of the CSSM_DATA, not the structure itself (e.g. you have a CSSM_DATA declared on the stack), use @link clearCSSMData clearCSSMData@/link.
    @param data The CSSM_DATA to free.  It does not have to be already cleared using clearCSSMData.  It is always invalid from the moment this function is called.  Should not be NULL. */

void freeCSSMData(CSSM_DATA *data);

/*! @function copyDataToData
    @abstract Copies a CSSM_DATA structure to another CSSM_DATA structure.
    @discussion The contents of 'source' are copied to 'destination'.  The 'Data' field of destination may be free'd and re-malloc'd if necessary (or, it may be reused).  In any case, don't rely on particular behaviour; it is undefined and indeed may vary both between versions and between parameter sets.
    @param source The source CSSM_DATA to be copied.  Should not be NULL.  If it is NULL, destination will be unmodified.
    @param destination The destination CSSM_DATA in which to copy the contents of 'source'.  Should not be NULL.
    @result Returns 0 if successful, an error code (from <errno.h>) otherwise. */

int copyDataToData(const CSSM_DATA *source, CSSM_DATA *destination);

/*! @function copyNSStringToData
    @abstract Copies an NSString to a given CSSM_DATA structure.
    @discussion The actual bytes copied are those returned by NSString's UTF8String method - i.e. the given string as UTF-8 encoded.
    @param source The source string to copy from.  Should not be nil.
    @param destination The destination to copy to.  This will be cleared of any existing data using clearCSSMData() - make sure it does not contain a dangling data pointer, or free() will get cranky.  Should not be NULL.
    @result Returns 0 if successful, a POSIX error code otherwise (from the standard errno.h). */

int copyNSStringToData(NSString *source, CSSM_DATA *destination);

/*! @function copyNSStringToString
    @abstract Copies an NSString to a CSSM_STRING.
    @discussion CSSM_STRINGs are some stupid fixed-size buffer the CDSA occasionally uses.  We can only imagine.  If the given source string won't fit into the destination, an error occurs and the destination is not modified.  The string is copied as UTF-8 encoded.
    @param source The source string to copy from.  Should not be nil.

                Note that if the source string does not entirely fill the destination buffer, any remaining bytes are set to 0.  This is for security reasons, to prevent any data hanging around longer than expected.
    @param destination The destination CSSM_STRING to copy to.  Should not be NULL.
    @result Returns 0 if successful, a POSIX error code otherwise (from the standard errno.h). */

int copyNSStringToString(NSString *source, CSSM_STRING *destination);

/*! @function dataFromNSString
	@abstract Returns a newly-allocated CSSM_DATA with the contents of the given NSString.
	@discussion The data within the string is copied into the CSSM_DATA, so it's lifetime is independent of the given NSString's.
	@param string The string.  Should not be nil.
	@result Returns a newly-allocated CSSM_DATA containing a copy of the contents of the given string.  The caller takes ownership of this instance and should deallocate it, when finished with it, using @link freeCSSMData freeCSSMData@/link.  Returns NULL if the given string is nil or memory could not be allocated for the CSSM_DATA. */

CSSM_DATA* dataFromNSString(NSString *string);

/*! @function copyNSDataToData
	@abstract Copies the contents of an NSData instance to a CSSM_DATA.
	@discussion The destination CSSM_DATA <i>may</i> be cleared first (using @link clearCSSMData clearCSSMData@/link).
	@param source The NSData to copy the contents of.  Should not be nil - if it is an error may be logged, and no copy will occur.
	@param destination The CSSM_DATA to copy into.  Should not be NULL - if it is an error may be logged, and no copy will occur. */

void copyNSDataToData(NSData *source, CSSM_DATA *destination);

/*! @function copyNSDataToDataNoCopy
	@abstract Replaces the contents of a given CSSM_DATA with that of the given NSData instance.
	@discussion This function is conceptually similar to @link copyNSDataToData copyNSDataToData@/link, except that it doesn't actually copy anything - it sets the destination's contents to the exact same buffer used by the source NSData.  The destination is thus guaranteed to be valid only for the destination of the source NSData, and only if that NSData remains unchanged.

				The destination will be cleared (using @link clearCSSMData clearCSSMData@/link) as part of the replacement.

				Be very careful using this function - lots of stuff goes on inside the Keychain & Security frameworks, and the CDSA itself, even for simple requests.  If you get malloc errors or EXC_BAD_ACCESS faults, you might want to check over any code which uses this method.
	@param source The NSData to 'copy'.  Should not be nil - if it is an error may be logged, and no copy will occur.
	@param destination The CSSM_DATA to 'copy' into.  Should not be NULL - if it is an error may be logged, and no copy will occur. */

void copyNSDataToDataNoCopy(NSData *source, CSSM_DATA *destination);

/*! @function dataFromNSData
	@abstract Returns a newly-allocated CSSM_DATA with the contents of the given NSData.
	@discussion The contents of the given NSData are copied into the CSSM_DATA, so it's lifetime is independent of the given NSData's.
	@param data The data.  Should not be nil.
	@result Returns a newly-allocated CSSM_DATA containing a copy of the contents of the given NSData.  The caller takes ownership of this instance and should deallocate it, when finished with it, using @link freeCSSMData freeCSSMData@/link.  Returns NULL if the given data is nil or memory could not be allocated for the CSSM_DATA. */

CSSM_DATA* dataFromNSData(NSData *data);

/*! @function NSStringFromData
	@abstract Returns an NSString version of the contents of a given CSSM_DATA.
	@discussion The given CSSM_DATA is assumed to use UTF-8 encoding for its contents.  Its contents are copied into the returned string, and thus its lifetime is independent of the original CSSM_DATA's.
	@param data The data to convert to a string.  Should not be NULL.
	@result Returns the given data as a string, assuming UTF-8 encoding, or nil if an error occurs (e.g. NULL was passed for the 'data' parameter, or there is insufficient memory available to create the string, etc). */

NSString* NSStringFromData(const CSSM_DATA *data);

/*! @function NSStringFromNSData
	@abstract Returns an NSString version of the contents of a given NSData.
	@discussion The given NSData is assumed to use UTF-8 encoding for its contents.  Its contents are copied into the returned string, and thus its lifetime is independent of the original NSData's.
	@param data The data to convert to a string.  Should not be nil.
	@result Returns the given data as a string, assuming UTF-8 encoding, or nil if an error occurs (e.g. nil was passed for the 'data' parameter, or there is insufficient memory available to create the string, etc). */

NSString* NSStringFromNSData(NSData *data);

/*! @function NSDataFromNSString
	@abstract Returns an NSData with the UTF-8 representation of a given NSString.
	@param string The NSString to convert to an NSData.  Should not be nil.
	@result Returns the given NSString as an NSData, using UTF-8 encoding, or nil if an error occurs (e.g. nil was passed for the 'string' parameter, or there is insufficient memory available to create the NSData, etc). */

NSData* NSDataFromNSString(NSString *string);

/*! @function NSDataFromData
	@abstract Returns an NSData version of the contents of a given CSSM_DATA.
	@discussion The given CSSM_DATA's contents are copied into the returned NSData, and thus its lifetime is independent of the original CSSM_DATA's.
	@param data The data to convert.  Should not be NULL.
	@result Returns the given data as an NSData, or nil if an error occurs (e.g. NULL was passed for the 'data' parameter, or there is insufficient memory available to create the NSData, etc). */

NSData* NSDataFromData(const CSSM_DATA *data);

/*! @function NSDataFromDataNoCopy
	@abstract Returns an NSData that shares the contents of a given CSSM_DATA.
	@discussion The given CSSM_DATA's contents are wrapped by the returned NSData, <i>not</i> copied.  If 'freeWhenDone' is NO, the CSSM_DATA retains ultimate authority over the contents and remains responsible for deallocating them when necessary.  If 'freeWhenDone' is YES, the returned NSData takes ultimate authority over the contents and will deallocate them when it itself is deallocated.

				In either case, the returned NSData is guaranteed to be valid only while the originating CSSM_DATA is unchanged.

				Be very careful using this function - lots of stuff goes on inside the Keychain & Security frameworks, and the CDSA itself, even for simple requests.  If you get malloc errors or EXC_BAD_ACCESS faults, you might want to check over any code which uses this method.
	@param data The data to convert.  Should not be NULL.
	@param freeWhenDone If YES, the data will be freed when the NSData is deallocated.
	@result Returns the given data as an NSData, or nil if an error occurs (e.g. NULL was passed for the 'data' parameter). */

NSData* NSDataFromDataNoCopy(const CSSM_DATA *data, BOOL freeWhenDone);

/*! @function OIDsAreEqual
	@abstract Compares to OIDs for equality.
	@discussion "Equality" is defined in this case to mean that both OIDs identify the same object - i.e. they are logically equivalent.  The OIDs may not necessarily be literally equivalent in terms of their underlying storage or representation.
	@param a One OID.
	@param b A second OID.
	@result Returns YES if the two OIDs are equal. */

BOOL OIDsAreEqual(const CSSM_OID *a, const CSSM_OID *b);

/*! @function NSDataFromHumanNSString
    @abstract Converts a human-readable representation of some raw data (i.e. hex form) to the raw data form.
    @discussion This is the opposite operation to NSData's description method, and is entirely compatible and complimentary.  It ignores all newlines, carriage returns, spaces, tabs, and angle-brackets ('<' and '>').  It is, of course, not case sensitive.
    @param string The string containing the human readable hex form, e.g. "<5d2f 5aa3>" or "0x836D" etc.
    @result nil if the string is not in a valid format, the resulting NSData otherwise. */

NSData* NSDataFromHumanNSString(NSString *string);

// BOOL DBUniqueRecordIDsAreEqual(const CSSM_DB_UNIQUE_RECORD *a, const CSSM_DB_UNIQUE_RECORD *b); // Didn't work from start; can't compare unique records, as in the current implementation (Tiger) of the Security framework there is *not* a 1:1 mapping between CSSM_DB_UNIQUE_RECORDs and the actual records.
