/*
 DIServiceTypeToIconPath.m
 delimport

 Created by Sven-S. Porst <ssp-web@earthlingsoft.net> on 2011-01-03.
 Copyright 2011 earthlingsoft. All rights reserved.
*/

#import "DIServiceTypeToIconPath.h"
#import "DILoginController.h"

@implementation DIServiceTypeToIconPath

+ (Class) transformedValueClass {
	return [NSString class];
}

+ (BOOL) allowsReverseTransformation {
	return NO;
}

- (id) transformedValue: (id) value {
	NSString * iconFileName = @"delicious.icns";
	
	if (value != nil && [value integerValue] == DIServiceTypePinboard) {
		iconFileName = @"pinboard.gif";
	}
	
    return [[NSBundle mainBundle] pathForImageResource:iconFileName];
}


@end
