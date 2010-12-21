//
//  KeychainTester.m
//  Keychain
//
//  Created by Wade Tregaskis on Thu Sep 20 2007.
//
//  Copyright (c) 2007, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of any other contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Keychain/Keychain.h>
#import <Keychain/SecurityUtils.h>

#import <Foundation/Foundation.h>

#import "TestingCommon.h"


Keychain* test_createKeychain(NSString *keychainPath, NSString *password) {
    Keychain *result;
	
	START_TEST("Create keychain");

	TEST(![[NSFileManager defaultManager] fileExistsAtPath:keychainPath], "Keychain file doesn't yet exist on disk");
	
	result = [Keychain createNewKeychainAtPath:keychainPath withPassword:password access:nil];
	
	TEST(nil != result, "Able to create keychain at \"%s\" with password \"%s\"", ((nil != keychainPath) ? [keychainPath UTF8String] : "(nil)"), ((nil != password) ? [password UTF8String] : "(nil)"));
    
	TEST([[NSFileManager defaultManager] fileExistsAtPath:keychainPath], "Keychain file now exists on disk");

	END_TEST();
	
	return result;
}

void test_deleteKeychain(NSString *keychainPath, Keychain *testKeychain) {
	START_TEST("Delete keychain");
	
	if (nil != testKeychain) {
		TEST([[NSFileManager defaultManager] fileExistsAtPath:keychainPath], "Keychain file exists on disk");

		[testKeychain deleteCompletely];
		
		TEST(noErr == [testKeychain lastError], "Delete command went through successfully");
		
		TEST(![[NSFileManager defaultManager] fileExistsAtPath:keychainPath], "Keychain file no longer exists on disk");
	}
	
	END_TEST();
}


