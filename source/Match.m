/*****************************************************************************
     Use: Control a table tennis tournament.
          Storage and display of a single match.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1993
 Version: 0.1, first try
 History: 2.1.94, Patru: project started
 	  15.4.95,  Patru: winners and loosers as incoming
    Bugs: -not very well documented
 *****************************************************************************/

#import "GroupMatch.h"
#import "Match.h"
#import <PGSQLKit/PGSQLKit.h>
#import "Player.h"
#import "SinglePlayer.h"
#import "GroupPlayer.h"
#import "GroupResult.h"
#import "Series.h"
#import "MatchResultController.h"
#import "MatchInspector.h"
#import "MatchView.h"
#import "MatchViewController.h"
#import "PlayingMatchesController.h"
#import "SmallTextController.h"
#import "TournamentController.h"
#import "UmpireController.h"
#import "Tournament-Swift.h"
#import <time.h>
#import <math.h>
#import "Tournament-Swift.h"

MatchInspector *_matchInspector=nil;

#define invalid 0

const int stringSize = 10.0;		// standard: 10 pt
//const int linedelta = 12;		// a bit more
const float xstrd = 1.5, ystrd = 0.0;	// characters should be readable
const float named = 20, clubd = 120;	// distances for names and clubs
const float xprev = 30;

@implementation Match

- init;
{
   self = [super init];
   upper = nil;
   lower = nil;
   upperIsWinner = YES;
   lowerIsWinner = YES;
   upperPrefix   = @"";
   lowerPrefix   = @"";
   next = nil;
   loserNext = nil;
   winner = nil;
   umpire = nil;
   pMatches = 0;
   tNumber = 0;
   rNumber = 0;
   round = 0;
   series = nil;
   startTime   = @"";
   shouldStart = @"";
   sets[0] = invalid;
   sets[1] = invalid;
   sets[2] = invalid;
   sets[3] = invalid;
   sets[4] = invalid;
   sets[6] = invalid;
   tableString = @"";
   wo = NO;
   notifiees = nil;
   return self;
} // init

- releaseAll;
// recursively frees all matches descending from this one
{  
   [[self upperPlayer] removeMatch:self];
   [[self lowerPlayer] removeMatch:self];
   [upper releaseAll];
   [lower releaseAll];
   
   return self;
} // free

- initUpTo:(long)max current:(long)cur total:(long)tot
           next:(Match *)nxt series:(id)ser posList:(NSMutableArray *)pts;
/* in: max: maximal number of participants
       cur: current number of the match
       tot: total number of matches on this level
       nxt: next match
       ser: series in which the match is played
       pts: positions where players may be set
 what: complex recursive initialization for a complete series with up to
       max participants                                                     */
{
   self=[super init];
   if (nxt == nil) {
      round = 1;
   } else {
      round = [nxt round]*2;
   } // if
   if (tot < max) {
      if (2*tot-cur+1 <= max) {
			if (cur%2) {
				upper = [[Match alloc] initUpTo:max current:cur total:2*tot
													next:self series:ser posList:pts];
				lower = [[Match alloc] initUpTo:max current:2*tot-cur+1 total:2*tot
													next:self series:ser posList:pts];
			} else {
				upper = [[Match alloc] initUpTo:max current:2*tot-cur+1 total:2*tot
													next:self series:ser posList:pts];
				lower = [[Match alloc] initUpTo:max current:cur total:2*tot
													next:self series:ser posList:pts];
			} // if
      } else {
         [pts addObject:self];
      } // if
      tNumber = cur;
   } else {
      upper = nil;
      lower = nil;
      tNumber = cur;
      rNumber = 0;
      [pts addObject:self];
   } // if
   upperIsWinner = YES;
   lowerIsWinner = YES;
   upperPrefix   = @"";
   lowerPrefix   = @"";
   series = ser;
   pMatches = 0;
   next = nxt;
   loserNext = nil;		// have to set it by "hand"
   umpire = nil;
   startTime   = @"";
   shouldStart = @"";
   sets[0] = invalid;
   sets[1] = invalid;
   sets[2] = invalid;
   sets[3] = invalid;
   sets[4] = invalid;
   sets[5] = invalid;
   sets[6] = invalid;
   tableString = @"";
   wo = NO;
   notifiees = nil;

   return self;
} // initUpTo

/*****************************************************************************
 *                          Output-methods                                   *
 *****************************************************************************/

- (NSString *)resultString;
   /* what: returns the result as a string, all the sets joined
   */
{
	if (wo) {
		return @"w.o.";
	} else {
		NSMutableString *result = [NSMutableString stringWithCapacity:25];
		int i=1;
		
		if (sets[0] != invalid) {
			[result appendString:[self winnerLoserShortStringSet:0]];
			
			while ((i < 7) && (sets[i] != invalid)) {
				[result appendFormat:@",%@", [self winnerLoserShortStringSet:i]];
				i++;
			}
		}
		
		return result;
	}
} // resultString

- (NSString *)matchResultString;
{
	return [NSString stringWithFormat:@"%ld:%ld", [self upperPlayerSets], [self lowerPlayerSets]];
}

- (NSString *)backupString;
{
   NSMutableString *result = [NSMutableString stringWithCapacity:25];
   int i;

   if (sets[0] != invalid) {
      [result appendFormat:@"%ld", sets[0]];

      for (i=1; i<7; i++) {
	 [result appendFormat:@",%ld", sets[i]];
      }
   }

   return result;
}

- (NSString *)allGamesString;
{
	return [NSString stringWithFormat:@"%ld,%ld,%ld,%ld,%ld,%ld,%ld",
			sets[0], sets[1], sets[2], sets[3], sets[4], sets[5], sets[6]];
}

- (BOOL) needsToDrawWinner {
  return (lower != nil) || (upper != nil);
}

- (float) drawPlayerOnLine: (float) right  top: (float *) top 
					 withAttributes: (NSDictionary *) attributes isWinner: (BOOL) isWinner  {
	float firstwid = [TournamentDelegate.shared.preferences firstWidth];
  float drawLeft = right-firstwid;
	float linepos = *top;
	*top = *top - [Match lineDelta];
	// line under player
	[NSBezierPath strokeLineFromPoint:NSMakePoint(drawLeft,linepos)
														toPoint:NSMakePoint(drawLeft+firstwid, linepos)];
	[[NSString stringWithFormat:@"%ld", tNumber]
	 drawAtPoint:NSMakePoint(drawLeft-xprev, linepos)
	 withAttributes:attributes];
	id<Player> player;
	if (isWinner) {
		player = winner;
	}	else {
		player = [self losing];
	}
	[player drawInMatchTableOf:self x:drawLeft y:linepos+ystrd];
	
	return linepos;
}


- (float)draw:(float *)top at:(float)right max:(long)maxMatches;
/* in:  top: top position for drawing
     right: rightmost position for drawing
maxMatches: maximum number of matches to draw on one page
 prec: lockFocus should be called on the correct view.
 what: recursively draws upper and lower to determine where winner should
       be drawn. The two endpoints are connected with a vertical line and
       in the middle a horizontal line is drawn below the winner.
chang: top will be the top position for the next match to be drawn
  ret: the position (y-direction) where the winner was drawn.       
*/
{
	int upPos=0, lowPos=0;
	PreferencesViewController * preferences = TournamentDelegate.shared.preferences;
	float width = (int)[preferences matchWidth];
	float mypos=0, left, drawLeft;
	NSString *buffer=@"";
	NSDictionary *smallAttributes = [Match smallAttributes];
	
	if ( ((next == nil) || (pMatches == maxMatches)) && (pMatches >= 14) ) {
   	// adjustments for final winner
		left=right;
		drawLeft = left - width;	// the final winner goes left for large tables
	} else {
		left = right-width;
		drawLeft = left;
	}
	
	
	/***************************************************************************
	 line drawing
	 ***************************************************************************/
	if ((upper != nil) && (lower != nil)) {  // upper and lower are defined, draw yourself in the middle
		if (upperIsWinner) {
			upPos = [upper draw:top at:left max:maxMatches];
		} else {
			upPos = [upper drawPlayerOnLine:left top:top withAttributes:smallAttributes isWinner:false];
		}
		if (lowerIsWinner) {
			lowPos = [lower draw:top at:left max:maxMatches];			
		} else {
			lowPos = [lower drawPlayerOnLine:left top:top withAttributes:smallAttributes isWinner:false];
		}
		mypos = (upPos+lowPos)/2;
		[NSBezierPath strokeLineFromPoint:NSMakePoint(left, upPos)
															toPoint:NSMakePoint(left, lowPos)];
		
		if (winner != nil) {
			buffer=[winner shortName];
		} else {
			NSMutableString *buf = [NSMutableString stringWithCapacity:20];
			if ([preferences tourNumbers]) {
				[buf appendFormat: @"%ld ", rNumber];
			}
			if ([tableString length] > 0) {
				[buf appendFormat:@"%@ %@ ", [preferences tableString], tableString];
			}
			if ([shouldStart length] > 0) {
				[buf appendFormat:@"%@", shouldStart];
			}
			buffer = buf;
		}
	} else if (upper) {  // only upper is defined, just draw the line
		mypos = [upper draw:top at:left max:maxMatches];
		buffer=@"";
	} else if (lower) {  // only lower is defined, just draw the line
		mypos = [lower draw:top at:left max:0];
		buffer=@"";
	} // if
	
	/***************************************************************************
	 text drawing
	 ***************************************************************************/
	if ([self needsToDrawWinner]) {		// either predecessor available
		[NSBezierPath strokeLineFromPoint:NSMakePoint(drawLeft,mypos)
															toPoint:NSMakePoint(drawLeft+width, mypos)];
		[buffer drawAtPoint:NSMakePoint(drawLeft+xstrd, mypos+ystrd) withAttributes:smallAttributes];
		
		[[self resultString] drawAtPoint:NSMakePoint(drawLeft+xstrd, mypos-stringSize + ystrd)
											withAttributes:smallAttributes];
	} else { // no predecessors or loser preceding so just draw player at top
		mypos = [self drawPlayerOnLine:drawLeft+width top:top withAttributes:smallAttributes isWinner:true];
/*		drawLeft = drawLeft+width-firstwid;
		mypos = *top;
		*top = *top - [Match lineDelta];
		// line under player
		[NSBezierPath strokeLineFromPoint:NSMakePoint(drawLeft,mypos)
															toPoint:NSMakePoint(drawLeft+firstwid, mypos)];
		[[NSString stringWithFormat:@"%d", tNumber]
		 drawAtPoint:NSMakePoint(drawLeft-xprev, mypos)
		 withAttributes:smallAttributes];
		if (winner != nil) {
			[winner drawInMatchTableOf:self x:drawLeft y:mypos+ystrd];
		}*/
	}
	
	return mypos;
} // draw

