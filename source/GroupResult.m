/*****************************************************************************
     Use: Control a table tennis tournament.
          Results of a group of in a series that is played with groups.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 20.7.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import "GroupResult.h"
#import "Group.h"
#import "Match.h"
#import "Player.h"
#import "PlayingMatchesController.h"
#import "PlayerController.h"
#import "Tournament-Swift.h"
#import "TournamentController.h"

#define MAXGROUP 12

@implementation GroupResult

-init;
{
   self=[super init];

	thisGroup=nil;			// working group
	matchList = nil;	// groups matches, only present
	plList = [[NSMutableArray alloc] init];
	playersInGroup = [[NSMutableDictionary alloc] init];

   positions = nil;
   matches = nil;
   players = nil;
   oneMatch = nil;
   playerPos = nil;
   resultList = nil;
   resultText = nil;
   matchMatrix = nil;
   eightTable = nil;
   setResult = nil;
   upperTitle = nil;
   lowerTitle = nil;
   upperName = nil;
   lowerName = nil;

   return self;
}

- (bool)setGroupForEvaluation:(Group*)aGroup;
{
   long i, max;
   NSArray *groupPlayers;
	
   if (thisGroup == aGroup) return YES;
	
   if (thisGroup != nil) {
      NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = NSLocalizedStringFromTable(@"Achtung!", @"Tournament", null);
		alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Die Resultate der %@ wurden\n"
								  @"noch nicht verarbeitet.\nSollen sie verworfen werden?", @"Tournament", null), [thisGroup description]];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Ja", @"Tournament", nil)];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Lieber nicht", @"Tournament", nil)];
      NSInteger returnCode = [alert synchronousModalSheetForWindow:[NSApp mainWindow]];
      if (returnCode == NSAlertFirstButtonReturn) {
         [matchList removeAllObjects];
      } else {
         [positions makeKeyAndOrderFront:self];
         return NO;
      }
   }
   if (matchList == nil) {
      matchList = [[NSMutableArray alloc] init];
   } // if
   thisGroup = aGroup;
	
   // the following seems ridiculous as all the players are already in an in store
   // table, unfortunately this does not hold true for DoublePlayers!
   // Moreover DoublePlayers are not uniquely identified by their licenceNumber
   // (only unique in the series)
   [playersInGroup removeAllObjects];
   groupPlayers = [thisGroup players];
   max=[groupPlayers count];
   for (i=0; i<max; i++) {
      id<Player> player = [groupPlayers objectAtIndex:i];
      
      [playersInGroup setObject:player forKey:[player licenceNumber]];
   }
   return YES;
} // setGroup

- (bool)currentlyEvaluates:(Group *)aGroup;
{
   return thisGroup == aGroup;
}

- posAbort:sender
{
   [positions orderOut:self];
   return self;
} // posAbort

- matchAbort:sender
{
   [matches orderOut:self];
   return self;
}

- rankAbort:sender;
{
   [resultList orderOut:self];
   return self;
}

- oneMatchAbort:sender;
{
   [NSApp stopModalWithCode:0];		// Something is wrong
   [oneMatch orderOut:self];
   [[NSApp mainWindow] makeKeyAndOrderFront:self];
   return [[TournamentDelegate.shared.matchController playingMatchesController] unselect];
} // Abort

int decided(NSMatrix* aMatrix)
/* in: aMatrix, the matrix to check
 what: checks if the result in aMatrix is decided, i.e. if either plusses or
       minuses are more than half of the rows.
returns: 1 if the plusses have won, -1 if minuses have won, 0 if not decided
*/
{
   long plus=0, minus=0, cols, i=0;
   
   cols=[aMatrix numberOfColumns];
   
   while((i<cols) && (plus <= cols/2) && (minus <= cols/2)
         && ([Match numberForSetString:[[aMatrix cellAtRow:0 column:i] stringValue]] != 0)) {
      if ([Match numberForSetString:[[aMatrix cellAtRow:0 column:i] stringValue]] > 0) {
         plus++;
      } else {
         minus++;
      } // if
      i++;
   } // while
   if (plus > cols/2) {
      return 1;
   } else if (minus > cols/2) {
      return -1;
   } else {
      return 0;
   } // if
   
} // decided

