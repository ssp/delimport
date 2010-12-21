//
//  Hashcash.h
//  Keychain
//
//  Created by Wade Tregaskis on 12/11/04.
//
//  Copyright (c) 2005 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>

#import <Keychain/CSSMModule.h>


/*! @constant kHashcashDefaultSeedLength
	@abstract The maximum number of bytes of random data to seed each new Hashcash instance with.
	@discussion This defines how many bytes are used to seed the "salt" of each new Hashcash instance.  It is a <i>maximum</i>, not an exact number - the result is masked against the characters that are representable in a hashcash string, and any that don't match are discarded.

				XXX: this should be changed to be an exact length, and a class property... and also, settable on instances...

				If not defined it defaults to 16. */

#ifndef kHashcashDefaultSeedLength
	#define kHashcashDefaultSeedLength 16
#endif

/*! @constant kHashcashSuffixLengthLimit
	@abstract The maximum length of the Hashcash suffix.
	@discussion This defines the maximum length of the stamp suffix, in bytes.  By default (XXX: only behaviour supported right now) the Hashcash class tries for the smallest suffix possible.  As such, if it exceeds this limit without finding a match it will abort, putting some kind of bound on how long it will search (where "bound" may be measured in centuries... but it's still a bound ;) ).

				XXX: this should be a class property, and/or a per-instance property... there also needs to be a way to set no limit.

				If not defined it defaults to 128. */

#ifndef kHashcashSuffixLengthLimit
	#define kHashcashSuffixLengthLimit 128
#endif

/*! @constant kDefaultHashcashStringFormat
	@abstract Specifies the NSCalendarDate formatter for the date in stamps.
	@discussion This determines the format used for stamp dates, both when generating stamps and when validating them.  When performing validation as many fields are parsed as are provided in the given stamp; it is not a requirement that the stamp's date match exactly this default format.

				XXX: again, this is retarded - it should be a class property as a default, overridable in instances.

				The default value is "%y%m%d%H%M%S". */

extern NSString *kDefaultHashcashStringFormat;