- (float)drawMaster:(float *)top at:(float)left max:(long)maxMatches
             page:(long*)page;
/* in: top: top position for drawing
        at: left position for drawing
       max: the last match, will be drawn to the left
      page: the next winner will come from this page
 prec: lockFocus should be called on the correct view.
 what: recursively draws upper and lower to determine where winner should
       be drawn. The two endpoints are connected with a vertical line and
       in the middle a horizontal line is drawn under the winner.
       Only matches with more than maxMatches preceeding matches will be
       drawn.
chang: top will be the top height for the next match to be drawn
       page: if the match was at the leftmost side, then page is incremented
  ret: the position (y-direction) where the winner was drawn.       
*/
{
   int upPos=0, lowPos=0;
   float wid = (int)[TournamentDelegate.shared.preferences matchWidth]+10;
   float mypos=*top, myleft=left-wid, mywidth = wid;
   NSDictionary *smallAttributes = [Match smallAttributes];

 /***************************************************************************
                               preceeding matches
  ***************************************************************************/
   if ([self pMatches] >= maxMatches)		// enough matches to draw
   {  // upper and lower are defined, draw yourself in the middle
      NSString *textBelowLine = @"";
      upPos = [upper drawMaster:top at:myleft max:maxMatches page:page];
      lowPos = [lower drawMaster:top at:myleft max:maxMatches page:page];
      mypos = (upPos+lowPos)/2;
      [NSBezierPath strokeLineFromPoint:NSMakePoint(myleft, upPos) toPoint:NSMakePoint(myleft, lowPos)];
      
      if ([TournamentDelegate.shared.preferences tourNumbers]) {
         textBelowLine=[NSString stringWithFormat:@"%ld", rNumber];
      } 
      if (winner != nil) {
	 textBelowLine=[self resultString];
      }
      
      [textBelowLine drawAtPoint:NSMakePoint(myleft+xstrd, mypos-stringSize)
		  withAttributes:smallAttributes];
   } else {			// match is on the left
      [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Sieger Blatt %d", @"Matchblatt", null), *page]
          drawAtPoint:NSMakePoint(myleft - 20.0 - wid, *top)
       withAttributes:smallAttributes];
      *top = *top - 2*[Match lineDelta];
      *page = *page + 1;
   } // if
   
   if (winner != nil) {
      [[winner shortName] drawAtPoint:NSMakePoint(myleft+xstrd, mypos+ystrd)
		       withAttributes:smallAttributes];
   } // if
   
   	// line under player
   [NSBezierPath strokeLineFromPoint:NSMakePoint(myleft, mypos)
			     toPoint:NSMakePoint(myleft+mywidth, mypos)];

   return mypos;
} // draw

- (float)drawIntAt:(float)x y:(float)y width:(float)w max:(long)maxMatches
           toptext:(NSString *)toptext;
/* in:    x: coordinates to start with
          y: center coordinate to draw at
          w: width of matches
    toptext: text drawn at top of starting series
 maxMatches: maximal number of matches
      aFlag: up or down drawing of name of winner
returns: y-distance of the central line drawn
 what: draws the match at position x y with width w, writing the name of the
       winner up if aFlag is set or down if not.
*/
{
   float left = x-w, h=maxMatches*INT_MATCH_HEIGHT;
   float upPos = y + h/4, lowPos = y - h/4;

   NSString *upPl=nil;
   NSString *lowPl=nil;
   NSString *below=nil;
   NSString *rNumString=nil;
   NSString *showNumString=nil;
   NSDictionary *smallAttributes = [Match smallAttributes];

   /***************************************************************************
      draw the final winner
      ***************************************************************************/
   if (next == nil) {			// then there will be nothing left
      [NSBezierPath strokeLineFromPoint:NSMakePoint(left, y) toPoint:NSMakePoint(left+w, y)];
      if (winner != nil) {
	 [[winner shortName] drawAtPoint:NSMakePoint(xstrd + left, y+ystrd)
			  withAttributes:smallAttributes];
	 [[[self losing] shortName] drawAtPoint:NSMakePoint(xstrd + left, y - 12.0)
				 withAttributes:smallAttributes];
      } // if
      left = left - w;			// adjust for rest
   } // if

   /***************************************************************************
      draw up and low matches
      ***************************************************************************/
   if (maxMatches > 2) {  // upper and lower valid, draw them also
      [upper drawIntAt:left y:upPos width:w max:maxMatches/2 toptext:toptext];
      [lower drawIntAt:left y:lowPos width:w max:maxMatches/2 toptext:@""];
   } // if

   /***************************************************************************
      draw this match
      ***************************************************************************/
   if (sets[0] != 0) {
      below=[self resultString];
   } else {
		 if (tableString != nil) {
			 below=[NSString stringWithFormat:@"Tisch %@", tableString];
		 } // if
   } // if

   if ([TournamentDelegate.shared.preferences tourNumbers]) {
      rNumString=[NSString stringWithFormat:@"%ld", rNumber];
   } else {
      rNumString=@"";
   } // if

   if ([self upperPlayer] != nil) {
      upPl=[NSString stringWithFormat:@"%@", [[self upperPlayer] shortName] ];
   } else if((maxMatches == 2) && ([upper tNumber] != 0)) {
      upPl=[NSString stringWithFormat:toptext, [upper tNumber]];
   } else {
      upPl=@"";
   } // if
   if ([self lowerPlayer] != nil) {
      lowPl=[NSString stringWithFormat:@"%@", [[self lowerPlayer] shortName] ];
   } else {
      lowPl=@"";
   } // if
   if(next != nil) {
      showNumString=[NSString stringWithFormat:@"%ld", tNumber];
   } else {
      showNumString=@"0";
   } // if

   //   PSmatchright(left, lowPos, w, h/2,
   //		  upperPrefix, upPl, lowerPrefix, lowPl,
   //		  tableString, [self shouldStart], showNumString, rNumString);
   // currently this drawing procedure is not converted as it has only ever been used for Youth Competition Series

   return 0.0;
} //drawIntAt

- (void)considerSmallFinal:(NSMutableArray *)players lowerMatches:(NSMutableArray *)matches;
{
	//NSLog(@"winner is %@, fourth is %@", [[[self seriesSmallFinal] winner] longName], [[players objectAtIndex:3] longName]);
   Match *smallFinal = [[self series] smallFinalTable];
	if ((smallFinal != nil) && ([smallFinal winner] == [players objectAtIndex:3])) {
		[players exchangeObjectAtIndex:2 withObjectAtIndex:3];
		[matches exchangeObjectAtIndex:0 withObjectAtIndex:1];
	} 
}

/** produces a ranking list starting at self up to the player ranked max
    players must be initialized and must contain the winner of the series
    the rankingList is returned in players */
- (void) rankingList:(NSMutableArray *)players upTo:(long)max;
{
	NSMutableArray *seek   = [NSMutableArray array];		// lists of matches
	NSMutableArray *first  = [NSMutableArray array];		// first half is clear
	NSMutableArray *second = [NSMutableArray array];		// second half is new
	int i;
	
	[seek addObject:self];		// start to seek at self
	
	while (([players count] < max) && ([seek count] > 0)) {
		long smax = [seek count];
		
		for(i=0; i<smax; i++) {
			id seekAti = [seek objectAtIndex:i];
			
			if([players indexOfObject:[seekAti upperPlayer]] == NSNotFound) {
				// winner is in lowerMatch
				if ([seekAti upperMatch] != nil) {
               id<Player> upPl = [seekAti upperPlayer];
               if (upPl != nil) {
                  [players addObject:upPl];
                  [second addObject:[seekAti upperMatch]];
               }     // else we are in a really weird situation, like a match modified after it was finished (through the inspector)
				} // if
				if ([seekAti lowerMatch] != nil) {
					[first addObject:[seekAti lowerMatch]];
				}
			} else { // winner must be in upperMatch
				if ([seekAti lowerMatch] != nil) {
               id<Player> lowPl = [seekAti lowerPlayer];
               if (lowPl != nil) {
                  [players addObject:[seekAti lowerPlayer]];
                  [second addObject:[seekAti lowerMatch]];
               }     // else we are in a really weird situation, like a match modified after it was finished (through the inspector)
				} // if
				if ([seekAti upperMatch] != nil) {
					[first addObject:[seekAti upperMatch]];
				} // if
			} // if
		} // for
		if ( ([first count] == 2) && ([second count] == 2)) {
//			NSLog(@"considering small final for %d and %d players", [first count], [players count]);
			[self considerSmallFinal:players lowerMatches:second];
	 	}
		[seek removeAllObjects];			// all sought
		[seek addObjectsFromArray:first];		// first half
		[seek addObjectsFromArray:second];	// second half
		[first removeAllObjects];
		[second removeAllObjects];
	} // while
} // rankingList