- oneMatchOk:sender;
{  int ret=decided(setResult);

   if (ret != 0) {
      [oneMatch orderOut:self];
      [NSApp stopModalWithCode:ret];		// One match is completed
      [[NSApp mainWindow] makeKeyAndOrderFront:self];
      return [[TournamentDelegate.shared.matchController playingMatchesController] unselect];
   } else {
      int i=0;

      while ([Match numberForSetString:[[setResult cellAtRow:0 column:i] stringValue]] != 0) {
         i++;
      }
      [setResult selectTextAtRow:0 column:i];
   } // if
   return self;
} // oneMatchOk

- results:(Group *)aGroup
{
   long i, numMatch;

   if (positions == nil) {
      [[NSBundle mainBundle] loadNibNamed:@"MatchResult" owner:self topLevelObjects:nil];
   } // if
   if (![self setGroupForEvaluation:aGroup]) {
      return self;
   }

   numMatch = [[thisGroup players] count];
   for(i=0; i<numMatch; i++) {
      id<Player> plAti = [[thisGroup players] objectAtIndex:i];
      NSCell *cell=[players cellAtRow:i column:0];
      // enter players
      [cell setTitle:[plAti longName]];
      [cell setEnabled:(([plAti present]) && (![plAti wo]))];
      [cell setIntValue:1];
   } // for
   for(; i<MAXGROUP; i++) {
      NSCell *cell=[players cellAtRow:i column:0];
      if (cell != nil) {
	 [cell setTitle:@""];
	 [cell setEnabled:NO];
	 [cell setIntValue:0];
      }
   } // for
   [players setNeedsDisplay:YES];
   [positions makeKeyAndOrderFront:self];
   return self;
} // results

- play:sender;
{
	long i, numberOfPlayers, rows;
	const NSSize distance = NSMakeSize(0.0, 0.0);
	NSSize cellSize;
	NSMutableDictionary *present = [NSMutableDictionary dictionary];
	
	numberOfPlayers = [[thisGroup players] count];
	for(i=0; i<numberOfPlayers; i++) {
		id<Player> thisPlayer=[[thisGroup players] objectAtIndex:i];
		
		if ((i >= [players numberOfRows]) || ([[players cellAtRow:i column:0] isEnabled])) {
			if ((i < [players numberOfRows])
					&& ([[players cellAtRow:i column:0] intValue] == 0)) {
				if ([thisPlayer present]) {
					[thisPlayer setWO:YES];
				}
				[thisPlayer removeMatch:thisGroup];
				// even if not present!
			} else {
				[present setObject:@"" forKey:[thisPlayer licenceNumber]];
			} // if
		} else {
	    [thisPlayer setReady:YES];  // ready anyway
		} // if
	} // for
	
	[matchList removeAllObjects];
	for(i=0; i<[[thisGroup matches] count]; i++) {
		id mat = [[thisGroup matches] objectAtIndex:i];
		
		if(([present objectForKey:[[mat upperPlayer] licenceNumber]] != nil)
			 && ([present objectForKey:[[mat lowerPlayer] licenceNumber]] != nil)) {
			[matchList addObject:mat];
		} // if
	} // for
	rows = [matchMatrix numberOfRows];
	if (rows > 0) {
		[matchMatrix setPrototype:[matchMatrix cellAtRow:0 column:0]];
	}
	[matchMatrix setIntercellSpacing:distance];
	[matchMatrix renewRows:[matchList count] columns:2];
	cellSize = [matchMatrix cellSize];
	NSRect frame = [[matches contentView] frame];
	if (frame.size.height > 250.0) {
		cellSize.height = (frame.size.height-60)/[matchList count];
	} else {
		cellSize.height = 250.0/[matchList count];
	}
	if (cellSize.height > 25.0) {
		cellSize.height = 25.0;
	}
	[matchMatrix setCellSize:cellSize];
	[matchMatrix sizeToCells];
	[[matches contentView] setNeedsDisplay:YES];
	for(i=0; i<[matchList count]; i++) {
		id mat = [matchList objectAtIndex:i];
		
		[[matchMatrix cellAtRow:i column:0] setTitle:[[mat upperPlayer] longName]];
		[[matchMatrix cellAtRow:i column:1] setTitle:[[mat lowerPlayer] longName]];
		
		if ([mat winner] == [mat lowerPlayer]) {
			[[matchMatrix cellAtRow:i column:0] setIntValue:0];
			[[matchMatrix cellAtRow:i column:1] setIntValue:1];
		} else {
			[[matchMatrix cellAtRow:i column:0] setIntValue:1];
			[[matchMatrix cellAtRow:i column:1] setIntValue:0];
		} // if
	} // for
	[matchMatrix display];
	[matches makeKeyAndOrderFront:self];
	
	return self;
}