/*! @class Hashcash
	@abstract Hashcash stamp generation and verification.
	@discussion <b>About Hashcash</b>Hashcash is a proof-of-work mechanism aimed at email and similar systems, for use in Denial of Service protection and spam filtering, among others.  It relies on one-way functions (hashes) which have the useful property that it is very difficult to determine the original text for a given hash, but very easy to verify that some text does indeed hash to a particular value.

				The basic idea of Hashcash is that party A specifies a minimum "value" of stamps it will accept in order to provide some service to party B.  Party B then tries to find a string (of a defined format and containing relevant information about the transaction) that hashes to a sufficient value.  The "value" of a stamp is measured in the number of contiguous zeros at the start of it's hash.  This is a concession to the fact that finding an exact match for a given hash is virtually impossible (which is the idea with any cryptographically-useful hash function).  It also allows party A to control the "cost" of using it's services, by requiring shorter or longer lengths of 0's.  Computation cost increases exponentially with the length of 0's required.

				Naturally as computers increase in speed the cost to compute stamps decreases, so a 20-bit stamp (20 leading 0's) that used to take many minutes can now be computed in seconds.  As such, you will need to adapt your use as appropriate.  Also keep in mind that there is no guaranteed minimum time required to generate a sufficient stamp - it could be the very first value that is tried.  Statistically, however, there is an average cost associated with a given stamp value, so over a sufficient number of transactions this theoretical average should be approximated reasonably well.

				<b>More Information</b>
				The official website for Hashcash is <a href="http://www.hashcash.org/">http://www.hashcash.org/</a>.  Of particular interest is the FAQ at <a href="http://www.hashcash.org/faq/">http://www.hashcash.org/faq/</a>, which provides much more information about all aspects of Hashcash.  Source code and pre-built binaries for various platforms and in numerous languages are also available.

				Note that the implementation used presently by the Keychain framework is based on Apple's implementation of the CDSA, not the standalone source from the website.  It is compatible, but performance may differ (to be honest, this implementation is if anything slower than the reference - in future a new, faster implementaton may be chosen).

				<b>Using Hashcash</b>

				Hashcash stamps have the format "<version>:<fields: ...>".  This implementation supports Hashcash versions 0 and 1.  Their formats are:

				v0: "0:<date>:<resource>:<suffix>"
				v1: "1:<bits>:<date>:<resource>:<extensions>:<salt>:<suffix>"

				The meaning of the fields are:

				<ul>
					<li>Version - The Hashcash version number.  Currently only '0' and '1' are supported.</li>
					<li>Bits - The claimed value of the stamp - i.e. number of leading 0's.  This is decided before you generate the stamp, and is typically specified by the party that requires the proof-of-work.  By specifying the claimed value explicitly one cannot opportunistically take advantage of a lucky find of a high-value hash, as the real value of a stamp is the minimum of either it's claimed value or it's actual value.</li>
					<li>Date - The date at which the stamp is valid.  Typically this is the date at which the stamp was generated, but it need not be - stamps can be generated ahead of time if necessary.  It is up to the users of Hashcash to determine what constitues and active, valid stamp, but it is typical - with email - to accept stamps that are dated up to 2 days in the future or 30 days in the past.</li>
					<li>Resource - The resource associated with the stamp - e.g. the email address of the party generating the stamp, in an email system.  Could be a username, a computer name, IP address, etc.  It should be something which uniquely identifies a particular user, to ensure stamps are not transferred between users.</li>
					<li>Extensions - A field for 3rd party extensions.  It may be empty, or may contains some number of fields, separated by semicolons, of the format either "name" or "name=value".</li>
					<li>Salt - Arbitrary data provided by the stamp requestor which the stamp generator must include verbatim.  This helps prevent pre-calculation of stamps.  It does not have to be used - it can be set to nil, in which the field is empty and pre-calculation is implicitly permitted.</li>
					<li>Suffix - Arbitrary data used by the generator to find matches.  The purpose of this field is to allow the generator to vary the contents of the stamp in order to change the value it hashes to, and thus search for suffixes which produce the desired value hash.</li>
				</ul>

				So, as an example, say you have a server "Bob" which provides some service to users.  In order to use its services, clients must produce a stamp of value 20.  A typical transaction would thus go something like:

					 --> Client "Alice" connects to Bob.
					<--  Bob informs Alice that a stamp of value 20 is required with a salt of "8dnbks8eth2308h" (Bob generates this salt using a source of random data, to ensure it is unpredictable to Alice).
					..   Alice generates a stamp with 'bits' set to 20, 'date' set to the current date & time, 'resource' set to her unique ID for Bob - e.g. "alice\@bob.com", 'extensions' left empty, 'salt' set to that provided by Bob.
					 --> Alice submits the stamp to Bob.
					  .. Bob validates the 'bits', 'date', 'resource' and 'salt' field of the given stamp, then hashes the stamp and verifies that it does indeed provide the required 20 leading bits (or more) of 0's.
					<--  Bob provides Alice with the desired services.

				Note that the 'extensions' field may be ignored by Bob, or may have some meaning which Bob also validates in some manner.  This is entirely up to Bob and the context in which he uses Hashcash.

				In terms of code, Bob would generate the salt using generateRandomData() (or a variant thereof) and send that to Alice, along with the stamp cost.  Alice would create a new Hashcash instance using [[Hashcash alloc] initWithModule:<module>], then:

				<ol>
					<li>Set the version if desired using setVersion: (default is 1).</li>
					<li>Set the bits using setBits: to whatever Bob specified (e.g. 20).</li>
					<li>Set the resource to her unique ID using setResource:.</li>
					<li>Set the salt to whatever Bob provided using setSalt:.</li>
					<li>Call "findSuffix" to generate the suffix necessary to make the receiver valid.</li>
					<li>Call "stamp" to obtain the stamp.</li>
				</ul>

				Alice can then send the stamp to Bob.  When Bob receives the stamp, as a string, he can initialise a new Hashcash instance from it using [Hashcash hashcashFromStamp:<stamp> module:<module>], verify its claimed value ("bits"), "version" if desired, "date", "resource", "extensions" if desired, and "salt".  Finally, Bob can check if the stamp really is worth what it claims by calling "valid", which returns YES if that is the case.

				Given that all passes, Bob can then be reasonably assured Alice had to perform some amount of busy work on Bob's behalf, and is thus now deserving of Bob's services. */

// XXX: this seemed nice and elegant to start with, and I guess it's not horrible, but really when you look at examples like the above, it's a bit tricky... there really needs to be some kind of "validator" (Postmaster?) object which will provide a suitable salt, then a separate object for the client-side to take the general "parameters" from the server, generate the stamp, which should then go back to a "validator" (ideally the same one) to be verified.  Verification should take into account preferences for range of valid dates, claimed value, checking of relevant fields (e.g. resource, salt, etc), and so forth.  Too much is manual at the moment, and the unified class is flexible, for sure, but hardly task-orientated.

