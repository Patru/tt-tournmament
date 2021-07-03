//
//  StartingListController.m
//  Tournament
//
//  Created by Paul Trunz on 17.09.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "StartingListController.h"
#import <PGSQLKit/PGSQLKit.h>
#import "SeriesController.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

@implementation StartingListController

- init;
{
   NSArray *tabStops = [NSMutableArray arrayWithObjects:
      [[NSTextTab alloc] initWithType:NSRightTabStopType location:50.0],
      [[NSTextTab alloc] initWithType:NSLeftTabStopType location:53.0],
      [[NSTextTab alloc] initWithType:NSLeftTabStopType location:153.0],
      [[NSTextTab alloc] initWithType:NSLeftTabStopType location:253.0],
      [[NSTextTab alloc] initWithType:NSRightTabStopType location:353.0],
      [[NSTextTab alloc] initWithType:NSRightTabStopType location:373.0],
      nil];
   NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle alloc] init];
   
   self=[super init];
	
   [textStyle setTabStops:tabStops];
	
   textAttributes = [[NSMutableDictionary alloc] initWithCapacity:7];
   [textAttributes setObject:[NSFont fontWithName:@"Helvetica" size:12.0]
							 forKey:NSFontAttributeName];
   [textAttributes setObject:textStyle forKey:NSParagraphStyleAttributeName];
	
   titleAttributes = [[NSMutableDictionary alloc] initWithCapacity:7];
	[titleAttributes setObject:[NSFont fontWithName:@"Helvetica-Bold" size:12.0]
							  forKey:NSFontAttributeName];
   [titleAttributes setObject:textStyle
							  forKey:NSParagraphStyleAttributeName];
   	
	window = nil;
	
   return self;
	
}

- (IBAction)showWindow:(id)sender;
{
   [self loadUiIfNecessary];
   [self clearText];
	[self appendHeader:@"Nummer\tName\tVorname\tClub\tKlassierung\n"];
	[self appendStartingList];
	[window makeKeyAndOrderFront:sender];
}

- (IBAction)showDrawingLists:(id)sender;
{
   [self loadUiIfNecessary];
	[self clearText];
	[self appendAttributedText: [[TournamentDelegate.shared seriesController] listsForDraw]];
	[window makeKeyAndOrderFront:sender];
}

- (void)loadUiIfNecessary;
{
   if (window == nil) {
      [[NSBundle mainBundle] loadNibNamed:@"StartingList" owner:self topLevelObjects:nil];
   }
}

- (void)clearText;
{
   NSMutableString *textString = [[text textStorage] mutableString];
	
   [textString setString:@""];
}

- (BOOL)empty;
{
   return ([[text textStorage] length] == 0);
}

- (void)appendHeader:(NSString *)aString;
{
   NSTextStorage *textStorage = [text textStorage];
   NSAttributedString *buffer = [[NSAttributedString alloc] initWithString:aString
																					 attributes:titleAttributes];
   [textStorage appendAttributedString:buffer];
}

- (void)appendText:(NSString *)aString;
	/* hŠngt aString am Ende des Textes an. */
{
	NSTextStorage *textStorage = [text textStorage];
	NSAttributedString *buffer = [[NSAttributedString alloc] initWithString:aString
																					  attributes:textAttributes];
	[textStorage appendAttributedString:buffer];
}

- (void)appendAttributedText:(NSAttributedString *)aAttributedString;
{
   NSTextStorage *textStorage = [text textStorage];
   [textStorage appendAttributedString:aAttributedString];
}

- (IBAction) print:(id)sender
{
	NSPrintOperation *printOperation=nil;
	
	printOperation=[NSPrintOperation printOperationWithView:text];
	[printOperation setShowsPrintPanel:YES];
	[printOperation runOperation];
}

- (void)appendStartingList;
{
   PGSQLConnection *database=[TournamentDelegate.shared database];
   NSString *selectPresentPlayers = [NSString stringWithFormat:@"SELECT Name, FirstName, Club, Ranking, WomanRanking FROM Player WHERE Licence IN (SELECT Licence FROM PlaySeries WHERE TournamentId = '%@') ORDER BY Club, Name, FirstName", TournamentDelegate.shared.preferences.tournamentId];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:selectPresentPlayers];
   if (rs != nil) {
      long nummer = 0;
      while (![rs isEOF]) {
         nummer++;
         NSString *name = [[rs fieldByName:@"Name"] asString];
         NSString *firstName = [[rs fieldByName:@"FirstName"] asString];
         NSString *club = [[rs fieldByName:@"Club"] asString];
         long ranking = [[rs fieldByName:@"Ranking"] asLong];
         long womanRanking = [[rs fieldByName:@"WomanRanking"] asLong];
         NSString *line = [NSString stringWithFormat:@"\t%ld\t%@\t%@\t%@\t%ld\t",
                           nummer, name, firstName, club, ranking];
         [self appendText:line];
         if (womanRanking > 0) {
            [self appendText:[NSString stringWithFormat:@"%ld\n", womanRanking]];
         } else {
            [self appendText:@"\n"];
         }
         [rs moveNext];
      }
      [rs close];
   }
}

@end
