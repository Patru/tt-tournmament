
#import "SmallTextController.h"
#import "TournamentController.h"
#import <sys/time.h>	

@implementation SmallTextController

   NSFont *titleFont;

- (instancetype)init;
{
   NSArray *tabStops = [NSMutableArray arrayWithObjects:
      [[NSTextTab alloc] initWithType:NSRightTabStopType location:20.0],
      [[NSTextTab alloc] initWithType:NSLeftTabStopType location:23.0],
      [[NSTextTab alloc] initWithType:NSLeftTabStopType location:153.0],
      nil];
   NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle alloc] init];
   
   self=[super init];

   [textStyle setTabStops:tabStops];

   textAttributes = [[NSMutableDictionary alloc] initWithCapacity:7];
   [textAttributes setObject:[NSFont fontWithName:@"Helvetica" size:10.0]
		      forKey:NSFontAttributeName];
   [textAttributes setObject:textStyle forKey:NSParagraphStyleAttributeName];

   titleAttributes = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica-Bold" size:12.0]
						 forKey:NSFontAttributeName];

   return self;

}

- (IBAction)showWindow:(id)sender;
{
   [window makeKeyAndOrderFront:sender];
}

- (void)clearText;
/* clears the whole text */
{
   NSMutableString *textString = [[text textStorage] mutableString];

   [textString setString:@""];
   titleLength = 0;
}

- (NSString *)pureText;
{
   return [[text textStorage] string];
}

- (void)setTitleText:(NSString *)aString;
 /* ändert den Titel des Textes */
{
   NSTextStorage *textStorage = [text textStorage];
   NSAttributedString *buffer = [[NSAttributedString alloc] initWithString:aString
							        attributes:titleAttributes];
   
   [textStorage replaceCharactersInRange:NSMakeRange(0,titleLength) withAttributedString:buffer];
   titleLength = [aString length];
}

- (void)appendText:(NSString *)aString;
 /* hängt aString am Ende des Textes an. */
{
   [self appendAttributed:[[NSAttributedString alloc] initWithString:aString
                                                         attributes:textAttributes]];
}

- (void)appendAttributed:(NSAttributedString *)string;
{
   [[text textStorage] appendAttributedString:string];
}

- (IBAction)print:(id)sender
{
   NSSize A6Paper=NSMakeSize(302, 420);
   NSPrintInfo *printInfo = [[NSPrintInfo sharedPrintInfo] copy];
   NSPrintOperation *printOperation=nil;

   [printInfo setPaperSize:A6Paper];
   [printInfo setOrientation:NSPaperOrientationPortrait];
   //[printInfo setHorizontallyCentered:YES];		
	[printInfo setVerticalPagination:NSFitPagination];
	[printInfo setHorizontalPagination:NSFitPagination];
	[printInfo setHorizontallyCentered:NO];
	[printInfo setVerticallyCentered:NO];
	
   [printInfo setLeftMargin:10.0];
   [printInfo setRightMargin:10.0];
   [printInfo setTopMargin:10.0];
   [printInfo setBottomMargin:10.0];
   printOperation=[NSPrintOperation printOperationWithView:text printInfo:printInfo];
   [printOperation setShowsPrintPanel:YES];
   [printOperation runOperation];
}

@end
