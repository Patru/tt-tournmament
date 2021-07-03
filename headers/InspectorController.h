//
//  InspectorController.h
//  Tournament
//
//  Created by Paul Trunz on Sun Jan 20 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol InspectorControllerProtocol <NSObject>
   - (NSView *)filledViewForOption:(long)option;
   - (void)updateFromView;
@end

@protocol Inspectable <NSObject>
- (id <InspectorControllerProtocol>) inspectorController;
@end

@interface InspectorController : NSObject {
	long _option;
}

@end
