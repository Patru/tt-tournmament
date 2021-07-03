
#import "GroupInspector.h"
#import "MatchBrowserCell.h"
#import "PlayerController.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

@implementation GroupInspector

- init;
{
   self=[super init];
   [[NSBundle mainBundle] loadNibNamed:@"GroupInspector" owner:self topLevelObjects:nil];
   _group=nil;
   _option=0;

   return self;
}

- (NSView *)fillMatchView;
{
   [matches loadColumnZero];
   return matchView;
}

- (void) sizeLicencesAndPlayersTo:(long)numberOfPlayers;
{
   long rows;
   NSRect newFrame, oldFrame;

   [licences setPrototype:[licences cellAtRow:0 column:0]];
   [players  setPrototype:[players  cellAtRow:0 column:0]];

   rows=[licences numberOfRows];

   if (numberOfPlayers != rows) {
      float deltaHeight=0;

      oldFrame=[players frame];
      [players renewRows:numberOfPlayers columns:1];
      [players sizeToCells];
      newFrame=[players frame];

      deltaHeight = NSHeight(oldFrame) - NSHeight(newFrame);
      newFrame.origin.y = NSMinY(newFrame) + deltaHeight;
      [players setFrame:newFrame];		// only y is changed

      oldFrame=[licences frame];
      [licences renewRows:numberOfPlayers columns:1];
      [licences sizeToCells];
      newFrame=[licences frame];

      deltaHeight = NSHeight(oldFrame) - NSHeight(newFrame);
      newFrame.origin.y = NSMinY(newFrame) + deltaHeight;
      [licences setFrame:newFrame];		// only y is changed

      [playerView setNeedsDisplay:YES];	// needs to draw background too
   }
   [licences selectCellAtRow:numberOfPlayers-1 column:0];
}	

- (NSView *)fillPlayerView;
{
   long i, max = [[_group players] count];

   [self sizeLicencesAndPlayersTo:max];

   [[infoForm cellAtRow:0 column:0] setStringValue:[[_group series] fullName]];
   [[infoForm cellAtRow:1 column:0] setIntValue:(int)[_group number]];
   [[infoForm cellAtRow:2 column:0] setFloatValue:[_group tp]];
   [tableField setStringValue:[_group tableString]];

   for(i=0; i<max; i++) {
      id<Player> pl = [[_group players] objectAtIndex:i];

      if ([pl licence] != 0) {
	 [[licences cellAtRow:i column:0] setIntValue:(int)[pl licence]];
	 [[players cellAtRow:i column:0] setStringValue:
	    [NSString stringWithFormat:@"%3d %@", (int) [pl ranking], [pl longName]]];
      } else {
	 [[licences cellAtRow:i column:0] setStringValue:@"neu"];
	 [[players cellAtRow:i column:0] setStringValue:@""];
      }
   } // for
   [licences setNeedsDisplay:YES];
   [players setNeedsDisplay:YES];

   return playerView;
}

- (NSView *)filledViewForOption:(long)option;
{
   _option=option;
   switch(_option) {
      case 0: {
	 return [self fillPlayerView];
      }
      case 1: {
	 return [self fillMatchView];
      }
   }
   return nil;
}

- (IBAction)addPlayer:(id)sender;
{
   if ([[_group players] count] < 6) {
      NSMutableArray *playerList=[NSMutableArray arrayWithArray:[_group players]];

      [playerList addObject:[[SinglePlayer alloc] init]];    // add empty player
      [_group setPlayers:playerList];
      [self fillPlayerView];
   } // if
} // addPlayer

- removeLastPlayer:sender;
{
   NSMutableArray *pls=[NSMutableArray arrayWithArray:[_group players]];
   [[pls lastObject] removeMatch:_group];
   [pls removeLastObject];
   [_group setPlayers:pls];
   [_group makeMatches];
   [self fillPlayerView];

   return self;
} // removeLastPlayer

- (void)updateFromPlayerView;
{
   NSMutableArray *pls = [NSMutableArray arrayWithArray:[_group players]];
   long i, max = [pls count];
   NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
   formatter.numberStyle = NSNumberFormatterDecimalStyle;

   [_group setNumber:[[infoForm cellAtRow:1 column:0] intValue]];
   //   fullName and priority are not editable here
   
   for(i=0; i<max; i++) {
      NSString * licenseStr = [[licences cellAtRow:i column:0] stringValue];
      int new = [[formatter numberFromString:licenseStr] intValue];
      
      if (new != [[pls objectAtIndex:i] licence]) {
         id  newpl = [[TournamentDelegate.shared playerController] playerWithLicence:new];
         
         [[pls objectAtIndex:i] removeMatch:_group];
         [pls replaceObjectAtIndex:i withObject:(id)newpl];
         [_group setPlayers:pls];
         [newpl addMatch:_group];		// remove from old, add to new
         [_group makeMatches];
      } // if
   } // for
   
   [self fillPlayerView];
} // ok

- (void)setGroup:(Group *)group;
{
   _group=group;
}

- (void)updateFromView;
{
   switch(_option) {
      case 0: {
	 [self updateFromPlayerView];
      }
      case 1: {
	 // not available
      }
   }
}

- playSingleMatches:sender;
{
	[_group playSingleMatches];
	
	return self;
}

- (IBAction)recomputeRanking:(id)sender;
{
   [_group result:NO];
}

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix;
   // fills the matches in the fields of the browser `sender`
{
   NSArray *groupMatches = [_group matches];
   long i, max = [groupMatches count];
   id cell;

   if(!([matrix prototype] == [MatchBrowserCell class])) {
      cell = [[MatchBrowserCell alloc] init];
      [sender setCellPrototype:cell];		// set prototype to MatchBrowserCell
      [matrix setPrototype:cell];
		NSString *browserTitle = NSLocalizedStringFromTable(@"Gruppenspiele", @"Tournament", null);
		[sender setTitle:browserTitle ofColumn:0];		
   } // if

   for(i=0; i<max; i++) {
      [matrix addRow];
      cell = [matrix cellAtRow:i column:0];
      [cell setPlayable:(Match *)[groupMatches objectAtIndex:i]];
      [cell setLoaded:YES];
      [cell setLeaf:YES];
   } // for
}

@end
