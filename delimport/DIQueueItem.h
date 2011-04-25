/*
  DIQueueItem.h
  delimport

  Created by Sven-S. Porst <ssp-web@earthlingsoft.net> on 23.04.11.
  Copyright 2011 earthlingsoft. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

@class DIQueue;


@interface DIQueueItem : NSObject {
	DIQueue * queue;
}

@property (retain) DIQueue * queue;

- (void) start;
- (void) finished;

@end

