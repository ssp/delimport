//
//  NSDataAdditions.h
//  Keychain
//
//  Created by Wade Tregaskis on Wed May 07 2003.
//
//  Copyright (c) 2003 - 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Keychain/Key.h>
#import <Security/Security.h>
#import <Keychain/MutableKey.h>
#import <Keychain/CSSMModule.h>


#ifdef __cplusplus
extern "C" {
#endif

NSData* cononicalFormOfExecutable(NSString *path);

#ifdef __cplusplus
}
#endif

/*! @category NSData (KeychainFramework)
	@abstract Extensions to NSData for various cryptographic operations.
	@discussion This category extends NSData to support numerous cryptographic operations, such as encryption, MAC & digest generation, signing and signature verification, conversion to a MutableKey* and so forth. */

@interface NSData (KeychainFramework)

/*! @method encryptedDataUsingKey:
	@abstract Returns the encrypted form of the receiver using the given key.
	@discussion This method returns the encrypted form of the receiver using the given key, with the "default" algorith mode and padding settings for the given key's type.  Default is defined as what is returned by defaultModeForAlgorithm() and defaultPaddingForAlgorithm().  If you wish to have explicit control over the algorith mode and/or padding, use encryptedDataUsingKey:mode:padding:.
	@param key The key to use.  May be a session or public key.  Should not be nil.
	@result Returns the receiver's contents encrypted by the given key, or nil if an error occurs. */

- (NSData*)encryptedDataUsingKey:(Key*)key;

/*! @method decryptedDataUsingKey:
	@abstract Returns the decrypted form of the receiver using the given key.
	@discussion This method returns the decrypted form of the receiver using the given key, with the "default" algorith mode and padding settings for the given key's type.  Default is defined as what is returned by defaultModeForAlgorithm() and defaultPaddingForAlgorithm().  If you wish to have explicit control over the algorith mode and/or padding, use decryptedDataUsingKey:mode:padding:.
	@param key The key to use.  May be a session or private key.  Should not be nil.
	@result Returns the receiver's contents decrypted by the given key, or nil if an error occurs. */

- (NSData*)decryptedDataUsingKey:(Key*)key;

/*! @method encryptedDataUsingKey:mode:padding:
	@abstract Returns the encrypted form of the receiver using the given key.
	@discussion This method returns the encrypted form of the receiver using the given key, with the algorith mode and padding specified.  If you don't know or don't care what algorith mode and padding you use, you can use the simpler method encryptedDataUsingKey:.
	@param key The key to use.  May be a session or public key.  Should not be nil.
	@param mode The algorithm mode to use.  Should be a valid algorithm mode for the given key.
	@param padding The padding mode to use.  Should be a valid padding mode for the given key.
	@result Returns the receiver's contents encrypted by the given key, or nil if an error occurs. */

- (NSData*)encryptedDataUsingKey:(Key*)key mode:(CSSM_ENCRYPT_MODE)mode padding:(CSSM_PADDING)padding;

/*! @method decryptedDataUsingKey:mode:padding:
	@abstract Returns the decrypted form of the receiver using the given key.
	@discussion This method returns the decrypted form of the receiver using the given key, with the algorith mode and padding specified.  If you don't know or don't care what algorith mode and padding you use, you can use the simpler method decryptedDataUsingKey:.  Not however that these modes must be what was actually used to encrypt the data originally, otherwise the operation will fail.
	@param key The key to use.  May be a session or private key.  Should not be nil.
	@param mode The algorithm mode to use.  Should be a valid algorithm mode for the given key.
	@param padding The padding mode to use.  Should be a valid padding mode for the given key.
	@result Returns the receiver's contents decrypted by the given key, or nil if an error occurs. */

- (NSData*)decryptedDataUsingKey:(Key*)key mode:(CSSM_ENCRYPT_MODE)mode padding:(CSSM_PADDING)padding;

/*! @method MACUsingKey:
	@abstract Computes and returns the MAC of the receiver, signed by the given key.
	@discussion MACs (Message Authentication Codes) are conceptually like hashes or digests, except that in addition to detecting modification of the data they also include a 'signature' from a key, which also provides authentication of the code itself (using the same key).

				Note that, despite the above conceptual description, this is distinctly not equivalent to simply calculating the digest of the data and signing or encrypting it, as separate operations.  If you require verification and authentication, use MACs - don't try to do it yourself.  MAC algorithms possess additional properties - see <a href="http://en.wikipedia.org/wiki/Message_authentication_code">http://en.wikipedia.org/wiki/Message_authentication_code</a> for additional information.
	@param key The key to compute the MAC with.  Should not be nil.
	@result Returns the MAC of the receiver's contents 'signed' by the receiver, or nil if an error occurs. */

- (NSData*)MACUsingKey:(Key*)key;

/*! @method verifyUsingKey:MAC:
	@abstract Verifies the receiver given a MAC and key.
	@discussion For information about MACs, see the discussion for MACUsingKey:.
	@param key The key used to generate the MAC originally.  Should not be nil.
	@param MAC The MAC.  Should not be nil.
	@result Returns YES if the receiver's contents match those of the given MAC, 'signed' by the given key.  Returns NO otherwise. */

- (BOOL)verifyUsingKey:(Key*)key MAC:(NSData*)MAC;

/*! @method signatureUsingKey:
	@abstract Returns a signature of the receiver using the given private key.
	@discussion The "default" digest mode for the given key's type is used, where "default" is as determined by defaultDigestForAlgorithm().  If you wish to specify the digest algorithm used, use signatureUsingKey:digest:.
	@param key The private key to sign the receiver's contents with.
	@result Returns the signature of the receiver's contents, as signed by the given key, or nil if an error occurs. */

- (NSData*)signatureUsingKey:(Key*)key;

/*! @method signatureUsingKey:digest:
	@abstract Returns a signature of the receiver using the given private key and digest type.
	@discussion If you don't know or don't care what digest mode is used, you may wish to use the simpler signatureUsingKey:.
	@param key The private key to sign the receiver's contents with.
	@param algorithm The digest mode to use.  Should be a valid digest mode for the given key.
	@result Returns the signature of the receiver's contents, as signed by the given key, or nil if an error occurs. */

- (NSData*)signatureUsingKey:(Key*)key digest:(CSSM_ALGORITHMS)algorithm;

/*! @method digestSignatureUsingKey:digest:
	@abstract */

- (NSData*)digestSignatureUsingKey:(Key*)key digest:(CSSM_ALGORITHMS)algorithm;

- (BOOL)verifySignature:(NSData*)signature usingKey:(Key*)key;
- (BOOL)verifySignature:(NSData*)signature usingKey:(Key*)key digest:(CSSM_ALGORITHMS)algorithm;
- (BOOL)verifyDigestSignature:(NSData*)signature usingKey:(Key*)key digest:(CSSM_ALGORITHMS)algorithm;

- (MutableKey*)keyForModule:(CSSMModule*)CSPModule;

- (NSData*)digestUsingAlgorithm:(CSSM_ALGORITHMS)algorithm module:(CSSMModule*)CSPModule;

@end