- (void)drawRankingList:(float)left at:(float *)top upTo:(long)max withOffset:(long)offset;
/* in: top: top line to begin drawing
       max: this many players should be on the ranking-list.
 what: gathers the players, orders and prints.
*/
{
	NSMutableArray *rankingList = [NSMutableArray array];	// list of players
	long i, drawNum;
	long rankingMax;
	
	[rankingList addObject:[self winner]];
	[self rankingList:rankingList upTo:max];
	rankingMax=[rankingList count];
	
	drawNum = 0;
	for(i=0; i<rankingMax; i++) {
		if ((i == drawNum) && ([rankingList objectAtIndex:i] != nil)) {
			[[NSMutableString stringWithFormat:@"%ld", offset+i+1] drawAtPoint:NSMakePoint(left, *top)
																									withAttributes:[Match smallAttributes]];
			if (0==drawNum) drawNum = 1; else drawNum = 2*drawNum;
		} // if
		[[rankingList objectAtIndex:i] drawInMatchTableOf:self x:left+20 y:*top];
		*top = *top - stringSize;
	} // for
} // drawRankingListAt

- textRankingListIn:text upTo:(long)max;
/* in: text: Controller where to display the text
       max: this many players should be on the ranking-list
            (if there are that many at all).
 what: gathers the players and outputs the text.
*/
{
	[text clearText];
	[text setTitleText:[NSString stringWithFormat:@"Rangliste: %@\n",
											[[self series] fullName]]];
	[self appendRankingToText:text upTo:max withOffset:0];
	return self;
} // textRankingListIn

- (void)appendRankingToText:text upTo:(long)max withOffset:(long) offset;
{
	NSMutableArray *rankingList = [NSMutableArray arrayWithCapacity:max];	// list of players
	[rankingList addObject:[self winner]];
	[self rankingList:rankingList upTo:max];
	long rankingMax=[rankingList count];
	
	long i, drawNum = 0;
	for(i=0; i<rankingMax; i++) {
		id <Player> plAti = (id <Player>)[rankingList objectAtIndex:i];
		
		if (plAti != nil) {
			NSString *rankString=nil;
			if ((i == drawNum) && (plAti != nil)) {
				rankString=[NSString stringWithFormat:@"%ld.", offset+i+1];
				if (0==drawNum) drawNum = 1; else drawNum = 2*drawNum;
			} else {
				rankString=@"";
			} // if
			[text appendText:[plAti rankingListLines:rankString]];
		} // if
	} // for
	[text appendText:@"\n"];
}

- (void)cardsTimeoutAt:(float)left height:(float)height;
{
	NSDictionary *smallAttributes=[Match smallAttributes];
	NSString *yellowCard = NSLocalizedStringFromTable(@"gelbe Karte", @"Matchblatt", @"gelbe Karte auf Matchblatt");
	NSString *redCard = NSLocalizedStringFromTable(@"rote Karte", @"Matchblatt", @"rote Karte auf Matchblatt");
	NSString *timeout = NSLocalizedStringFromTable(@"Timeout", @"Matchblatt", @"Timeout auf Matchblatt");
	[NSBezierPath strokeRect:NSMakeRect(left, height, 10.0, 10.0)];
	[yellowCard drawAtPoint:NSMakePoint(left+12, height) withAttributes:smallAttributes];
	[NSBezierPath strokeRect:NSMakeRect(left+68, height, 10.0, 10.0)];
	[redCard drawAtPoint:NSMakePoint(left+80, height) withAttributes:smallAttributes];
	[NSBezierPath strokeRect:NSMakeRect(left+200, height, 10.0, 10.0)];
	[timeout drawAtPoint:NSMakePoint(left+166, height) withAttributes:smallAttributes];
}

- matchSheet:sender :(const NSRect)rect;
{
	NSDictionary *largeBoldAttributes=[NSDictionary dictionaryWithObject:
																		 [NSFont fontWithName:@"Helvetica-Bold" size:18.0] forKey:NSFontAttributeName];
	NSDictionary *largeAttributes=[NSDictionary dictionaryWithObject:
																 [NSFont fontWithName:@"Times-Roman" size:16.0] forKey:NSFontAttributeName];
	NSDictionary *attributes=[Match textAttributes];
	NSBezierPath *aPath=[NSBezierPath bezierPath];
   Tournament *tournament = TournamentDelegate.shared.tournament;
	NSImage *commercialImage = [tournament commercialImage];
	const float rectleft = 20.0;
	const float srleft = 120.0;
	const float topbase = 120.0;
	const float left = 85.0;
	const float recty = 140.0;
	long i, numberOfSets;
	
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:rect];
   [commercialImage drawAtPoint:NSMakePoint(390-[commercialImage size].width, 200) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	[[NSColor blackColor] set];
	[[tournament title] drawAtPoint:NSMakePoint(20.0, 260.0)
																								 withAttributes:largeBoldAttributes];
	[[tournament subtitle] drawAtPoint:NSMakePoint(20.0, 240.0)
																								withAttributes:largeBoldAttributes];
	NSString *tisch = NSLocalizedStringFromTable(@"Tisch:", @"Matchblatt", @"Tisch auf Matchblatt");
	[tisch drawAtPoint:NSMakePoint(20.0, 220.0) withAttributes:largeAttributes];
	[tableString drawAtPoint:NSMakePoint(left, 220) withAttributes:largeAttributes];
	if ([[self shouldStart] length] > 0) {
		NSString *zeit = NSLocalizedStringFromTable(@"Zeit: %@", @"Matchblatt", @"Zeit auf Matchblatt");
		[[NSString stringWithFormat:zeit, [self shouldStart]]
		 drawAtPoint:NSMakePoint(120, 220) withAttributes:largeAttributes];
	} // if
	NSString *serie = NSLocalizedStringFromTable(@"Serie: ", @"Matchblatt", @"Serie auf Matchblatt");
	[serie drawAtPoint:NSMakePoint(20.0, 200.0) withAttributes:largeAttributes];
   [[series nameFor:self] drawAtPoint:NSMakePoint(left, 200.0) withAttributes:largeAttributes];
	NSString *runde = NSLocalizedStringFromTable(@"Runde: ", @"Matchblatt", @"Runde auf Matchblatt");
	[runde drawAtPoint:NSMakePoint(20.0, 180.0) withAttributes:largeAttributes];
	[[self roundString] drawAtPoint:NSMakePoint(left, 180.0) withAttributes:largeAttributes];
	NSString *spielNr = NSLocalizedStringFromTable(@"Spiel-Nr.:", @"Matchblatt", @"Spielnummer auf Matchblatt");
	[spielNr drawAtPoint:NSMakePoint(20.0, 160.0) withAttributes:largeAttributes];
	if (rNumber != 0) {
		[[NSString stringWithFormat:@"%ld", rNumber]
		 drawAtPoint:NSMakePoint(left, 160.0) withAttributes:largeAttributes];
	}
	
	[NSBezierPath strokeRect:NSMakeRect(rectleft, recty-100.0, 400.0, 100.0)];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(rectleft, recty - 50.0)
														toPoint: NSMakePoint(rectleft+400, recty - 50.0)];
	numberOfSets = [self numberOfSets];
	NSString *gewinnsaetzeFormat = NSLocalizedStringFromTable(@"Gewinnsaetze", @"Matchblatt", 
																														@"Format für Gewinnsätze auf Matchblatt");
	[[NSString stringWithFormat:gewinnsaetzeFormat, [self roundString], numberOfSets/2 + 1]
	 drawAtPoint:NSMakePoint(rectleft+210, recty + 4) withAttributes:attributes];
	
	for(i=0; i<=numberOfSets; i++) {
		float linex = rectleft + 210 + (i*140/numberOfSets);
		[NSBezierPath strokeLineFromPoint:NSMakePoint(linex, recty)
															toPoint:NSMakePoint(linex, recty - 100.0)];
	}
	NSString *sieger = NSLocalizedStringFromTable(@"Sieger", @"Matchblatt", @"Sieger auf Matchblatt");
	[sieger drawAtPoint:NSMakePoint(rectleft+354, recty -14.0) withAttributes:attributes];
	NSString *aufruf = NSLocalizedStringFromTable(@"Aufruf", @"Matchblatt", @"Aufruf auf Matchblatt");
	[aufruf drawAtPoint:NSMakePoint(320.0, 20.0) withAttributes:attributes];
	[aPath setLineWidth:1.5];
	[aPath setLineCapStyle:NSRoundLineCapStyle];
	[aPath moveToPoint:NSMakePoint(363.0, 22.0)];
	[aPath lineToPoint:NSMakePoint(373.0, 32.0)];
	[aPath moveToPoint:NSMakePoint(363.0, 32.0)];
	[aPath lineToPoint:NSMakePoint(373.0, 22.0)];
	[aPath stroke];
	[[self upperPlayer] showAt:rectleft+10.0 yPos: topbase clPos:srleft];
	[[self lowerPlayer] showAt:rectleft+10.0 yPos: topbase - 50.0 clPos:srleft];
	
	NSString *schiedsrichter = NSLocalizedStringFromTable(@"Schiedsrichter", @"Matchblatt", @"Schiedsrichter auf Matchblatt");
	[schiedsrichter drawAtPoint:NSMakePoint(20.0, 20.0) withAttributes:largeAttributes];
	[[umpire longName] drawAtPoint:NSMakePoint(srleft, 20.0) withAttributes:[Match textAttributes]];
	[[umpire club] drawAtPoint:NSMakePoint(230, 20.0) withAttributes:[Match textAttributes]];
	if ([shouldStart length] > 0) {
		[self cardsTimeoutAt:rectleft height:recty-50];
		[self cardsTimeoutAt:rectleft height:recty-100];
	}
	
	return self;
} // matchSheet

