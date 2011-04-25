/*
  DIQueueItem.m
  delimport

 Created by Sven-S. Porst <ssp-web@earthlingsoft.net> on 23.04.11.
 Copyright 2011 earthlingsoft. All rights reserved.
*/


#import "DIQueueItem.h"
#import "DIQueue.h"

@implementation DIQueueItem


@synthesize queue;

- (void) start {
	[self performSelector:@selector(finished) withObject:nil afterDelay:0];
}

- (void) finished {
	[self.queue itemFinished:self];
}

@end
