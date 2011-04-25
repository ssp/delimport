/*
  DIQueue.m
  delimport

  Created by Sven-S. Porst <ssp-web@earthlingsoft.net> on 23.04.11.
  Copyright 2011 earthlingsoft. All rights reserved.
*/

#import "DIQueue.h"
#import "DIQueueItem.h"

@interface DIQueue (Private)
- (void) addToQueue: (DIQueueItem*) item;
- (void) nextItem;
- (void) start;
@end


@implementation DIQueue

@synthesize isRunning;

- (id) init {
	self = [super init];
	if (self) {
		queue = [NSMutableArray array];
	}
	return self;
}


- (void) addToQueue: (DIQueueItem*) item {
	[queue addObject:item];
	item.queue = self;
	[self start];
}


- (void) start {
	if (!isRunning) {
		isRunning = YES;
		[self nextItem];
	}
}


- (void) nextItem {
	if ([queue count] > 0) {
		DIQueueItem * item = [queue objectAtIndex:0];
		[item start];
	}
	else {
		// No items left, stop.
		isRunning = NO;
	}
}


- (void) itemFinished: (DIQueueItem*) item {
	if ([queue count] > 0) {
		if ([queue objectAtIndex:0] == item) {
			[queue removeObjectAtIndex:0];
		}
		else {
			NSLog(@"DIQueue -itemFinished: Wrong item at the beginning of the queue. This shouldn't happen.");
		}
		[self nextItem];
	}
}


@end