/*****************************************************************************
 *                         Get-methods                                       *
 *****************************************************************************/

- (BOOL)ready;
   // returns YES if both players are available currently and the series started
{
   return [[self upperPlayer] ready] && [[self lowerPlayer] ready]
          && [series started];
} // ready

- (NSString *)seriesName;
{
   return [series nameFor:self];
}

- (BOOL)wo;
// return YES if match was played wo
{
   return wo;
} // wo

- (Match *)lowerMatch;
{
   return lower;
} // lower

- (NSString *)lowerPrefix;
{
   return lowerPrefix;
} // lowerPrefix

- (BOOL)lowerIsWinner;
{
   return lowerIsWinner;
} // lowerPrefix

- (Match *)upperMatch;
{
   return upper;
} // upper

- (NSString *)upperPrefix;
{
   return upperPrefix;
} // upperPrefix

- (BOOL)upperIsWinner;
{
   return upperIsWinner;
}

- (id <Player>) lowerPlayer;
// returns the player at lower position,
// considers winner and looser of previous match
{
   if (lower != nil) {
      if (lowerIsWinner) {
         return [lower winning];
      } else {
         return [lower losing];
      } // if
   } else {
      return nil;
   } // if
} // lowerPlayer

- (id <Player>) upperPlayer;
// returns the player at upper position,
// considers winner and loser of previous match
{
   if (upper != nil) {
      if (upperIsWinner) {
         return [upper winning];
      } else {
         return [upper losing];
      } // if
   } else {
      return nil;
   } // if
} // upperPlayer

- (id <Player>)opponentOf:(id <Player>)aPlayer;
// returns the opponent of aPlayer if any
{
   if ([self upperPlayer] == aPlayer) {
      return [self lowerPlayer];
   } else {
      return [self upperPlayer];
   } // if
} // opponentOf

- (Match *)nextMatch;
{
   return next;
} // nextMatch

- (Match *)loserMatch;
{
   return loserNext;
} // loserMatch

- (id <Player>) winner;
{
    return winner;
} // winner

- (SinglePlayer *)umpire;
{
   return umpire;
} // umpire

- (long)pMatches;
{
	if((upper == nil) && (lower == nil)) {
		return 0;
	} else if (pMatches < 128) {
		long upperPMatches = 0;
		if ([self upperIsWinner]) {
			upperPMatches= [upper pMatches];
		}
		long lowerPMatches = 0;
		if ([self lowerIsWinner]) {
			lowerPMatches= [lower pMatches];
		}
		pMatches = upperPMatches + lowerPMatches + 1;
	} // if
	
	return pMatches;
} // pMatches

- (long)tNumber;
{
   return tNumber;
} // tNumber

- (long)rNumber;
{
   return rNumber;
} // rNumber

- (long)round;
{
   return round;
} // round

- (long)sternmostRoundUnplayed;
{
	if ([self finished]) {
		return 0;
	} else if ([self isCurrentlyPlayed]) {
		return round/2;
	} else if ([upper finished] && [lower finished]) {
		return round;
	} else {
		long upperUnplayed = [upper sternmostRoundUnplayed];
		long lowerUnplayed = [lower sternmostRoundUnplayed];
		
		if (upperUnplayed > lowerUnplayed) {
			return upperUnplayed;
		} else {
			return lowerUnplayed;
		}
	}
}

- (id<drawableSeries>)series;
{
   return series;
} // series

- (NSString *)tableString;
{
   return tableString;
}

- (NSString *)time;
{
   return startTime;
} // time

