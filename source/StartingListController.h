//
//  StartingListController.h
//  Tournament
//
//  Created by Paul Trunz on 17.09.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface StartingListController : NSObject {
	IBOutlet NSTextView	*text;
	IBOutlet NSWindow	*window;
   NSMutableDictionary *titleAttributes;
   NSMutableDictionary *textAttributes;
}
	
- init;
- (IBAction)showWindow:(id)sender;
- (IBAction)showDrawingLists:(id)sender;
- (IBAction)print:(id)sender;
- (IBAction)clearText;
- (BOOL)empty;
- (void)appendHeader:(NSString *)aString;
- (void)appendText:(NSString *)aString;
- (void)appendAttributedText:(NSAttributedString *)aAttributedString;
- (void)appendStartingList;

@end
