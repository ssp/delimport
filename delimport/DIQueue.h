/*
  DIQueue.h
  delimport

  Created by Sven-S. Porst <ssp-web@earthlingsoft.net> on 23.04.11.
  Copyright 2011 earthlingsoft. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

@class DIQueueItem;


@interface DIQueue : NSObject {
	NSMutableArray * queue;
	BOOL isRunning;
}

@property (readonly) BOOL isRunning;


- (void) addToQueue: (DIQueueItem*) item;
- (void) itemFinished: (DIQueueItem*) item;

@end