void test_addInternetPasswords(Keychain *testKeychain) {
	START_TEST("Add internet passwords");
	
	NSDate *testStart = [NSDate date];
	
	KeychainItem *originalItem, *currentItem;
	
	originalItem = currentItem = [testKeychain addInternetPassword:@"test123" onServer:@"localhost" forAccount:@"test" port:123 path:@"/" inSecurityDomain:nil protocol:kSecProtocolTypeHTTP auth:kSecAuthenticationTypeDefault replaceExisting:NO];
	TEST(nil != currentItem, "Can create HTTP password");
	
	if (nil != currentItem) {
		TEST_ISEQUAL([currentItem dataAsString], @"test123", "\tPassword is correct");
		
		TEST_ISEQUAL([currentItem account], @"test", "\tAccount is correct");
		TEST_ISEQUAL([currentItem securityDomain], @"", "\tSecurity domain is correct (none)");
		TEST_ISEQUAL([currentItem server], @"localhost", "\tServer is correct");
		TEST_INTSEQUAL_F([currentItem authenticationType], kSecAuthenticationTypeDefault, nameOfAuthenticationTypeConstant, "\tAuthentication type is correct");
		TEST_INTSEQUAL([currentItem port], 123, "\tPort is correct");
		TEST_ISEQUAL([currentItem path], @"/", "\tPath is correct");
		TEST_INTSEQUAL_F([currentItem protocol], kSecProtocolTypeHTTP, nameOfProtocolConstant, "\tProtocol is correct");
		
		TEST([currentItem passwordIsValid], "\tPassword is noted as valid");
		TEST([currentItem isVisible], "\tPassword is visible");
		TEST(![currentItem hasCustomIcon], "\tDoesn't have custom icon");
		
		NSDate *creationDate = [currentItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDate, >=, testStart, "\tCreation date is the same time as or after this test started");
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDate, <=, [NSDate date], "\tCreation date is the same time as or earlier than right now");
				
		NSDate *modificationDate = [currentItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDate, >=, testStart, "\tModification date is the same time as or after this test started");
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDate, <=, [NSDate date], "\tModification date is the same time as or earlier than right now");
				
		TEST_ISEQUAL([currentItem typeDescription], @"", "\tHas no type description");
		TEST_ISEQUAL([currentItem comment], @"", "\tHas no comment");
		TEST_INTSEQUAL([currentItem creator], 0, "\tHas no creator (FourCharCode version)");
		TEST_ISEQUAL([currentItem creatorAsString], @"", "\tHas no creator (string version)");
		TEST_INTSEQUAL([currentItem type], 0, "\tHas no type (FourCharCode version)");
		TEST_ISEQUAL([currentItem typeAsString], @"", "\tHas no type (string version)");
		//TEST_ISEQUAL([currentItem label], @"", "\tHas no label"); // A label is set by default ("localhost", in this example, at present), which is valid.. but I don't want to test against it explicitly, because really any default is valid.
		TEST_ISEQUAL([currentItem alias], @"", "\tHas no alias");
		
		TEST_ISNIL([currentItem service], "\tDoesn't have a service (not applicable to interest passwords)");
		TEST_ISNIL([currentItem userDefinedAttribute], "\tDoesn't have user-defined attribute (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareVolume], "\tDoesn't have AppleShare volume (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareAddress], "\tDoesn't have AppleShare address (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareSignatureData], "\tDoesn't have AppleShare signature (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem certificateType], CSSM_CERT_UNKNOWN, nameOfCertificateTypeConstant, "\tDoesn't have a certificate type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem certificateEncoding], CSSM_CERT_ENCODING_UNKNOWN, nameOfCertificateEncodingConstant, "\tDoesn't have a certificate encoding (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem CRLType], CSSM_CRL_TYPE_UNKNOWN, nameOfCRLTypeConstant, "\tDoesn't have a CRL type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem CRLEncoding], CSSM_CRL_ENCODING_UNKNOWN, nameOfCRLEncodingConstant, "\tDoesn't have a CRL encoding (not applicable to internet passwords)");
	}
	
	currentItem = [testKeychain addInternetPassword:@"test123" onServer:@"localhost" forAccount:@"test" port:123 path:@"/" inSecurityDomain:nil protocol:kSecProtocolTypeHTTP auth:kSecAuthenticationTypeDefault replaceExisting:NO];
	TEST(nil == currentItem, "Cannot accidentally overwrite previous password");
	
	if (nil != originalItem) {
		TEST_ISEQUAL([originalItem dataAsString], @"test123", "\tOriginal item's password is unchanged");
		
		TEST_ISEQUAL([originalItem account], @"test", "\tOriginal item's account is still correct");
		TEST_ISEQUAL([originalItem securityDomain], @"", "\tOriginal item's security domain is still correct (none)");
		TEST_ISEQUAL([originalItem server], @"localhost", "\tOriginal item's server is still correct");
		TEST_INTSEQUAL_F([originalItem authenticationType], kSecAuthenticationTypeDefault, nameOfAuthenticationTypeConstant, "\tOriginal item's authentication type is still correct");
		TEST_INTSEQUAL([originalItem port], 123, "\tOriginal item's port is still correct");
		TEST_ISEQUAL([originalItem path], @"/", "\tOriginal item's path is still correct");
		TEST_INTSEQUAL_F([originalItem protocol], kSecProtocolTypeHTTP, nameOfProtocolConstant, "\tOriginal item's protocol is still correct");
		
		TEST([originalItem passwordIsValid], "\tOriginal item's password is still noted as valid");
		TEST([originalItem isVisible], "\tOriginal item's password is still visible");
		TEST(![originalItem hasCustomIcon], "\tOriginal item's still doesn't have custom icon");
		
		NSDate *creationDate = [originalItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDate, >=, testStart, "\tOriginal item's creation date is the same time as or after this test started");
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDate, <=, [NSDate date], "\tOriginal item's creation date is the same time as or earlier than right now");
		
		NSDate *modificationDate = [originalItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDate, >=, testStart, "\tOriginal item's modification date is the same time as or after this test started");
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDate, <=, [NSDate date], "\tOriginal item's modification date is the same time as or earlier than right now");
		
		TEST_ISEQUAL([originalItem typeDescription], @"", "\tOriginal item still has no type description");
		TEST_ISEQUAL([originalItem comment], @"", "\tOriginal item still has no comment");
		TEST_INTSEQUAL([originalItem creator], 0, "\tOriginal item still has no creator (FourCharCode version)");
		TEST_ISEQUAL([originalItem creatorAsString], @"", "\tOriginal item still has no creator (string version)");
		TEST_INTSEQUAL([originalItem type], 0, "\tOriginal item still has no type (FourCharCode version)");
		TEST_ISEQUAL([originalItem typeAsString], @"", "\tOriginal item still has no type (string version)");
		//TEST_ISEQUAL([currentItem label], @"", "\tOriginal item's Has no label"); // A label is set by default ("localhost", in this example, at present), which is valid.. but I don't want to test against it explicitly, because really any default is valid.
		TEST_ISEQUAL([originalItem alias], @"", "\tOriginal item still has no alias");
		
		TEST_ISNIL([originalItem service], "\tOriginal item still doesn't have a service (not applicable to interest passwords)");
		TEST_ISNIL([originalItem userDefinedAttribute], "\tOriginal item still doesn't have user-defined attribute (not applicable to internet passwords)");
		TEST_ISNIL([originalItem appleShareVolume], "\tOriginal item still doesn't have AppleShare volume (not applicable to internet passwords)");
		TEST_ISNIL([originalItem appleShareAddress], "\tOriginal item still doesn't have AppleShare address (not applicable to internet passwords)");
		TEST_ISNIL([originalItem appleShareSignatureData], "\tOriginal item still doesn't have AppleShare signature (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([originalItem certificateType], CSSM_CERT_UNKNOWN, nameOfCertificateTypeConstant, "\tOriginal item still doesn't have a certificate type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([originalItem certificateEncoding], CSSM_CERT_ENCODING_UNKNOWN, nameOfCertificateEncodingConstant, "\tOriginal item still doesn't have a certificate encoding (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([originalItem CRLType], CSSM_CRL_TYPE_UNKNOWN, nameOfCRLTypeConstant, "\tOriginal item still doesn't have a CRL type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([originalItem CRLEncoding], CSSM_CRL_ENCODING_UNKNOWN, nameOfCRLEncodingConstant, "\tOriginal item still doesn't have a CRL encoding (not applicable to internet passwords)");
	}
	
	currentItem = [testKeychain addInternetPassword:@"overwritten" onServer:@"localhost" forAccount:@"test" port:123 path:@"/" inSecurityDomain:nil protocol:kSecProtocolTypeHTTP auth:kSecAuthenticationTypeDefault replaceExisting:YES];
	TEST(nil != currentItem, "Can intentionally overwrite previous password");
	
	if (nil != currentItem) {
		TEST_ISEQUAL([currentItem dataAsString], @"overwritten", "\tPassword is correct");
		
		TEST_ISEQUAL([currentItem account], @"test", "\tAccount is correct");
		TEST_ISEQUAL([currentItem securityDomain], @"", "\tSecurity domain is correct (none)");
		TEST_ISEQUAL([currentItem server], @"localhost", "\tServer is correct");
		TEST_INTSEQUAL_F([currentItem authenticationType], kSecAuthenticationTypeDefault, nameOfAuthenticationTypeConstant, "\tAuthentication type is correct");
		TEST_INTSEQUAL([currentItem port], 123, "\tPort is correct");
		TEST_ISEQUAL([currentItem path], @"/", "\tPath is correct");
		TEST_INTSEQUAL_F([currentItem protocol], kSecProtocolTypeHTTP, nameOfProtocolConstant, "\tProtocol is correct");
		
		TEST([currentItem passwordIsValid], "\tPassword is noted as valid");
		TEST([currentItem isVisible], "\tPassword is visible");
		TEST(![currentItem hasCustomIcon], "\tDoesn't have custom icon");
		
		NSDate *creationDate = [currentItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDate, >=, testStart, "\tCreation date is the same time as or after this test started");
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDate, <=, [NSDate date], "\tCreation date is the same time as or earlier than right now");
		
		NSDate *modificationDate = [currentItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDate, >=, testStart, "\tModification date is the same time as or after this test started");
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDate, <=, [NSDate date], "\tModification date is the same time as or earlier than right now");
		
		TEST_ISEQUAL([currentItem typeDescription], @"", "\tHas no type description");
		TEST_ISEQUAL([currentItem comment], @"", "\tHas no comment");
		TEST_INTSEQUAL([currentItem creator], 0, "\tHas no creator (FourCharCode version)");
		TEST_ISEQUAL([currentItem creatorAsString], @"", "\tHas no creator (string version)");
		TEST_INTSEQUAL([currentItem type], 0, "\tHas no type (FourCharCode version)");
		TEST_ISEQUAL([currentItem typeAsString], @"", "\tHas no type (string version)");
		//TEST_ISEQUAL([currentItem label], @"", "\tHas no label"); // A label is set by default ("localhost", in this example, at present), which is valid.. but I don't want to test against it explicitly, because really any default is valid.
		TEST_ISEQUAL([currentItem alias], @"", "\tHas no alias");
		
		TEST_ISNIL([currentItem service], "\tDoesn't have a service (not applicable to interest passwords)");
		TEST_ISNIL([currentItem userDefinedAttribute], "\tDoesn't have user-defined attribute (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareVolume], "\tDoesn't have AppleShare volume (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareAddress], "\tDoesn't have AppleShare address (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareSignatureData], "\tDoesn't have AppleShare signature (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem certificateType], CSSM_CERT_UNKNOWN, nameOfCertificateTypeConstant, "\tDoesn't have a certificate type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem certificateEncoding], CSSM_CERT_ENCODING_UNKNOWN, nameOfCertificateEncodingConstant, "\tDoesn't have a certificate encoding (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem CRLType], CSSM_CRL_TYPE_UNKNOWN, nameOfCRLTypeConstant, "\tDoesn't have a CRL type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem CRLEncoding], CSSM_CRL_ENCODING_UNKNOWN, nameOfCRLEncodingConstant, "\tDoesn't have a CRL encoding (not applicable to internet passwords)");
	}
	
	if (nil != originalItem) {
		TEST_ISEQUAL([currentItem dataAsString], @"overwritten", "\tOriginal item's password reflects the change");
	}
	
	originalItem = currentItem = [testKeychain addInternetPassword:nil onServer:@"www.widget.com" forAccount:@"root" port:22 path:nil inSecurityDomain:nil protocol:kSecProtocolTypeSSH auth:kSecAuthenticationTypeDefault replaceExisting:NO];
	TEST(nil != currentItem, "Can create SSH keychain item without password");
	
	if (nil != currentItem) {
		TEST_ISEQUAL([currentItem dataAsString], @"", "\tPassword is correct");
		
		TEST_ISEQUAL([currentItem account], @"root", "\tAccount is correct");
		TEST_ISEQUAL([currentItem securityDomain], @"", "\tSecurity domain is correct (none)");
		TEST_ISEQUAL([currentItem server], @"www.widget.com", "\tServer is correct");
		TEST_INTSEQUAL_F([currentItem authenticationType], kSecAuthenticationTypeDefault, nameOfAuthenticationTypeConstant, "\tAuthentication type is correct");
		TEST_INTSEQUAL([currentItem port], 22, "\tPort is correct");
		TEST_ISEQUAL([currentItem path], @"", "\tPath is correct");
		TEST_INTSEQUAL_F([currentItem protocol], kSecProtocolTypeSSH, nameOfProtocolConstant, "\tProtocol is correct");
		
		TEST(![currentItem passwordIsValid], "\tPassword is noted as invalid");
		TEST(![currentItem isVisible], "\tPassword is invisible");
		TEST(![currentItem hasCustomIcon], "\tDoesn't have custom icon");
		
		NSDate *creationDate = [currentItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDate, >=, testStart, "\tCreation date is the same time as or after this test started");
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDate, <=, [NSDate date], "\tCreation date is the same time as or earlier than right now");
				
		NSDate *modificationDate = [currentItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDate, >=, testStart, "\tModification date is the same time as or after this test started");
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDate, <=, [NSDate date], "\tModification date is the same time as or earlier than right now");
				
		TEST_ISEQUAL([currentItem typeDescription], @"", "\tHas no type description");
		TEST_ISEQUAL([currentItem comment], @"", "\tHas no comment");
		TEST_INTSEQUAL([currentItem creator], 0, "\tHas no creator (FourCharCode version)");
		TEST_ISEQUAL([currentItem creatorAsString], @"", "\tHas no creator (string version)");
		TEST_INTSEQUAL([currentItem type], 0, "\tHas no type (FourCharCode version)");
		TEST_ISEQUAL([currentItem typeAsString], @"", "\tHas no type (string version)");
		//TEST_ISEQUAL([currentItem label], @"", "\tHas no label"); // A label is set by default ("localhost", in this example, at present), which is valid.. but I don't want to test against it explicitly, because really any default is valid.
		TEST_ISEQUAL([currentItem alias], @"", "\tHas no alias");
		
		TEST_ISNIL([currentItem service], "\tDoesn't have a service (not applicable to interest passwords)");
		TEST_ISNIL([currentItem userDefinedAttribute], "\tDoesn't have user-defined attribute (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareVolume], "\tDoesn't have AppleShare volume (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareAddress], "\tDoesn't have AppleShare address (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareSignatureData], "\tDoesn't have AppleShare signature (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem certificateType], CSSM_CERT_UNKNOWN, nameOfCertificateTypeConstant, "\tDoesn't have a certificate type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem certificateEncoding], CSSM_CERT_ENCODING_UNKNOWN, nameOfCertificateEncodingConstant, "\tDoesn't have a certificate encoding (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem CRLType], CSSM_CRL_TYPE_UNKNOWN, nameOfCRLTypeConstant, "\tDoesn't have a CRL type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem CRLEncoding], CSSM_CRL_ENCODING_UNKNOWN, nameOfCRLEncodingConstant, "\tDoesn't have a CRL encoding (not applicable to internet passwords)");
	}
	
	