- selectWinner:sender;
{
   long row, column;
   NSRect frame;
   
   [matchMatrix getRow:&row column:&column ofCell:[sender selectedCell]];
   [[matchMatrix cellAtRow:row column:column] setIntValue:1];
   frame=[matchMatrix cellFrameAtRow:row column:column];
   [[matchMatrix cellAtRow:row column:column] drawInteriorWithFrame:frame inView:matchMatrix];
   [[matchMatrix cellAtRow:row column:1-column] setIntValue:0];
   frame=[matchMatrix cellFrameAtRow:row column:1-column];
   [[matchMatrix cellAtRow:row column:1-column]  drawInteriorWithFrame:frame inView:matchMatrix];
	
   if ([TournamentDelegate.shared.preferences exactResults]) {
      id <Player> winner;
      if (column == 0) {
         winner = [[matchList objectAtIndex:row] upperPlayer];
      } else {
         winner = [[matchList objectAtIndex:row] lowerPlayer];
      } // if
      [self singleMatchExact:[matchList objectAtIndex:row] winner:winner for:matches];
   } // if
   return self;
} // selectWinner

- (bool) singleMatchExact:(Match *)aMatch winner:(id <Player>)aPlayer  for:(NSWindow *)window;
// aPlayer should be the winner
{
   long i, cols, ret;
   id <Player> oldWinner = [aMatch winner];     // we have to revert if we do not continue to the end
   
   [aMatch sWinner:aPlayer];
   
   cols = [setResult numberOfColumns];		// determine rows
   
   if ([aMatch isBestOfSeven]) {				// seven rows necessary (5 are always present)
      if (cols < 6) {		// add sixth row if not present
         [setResult setPrototype:[setResult cellAtRow:0 column:0]];
         [setResult addColumn];
         [[setResult cellAtRow:0 column:5] setTag:5];
      } // if
      
      if (cols < 7) {		// add seventh row if not present
         [setResult addColumn];
         [[setResult cellAtRow:0 column:6] setTag:6];
      } // if
   } else {
      if (cols > 6) {		// if more than 5 then there are 7
         [setResult removeColumn:6];
         [setResult removeColumn:5];
      } // if
   } // if
   [setResult sizeToCells];
   [setResult display];
   
   cols=[setResult numberOfColumns];
   
   for(i=0; i < cols; i++) {
      [[setResult cellAtRow:0 column:i] setStringValue:[aMatch upperLowerShortStringSet:i]];
   } // for
   [setResult selectTextAtRow:0 column:0];
   [upperTitle setEditable:YES];
   [lowerTitle setEditable:YES];
   
   NSString *siegerTitle = NSLocalizedStringFromTable(@"Sieger", @"Tournament", @"Winner");
   NSString *verliererTitle = NSLocalizedStringFromTable(@"Verlierer", @"Tournament", @"Loser");
   if (aPlayer == [aMatch upperPlayer]) {
      [upperTitle setStringValue:siegerTitle];
      [lowerTitle setStringValue:verliererTitle];
   } else {
      [upperTitle setStringValue:verliererTitle];
      [lowerTitle setStringValue:siegerTitle];
   } // if
   
   [upperTitle setEditable:NO];
   [lowerTitle setEditable:NO];
   [upperName setEditable:YES];
   [upperName setStringValue:[[aMatch upperPlayer] longName]];
   [upperName setEditable:NO];
   [lowerName setEditable:YES];
   [lowerName setStringValue:[[aMatch lowerPlayer] longName]];
   [lowerName setEditable:NO];
   [setResult display];
   
   if ((ret = [NSApp runModalForWindow:oneMatch]) == 0) {
      [aMatch sWinner:oldWinner];
      return NO;
   } // if
   
   /*************************************************************************/
   /*     determine if the correct player (the one given by the button)     */
   /*     has won by the numbers also.                                      */
   /*************************************************************************/
   
   if (((aPlayer == [aMatch upperPlayer]) && (ret < 0))
       || ((aPlayer == [aMatch lowerPlayer]) && (ret > 0))) {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Achtung!", @"Tournament", null);
      alert.informativeText = NSLocalizedStringFromTable(@"Falscher Sieger", @"Tournament", null);
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", null)];
      [alert beginSheetModalForWindow:TournamentDelegate.shared.matchController.matchWindow completionHandler:nil];
      [aMatch sWinner:oldWinner];

      return NO;
   } else {
      for(i=0; i<cols; i++) {
         [aMatch setUpperLowerSet:i to:[[setResult cellAtRow:0 column:i] stringValue]];
      }
      
      return YES;
   }
} // singleMatchExact