@interface Hashcash : NSObject {
    CSSMModule *_CSPModule;
    unsigned int _version;
    unsigned int _bits;
    NSCalendarDate *_date;
    NSString *_resource;
    NSString *_extensions;
    NSString *_salt;
    NSString *_suffix;
}

/*! @method stampFieldCharacterSet
	@abstract The set of acceptable characters for stamp fields (except the date field).
	@discussion This set defines which characters may appear in a stamp (excepting the date field, which is a further subset of these).  Currently, the acceptable characters are:

					abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789,./'"[]{}\\|=+-_)(*&^%$#\@!`~;<>?

				XXX: what if this depends on version, i.e. v2 allows other characters?  Should have version parameter, or perhaps just make this an instance method.
 */

+ (NSCharacterSet*)stampFieldCharacterSet;

/*! @method stampDateCharacterSet
	@abstract The set of acceptable characters for the 'date' field.
	@discussion This set defines which characters may appear in the 'date' field of a stamp.  Currently, the acceptable characters are:

					0123456789

				XXX: what if this depends on version, i.e. v2 allows other characters?  Should have version parameter, or perhaps just make this an instance method.
 */

+ (NSCharacterSet*)stampDateCharacterSet;

/*! @method hashcashFromStamp:module:
	@abstract Creates and returns a new Hashcash instance for the given stamp.
	@discussion A Hashcash instance will be returned even if the stamp is invalid, provided it is in the correct format for a v0 or v1 stamp, so this method is by no means any sort of validator of the stamp.
	@param stamp The stamp.  Should not be nil.
	@param CSPModule The CSP module to use for hashing operations.  The given CSP must support the SHA-1 hash.  Pass nil to use the default CSP.
	@result Returns a new Hashcash instance for the given stamp, or nil if an error occurs (e.g. the 'stamp' parameter was nil, or the given CSP doesn't provide the necessary capabilities, etc). */

+ (Hashcash*)hashcashFromStamp:(NSString*)stamp module:(CSSMModule*)CSPModule;

/*! @method initWithStamp:module:
	@abstract Initialises the receiver using the given stamp.
	@discussion The receiver will be initialised and returned even if the stamp is invalid, provided it is in the correct format for a v0 or v1 stamp, so this method is by no means any sort of validator of the stamp.

				You use this method (or the class convenience method +hashcashFromStamp:module:) to construct a new Hashcash instance for the purpose of verifying a stamp.  If you wish to generate a new stamp, use the initialiser initWithModule:.
	@param stamp The stamp.  Should not be nil.
	@param CSPModule The CSP module to use for hashing operations.  The given CSP must support the SHA-1 hash.  Pass nil to use the default CSP.
	@result Returns a new Hashcash instance for the given stamp, or nil if an error occurs (e.g. the 'stamp' parameter was nil, or the given CSP doesn't provide the necessary capabilities, etc). */

- (Hashcash*)initWithStamp:(NSString*)stamp module:(CSSMModule*)CSPModule;

/*! @method initWithModule:
	@abstract Initialises the receiver with default settings.
	@discussion This simply initialises the receiver with default settings for value ("bits"), version, date and salt.  You may then change these defaults, if desired, and set the other required information such as the resource and [optionally] extensions.
	@param CSPModule The CSP module to use for hashing operations.  The given CSP must support the SHA-1 hash.  Pass nil to use the default CSP. */

- (Hashcash*)initWithModule:(CSSMModule*)CSPModule;

/*! @method version
	@abstract Returns the Hashcash version of the receiver.
	@discussion Currently versions 0 and 1 are supported.  You would primarily use this only when verifying a stamp if you have requirements for which version(s) it must be - it is not uncommon to require version 1 for the extra fields it has.

				The default value for stamps created with initWithModule: is 1.
	@result Returns the Hashcash version of the receiver, either 0 or 1. */

- (unsigned int)version;

/*! @method setVersion:
	@abstract Sets the Hashcash version to use for the receiver.
	@discussion Use this only when generating stamps, to set the desired Hashcash version of the generated stamp.

				The default value for stamps created with initWithModule: is 1.
	@param newVersion The version to use.  Currently versions 0 and 1 are supported.  Any other values are invalid.
	@result Returns 0 if successful, EINVAL otherwise (indicating the specified version is invalid or otherwise not supported). */

- (int)setVersion:(unsigned int)newVersion;