#pragma mark -- Chinese Internet password
	
	NSString *chinesePassword = [NSString stringWithUTF8String:"我姓王"];
	NSString *chineseAccount = [NSString stringWithUTF8String:"你贵姓"];
	NSString *chineseServer = [NSString stringWithUTF8String:"中文。com"];
	NSString *chinesePath = [NSString stringWithUTF8String:"／美国／"];
	
	currentItem = [testKeychain addInternetPassword:chinesePassword onServer:chineseServer forAccount:chineseAccount port:1337 path:chinesePath inSecurityDomain:nil protocol:kSecProtocolTypeHTTPS auth:kSecAuthenticationTypeHTTPDigest replaceExisting:NO];
	TEST(nil != currentItem, "Can create Chinese Internet password");
	
	if (nil != currentItem) {
		TEST_ISEQUAL([currentItem dataAsString], chinesePassword, "\tPassword is correct");
		
		TEST_ISEQUAL([currentItem account], chineseAccount, "\tAccount is correct");
		TEST_ISEQUAL([currentItem securityDomain], @"", "\tSecurity domain is correct (none)");
		TEST_ISEQUAL([currentItem server], chineseServer, "\tServer is correct");
		TEST_INTSEQUAL_F([currentItem authenticationType], kSecAuthenticationTypeHTTPDigest, nameOfAuthenticationTypeConstant, "\tAuthentication type is correct");
		TEST_INTSEQUAL([currentItem port], 1337, "\tPort is correct");
		TEST_ISEQUAL([currentItem path], chinesePath, "\tPath is correct");
		TEST_INTSEQUAL_F([currentItem protocol], kSecProtocolTypeHTTPS, nameOfProtocolConstant, "\tProtocol is correct");
		
		TEST([currentItem passwordIsValid], "\tPassword is noted as valid");
		TEST([currentItem isVisible], "\tPassword is visible");
		TEST(![currentItem hasCustomIcon], "\tDoesn't have custom icon");
		
		NSDate *creationDate = [currentItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDate, >=, testStart, "\tCreation date is the same time as or after this test started");
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDate, <=, [NSDate date], "\tCreation date is the same time as or earlier than right now");
		
		NSDate *modificationDate = [currentItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDate, >=, testStart, "\tModification date is the same time as or after this test started");
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDate, <=, [NSDate date], "\tModification date is the same time as or earlier than right now");
		
		TEST_ISEQUAL([currentItem typeDescription], @"", "\tHas no type description");
		TEST_ISEQUAL([currentItem comment], @"", "\tHas no comment");
		TEST_INTSEQUAL([currentItem creator], 0, "\tHas no creator (FourCharCode version)");
		TEST_ISEQUAL([currentItem creatorAsString], @"", "\tHas no creator (string version)");
		TEST_INTSEQUAL([currentItem type], 0, "\tHas no type (FourCharCode version)");
		TEST_ISEQUAL([currentItem typeAsString], @"", "\tHas no type (string version)");
		//TEST_ISEQUAL([currentItem label], @"", "\tHas no label"); // A label is set by default ("localhost", in this example, at present), which is valid.. but I don't want to test against it explicitly, because really any default is valid.
		TEST_ISEQUAL([currentItem alias], @"", "\tHas no alias");
		
		TEST_ISNIL([currentItem service], "\tDoesn't have a service (not applicable to interest passwords)");
		TEST_ISNIL([currentItem userDefinedAttribute], "\tDoesn't have user-defined attribute (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareVolume], "\tDoesn't have AppleShare volume (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareAddress], "\tDoesn't have AppleShare address (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareSignatureData], "\tDoesn't have AppleShare signature (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem certificateType], CSSM_CERT_UNKNOWN, nameOfCertificateTypeConstant, "\tDoesn't have a certificate type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem certificateEncoding], CSSM_CERT_ENCODING_UNKNOWN, nameOfCertificateEncodingConstant, "\tDoesn't have a certificate encoding (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem CRLType], CSSM_CRL_TYPE_UNKNOWN, nameOfCRLTypeConstant, "\tDoesn't have a CRL type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem CRLEncoding], CSSM_CRL_ENCODING_UNKNOWN, nameOfCRLEncodingConstant, "\tDoesn't have a CRL encoding (not applicable to internet passwords)");
	}
	
	END_TEST();
}

