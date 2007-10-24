//
//  DILoginController.h
//  delimport
//
//  Created by Ian Henderson on 01.05.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DILoginController : NSWindowController {
	IBOutlet NSTextField *userField;
	IBOutlet NSTextField *passField;
}

- (IBAction)logIn:sender;
- (IBAction)quit:sender;
- (void)getUsername:(NSString **)username password:(NSString **)password;

@end