/*! @method bits
	@abstract Returns the claimed value of the receiver.
	@discussion This is the value the stamp <i>claims</i> it has, not what it actually has.  You would typically use this - in conjunction with "valid" to ensure the stamp actually meets its claim - during stamp verification to ensure it has sufficient value.

				The default value for stamps created with initWithModule: is 20.
	@result Returns the claimed value of the receiver. */

- (unsigned int)bits;

/*! @method setBits:
	@abstract Sets the claimed value of the receiver.
	@discussion This sets the claimed value of the stamp - i.e. the minimum value.  This is a crucial parameter to stamp generation, defining the minimum number of leading 0's the resulting hash must have.  You set this when generating stamps.  You should <i>not</i> set this when performing verification - doing so would alter the stamp, and the result is undefined.

				The default value for stamps created with initWithModule: is 20.
	@result Returns 0 if successful, EINVAL otherwise (indicating that the given value is out of range - it must be between 0 and 160 for v0 and v1 stamps). */

- (int)setBits:(unsigned int)newBits;

/*! @method date
	@abstract Returns the date of the receiver.
	@discussion This is the date of the stamp, which is by default - but not necessarily - the date it was created.  You should use this to verify that the stamp is neither too far in the feature (2 days is a common threshold for email) nor too far in the past (28-30 days is typical for email) when validating stamps.

				The default value for stamps created with initWithModule: is the date when the Hashcash instance is initialised.
	@result Returns the date of the receiver. */

- (NSCalendarDate*)date;

/*! @method setDate:usingDefaultFormat:
	@abstract Sets the date of the receiver.
	@discussion What exactly the date means, in terms of validity, is determined by the user of Hashcash.  Typically this is the claimed date at which the stamp is valid, and there is some sufficient period to either side of this date in which the stamp is valid.  You set this when generating stamps.  You should <i>not</i> set this when performing verification - doing so would alter the stamp, and the result is undefined.

				The default value for stamps created with initWithModule: is the date when the Hashcash instance is initialised.
	@param newDate The date to use for the receiver.  Should not be nil.
	@param useDefaultFormat If YES, the default Hashcash date format is used.  Otherwise, and only if the 'newDate' is actually an NSCalendarDate, the format of that calendar date is used - provided it passes a suffix match against the default format.  i.e. "%y%m%d" is valid, because it matches the start of the default format - which is "%y%m%d%H%M%S" - but "%Y%m%d" is not.
	@result Returns 0 if successful, a POSIX error code otherwise.  EINVAL indicates the given date was nil. */

- (int)setDate:(NSDate*)newDate usingDefaultFormat:(BOOL)useDefaultFormat;

/*! @method resource
	@abstract Returns the resource of the receiver.
	@discussion What exactly the resource is depends entirely on how Hashcash is used, but its general purpose is to uniquely identify a particular user, such that the stamp can be reliably said to "belong" to them (whether they generated it or not is not within Hashcash's scope), as it can only be used by them.  You should check this as part of your validation of stamps to ensure it matches the user that is presenting the stamp.

				The default value for stamps created with initWithModule: is nil.  It must be set before a stamp can be generated.
	@result Returns the resource of the receiver.  Returns nil if the receiver is still unconfigured. */

- (NSString*)resource;

/*! @method setResource:
	@abstract Sets the resource of the receiver.
	@discussion What exactly the resource is depends entirely on how Hashcash is used, but its general purpose is to uniquely identify a particular user, such that the stamp can be reliably said to "belong" to them (whether they generated it or not is not within Hashcash's scope), as it can only be used by them.  You must set this for new stamps - it is required before the stamp can be generated.
	
				The default value for stamps created with initWithModule: is nil.
	@param newResource The resource.  Should not be nil.
	@result Returns 0 if successful, an error code otherwise.  EINVAL indicates the given resource was either nil or contained invalid characters. */

- (int)setResource:(NSString*)newResource;

/*! @method extensions
	@abstract Returns the 'extensions' field of the stamp.
	@discussion The format of this field is zero or more subfields, separated by semicolons, which contain either outright names or key-value pairs, for example "required" or "generator=Mail", respectively.

				Depending on your use of Hashcash, you may or may not need to consider this field as part of stamp validation.  For future compatibility, if you are not using it presently, it is typical to ignore it.

				The default value for stamps created with initWithModule: is nil.
	@result Returns the extensions, if any.  When validating existing stamps (i.e. the receiver was created using initWithStamp:module:) the value should not be nil, but may be an empty string.  When generating new stamps the default value is nil, and this is valid - it is treated as equivalent to an empty string. */

- (NSString*)extensions;