- (BOOL) appendSorted:(NSMutableArray<id<Player>> *)pls rank:(long *)aRank wins:(long)wins show:(BOOL)show;
/* in: pls: players to append
      rank: starting rank for players
      wins: number of wins, equal for all players
      show: show the panel with the ranking at the end
  out: YES if sort was possible, NO otherwise
*/
{
   if ([pls count] == 0) {
      return YES;			// always sorted
   } else if ([pls count] == 1) {		// sorted by wins
      NSString *buffer;
      NSTextStorage *textStorage = [resultText textStorage];
      
      (*aRank)++;
      [plList addObject:[pls objectAtIndex:0]];
      buffer = [NSString stringWithFormat:@"%ld. %@\t%ld\n", *aRank,
                [[pls objectAtIndex:0] longName], wins];
      [textStorage appendAttributedString:[[NSAttributedString alloc]
                                           initWithString:buffer
                                           attributes:[GroupResult tabbedAttributes]]];
      [thisGroup keepResultOf:[pls objectAtIndex:0] rank:*aRank wins:wins
                     setsPlus:0 minus:0 pointsPlus:0 minus:0];
   } else {
      int i;
      NSMutableDictionary * setsp = [NSMutableDictionary dictionary];
      NSMutableDictionary * setsm = [NSMutableDictionary dictionary];
      NSMutableDictionary * pointsp = [NSMutableDictionary dictionary];
      NSMutableDictionary * pointsm = [NSMutableDictionary dictionary];
      NSDictionary<NSString *, id> *tabbedAttributes = [GroupResult tabbedAttributes];
      
      for(i=0; i<[matchList count]; i++) {
         Match *aMatch = (Match *)[matchList objectAtIndex:i];
         id upper = [aMatch upperPlayer];
         id lower = [aMatch lowerPlayer];
         long upperSets = [aMatch upperPlayerSets], lowerSets = [aMatch lowerPlayerSets];
         long upperPoints = [aMatch upperPlayerPoints], lowerPoints = [aMatch lowerPlayerPoints];
         
         if (([pls indexOfObject:upper] != NSNotFound) &&
             ([pls indexOfObject:lower] != NSNotFound)) {
            BOOL winnerFront=NO;	// Flag correct for more than two
            
            if ((show) && ([pls count] >2)) {
               if (![self singleMatchExact:aMatch winner:[aMatch winner] for:matches]) {
                  return NO;
               } // if
            } else if ([pls count] == 2) {
               winnerFront = YES;	// two are decided by direct match
            } // if
            
            upperSets = [aMatch upperPlayerSets];
            lowerSets = [aMatch lowerPlayerSets];
            upperPoints = [aMatch upperPlayerPoints];
            lowerPoints = [aMatch lowerPlayerPoints];
            
            [setsp setObject:[NSNumber numberWithLong:[[setsp objectForKey:[upper licenceNumber]] longValue] + upperSets]
                      forKey:[upper licenceNumber]];
            [setsp setObject:[NSNumber numberWithLong:[[setsp objectForKey:[lower licenceNumber]] longValue] + lowerSets]
                      forKey:[lower licenceNumber]];
            [setsm setObject:[NSNumber numberWithLong:[[setsm objectForKey:[upper licenceNumber]] longValue] + lowerSets]
                      forKey:[upper licenceNumber]];
            [setsm setObject:[NSNumber numberWithLong:[[setsm objectForKey:[lower licenceNumber]] longValue] + upperSets]
                      forKey:[lower licenceNumber]];
            [pointsp setObject:[NSNumber numberWithLong:
                                [[pointsp objectForKey:[upper licenceNumber]] longValue] + upperPoints]
                        forKey:[upper licenceNumber]];
            [pointsp setObject:[NSNumber numberWithLong:
                                [[pointsp objectForKey:[lower licenceNumber]] longValue] + lowerPoints]
                        forKey:[lower licenceNumber]];
            [pointsm setObject:[NSNumber numberWithLong:
                                [[pointsm objectForKey:[upper licenceNumber]] longValue] + lowerPoints]
                        forKey:[upper licenceNumber]];
            [pointsm setObject:[NSNumber numberWithLong:
                                [[pointsm objectForKey:[lower licenceNumber]] longValue] + upperPoints]
                        forKey:[lower licenceNumber]];
         } // if
      } // for
      
      for(i=1; i<[pls count]; i++) {  // sortieren
         int j=i;
         id  pli=[pls objectAtIndex:i], plj;
         int sepi=[[setsp objectForKey:[pli licenceNumber]] intValue],
         semi=[[setsm objectForKey:[pli licenceNumber]] intValue],
         popi=[[pointsp objectForKey:[pli licenceNumber]] intValue],
         pomi=[[pointsm objectForKey:[pli licenceNumber]] intValue],
         sepj, semj, popj, pomj;
         
         while ( (j>0)
                && ( (semi == 0)
                    || ( (plj = [pls objectAtIndex:j-1],		// better
                          popj = [[pointsp objectForKey:[plj licenceNumber]] intValue],
                          pomj = [[pointsm objectForKey:[plj licenceNumber]] intValue],
                          sepj = [[setsp objectForKey:[plj licenceNumber]] intValue],
                          semj = [[setsm objectForKey:[plj licenceNumber]] intValue])
                        && ( ((float)sepi/(float)semi > (float)sepj/semj)
                            || ( ((float)sepi/semi == (float)sepj/semj)
                                && ((float)popi/pomi > (float)popj/pomj) ) )
                        ) ) ) {
                       j--;
                    } // while
         if (j < i) {
            id temp = [pls objectAtIndex:i];		// save player
            [pls removeObjectAtIndex:i];		// remove
            [pls insertObject:temp atIndex:j];	 	// and put in front
         } // if
      } // for
      for(i=0; i<[pls count]; i++) {
         id<Player> pli = [pls objectAtIndex:i];
         
         (*aRank)++;
         [plList addObject:pli];
         if (show) {
            NSTextStorage *textStorage = [resultText textStorage];
            NSString *buf=[NSString stringWithFormat:@"%ld. %@\t%ld\t%ld\t:\t%ld\t%ld\t:\t%ld\n",
                           *aRank, [pli longName], wins,
                           [[setsp objectForKey:[pli licenceNumber]] longValue],
                           [[setsm objectForKey:[pli licenceNumber]] longValue],
                           [[pointsp objectForKey:[pli licenceNumber]] longValue],
                           [[pointsm objectForKey:[pli licenceNumber]] longValue]];
            NSAttributedString *tabbedBuffer = [[NSAttributedString alloc] initWithString:buf
                                                                               attributes:tabbedAttributes];
            
            [textStorage appendAttributedString:tabbedBuffer];
         }
         [thisGroup keepResultOf:pli rank:*aRank wins:wins
                        setsPlus:[[setsp objectForKey:[pli licenceNumber]] longValue]
                           minus:[[setsm objectForKey:[pli licenceNumber]] longValue]
                      pointsPlus:[[pointsp objectForKey:[pli licenceNumber]] longValue]
                           minus:[[pointsm objectForKey:[pli licenceNumber]] longValue] ];
      } // for
   } // if
   return YES;
} // appendSorted

