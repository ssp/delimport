//
//  DIFileController.h
//  delimport
//
//  Created by Ian Henderson on 28.04.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DIFileController : NSObject {

}

- (void)saveDictionary:(NSDictionary *)dictionary;

- (void)saveDictionaries:(NSSet *)dictionaries;
- (void)deleteDictionaries:(NSSet *)dictionaries;

- (BOOL)openFile:(NSString *)filename;

@end