- (void)fixDuration;
{
   long startHour = -1, startMinute = -1;
   if (([self time] != nil) && ([[self time] length] > 3)) {
      startHour = [[[self time] substringToIndex:2] integerValue];
      startMinute = [[[self time] substringFromIndex:3] integerValue];
      NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
      NSDateComponents *hh_mm = [gregorian components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
      
      duration = 60*([hh_mm hour] - startHour) + [hh_mm minute] - startMinute;
   } else {
      duration = 0;
   }
}

- (long)duration;
{
   return duration;
} // time

- (NSString *)clickScheduled;
{
	return [NSString stringWithFormat:@"%@ %@", TournamentDelegate.shared.clickTtDateStringForExport, [self time]];
}

- (NSString *)shouldStart;
{
   if (winner == nil) {
      return shouldStart;
   } else {
      return @"";
   } // if
} // shouldStart

- (BOOL)inBrowser;
{
   return inBrowser;
} // inBrowser

- (float) tourPriority;
// compute tourPriority and return its value
{
   tourPrioCache = [[self lowerPlayer] tourPriority] 
                    + [[self upperPlayer] tourPriority] + [self minRoundPriority];
   return tourPrioCache;
} // tourPriority

- (float) tp;
// return last computed tourPriority (used for sorting)
{
   return tourPrioCache;
} // tp

- (float) simpleTourPriority:(float)playerDayRanking;
{
   if (series != nil) {
      return [series basePriority] + [self numRoundPriority] + [self roundPriority]
			+ [series tourPriorityFor:playerDayRanking];
   } else {
      return [self numRoundPriority] + [self roundPriority];
   } // if
}

- (BOOL)contains:(id <Player>)aPlayer;
// YES if aPlayer is in lower or upper.
{
   return [[self upperPlayer] contains:aPlayer]
           || [[self lowerPlayer] contains:aPlayer];
} // contains

- (long)set:(long)setIndex;
// return the result of the set number aSet
{
   return sets[setIndex];
} // set

- (long)numSet:(long)setIndex;
{
   return sets[setIndex];
} // set

- (long)upperPlayerPointsInSet:(long)setIndex;
{
   long result = sets[setIndex];

   if (winner == [self lowerPlayer]) {
      result = -result;
   }

   if (result > 0) { 		// upper won this set
      if (result < 10) {
	 return 11;
      } else {
	 return result+1;
      }
   } else if (result < 0) {	// upper lost
      return -(result + 1);
   } else {			// not played, zero for both
      return 0;
   }
}

- (long)lowerPlayerPointsInSet:(long)setIndex;
{
   long result = sets[setIndex];

   if (winner == [self lowerPlayer]) {
      result = -result;
   }

   if (result < 0) { 		// lower won this set
      if (result > -10) {
	 return 11;
      } else {
	 return -result+1;
      }
   } else if (result > 0) {	// lower lost
      return result - 1;
   } else {			// not played, zero for both
      return 0;
   }
}

+ (NSString *)stringForSetResult:(long)result;
{
   if (result == 1) {
      return @"+0";
   } else if (result == -1) {
      return @"-0";
   } else if (result > 0) {
      return [NSString stringWithFormat:@"%ld", result-1];
   } else if (result < 0) {
      return [NSString stringWithFormat:@"%ld", result+1];
   } else {
      return @"";
   }
}

+ (long)numberForSetString:(NSString *)result;
{
   int value = [result intValue];

   if (value > 0) {
      return value+1;
   } else if (value < 0) {
      return value-1;
   } else {
      if ([result length] > 0) {
	 if ([result characterAtIndex:0] == '+') {
	    return 1;
	 } else if ([result characterAtIndex:0] == '-') {
	    return -1;
	 }
      }

      return invalid;
   }
}
      
- (NSString *)upperLowerShortStringSet:(long)setIndex;
{
   if ([self upperPlayer] == winner) {
      return [Match stringForSetResult:sets[setIndex]];
   } else {
      return [Match stringForSetResult:-sets[setIndex]];
   }   
}

- (NSString *)winnerLoserShortStringSet:(long)setIndex;
{
   return [Match stringForSetResult:sets[setIndex]];
} // set


- (id<Player>)winning;
{
   return winner;
} // winning

- (id<Player>)losing;
{
   if (winner == nil) {
      return nil;
   } // if
   
   if (winner == [self upperPlayer]) {
      return [self lowerPlayer];
   } else {
      return [self upperPlayer];
   } // if
} // losing

- (BOOL)finished;
// return YES if there already is a winner (which is not a GroupPlayer)
{
   return (winner != nil) && !([winner isKindOfClass:[GroupPlayer class]]);
} // finished

- (BOOL)isBestOfSeven;
// return YES if the match ist to be played best of 5 sets
{
   return [self numberOfSets] == 7;
} // isBestOfSeven

- (BOOL)isCurrentlyPlayed;
// returns YES if self is currently playing, NO otherwise
{
   return [[TournamentDelegate.shared.matchController playingMatchesController] containsPlayable:self];
} // isCurrentlyPlayed

/*****************************************************************************
 *                         Set-methods                                       *
 *****************************************************************************/

- (void)setReady:(BOOL)aFlag;
{
   [[self upperPlayer] setReady:aFlag];
   [[self lowerPlayer] setReady:aFlag];
   if (umpire != nil) {
      [umpire setReady:aFlag];
   } // if
} // setReady

- (void)setLower:(Match *)low;
{
   lower = low;
}

- (void)setLowerPrefix:(const char *)aString;
{
   lowerPrefix = [NSString stringWithCString:aString encoding:NSUTF8StringEncoding];
} // setLowerPrefix;

- (void)setLowerIsWinner:(BOOL)aFlag;
{
   lowerIsWinner = aFlag;
}

- (void)setUpper:(Match *)up;
{
   upper = up;
}

- (void)setUpperPrefix:(const char *)aString;
{
   upperPrefix = [NSString stringWithCString:aString encoding:NSUTF8StringEncoding];
}

- (void)setUpperIsWinner:(BOOL)aFlag;
{
    upperIsWinner = aFlag;
}

- (void)setNext:(Match *)nx;
{
   next = nx;
}

- (void)setLoserMatch:(Match *)aMatch;
{
   loserNext = aMatch;
}

- (void)setRound:(long)aInt;
{
   round = aInt;
}

- (void)setTableString:(NSString *)aString;
{
   tableString = aString;
}

- (void)sWinner:(id <Player>)win;
{
	if (winner != win) {
		winner = win;
	}
}

- (void)invalidateFollowingResults:(id<Player>)previousWinner;
{  int i;

   if ([self finished]) {
      [next invalidateFollowingResults:winner];
   } else if ([self isCurrentlyPlayed]) {
      [next withdraw];
   }
   [winner removeMatch:next];
   [self sWinner:nil];
   [[self opponentOf:previousWinner] addMatch:self];
   [self setWO:NO];
   for (i=0; i<7; i++) {
      sets[i] = invalid;
   }
}

- (void)replaceWinnerInRunningMatchWith:(id <Player>)aPlayer;
{
   NSAlert *alert = [NSAlert new];
   alert.messageText = NSLocalizedStringFromTable(@"Ersetzen", @"Tournament", nil);
   alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Soll das darauffolgende, laufende Spiel\n%@ : %@\nzurückgezogen werden?", @"Tournament", nil), [[next upperPlayer] longName], [[next lowerPlayer] longName]];
   [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Ja", @"Tournament", nil)];
   [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Nein, direkt ersetzen", @"Tournament", nil)];
   if ( (aPlayer == nil) || ([alert synchronousModalSheetForWindow:[NSApp mainWindow]] == NSAlertFirstButtonReturn) ) {
      [next withdraw];
      [winner removeMatch:next];
      [[self losing] removeMatch:loserNext];
      [aPlayer removeFromUmpireList];
      [self sWinner:aPlayer];
      if (winner != nil) {
			[self endMatchProcessing];
      }
   } else {
      bool winnerReady = [winner ready];
      bool loserReady  = [[self losing] ready];
      [self sWinner:aPlayer];
      [self endMatchProcessing];
      [winner setReady:winnerReady];
      [[self losing] setReady:loserReady];
   }
   [[self losing] putAsUmpire];
}

- (void)updateWinnerTo:(id <Player>)aPlayer;
{
	if (aPlayer == winner) {
		return;
	}
	
	if ((upper == nil) && (lower == nil)) {
		[winner removeMatch:next];
		[self sWinner:aPlayer];
		[winner addMatch:next];
	} else if ( ([self upperPlayer] == aPlayer) || ([self lowerPlayer] == aPlayer)
						 || (aPlayer == nil) ) {
		if ([self finished]) {
			if ([next finished]) {
				[next invalidateFollowingResults:winner];
				[aPlayer removeFromUmpireList];
				[self sWinner:aPlayer];
				[self endMatchProcessing];
			} else if ([next isCurrentlyPlayed]) {
				[self replaceWinnerInRunningMatchWith:aPlayer];
			} else {
				[winner removeMatch:next];
				[aPlayer removeFromUmpireList];
				[self sWinner:aPlayer];
				[winner addMatch:next];
				if (![self wo]) {
					[[self losing] putAsUmpire];
				}
            [[TournamentDelegate.shared.matchController matchBrowser] updateMatrix];
            [[TournamentDelegate.shared.matchController matchBrowser] updateMatrix];
			}
		} else {
			[self setWinner:aPlayer];
		}
	}
}

- (void)handleWoOf:(id<Player>)woPlayer potentialWinner:(id<Player>)winPlayer;
{
   if (![TournamentDelegate.shared restoreInProgress]) {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Achtung!", @"Tournament", nil);
      alert.informativeText = [NSString stringWithFormat: NSLocalizedStringFromTable(@"%@ hat seinen letzten\nMatch WO verloren. Jetzt ist der",
                                                                                     @"Tournament", nil), [woPlayer longName]];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Match WO", @"Tournament", nil)];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Spieler wieder da", @"Tournament", nil)];
      if ([alert synchronousModalSheetForWindow:[NSApp mainWindow]] == NSAlertFirstButtonReturn) {
         [self setWO:YES];
         [self setWinner:winPlayer];
      } else {
         [woPlayer setWO:NO];
      }
   }
}

- (void)matchNotPlayed;
{
	[self setWO:YES];
	[self setWinner:[self upperPlayer]];	// sauf de mieux ...
	[series matchNotPlayed:self];					// hook for special processing
}

- (void)checkForWO;
{
	id<Player> upperPlayer = [self upperPlayer];
	id<Player> lowerPlayer = [self lowerPlayer];
	
	if ((upperPlayer == nil) || (lowerPlayer == nil)
			|| (![upperPlayer canContinue]) || (![lowerPlayer canContinue])) {
		// at least one of the players is not (yet) there
		return;
	}
	
	if ((![upperPlayer present]) && (![lowerPlayer present])) {
		[self matchNotPlayed];
	} else {
		if (![upperPlayer present]) {
			[self setWO:YES];
			[self setWinner:lowerPlayer];
			return;
		}
		
		if (![lowerPlayer present]) {
			[self setWO:YES];
			[self setWinner:upperPlayer];
			return;
		}
	}
	
	if ([upperPlayer wo]) {
		[self handleWoOf:upperPlayer potentialWinner:lowerPlayer];
	}
	
	if ([lowerPlayer wo]) {
		[self handleWoOf:lowerPlayer potentialWinner:upperPlayer];
	}
}

- (void)endMatchProcessing;
{
	[[TournamentDelegate.shared.matchController playingTableController] freeTablesOf:self];
	
	if (next != nil) {
		[winner addMatch:next];
		[next checkForWO];
	}
	if (loserNext != nil) {
		[[self losing] addMatch:loserNext];
		[loserNext checkForWO];
	}
	[[self winning] adjustDayRanking:[[self losing] dayRanking]];
	[[self losing] adjustDayRanking:-[[self winning] dayRanking]];
	
	[series checkMinRound:[next round]];		// at least one player in next.
	[series checkMaxRanking:winner];
	
	if ([[self series] finished]) {	// The series is (already?) finished, there might be some processing left to be done
		[[self series] endSeriesProcessing:self];
	}
	
	if ([self inBrowser]) {
		[[TournamentDelegate.shared.matchController matchBrowser] removeMatch:self];
	}
   
   for(id<VictoryNotification>notifiee in notifiees) {
      [notifiee victoryOf:winner in:self];
   }
}

- (void)setWinner:(id <Player>)aPlayer;
{
	if (aPlayer == nil) {
		return;
	}
	
	if ((upper == nil) && (lower == nil)) {
		[self sWinner:aPlayer];
		if (next != nil) {
			[winner addMatch:next];
		} else if ([winner isKindOfClass:[GroupPlayer class]]) {		// cover the odd case where a group player directly wins the series
			[winner addMatch:self];
		}
		[next checkForWO];
	} else if ( ([self upperPlayer] == aPlayer) || ([self lowerPlayer] == aPlayer) ) {
      if ([self winner] != nil) {
         [[self winner] removeMatch:next];
         [TournamentDelegate.shared.matchController.umpireController removeUmpire:[self losing]];
      }
		[[self upperPlayer] removeMatch:self];
		[[self lowerPlayer] removeMatch:self];
		[self sWinner:aPlayer];
		[self endMatchProcessing];
	} else {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Achtung", @"Tournament", nil);
      alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ nicht in diesem Match!", @"Tournament", nil), [aPlayer longName]];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", nil)];
      [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:nil];
      // this is just info anyways, so we do not care that the method returns immediately and without consequence
	}
}

- (void)setWO:(BOOL)aFlag;
{
	wo = aFlag;
	if (wo) {
		[PlayingMatchesController fixCurrentTimeFor:self];
	}
}