- rankDecided:sender
// all matches decided, now determine the ranking
{
	NSMutableDictionary *won,      	// A list with winners
	*lost;		// ... and a list with loosers
	long i, max, rank=0;
	NSMutableArray * rankTable[MAXGROUP];
	NSRange fullRange;
	NSEnumerator *enumerator;
	NSNumber *licence;
	
	won = [NSMutableDictionary dictionary];
	lost = [NSMutableDictionary dictionary];
	
	if (matchList == nil) {
		matchList = [[NSMutableArray alloc] init];
	} else {
		[matchList removeAllObjects];
	} // if
	for(i=0; i<[[thisGroup matches] count]; i++) {
		id mat = [[thisGroup matches] objectAtIndex:i];
		
		if(([[mat upperPlayer] present]) && ([[mat lowerPlayer] present])) {
			[matchList addObject:mat];
		} // if
	} // for
	
	for(i=0; i<[matchList count]; i++) {
		id aWinner = [[matchList objectAtIndex:i] winning];
		id aLooser = [[matchList objectAtIndex:i] losing];
		if ([won objectForKey:[aWinner licenceNumber]] == nil) {
			[won setObject:[NSMutableArray array] forKey:[aWinner licenceNumber]];
		} // if
		if ([lost objectForKey:[aLooser licenceNumber]] == nil) {
			[lost setObject:[NSMutableArray array] forKey:[aLooser licenceNumber]];
		} // if
		[(id) [won objectForKey:[aWinner licenceNumber]] addObject:aLooser];
		[(id) [lost objectForKey:[aLooser licenceNumber]] addObject:aWinner];
	}// for
	
	for(i=0; i<MAXGROUP; i++) {
		rankTable[i] = [NSMutableArray array];
	} // for
	enumerator = [won keyEnumerator];
	while (licence=[enumerator nextObject]) {
		id list=[won objectForKey:licence];
		id player = [playersInGroup objectForKey:licence];
		
		[rankTable[[list count]] addObject:player];
	}
	
	max = [[thisGroup players] count];
	
	for (i=0; i < max; i++) {
		id<Player> player = [[thisGroup players] objectAtIndex:i];
		
		if ([player present] && ![player wo]) {
			licence = [player licenceNumber];
			if ([won objectForKey:licence] == nil) {
				[rankTable[0] addObject:player];
			}
		}
	}
	
	[resultText setEditable:YES];
	fullRange=NSMakeRange(0, [[resultText string] length]);
	[resultText replaceCharactersInRange:fullRange withString:@""];
	[resultText setEditable:NO];
	[plList removeAllObjects];
	for(i=MAXGROUP-1; i>=0; i--) {
		if (![self appendSorted:rankTable[i] rank:&rank wins:i show:NO]) {
			return self;
		} // if
	} // for
	
	[thisGroup setRankingList:plList];	// first store new order
	[thisGroup setFinished:YES];			// then go on playing
	[[TournamentDelegate.shared.matchController playingMatchesController] removePlayable:thisGroup];
	// do umpires and matches soon
	thisGroup = nil;			// this group is definitely finished
	[matchList removeAllObjects];
	[[TournamentDelegate.shared.matchController matchBrowser] updateMatrix];
	return self;
} // rankDecided

