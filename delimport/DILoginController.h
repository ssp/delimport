//
//  DILoginController.h
//  delimport
//
//  Created by Ian Henderson on 01.05.05.
//  Copyright 2005 Ian Henderson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum serviceIDs {
	DIServiceTypeDelicious = 0,
	DIServiceTypePinboard = 1
} serviceID;


@interface DILoginController : NSWindowController {
	IBOutlet NSTextField * userField;
	IBOutlet NSTextField * passField;
}

- (void) run;
- (IBAction) logIn: (id) sender;
- (IBAction) quit: (id) sender;
- (IBAction) showWebPage: (id) sender;

@end