- (void)setSet:(long)setIndex directlyTo:(long)result;
// set the result of set aSet
{
   if ( (setIndex >= 0) && (setIndex < 7) ) {
      sets[setIndex] = result;
   } // if
}

- (void)setWinnerLoserSet:(long)setIndex to:(NSString *)result;
{
   sets[setIndex] = [Match numberForSetString:result];
}

- (void)setUpperLowerSet:(long)setIndex to:(NSString *)result;
{
   if ([self upperPlayer] == winner) {
      sets[setIndex] = [Match numberForSetString:result];
   } else {
      sets[setIndex] = -[Match numberForSetString:result];
   }
}

- (NSString *)stringSet:(long)aSet;
// return the result of set aSet as string
{
   long val = sets[aSet];

   if ((val != invalid)) {
      return [NSString stringWithFormat:@"%ld:%ld", [self upperPlayerPointsInSet:aSet],
						  [self lowerPlayerPointsInSet:aSet]];
   } // if
   return @"";
}

- (void)setUmpire:(SinglePlayer *)aUmpire;
{
   if (umpire != nil) {			// free old umpire if there is one
      [umpire setReady:YES];
   } // if
   umpire = aUmpire;
   if (aUmpire != nil) {
      [umpire setUmpiresMatch:self];
   }
}

- (void)setPMatches:(long)pm;
{
   pMatches = pm;
}

- (void)setTNumber:(long)tn;
{
   tNumber = tn;
}

- (void)setRNumber:(long)rn;
{
   rNumber = rn;
}

- (void)setSeries:(id <NSObject, drawableSeries>)aSeries;
{
   series = aSeries;
}

- (void)setTime:(NSString *)aString;
{
   startTime = aString;
}

- (void)setShouldStart:(const char *)aString;
{
	shouldStart = [NSString stringWithCString:aString encoding:NSUTF8StringEncoding];
}

- (void)setPlannedStart:(NSString *)timeString;
{
	shouldStart = timeString;
}

- (void)setInBrowser:(BOOL)aFlag;
{
   inBrowser = aFlag;
}

- awake;
{
   if ((inBrowser) && (winner == nil))		// started and not finished
   {
      inBrowser = NO;
      [self setReady:YES];
      [[TournamentDelegate.shared.matchController matchBrowser] addMatch:self];
   } // if
   
   return self;
} // awake

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeValueOfObjCType:@encode(BOOL) at:&inBrowser];
	[encoder encodeObject:lower];
	[encoder encodeValueOfObjCType:@encode(BOOL) at:&lowerIsWinner];
	[encoder encodeObject:lowerPrefix];
	[encoder encodeObject:upper];
	[encoder encodeValueOfObjCType:@encode(BOOL) at:&upperIsWinner];
	[encoder encodeObject:upperPrefix];
	[encoder encodeObject:next];
	[encoder encodeObject:loserNext];
	[encoder encodeObject:umpire];
	[encoder encodeObject:winner];
	[encoder encodeObject:tableString];
	[encoder encodeValueOfObjCType:@encode(int) at:&pMatches];
	[encoder encodeValueOfObjCType:@encode(int) at:&tNumber];
	[encoder encodeValueOfObjCType:@encode(int) at:&rNumber];
	[encoder encodeValueOfObjCType:@encode(int) at:&round];
	[encoder encodeValueOfObjCType:@encode(float) at:&tourPrioCache];
	[encoder encodeObject:series];
	[encoder encodeObject:startTime];
	[encoder encodeObject:shouldStart];
	[encoder encodeArrayOfObjCType:@encode(long) count:7 at:sets];
	[encoder encodeValueOfObjCType:@encode(BOOL) at:&wo];
   [encoder encodeObject:notifiees];
}

- (id)initWithCoder:(NSCoder *)decoder
{
   self=[super init];
   [decoder decodeValueOfObjCType:@encode(BOOL) at:&inBrowser];
   lower=[decoder decodeObject];
   [decoder decodeValueOfObjCType:@encode(BOOL) at:&lowerIsWinner];
   lowerPrefix=[decoder decodeObject];
   upper=[decoder decodeObject];
   [decoder decodeValueOfObjCType:@encode(BOOL) at:&upperIsWinner];
   upperPrefix=[decoder decodeObject];
   next=[decoder decodeObject];
   loserNext=[decoder decodeObject];
   umpire=[decoder decodeObject];
   winner=[decoder decodeObject];
   if ([decoder versionForClassName:@"Match"] > 2) {
      tableString=[decoder decodeObject];
   } else {
      int table;

      [decoder decodeValueOfObjCType:@encode(int) at:&table];
      tableString=[[NSString alloc] initWithFormat:@"%d", table];
   }
   [decoder decodeValueOfObjCType:@encode(int) at:&pMatches];
   [decoder decodeValueOfObjCType:@encode(int) at:&tNumber];
   [decoder decodeValueOfObjCType:@encode(int) at:&rNumber];
   [decoder decodeValueOfObjCType:@encode(int) at:&round];
   [decoder decodeValueOfObjCType:@encode(float) at:&tourPrioCache];
   series=[decoder decodeObject];
   startTime=[decoder decodeObject];
   shouldStart=[decoder decodeObject];
   // TODO TODO TODO: revert this once re-saved
   [decoder decodeArrayOfObjCType:@encode(long) count:7 at:sets];
/*   int intSets[7];
   [decoder decodeArrayOfObjCType:@encode(int) count:7 at:intSets];

   sets[0] = intSets[0];
   sets[1] = intSets[2];
   sets[2] = intSets[4];
   sets[3] = intSets[6];*/
   [decoder decodeValueOfObjCType:@encode(BOOL) at:&wo];
   if ([decoder versionForClassName:@"Match"] > 3) {
      notifiees=[decoder decodeObject];
   }

   return self;
}

- (id <InspectorControllerProtocol>) inspectorController;
{
   if (_matchInspector == nil) {
      _matchInspector=[[MatchInspector alloc] init];
   }
   [_matchInspector setMatch:self];

   return _matchInspector;
}

- (NSString *) insertSQL;
{
   return [NSString stringWithFormat:@"INSERT INTO PlayedMatch (Number, Winner, Looser, Result, StartTime, wo, Duration, TournamentID) VALUES (%ld, %ld, %ld, '%@', '%@', '%d', %ld, '%@')",  rNumber, [[self winning] licence], [[self losing] licence], [self backupString], [self time], [self wo], [self duration], TournamentDelegate.shared.preferences.tournamentId];
}

- (NSString *) updateSQL;
{
   // Note that we purposefully do not update the duration, it will only be inserted
   return [NSString stringWithFormat:@"UPDATE PlayedMatch SET Winner=%ld, Looser=%ld, Result='%@', StartTime='%@', wo='%d' WHERE Number=%ld AND TournamentID='%@'",  [[self winning] licence], [[self losing] licence], [self backupString], [self time], [self wo], rNumber, TournamentDelegate.shared.preferences.tournamentId];
}

- (void) storeInDB;
{
   PGSQLConnection *database=[TournamentDelegate.shared database];
   
   NSString *selectMatch = [NSString stringWithFormat:@"SELECT COUNT(*) FROM PlayedMatch WHERE Number=%ld AND TournamentID ='%@'", rNumber, TournamentDelegate.shared.preferences.tournamentId];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:selectMatch];
   NSString *command = nil;

   if (rs != nil) {
      if (![rs isEOF]) {
         long count = [[rs fieldByIndex:0] asLong];
         if (count == 0) {
            [self fixDuration];
            command = [self insertSQL];
         } else {
            if ((count == 1) && ([[self winning] licence] != 0)) {
               command = [self updateSQL];
            } else {
               command = [NSString stringWithFormat:@"DELETE FROM PlayedMatch WHERE Number=%ld AND TournamentID ='%@'", rNumber,
                          TournamentDelegate.shared.preferences.tournamentId];
            }
         }
      }
      [rs close];
   } else {
      [TournamentDelegate.shared reportDbError:[database errorDescription]];
   }
   if (![database execCommand:command]) {
      [TournamentDelegate.shared reportDbError:[database errorDescription]];
   }
}

- result:(BOOL)show;
// read the result of the player from the user
{
   [TournamentDelegate.shared.matchResultController show:self];

   return self;
} // result