- rank:sender;
{
   NSMutableDictionary *won,      	// A list with winners
   *lost;		// ... and a list with loosers
   long rows, i, max, rank=0;
   id rankTable[MAXGROUP];
   NSRange fullRange;
   NSNumber *licence;
   NSEnumerator *enumerator;

   rows = [matchMatrix numberOfRows];
   for(i=0; i<rows; i++) {  // register all matches
      if ((![[matchMatrix cellAtRow:i column:0] intValue]) &&
			 (![[matchMatrix cellAtRow:i column:1] intValue])) {
         // the current UI does not seem to allow this situation, we could drop this alert.
         NSAlert *alert = [NSAlert new];
         alert.messageText = NSLocalizedStringFromTable(@"Achtung!", @"Tournament", null);
         alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Spiel Nummer %d nicht ausgetragen!?", @"Tournament", null), i+1];
         [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Ich versuchs nochmal", @"Tournament", null)];
         [alert beginSheetModalForWindow:matches completionHandler:nil];

			return self;		// undecided match ?!
      }
      if ([[matchMatrix cellAtRow:i column:0] intValue] == 1) {
			[[matchList objectAtIndex:i]
			 setWinner:[[matchList objectAtIndex:i] upperPlayer]];
      } else {
			[[matchList objectAtIndex:i]
			 setWinner:[[matchList objectAtIndex:i] lowerPlayer]];
      } // if
   } // for
   won = [NSMutableDictionary dictionary];
   lost = [NSMutableDictionary dictionary];
   for(i=0; i<[matchList count]; i++) {
      id aWinner = [[matchList objectAtIndex:i] winning];
      id aLooser = [[matchList objectAtIndex:i] losing];
      if ([won objectForKey:[aWinner licenceNumber]] == nil) {
         [won setObject:[NSMutableArray array] forKey:[aWinner licenceNumber]];
      } // if
      if ([lost objectForKey:[aLooser licenceNumber]] == nil) {
         [lost setObject:[NSMutableArray array] forKey:[aLooser licenceNumber]];
      } // if
      [[won objectForKey:[aWinner licenceNumber]] addObject:aLooser];
      [[lost objectForKey:[aLooser licenceNumber]] addObject:aWinner];
   }// for
   for(i=0; i<MAXGROUP; i++) {
      rankTable[i] = [NSMutableArray array];
   } // for
   enumerator = [won keyEnumerator];
   while (licence=[enumerator nextObject]) {
      id list=[won objectForKey:licence];
      id player = [playersInGroup objectForKey:licence];

      [rankTable[[list count]] addObject:player];
   }

   max = [[thisGroup players] count];

   for (i=0; i < max; i++) {
      id<Player> player = [[thisGroup players] objectAtIndex:i];
      
      if ([player present] && ![player wo]) {
         licence = [player licenceNumber];
         if ([won objectForKey:licence] == nil) {
            [rankTable[0] addObject:player];
         }
      }
   }

   [resultText setEditable:YES];
   fullRange=NSMakeRange(0, [[resultText string] length]);
   [resultText replaceCharactersInRange:fullRange withString:@""];
   [resultText setEditable:NO];
   [plList removeAllObjects];
   for(i=MAXGROUP-1; i>=0; i--) {
      if (![self appendSorted:rankTable[i] rank:&rank wins:i show:YES]) {
	 return self;
      } // if
   } // for
   [resultText setNeedsDisplay:YES];
   [matches beginSheet:resultList completionHandler:^(NSModalResponse returnCode) {
      if (returnCode == NSAlertFirstButtonReturn) {
         return;
      }
   }];
   return self;
} // rank

- saveMatches:sender;
{
   long i, max = [matchList count];
   
   for(i=0; i<max; i++) {
      [[matchList objectAtIndex:i] storeInDB];
   } // for
   [thisGroup setRankingList:plList];	// first store new order
   [thisGroup setFinished:YES];			// then go on playing
   [[TournamentDelegate.shared.matchController playingMatchesController] removePlayable:thisGroup];
   // do umpires and matches soon
   thisGroup = nil;			// this group is definitely finished
   [matchList removeAllObjects];
   [positions orderOut:self];
   [matches orderOut:self];
   [resultList orderOut:self];
   [[NSApp mainWindow] makeKeyAndOrderFront:self];

   return self;
} // saveMatches

- (BOOL)textShouldEndEditing:(NSText *)textObject;
{
	printf("text should end editing\n");
	return YES;
}

+ (NSMutableParagraphStyle *)paragraphStyle;
{
   NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
   NSMutableArray *tabList = [NSMutableArray array];

   [tabList addObject:[[NSTextTab alloc] initWithType:NSRightTabStopType location:150.0]];
   [tabList addObject:[[NSTextTab alloc] initWithType:NSRightTabStopType location:172.0]];
   [tabList addObject:[[NSTextTab alloc] initWithType:NSCenterTabStopType location:176.0]];
   [tabList addObject:[[NSTextTab alloc] initWithType:NSLeftTabStopType location:180.0]];
   [tabList addObject:[[NSTextTab alloc] initWithType:NSRightTabStopType location:217.0]];
   [tabList addObject:[[NSTextTab alloc] initWithType:NSRightTabStopType location:221.0]];
   [tabList addObject:[[NSTextTab alloc] initWithType:NSLeftTabStopType location:224.0]];
   [paragraphStyle setTabStops:tabList];
   
   return paragraphStyle;
}

+ (NSDictionary *)tabbedAttributes;
{
   NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:
			    [NSFont fontWithName:@"Helvetica" size:12.0] forKey:NSFontAttributeName];
			    
   [attributes setObject:[GroupResult paragraphStyle] forKey:NSParagraphStyleAttributeName];

   return attributes;
}

- (NSWindow *) oneMatch;
{
   return oneMatch;
}
@end