/*! @method setExtensions:
	@abstract Set the 'extensions' field of the receiver.
	@discussion The format of this field is zero or more subfields, separated by semicolons, which contain either outright names or key-value pairs, for example "required" or "generator=Mail", respectively.

				You do not necessarily need to set this when generating stamps - a value of nil is valid, and will result in this field simply being empty in the generated stamp.

				The default value for stamps created with initWithModule: is nil.
	@param newExtensions The new extensions.  May be nil.
	@result Returns 0 if successful, a POSIX error code otherwise. */

- (int)setExtensions:(NSString*)newExtensions;

/*! @method salt
	@abstract Returns the salt of the receiver.
	@discussion This field defines some arbitrary data that is provided by the party requesting a stamp, to prevent pre-calculation of stamps, replay attacks, and whatnot.

				Depending on your use of Hashcash, you may or may not need to consider this field as part of stamp validation.  For security, however, if you are not using it presently you should require that it be empty.

				The default value for stamps created with initWithModule: is a random string generated at initialisation time.
	@result Returns the salt, if any.  When validating existing stamps (i.e. the receiver was created using initWithStamp:module:) the value should not be nil, but may be an empty string.  When generating new stamps the default value is some length of random data, but it may be set to nil, which is treated as equivalent to an empty string. */

- (NSString*)salt;

/*! @method setSalt:
	@abstract Set the salt of the receiver.
	@discussion This field defines some arbitrary data that is provided by the party requesting a stamp, to prevent pre-calculation of stamps, replay attacks, and whatnot.

				You do not necessarily need to set this when generating stamps - a value of nil is valid, and will result in this field simply being empty in the generated stamp.

				The default value for stamps created with initWithModule: is a random string generated at initialisation time.
	@param setSalt The salt.  May be nil.
	@result Returns 0 if successful, a POSIX error code otherwise. */

- (int)setSalt:(NSString*)newSalt;

/*! @method suffix
	@abstract Returns the suffix of the receiver.
	@discussion The suffix field is the mutable area of the stamp which is fiddled with during stamp generation to find a suitable value, one that results in a hash of sufficient value.

				You do not need to explicitly consider this value when validating stamps; it's only purpose is to ensure the hash of the stamp has the necessary value.

				The default value for stamps created with initWithModule: is nil.  This value is filled in when the stamp is actually generated using either "findSuffix" or "stamp".
	@result Returns the suffix of the receiver, which may be nil if it has not yet been generated. */

- (NSString*)suffix;

/*! @method setSuffix:
	@abstract Sets the suffix of the receiver.
	@discussion You should never have need to set this directly... in fact I'm really not sure why it's here to start with... bottom line, don't poke at this, it'll probably go away in future anyway.
	@param newSuffix The new suffix.
	@result Returns 0 if successful, a POSIX error code otherwise. */

- (int)setSuffix:(NSString*)newSuffix;

/*! @method findSuffix
	@abstract Finds a suffix which will make the receiver valid.
	@discussion This is the method which actually does the work of finding the necessary suffix to make the receiver valid.  In particular, it searches for a suffix which produces a hash of at least "bits" value.

				You may call this multiple times; if the existing suffix is still valid for the receiver's settings, it will be retained and no work will be done.  Otherwise, if no suffix has yet been computed or the existing one is invalid, this will generate a new one.
	@result Returns 0 if successful, a POSIX error code otherwise. */

// XXX: need a findSuffixBeforeDate: or findSuffixWithTimeout: method.

- (int)findSuffix;

/*! @method stamp
	@abstract Returns the stamp of the receiver.
	@discussion This method does <i>not</i> guarantee the returned stamp string is valid - it is simply the receiver rendered in the correct form.  If the receiver is invalid, then so shall be the returned stamp.  If you are generating a new stamp, you need to invoke "findSuffix" before calling this method in order to have a valid stamp returned.
	@result Returns the receiver represented as a stamp, whether valid or otherwise.  Returns nil if an error occurs (e.g the receiver does not contain the necessary information to generate a properly-structured stamp in the current version). */

- (NSString*)stamp;

/*! @method valid
	@abstract Returns whether or not the receiver is valid at the most basic level - that is, its hash has at least the claimed value.
	@discussion This method simply determines if the receiver is valid insofar as its actual value is at least the claimed value as returned by "bits".  It does not perform any validation of any of the individual fields - that is up to the user of this class.
	@result Returns YES if the receiver's actual value is at least as much as the receiver's claimed value, NO otherwise. */

- (BOOL)valid;

@end