- drawAsOpen:(const NSRect)cellFrame inView:aView withAttributes:(NSDictionary *)attributes;
/* in: cellFrame: the frame to fit in
       aView:     the View in which drawing takes place (assume: lockFocus'ed)
 what: draws the information of match into cellFrame
return:self
*/
{
   const float y = NSMinY(cellFrame)+1;
   const float ser = NSMinX(cellFrame) + 1;
   const float nam1 = NSMinX(cellFrame) + 53;
   const float prioRight = NSMinX(cellFrame) + NSWidth(cellFrame) - 2;
   const float roundRight = prioRight - 40;
   const float dep2 = roundRight - 35;
   const float nam2 = (nam1 + dep2)/2;
   const float dep1 = nam2 - 12;

   [[series seriesName] drawAtPoint:NSMakePoint(ser, y)  withAttributes:attributes];
   if ([self upperPlayer] != nil) {
      [[[self upperPlayer] shortName] drawAtPoint:NSMakePoint(nam1, y)
				   withAttributes:attributes];
      [[NSString stringWithFormat:@"%ld", [[self upperPlayer] numberOfDependentMatches]]
            drawAtPoint:NSMakePoint(dep1, y) withAttributes:attributes];
   } else {
      [@"offen" drawAtPoint:NSMakePoint(nam1, y) withAttributes:attributes];
   }

   if ([self lowerPlayer] != nil) {
      [[[self lowerPlayer] shortName] drawAtPoint:NSMakePoint(nam2,y)
				   withAttributes:attributes];
      [[NSString stringWithFormat:@"%ld", [[self lowerPlayer] numberOfDependentMatches]]
            drawAtPoint:NSMakePoint(dep2, y) withAttributes:attributes];
   } else {
      [@"offen" drawAtPoint:NSMakePoint(nam2,y) withAttributes:attributes];
   }
   
   NSString *roundStr = [NSString stringWithFormat:@"%ld", [self round]];
   NSMutableDictionary *blueAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
   [blueAttributes setObject:NSColor.blueColor forKey:NSForegroundColorAttributeName];
   NSAttributedString *roundAttr = [[NSAttributedString alloc] initWithString:roundStr attributes:blueAttributes];
   float roundLeft = roundRight - [roundAttr size].width;
   [roundAttr drawAtPoint:NSMakePoint(roundLeft, y)];

	NSString *prioStr;
	if ((shouldStart == nil) || ([shouldStart length] == 0)) {
		prioStr = [NSString stringWithFormat:@"%.2f", tourPrioCache];
	} else {
		prioStr = shouldStart;
	}
   NSAttributedString *prioAttr = [[NSAttributedString alloc] initWithString:prioStr attributes:attributes];
   float prioLeft = prioRight - [prioAttr size].width;
   
   [prioAttr drawAtPoint:NSMakePoint(prioLeft, y)];

   return self;
} // drawAsOpen

- drawAsPlaying:(const NSRect)cellFrame inView:aView;
/* in: cellFrame: the frame to fit in
       aView:     the View in which drawing takes place (assume: lockFocus'ed)
 what: draws the information of match into cellFrame
return:self
*/
{
   const float base = NSMinY(cellFrame) + 1.0;
   float seriesPosition = NSMinX(cellFrame) + 37.0;
   const float nam1 = NSMinX(cellFrame) + 40.0;
   const float nam2 = nam1 + (NSWidth(cellFrame) - 110.0)/2.0;
   float runNumPosition = NSMaxX(cellFrame)- 1.0;
   float timePosition = runNumPosition - 25.0;
   float tablePosition = timePosition - 35.0;
   NSDictionary *textAttributes = [Match textAttributes];
   NSString *runNumString = [NSString stringWithFormat:@"%ld", rNumber];

   seriesPosition = seriesPosition - [[series seriesName] sizeWithAttributes:textAttributes].width;
   runNumPosition = runNumPosition - [runNumString sizeWithAttributes:textAttributes].width;
   timePosition = timePosition - [startTime sizeWithAttributes:textAttributes].width;
   tablePosition = tablePosition  - [tableString sizeWithAttributes:textAttributes].width;
   
   [[NSColor blackColor] set];
   [[series seriesName] drawAtPoint:NSMakePoint(seriesPosition, base)
		     withAttributes:textAttributes];
   [[[self upperPlayer] shortName] drawAtPoint:NSMakePoint(nam1, base)
				withAttributes:textAttributes];
   [[[self lowerPlayer] shortName] drawAtPoint:NSMakePoint(nam2, base)
				withAttributes:textAttributes];
   [runNumString drawAtPoint:NSMakePoint(runNumPosition, base) withAttributes:textAttributes];
   [startTime drawAtPoint:NSMakePoint(timePosition, base) withAttributes:textAttributes];
   [tableString drawAtPoint:NSMakePoint(tablePosition, base) withAttributes:textAttributes];
   
   return self;
}

+ (NSMutableDictionary*)textAttributes {
	return [NSMutableDictionary dictionaryWithObject:
					[NSFont fontWithName:@"Helvetica" size:12.0] forKey:NSFontAttributeName];
}

+ (NSDictionary*)smallAttributes {
   return [NSDictionary dictionaryWithObject:
	    [NSFont fontWithName:@"Helvetica" size:9.0] forKey:NSFontAttributeName];
}

- (void)print:(id)sender;
{
   [TournamentDelegate.shared.matchViewController setPlayable:self];
}

- (void)putUmpire;
{
   if ([TournamentDelegate.shared.preferences umpires]) {
      if ([self wo]) {
         [[self umpire] putAsUmpire];			// "recycle" umpire on wo
      } else {
         [[self losing] putAsUmpire];			// looser is umpire if regular
      }
   }
}

- (void)removeUmpire;
{
   [[self losing] removeFromUmpireList];
}

- (bool)playersShouldUmpire;
{
   return [[self upperPlayer] shouldUmpire] || [[self lowerPlayer] shouldUmpire];
}

- (void)removeAllPlayersFromUmpireList;
{
   UmpireController *umpireController = [TournamentDelegate.shared.matchController umpireController];
   SinglePlayer     *currentUmpire    = [umpireController selectedUmpire];
   
   [[self upperPlayer] removeFromUmpireList];
   [[self lowerPlayer] removeFromUmpireList];

   [umpireController selectSpecificUmpire:currentUmpire];
}

- (void)takeUmpire;
{
   [self setUmpire:[[TournamentDelegate.shared.matchController umpireController] getUmpire]];
}

- (NSString *)roundString;
{
   return [[self series] roundStringFor:self];
}

- (long)numberOfSets;
{
	return [series numberOfSetsFor:self];
}

- (int)setsWon:(int)positiveNegative;
{
	int i, setsWon = 0;
	
	for (i=0; i<7; i++) {
		if (positiveNegative * sets[i] > 0) {
			setsWon++;
		}
	}
	
	return setsWon;   
}

- (long)upperPlayerSets;
{
   if (winner == [self upperPlayer]) {
      return [self setsWon:+1];
   } else {
      return [self setsWon:-1];
   }
}

- (long)lowerPlayerSets;
{
   if (winner == [self lowerPlayer]) {
      return [self setsWon:+1];
   } else {
      return [self setsWon:-1];
   }
}

- (long)upperPlayerPoints;
{
   long i, pointsWon = 0;

   for (i=0; i<7; i++) {
      pointsWon = pointsWon + [self upperPlayerPointsInSet:i];
   }

   return pointsWon;
   
}

- (long)lowerPlayerPoints;
{
   long i, pointsWon = 0;

   for (i=0; i<7; i++) {
      pointsWon = pointsWon + [self lowerPlayerPointsInSet:i];
   }

   return pointsWon;

}

- (NSString *)description;
{
   return [NSString stringWithFormat:@"Spiel %ld", rNumber];
}

- (void)withdraw;
{
   [[TournamentDelegate.shared.matchController playingTableController] freeTablesOf:self];
   [[TournamentDelegate.shared.matchController playingMatchesController] removePlayable:self];
   [umpire putAsUmpire];
   [self setReady:YES];
   umpire = nil;
}

- (float)textGray;
{
   float upperTextGray = [self upperPlayer]?[[self upperPlayer] seriesPriority:series]:0.0;
   float lowerTextGray = [self lowerPlayer]?[[self lowerPlayer] seriesPriority:series]:0.0;
   return (upperTextGray+lowerTextGray)/2.0;
}

- (long)desiredTablePriority;
{
   NSString *seriesName = [[self series] seriesName];
   char level = [seriesName characterAtIndex:[seriesName length]-1];
   int priority = 5;
   
   if ( ([upper upperMatch] == nil) && ([lower upperMatch] == nil) && (round > 4) ) {
      priority = 4;
   } else if (round > 8) {
      priority = 3;
   } else if (round > 2) {
      priority = 2;
   } else {
      priority = 1;
   }

   if ((level == 'A') && (priority > 1)) {
      priority--;
   }
   
   return priority;
}

- (long)numberOfTables;
{
   return 1;
}

- (void)addTable:(long)tableNumber;
{
   [self setTableString:[NSString stringWithFormat:@"%ld", tableNumber]];
}

- (void)appendResultsAsTextTo:(NSMutableString *)text;
{
   NSString *matchWO = wo?@"wo":@"";

   if ((upper == nil) || (lower == nil) || (winner == nil)) {
      return;	// this is a simple player, no need to store or not played due to absence
   }

	 if (([self upperMatch] != nil) && ([self upperIsWinner])) {
      [[self upperMatch] appendResultsAsTextTo:text];
   }

   if (([self lowerMatch] != nil) && ([self lowerIsWinner])) {
      [[self lowerMatch] appendResultsAsTextTo:text];
   }

   [text appendFormat:@"%ld\t%ld\t%ld\t%ld\t%ld\t%@\t%@\t%@\t%@\t%@\n",
      [[self upperPlayer] licence], [[self upperPlayer] rankingInSeries:series],
      [[self lowerPlayer] licence], [[self lowerPlayer] rankingInSeries:series],
      [winner licence],
      [self resultSeriesName], matchWO, [self matchId], [self nextMatchId], [self matchResultString]];
      
//   [self upperLowerShortStringSet:<#(int)setIndex#>]
//   @"UpperLicence\tupperRanking\tLowerLicence\tlowerRanking\tWinnerLicence"
//      @"\tSeriescode\tWO\tMatchId\tNextMatchId\n"];

}