void test_modifyInternetPasswords(Keychain *testKeychain) {
	START_TEST("Modify internet passwords");
	
	NSDate *testStart = [NSDate date];
	
	KeychainItem *currentItem;
	
	currentItem = [testKeychain addInternetPassword:@"smeg" onServer:@"reddwarf.org" forAccount:@"lister" port:997 path:@"/StarBug/2/Pilot's Log" inSecurityDomain:@"Red Dwarf" protocol:kSecProtocolTypeFTPS auth:kSecAuthenticationTypeDefault replaceExisting:NO];
	TEST(nil != currentItem, "Can create FTP password");
	
	if (nil != currentItem) {
		TEST_ISEQUAL([currentItem dataAsString], @"smeg", "\tPassword is correct");
		
		TEST_ISEQUAL([currentItem account], @"lister", "\tAccount is correct");
		TEST_ISEQUAL([currentItem securityDomain], @"Red Dwarf", "\tSecurity domain is correct (none)");
		TEST_ISEQUAL([currentItem server], @"reddwarf.org", "\tServer is correct");
		TEST_INTSEQUAL_F([currentItem authenticationType], kSecAuthenticationTypeDefault, nameOfAuthenticationTypeConstant, "\tAuthentication type is correct");
		TEST_INTSEQUAL([currentItem port], 997, "\tPort is correct");
		TEST_ISEQUAL([currentItem path], @"/StarBug/2/Pilot's Log", "\tPath is correct");
		TEST_INTSEQUAL_F([currentItem protocol], kSecProtocolTypeFTPS, nameOfProtocolConstant, "\tProtocol is correct");
		
		TEST([currentItem passwordIsValid], "\tPassword is noted as valid");
		TEST([currentItem isVisible], "\tPassword is visible");
		TEST(![currentItem hasCustomIcon], "\tDoesn't have custom icon");
		
		NSDate *creationDate = [currentItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDate, >=, testStart, "\tCreation date is the same time as or after this test started");
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDate, <=, [NSDate date], "\tCreation date is the same time as or earlier than right now");
				
		NSDate *modificationDate = [currentItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDate, >=, testStart, "\tModification date is the same time as or after this test started");
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDate, <=, [NSDate date], "\tModification date is the same time as or earlier than right now");
				
		TEST_ISEQUAL([currentItem typeDescription], @"", "\tHas no type description");
		TEST_ISEQUAL([currentItem comment], @"", "\tHas no comment");
		TEST_INTSEQUAL([currentItem creator], 0, "\tHas no creator (FourCharCode version)");
		TEST_ISEQUAL([currentItem creatorAsString], @"", "\tHas no creator (string version)");
		TEST_INTSEQUAL([currentItem type], 0, "\tHas no type (FourCharCode version)");
		TEST_ISEQUAL([currentItem typeAsString], @"", "\tHas no type (string version)");
		//TEST_ISEQUAL([currentItem label], @"", "\tHas no label"); // A label is set by default ("localhost", in this example, at present), which is valid.. but I don't want to test against it explicitly, because really any default is valid.
		TEST_ISEQUAL([currentItem alias], @"", "\tHas no alias");
		
		TEST_ISNIL([currentItem service], "\tDoesn't have a service (not applicable to interest passwords)");
		TEST_ISNIL([currentItem userDefinedAttribute], "\tDoesn't have user-defined attribute (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareVolume], "\tDoesn't have AppleShare volume (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareAddress], "\tDoesn't have AppleShare address (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareSignatureData], "\tDoesn't have AppleShare signature (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem certificateType], CSSM_CERT_UNKNOWN, nameOfCertificateTypeConstant, "\tDoesn't have a certificate type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem certificateEncoding], CSSM_CERT_ENCODING_UNKNOWN, nameOfCertificateEncodingConstant, "\tDoesn't have a certificate encoding (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem CRLType], CSSM_CRL_TYPE_UNKNOWN, nameOfCRLTypeConstant, "\tDoesn't have a CRL type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem CRLEncoding], CSSM_CRL_ENCODING_UNKNOWN, nameOfCRLEncodingConstant, "\tDoesn't have a CRL encoding (not applicable to internet passwords)");
		
		
		// Now, try modifying each and every attribute.
		
		[currentItem setDataFromString:@"rimmerisanacehole"];
		TEST_ISEQUAL([currentItem dataAsString], @"rimmerisanacehole", "\tCan change password");
		
		NSDate *newCreationDate = [NSDate dateWithNaturalLanguageString:@"12 hours ago"];
		[currentItem setCreationDate:newCreationDate];		
		NSDate *creationDateAsSet = [currentItem creationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(creationDateAsSet, ==, newCreationDate, "\tCan change creation date");
		
		// Setting the modification date doesn't currently work.
		/*NSDate *newModificationDate = [NSDate dateWithNaturalLanguageString:@"10 minutes ago"];
		[currentItem setModificationDate:newModificationDate];		
		NSDate *modificationDateAsSet = [currentItem modificationDate];
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS(modificationDateAsSet, ==, newModificationDate, "\tCan change modification date");*/
		
		[currentItem setTypeDescription:@"FTP password for Lister's pilot log on Red Dwarf"]; // Note that I don't think this is a good example, as it's not really the purpose of the type description afaik.
		TEST_ISEQUAL([currentItem typeDescription], @"FTP password for Lister's pilot log on Red Dwarf", "\tCan change type description");
		
		[currentItem setComment:@"Like this will ever get used"];
		TEST_ISEQUAL([currentItem comment], @"Like this will ever get used", "\tCan change comment");
		
		[currentItem setCreator:'Lstr']; // Again, not a good example, since the creator is the Mac Creator Code of the application that created the keychain item.
		TEST_INTSEQUAL([currentItem creator], 'Lstr', "\tCan change creator (using FourCharCode)");
		
		[currentItem setCreatorFromString:@"Admn"];
		TEST_ISEQUAL([currentItem creatorAsString], @"Admn", "\tCan change creator (using string)");
		
		[currentItem setType:'PLog'];
		TEST_INTSEQUAL([currentItem type], 'PLog', "\tCan change type (using FourCharCode)");
		
		[currentItem setTypeFromString:@"RedD"];
		TEST_ISEQUAL([currentItem typeAsString], @"RedD", "\tCan change type (using string)");
		
		[currentItem setLabel:@"Lister's log access password"];
		TEST_ISEQUAL([currentItem label], @"Lister's log access password", "\tCan change label");
		
		[currentItem setIsVisible:NO];
		TEST(![currentItem isVisible], "\tCan change visibility");
		
		[currentItem setPasswordIsValid:NO];
		TEST(![currentItem passwordIsValid], "\tCan change password validity");
		
		[currentItem setHasCustomIcon:YES];
		TEST([currentItem hasCustomIcon], "\tCan change custom icon flag");
		
		[currentItem setAccount:@"Lister"];
		TEST_ISEQUAL([currentItem account], @"Lister", "\tCan change account");
		
		[currentItem setService:@"Impossible"];
		TEST_ISNIL([currentItem service], "\tCannot change service (not applicable to Internet passwords)");
		
		NSData *userDefinedAttribute = [NSData dataWithBytes:"Arbitrary" length:9];
		[currentItem setUserDefinedAttribute:userDefinedAttribute];
		TEST_ISNIL([currentItem userDefinedAttribute], "\tCannot change user-defined attribute (not applicable to Internet passwords)");
		
		[currentItem setSecurityDomain:@"Red Dwarf Pilots"];
		TEST_ISEQUAL([currentItem securityDomain], @"Red Dwarf Pilots", "\tCan change security domain");
		
		[currentItem setServer:@"reddwarf.net"];
		TEST_ISEQUAL([currentItem server], @"reddwarf.net", "\tCan change server");
		
		[currentItem setAuthenticationType:kSecAuthenticationTypeRPA];
		TEST_INTSEQUAL_F([currentItem authenticationType], kSecAuthenticationTypeRPA, nameOfAuthenticationTypeConstant, "\tCan change authentication type");
		
		[currentItem setPort:21];
		TEST_INTSEQUAL([currentItem port], 21, "\tCan change port");
		
		[currentItem setPath:@"/StarBug2/Logs/Pilot"];
		TEST_ISEQUAL([currentItem path], @"/StarBug2/Logs/Pilot", "\tCan change path");
		
		[currentItem setAppleShareVolume:@"DwarfServer"];
		TEST_ISNIL([currentItem appleShareVolume], "\tCannot change AppleShare address (not applicable to Internet passwords)");
		
		[currentItem setAppleShareAddress:@"ab:cd:ef"];
		TEST_ISNIL([currentItem appleShareAddress], "\tCannot change AppleShare address (not applicable to Internet passwords)");
		
		SecAFPServerSignature signature = {0, 3, 5, 7, 9, 255, 245, 235, 225, 215, 3, 5, 7, 11, 13, 17};
		[currentItem setAppleShareSignature:&signature];
		TEST_ISNULL([currentItem appleShareSignature], "\tCannot change AppleShare signature (not applicable to Internet passwords)");
		
		[currentItem setProtocol:kSecProtocolTypeFTP];
		TEST_INTSEQUAL_F([currentItem protocol], kSecProtocolTypeFTP, nameOfProtocolConstant, "\tCan change protocol");
		
		[currentItem setCertificateType:CSSM_CERT_X_509v3];
		TEST_INTSEQUAL_F([currentItem certificateType], CSSM_CERT_UNKNOWN, nameOfCertificateTypeConstant, "\tCannot change certificate type");
		
		[currentItem setCertificateEncoding:CSSM_CERT_ENCODING_BER];
		TEST_INTSEQUAL_F([currentItem certificateEncoding], CSSM_CERT_ENCODING_UNKNOWN, nameOfCertificateEncodingConstant, "\tCannot change certificate encoding (not applicable to Internet passwords)");
		
		[currentItem setCRLType:CSSM_CRL_TYPE_X_509v2];
		TEST_INTSEQUAL_F([currentItem CRLType], CSSM_CRL_TYPE_UNKNOWN, nameOfCRLTypeConstant, "\tCannot change CRL type (not applicable to Internet passwords)");
		
		[currentItem setCRLEncoding:CSSM_CRL_ENCODING_DER];
		TEST_INTSEQUAL_F([currentItem CRLEncoding], CSSM_CRL_ENCODING_UNKNOWN, nameOfCRLEncodingConstant, "\tCannot change CRL encoding (not applicable to Internet passwords)");
		
		[currentItem setAlias:@"Get lost, Rimmer"];
		TEST_ISEQUAL([currentItem alias], @"Get lost, Rimmer", "\tCan change alias");
		
		
		// Verify changes all together
		
		TEST_ISEQUAL([currentItem dataAsString], @"rimmerisanacehole", "\tPassword is still correct");
		
		TEST_ISEQUAL([currentItem account], @"Lister", "\tAccount is still correct");
		TEST_ISEQUAL([currentItem securityDomain], @"Red Dwarf Pilots", "\tSecurity domain is still correct (none)");
		TEST_ISEQUAL([currentItem server], @"reddwarf.net", "\tServer is still correct");
		TEST_INTSEQUAL_F([currentItem authenticationType], kSecAuthenticationTypeRPA, nameOfAuthenticationTypeConstant, "\tAuthentication type is still correct");
		TEST_INTSEQUAL([currentItem port], 21, "\tPort is still correct");
		TEST_ISEQUAL([currentItem path], @"/StarBug2/Logs/Pilot", "\tPath is still correct");
		TEST_INTSEQUAL_F([currentItem protocol], kSecProtocolTypeFTP, nameOfProtocolConstant, "\tProtocol is still correct");
		
		TEST(![currentItem passwordIsValid], "\tPassword is still noted as invalid");
		TEST(![currentItem isVisible], "\tPassword is still invisible");
		TEST([currentItem hasCustomIcon], "\tStill has custom icon");
		
		TEST_COMPARE_DATES_WITHOUT_SUBSECONDS([currentItem creationDate], ==, newCreationDate, "\tCreation date is still correct");
		//TEST_COMPARE_DATES_WITHOUT_SUBSECONDS([currentItem modificationDate], ==, newModificationDate, "\tModification date is still correct");
		
		TEST_ISEQUAL([currentItem typeDescription], @"FTP password for Lister's pilot log on Red Dwarf", "\tType description is still correct");
		TEST_ISEQUAL([currentItem comment], @"Like this will ever get used", "\tComment is still correct");
		TEST_INTSEQUAL([currentItem creator], 'Admn', "\tCreator is still correct (FourCharCode version)");
		TEST_ISEQUAL([currentItem creatorAsString], @"Admn", "\tCreator is still correct (string version)");
		TEST_INTSEQUAL([currentItem type], 'RedD', "\tType is still correct (FourCharCode version)");
		TEST_ISEQUAL([currentItem typeAsString], @"RedD", "\tType is still correct (string version)");
		TEST_ISEQUAL([currentItem label], @"Lister's log access password", "\tLabel is still correct");
		TEST_ISEQUAL([currentItem alias], @"Get lost, Rimmer", "\tAlias is still correct");
		
		TEST_ISNIL([currentItem service], "\tStill doesn't have a service (not applicable to interest passwords)");
		TEST_ISNIL([currentItem userDefinedAttribute], "\tStill doesn't have user-defined attribute (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareVolume], "\tStill doesn't have AppleShare volume (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareAddress], "\tStill doesn't have AppleShare address (not applicable to internet passwords)");
		TEST_ISNIL([currentItem appleShareSignatureData], "\tStill doesn't have AppleShare signature (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem certificateType], CSSM_CERT_UNKNOWN, nameOfCertificateTypeConstant, "\tStill doesn't have a certificate type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem certificateEncoding], CSSM_CERT_ENCODING_UNKNOWN, nameOfCertificateEncodingConstant, "\tStill doesn't have a certificate encoding (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem CRLType], CSSM_CRL_TYPE_UNKNOWN, nameOfCRLTypeConstant, "\tStill doesn't have a CRL type (not applicable to internet passwords)");
		TEST_INTSEQUAL_F([currentItem CRLEncoding], CSSM_CRL_ENCODING_UNKNOWN, nameOfCRLEncodingConstant, "\tStill doesn't have a CRL encoding (not applicable to internet passwords)");
	}
	
	END_TEST();
}

int main(int argc, char const *argv[]) {
#pragma unused (argc, argv) // We have no need for these right now.
    
#if __DARWIN_UNIX03
	srandom((unsigned int)time(NULL));
#else
	srandom(time(NULL));
#endif
	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	Keychain *testKeychain;
	NSString *keychainPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Test Keychain %ld", random()]];

	testKeychain = test_createKeychain(keychainPath, @"password");
	
	if (nil != testKeychain) {
		test_addInternetPasswords(testKeychain);
		test_modifyInternetPasswords(testKeychain);
	}
	
	test_deleteKeychain(keychainPath, testKeychain);
	
    [pool release];

    FINAL_SUMMARY();    
}