- (NSString *)matchId;
{
   return [NSString stringWithFormat:@"%ld", rNumber];
}

- (NSString *)nextMatchId;
{
   if (next != nil) {
      return [next matchId];
   } else {
      return [[self series] nextMatchIdFor:self];
   }
}

- (Match *) seriesSmallFinal;
{
	return [[self series] smallFinalTable];
}

- (NSString *)resultSeriesName;
{
    return [series seriesName];
}

- (float)roundPriority;
{
	return 1.0/(round+0.1);
}

- (float)numRoundPriority;
{
	return 0.2*[self deltaRound:1];
}

- (float)minRoundPriority;
{
	long deltaMinRound = [self deltaRound:[series minRound]];
	
	if (deltaMinRound > 0) {
		return 5.0/deltaMinRound;
	} else {
		return 0.0;
	}
}

- (long)deltaRound:(long)toRound;
{
	long delta = 0;
	long deltaRound = round;
	
	while (deltaRound > toRound) {
		deltaRound = deltaRound/2;
		delta++;
	}
	return delta;
}

- (BOOL)replacePlayer:(id<Player>)player by:(id<Player>)replacement;
{
	if([self upperPlayer] == player) {
		[[self upperMatch] setWinner:replacement];
		return YES;
	} else if ([self lowerPlayer] == player) {	// just check for security
		[[self lowerMatch] setWinner:replacement];
		return YES;
	} else if ([self winner] == player) {
		[self setWinner:replacement];
		return YES;
	} else {
		return NO;
	}
}

// return YES if neither player is absent *and* set a winner otherwise!
- (bool)neitherPlayerAbsent;
{
	return [[self upperPlayer] attendant] && [[self lowerPlayer] attendant];
}

- (BOOL)hasSamePlayersAs:(Match *)match;
{
	return ((([self upperPlayer] == [match upperPlayer]) && (([self lowerPlayer] == [match lowerPlayer])))
			  || (([self upperPlayer] == [match lowerPlayer]) && (([self lowerPlayer] == [match upperPlayer]))));
}

- (void)takeResultFrom:(Match *)match;
{
	// no need to care about the sign of the result, string-Result will be converted upon formatting
	[self setWinner:[match winner]];
	int i;
	for (i=0; i<5; i++) {
		NSString *setRes = [match winnerLoserShortStringSet:i];
		if ([setRes length] > 0) {
			[self setWinnerLoserSet:i to:setRes];
		}
	}
}

- (NSString *)matchGroup;
{
	return [self roundString];
}

- (int)matchesUpper;
{
	if ([self upperPlayer] == winner) {
		return 1;
	} else {
		return 0;
	}
}

- (int)matchesLower;
{
	if ([self lowerPlayer] == winner) {
		return 1;
	} else {
		return 0;
	}
}

- (NSString *)typeUpper;
{
	if (([self wo]) && ([self lowerPlayer] == winner)) {
		return @"2";		// did not start
	} else {					// no way to determine "was not finished" (1) at the moment
		return @"0";		// finished regularly
	}
}

- (NSString *)typeLower;
{
	if (([self wo]) && ([self upperPlayer] == winner)) {
		return @"2";		// did not start
	} else {
		return @"0";
	}
}

- (NSString *)matchResXml;
{
	return [NSString stringWithFormat:@"     matches-a=\"%d\" matches-b=\"%d\" state-a=\"%@\" state-b=\"%@\"",
					[self matchesUpper], [self matchesLower], [self typeUpper], [self typeLower]];
}

- (NSString *)setsResXml;
{
	return [NSString stringWithFormat:@"     sets-a=\"%ld\" sets-b=\"%ld\"", [self upperPlayerSets], [self lowerPlayerSets]];
}

- (long) setPoints:(long) points;
{
	if (points > 0) {
		if (points < 11) {
			return 11;
		} else {
			return points+1;
		}
	} else if (points < 0) {
		return -points-1;
	} else{
		return 0;
	}
}

- (long) upperSetPoints:(long) i;
{
	if ([self upperPlayer] == winner) {
		return [self setPoints:sets[i]];
	} else {
		return [self setPoints:-sets[i]];
	}
}

- (long) lowerSetPoints:(long) i;
{
	if ([self lowerPlayer] == winner) {
		return [self setPoints:sets[i]];
	} else {
		return [self setPoints:-sets[i]];
	}
}

- (NSString *)setResultXml:(long)setNo a:(long) aPoints b:(long) bPoints;
{
   if (rNumber == 142) {
      printf("hit");
   }
	return [NSString stringWithFormat:@"     set-a-%ld=\"%ld\" set-b-%ld=\"%ld\"\n",
					setNo, aPoints, setNo, bPoints];
}


- (NSString *)pointsResXml;
{
	NSMutableString *result = [NSMutableString string];
	long i, pointsA=0, pointsB=0;

	for (i=0; i<7; i++) {
		long setPointsA=[self upperSetPoints:i];
		long setPointsB=[self lowerSetPoints:i];
		[result appendString:[self setResultXml:i+1 a:setPointsA b:setPointsB]];
		pointsA=pointsA+setPointsA;
		pointsB=pointsB+setPointsB;
	}
	[result appendFormat:@"     games-a=\"%ld\" games-b=\"%ld\"", pointsA, pointsB];
	
	return result;
}

- (NSString *)resultDetailsXml;
{
	return [NSString stringWithFormat:@"%@\n%@\n%@", [self matchResXml], [self setsResXml], [self pointsResXml]];
}

- (void)appendMatchResultAsXmlTo:(NSMutableString *)text;
{
	[text appendFormat:@"    <match nr=\"%@\" group=\"%@\"\n", [self matchId], [self matchGroup]];
	[text appendFormat:@"     scheduled =\"%@\" player-a=\"%@\" player-b=\"%@\"\n", [self clickScheduled], 
	  [[self upperPlayer] clickId:series], [[self lowerPlayer] clickId:series]];
	[text appendString: [self resultDetailsXml]];
	[text appendString:@" />\n"];
}

- (void)appendMatchResultsAsXmlTo:(NSMutableString *)text;
{
	if ((upper == nil) || (lower == nil) || (winner == nil)) {
		return;	// this is a simple player, no result and no XML
	}
	
	if (([self upperMatch] != nil) && ([self upperIsWinner])) {
		[[self upperMatch] appendMatchResultsAsXmlTo:text];
	}
	
	if (([self lowerMatch] != nil) && ([self lowerIsWinner])) {
		[[self lowerMatch] appendMatchResultsAsXmlTo:text];
	}
	
	[self appendMatchResultAsXmlTo:text];
}

- (void)gatherPlayersIn:(NSMutableSet *)allPlayers;
{
	if (winner != nil) {
		[allPlayers addObject:winner];
	}
	if (lower != nil) {
		[lower gatherPlayersIn:allPlayers];
	}
	if (upper != nil) {
		[upper gatherPlayersIn:allPlayers];
	}
}

// create a new match from the losers of the matches directly preceeding this one
- (Match *)makeLoserMatch;
{
	NSMutableArray *pstns = [NSMutableArray array];
	Match *lMatch = [[Match alloc] initUpTo:2 current:1 total:1 next:nil series:series
														posList:pstns];
	[upper setLoserMatch:lMatch];
	[lMatch setUpper:upper];
	[lMatch setUpperIsWinner:NO];
	[lower setLoserMatch:lMatch];
	[lMatch setLower:lower];
	[lMatch setLowerIsWinner:NO];
	
	return lMatch;
}

- (NSComparisonResult)prioCompare:(id<Playable>)otherPlayable;
{
	if ([shouldStart length] == 0) {
		if ([[otherPlayable shouldStart] length] == 0) {
			float otherPrio = [otherPlayable tp];
			if (tourPrioCache < otherPrio) {		// higher priorities first
				return NSOrderedDescending;
			} else if (tourPrioCache > otherPrio) {
				return NSOrderedAscending;
			} else {
				return NSOrderedSame;
			}
		} else {
			return NSOrderedDescending;					// timed matches before untimed
		}
	} else {
		if ([[otherPlayable shouldStart] length] > 0) {
			NSComparisonResult compResult = [shouldStart compare:[otherPlayable shouldStart]];
			if (compResult != NSOrderedSame) {
				return compResult;
			} else {
				return [tableString compare:[otherPlayable tableString]];
			} 
		} else {
			return NSOrderedAscending;					// again the timed match first
		}
	}
}

static float _lineDelta=12.0;


+ (float) lineDelta;
{
	return _lineDelta;
}

+ (void) fixDimensions;
{
	_lineDelta = TournamentDelegate.shared.preferences.lineDelta;
}

- (NSString *)textRepresentation;
{
   NSString *upperName, *lowerName;
   
   if ([upper winner] != nil) {
      upperName = [[upper winner] longName];
   } else {
      upperName = @"unknown";
   }
   
   if ([lower winner] != nil) {
      lowerName = [[lower winner] longName];
   } else {
      lowerName = @"unknown";
   }

   return [NSString stringWithFormat:@"%@ – %@", upperName, lowerName];
}

- (void)addNotification:(id<VictoryNotification>)notifiee;
{
   if (notifiees == nil) {
      notifiees = [[NSMutableArray<VictoryNotification> alloc] init];
   }
   [notifiees addObject:notifiee];
}
@end
