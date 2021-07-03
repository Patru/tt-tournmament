/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a group of a series that is played with groups.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 6.3.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import "Group.h"
#import "GroupMatch.h"
#import "GroupInspector.h"
#import "GroupPlayer.h"
#import "GroupResult.h"
#import "SinglePlayer.h"
#import "MatchConstants.h"
#import "MatchViewController.h"
#import "SmallTextController.h"
#import "TournamentController.h"
#import "GroupResult.h"
#import "GroupSeries.h"
#import "PlayingMatchesController.h"
#import "UmpireController.h"
#import "Tournament-Swift.h"

#define MAX_PLAYER_GROUPDETAILS_ON_SINGLE_PAGE 8

GroupInspector *_groupInspector=nil;

@implementation Group
/* The Group-class manages all the things related to a group of 3 to 8 players,
   first the Round Robin matches, subsequently the propagation to single
   elimintation
 */
 
-init;
// Initialization with all standard values
{
   return [self initFromPositions:nil series:nil number:0];
} // init

-initSeries:(id <NSObject, drawableSeries>)ser number:(long)num;
// Initialization with no positions
{
   return [self initFromPositions:nil series:ser number:num];
} // initSeries

-initFromPositions:(NSArray *)pos series:(id <drawableSeries>)ser number:(long)num;
/* in: pos:	list of positions in the elimination-table
   .   ser:	series in which the group is played
   .   num:	number of the group
 what: initializes the respective values of the group
*/
{
   self=[super init];
   players = [[NSMutableArray alloc] init];
   matches = [[NSMutableArray alloc] init];
   _ranking = [[NSArray alloc] init];
   positions = [[NSMutableArray alloc] init];

   _wins  = [[NSMutableDictionary alloc] init];		// indexed by licence number
   _sets  = [[NSMutableDictionary alloc] init];
   _points= [[NSMutableDictionary alloc] init];
   _rank  = [[NSMutableDictionary alloc] init];
   if (pos)
   {
      [positions addObjectsFromArray:pos];
   } // if
   series = ser;
   number = num;
   inBrowser = NO;
   startTime = @"";
   tableString = @"";
   [TournamentDelegate.shared number:self];
   tourPrioCache = 0.0;
   _detailPages=0;
	
   return self;
} // initFromPositions

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeValueOfObjCType:@encode(BOOL) at:&inBrowser];
	[encoder encodeObject:players];
	[encoder encodeObject:matches];
	[encoder encodeObject:positions];
	[encoder encodeObject:tableString];
	[encoder encodeValueOfObjCType:@encode(long) at:&number];
	[encoder encodeValueOfObjCType:@encode(long) at:&rNumber];
	[encoder encodeValueOfObjCType:@encode(float) at:&tourPrioCache];
	[encoder encodeObject:series];
	[encoder encodeValueOfObjCType:@encode(BOOL) at:&finished];
	[encoder encodeObject:startTime];

	[encoder encodeObject:_ranking];
	[encoder encodeObject:_wins];
	[encoder encodeObject:_sets];
	[encoder encodeObject:_points];
	[encoder encodeObject:_rank];
}

- (id)initWithCoder:(NSCoder *)decoder
{
   self=[super init];
   [decoder decodeValueOfObjCType:@encode(BOOL) at:&inBrowser];
   players=[decoder decodeObject];
   matches=[decoder decodeObject];
   positions=[decoder decodeObject];
   if ([decoder versionForClassName:@"Group"] > 0) {
      tableString=[decoder decodeObject];
   } else {
      long table;

      [decoder decodeValueOfObjCType:@encode(long) at:&table];
      tableString=[NSString stringWithFormat:@"%ld", table];
   }
   [decoder decodeValueOfObjCType:@encode(long) at:&number];
   [decoder decodeValueOfObjCType:@encode(long) at:&rNumber];
   [decoder decodeValueOfObjCType:@encode(float) at:&tourPrioCache];
   series=[decoder decodeObject];
   [decoder decodeValueOfObjCType:@encode(BOOL) at:&finished];
   startTime=[decoder decodeObject];

   // added, versionize if time permits ...
   _ranking=[decoder decodeObject];
   _wins   =[decoder decodeObject];
   _sets   =[decoder decodeObject];
   _points =[decoder decodeObject];
   _rank   =[decoder decodeObject];
   _detailPages=0;

   return self;
}

// special methods

- (const char *)groupMode:(long)numPlayers;
{
	if ([[self series] isMemberOfClass:[GroupSeries class]]) {
		if (numPlayers <= 4) {
			return "acbdadbcabcd";
		}
		else if (numPlayers <= 6) {
			return "adbecfaedfbcafcebdacbfdeabcdef";
		}
		else if (numPlayers <= 8) {
			return "ahbgcfdedhcebfagghcdbeafchbdaefgfhbcadegbhacdgefehabcgdf";
		}
		else if (numPlayers <= 10) {
			return "afbgchdiejaibdcjegfhadbicfehgjacbfdgeihjaebhcgdjfiagbecidhfjahbjcedfgi"
					"ajbcdefghiabcdefghij";
		}
	} else {
		if (numPlayers <= 4) {
			return "adbcacbdabcd";
		}
		else if (numPlayers <= 6) {
			return "afbdcedfaebcadbecfdeacbfcdabef";
		}
		else if (numPlayers <= 8) {
			return "ahbgcfdeagbhcedfafbechdgaebfcgdhadbcegfhacbdehfgabcdefgh";
		}	else if (numPlayers <= 10) {		// TODO? determine some order for STT-10?
			return "afbgchdiejaibdcjegfhadbicfehgjacbfdgeihjaebhcgdjfiagbecidhfjahbjcedfgi"
						 "ajbcdefghiabcdefghij";
		}
	}
   return "";
}

- makeMatches;
// inserts the necessary matches into the list matches
{
   long i, max, maxPl = [players count], modeLen;
   const char *mode = [self groupMode:maxPl];

   /*************** if matches existed remove them from table ***************/
   
   [matches removeAllObjects];
   
   /************* determine mode by looking at number of players ************/
   
   modeLen = strlen(mode);
   for(i=0; i<modeLen; i=i+2)
   {
      long pl1 = mode[i] - 'a';
      long pl2 = mode[i + 1] - 'a';
      
      if ((maxPl > pl1) && (maxPl > pl2) &&
          ([[players objectAtIndex:pl1] present]) &&
			 ([[players objectAtIndex:pl2] present]))
      {
         GroupMatch *gm = [[GroupMatch alloc] initFrom:mode[i] andPlayer:mode[i+1] of:self];
         [matches addObject:gm];
      } // if
   } // for

   max = [matches count];
   for(i=0; i<max; i++)
   {
      [TournamentDelegate.shared number:[matches objectAtIndex:i]];
   } // for   
   return self;
} // makeMatches

// set- and get-methods

- (void)setPlayers:(NSArray *)plys;
	// set plys as the new list of players
{
   [players setArray:plys];
} // setPlayers

- (void)setRankingList:(NSArray *)rankingList;
	// set ranking for the group (used by GroupResult)
{
   _ranking = [[NSArray alloc] initWithArray:rankingList];
} // setPlayers

- (void)setReady:(BOOL)aFlag;
// set all the groups players ready-state to aFlag
{  long i, max=[players count];

   for(i=0; i<max; i++) {
      [[players objectAtIndex:i] setReady:aFlag];
   } // for
} // setReady

- (NSArray *)players;
// return the list of players for this group
{
   return players;
} // players

- (NSArray *)matches;
	// return the list of matches for this group
{
   return matches;
} // matches

- (NSArray *)rankingList;
	// return the ranking list of this group
{
   return _ranking;
}

- (NSMutableArray *)positions;
// return the list of positions, should not be called
{
   return positions;
} // positions

- (void)setNumber:(long)num;
// set the number of the group
{
   number = num;
} // setNumber

- (long)number;
// return the number of the group
{
   return number;
} // number

- (long)rNumber;
// return the running number
{
   return rNumber;
} // rNumber

- (id <NSObject, drawableSeries>)series;
// return the series in which the group is to be played
{
   return series;
} // series

// special methods

- printGroup;
// dummy method
{
   return self;
} // printGroup

- (void)addPosition:(GroupPlayer *)aPosition;
// add aPosition to the list of positions at the end
{
   [positions addObject:aPosition];
} // addPosition

- (void)setSeries:(id <NSObject, drawableSeries>)aSeries;
// set the series in which the group is to be played
{
	series = aSeries;
} // setSeries

- (void)setRNumber:(long)rn;
// set the running number of the group (for matchSheet)
{
   rNumber = rn;
}

- (NSString *)tableString;
{
   return tableString;
}

- (void)setTableString:(NSString *)aString;
{
   tableString = aString;
}

- (void)setFinished:(BOOL)aFlag;
/* if aFlag is YES, then players are distributed. The first [position count]
   players go into the ko-round, the rest can umpire.
   It is assumed that the players-list has been reordered and that all the
   positions go from the top.
*/
{
	finished = aFlag;
	if (finished) {
		long i, numInKo = [positions count], max = [players count];
		
		[self putUmpire];
		[[TournamentDelegate.shared.matchController playingTableController] freeTablesOf:self];
		// free tables before adding new matches
		
		for(i=0; i<numInKo; i++) {
			[[positions objectAtIndex:i] setFinished];// goes to predetermined place
		} // for
		[positions removeAllObjects];	// works only once, then correct by hand!
				// (maybe the link should be allowed to stay, but reused with extreme care?)
		
		for(i=0; i<max; i++) {		// remove the group from all the players list of open matches
			id<Player> player = [players objectAtIndex:i];
			
			[player finishMatch:self];
		} // for
	} // if
} // setFinished

- (BOOL)finished;
// return YES if all matches are finished, NO otherwise
{
   return finished;
} // finished

- (void)setInBrowser:(BOOL)aFlag;
// sets browser-state to aFlag
{
   inBrowser = aFlag;
} // setInBrowser

- (void)setTime:(NSString *)aString;
// set time at which the group was actually started
{
   startTime = aString;
} // setTime;

- (BOOL)contains:(id<Player> )aPlayer;
// YES if aPlayer is in the this group
{
	long i=0;
	long max=[players count];

	while ((i<max) && (![[players objectAtIndex:i] contains:aPlayer])) {
		i++;
	}

	return i<max;
// return ( [players indexOfObjectIdenticalTo:aPlayer] != NSNotFound);
} // contains

- (BOOL)isCurrentlyPlayed;
// returns YES if self is currently playing, NO otherwise
{
   return [[TournamentDelegate.shared.matchController playingMatchesController] containsPlayable:self];
} // isCurrentlyPlayed

- (bool)hasBeenStarted;
{
	return [self finished] || [self isCurrentlyPlayed];
}

- (BOOL)inBrowser;
// returns YES if the group is in the browser, NO otherwise
{
   return inBrowser;
} // inBrowser

- (float) tourPriority;
// compute tourPriority and return its value
{  long i, max = [players count];
   
   tourPrioCache=0.0;
   for(i=0; i<max; i++)
   {
      tourPrioCache = tourPrioCache + [[players objectAtIndex:i] tourPriority];
   }
   return tourPrioCache;
   
} // tourPriority

- (float) tp;
// return last computed tourPriority (used for sorting)
{
   return tourPrioCache;
} // tp

- (float) simpleTourPriority:(float)playerDayRanking;
// aFloat: the dayRanking of the player, describes probability of a win
// WARNING: this is not in any way scientific, just one more heuristic
{
	long i, max = [players count];
	float priority= max-1;
	
	priority = priority + [series tourPriorityFor:playerDayRanking];
	
	max = [positions count];
	for(i=0; i<max; i++) {
		GroupPlayer *gp = (GroupPlayer *)[positions objectAtIndex:i];
		priority = priority + [gp numRoundPriority];
	}
	
	return priority;
} // simpleTourPriority

- (BOOL)ready;
// returns YES if both players are available currently
{  long i=0, max = [players count];

   while((i < max) && ([[players objectAtIndex:i] ready]))
   {
      i++;
   } // while
   return (i == max) && ([series started]);
} // ready

- (NSString *)time;
// return the time when the group was started
{
   return startTime;
} // time

- drawGroupLeft:(long)left top:(float *)top;
/* in: left:	left border of drawing field
	 .   top:	top border for next players
	what: draw group information into the currently lockFocused view
	*/
{  long i, max = [players count];
   const float name = left+25.0;
   const float club = left+160;
   NSDictionary *attributes=[self textAttributes];

   if ([TournamentDelegate.shared.preferences tourNumbers]) {
      [[NSString stringWithFormat:@"%ld   %@", rNumber, [self description]]
			drawAtPoint:NSMakePoint(name, *top) withAttributes:attributes];
   } else {
      [[self description] drawAtPoint:NSMakePoint(name, *top)
		       withAttributes:attributes];
   } // if
   *top = *top - 2;
   for(i = 0; i<max; i++) {
      id pl = [players objectAtIndex:i];

      *top = *top - 12.0;
      if ([series rankSel] != (SEL) nil) {
			[[series rankingStringFor:pl] drawAtPoint:NSMakePoint(left, *top) withAttributes:attributes];
      } // if
      [[pl longName] drawAtPoint:NSMakePoint(name, *top) withAttributes:attributes];
      [[pl club] drawAtPoint:NSMakePoint(club, *top) withAttributes:attributes];
   } // for

   return self;
} // drawGroup

- matchSheet:sender :(const NSRect)rects;
// draw the sheet for use at the table
{
   const float titleleft = 14.0;
   const float infoleft = 20.0;
   const float left = 90.0;
   const float topplayer = 298.0;
   const float clubleft = 120.0;
   const float classleft = 205.0;
   const float winleft = 215.0;
   const float setleft = 235.0;
   const float setmid = 250.0;
   const float rankleft = 265.0;
   const float right = MATCH_RIGHT;
   const float topmatch = 200.0;
   const float even = 40;
   const float winLeft = MATCH_RIGHT - MATCH_WIN_WIDTH*[players count];
   const float setsLeft = winLeft - 5*MATCH_SET_WIDTH;
   const float base = 12.0;
   float actPlayerHeight, otherbase;
   BOOL otherMatches = [TournamentDelegate.shared.preferences otherMatches];
   NSDictionary *titleAttributes=[self titleAttributes];
   NSDictionary *largeAttributes=[self largeAttributes];
   NSDictionary *largeBoldAttributes=[self largeBoldAttributes];
   NSDictionary *smallAttributes=[self smallAttributes];
   NSDictionary *tinyAttributes=[self tinyAttributes];
   NSDictionary *otherMatchesAttributes=[self otherMatchesAttributes];
   NSBezierPath *aPath = [NSBezierPath bezierPath];
   
   long i=0, max, maxMatches;

/* Title and other things around the important stuff */
   [[NSColor whiteColor] set];
   [NSBezierPath fillRect:[sender frame]];
   [[NSColor blackColor] set];
   [TournamentDelegate.shared.tournament.title
		drawAtPoint:NSMakePoint(titleleft, 390.0)	withAttributes:titleAttributes];
   [TournamentDelegate.shared.tournament.subtitle
      drawAtPoint:NSMakePoint(titleleft, 372.0)	withAttributes:titleAttributes];

   /* Specific information on location etc. */

	NSString *tischNr = NSLocalizedStringFromTable(@"Tisch:", @"Matchblatt", @"Tischnummer auf Matchblatt");
   [tischNr drawAtPoint:NSMakePoint(infoleft, 352.0) withAttributes:largeAttributes];
   [tableString drawAtPoint:NSMakePoint(left, 352.0) withAttributes:largeAttributes];
	NSString *serie = NSLocalizedStringFromTable(@"Serie: ", @"Matchblatt", @"Serie auf Matchblatt");
   [serie drawAtPoint:NSMakePoint(infoleft, 334.0) withAttributes:largeAttributes];
   [[series fullName] drawAtPoint:NSMakePoint(left, 334.0) withAttributes:largeBoldAttributes];
	NSString *gruppe = NSLocalizedStringFromTable(@"Gruppe: ", @"Matchblatt", @"Gruppe auf Gruppen-Matchblatt");
   [gruppe drawAtPoint:NSMakePoint(infoleft, 316.0) withAttributes:largeAttributes];

   [[self identifier] drawAtPoint:NSMakePoint(left, 316.0) withAttributes:largeAttributes];
	NSString *spielNr = NSLocalizedStringFromTable(@"Spiel-Nr.:", @"Matchblatt", @"Spielnummer auf Matchblatt");
   [spielNr drawAtPoint: NSMakePoint(infoleft, 300.0) withAttributes:largeAttributes];
   if (rNumber != 0) {
      [[NSString stringWithFormat:@"%ld", rNumber] drawAtPoint:NSMakePoint(left, 300.0)
					       withAttributes:largeAttributes];
   } // if

   /* top-info for the players */

   [NSLocalizedStringFromTable(@"Rang", @"Matchblatt", @"Rang fŸr Gruppe")
		drawAtPoint:NSMakePoint(rankleft, topplayer + 3.0) withAttributes:tinyAttributes];
   [NSLocalizedStringFromTable(@"Saetze", @"Matchblatt", @"Saetze fŸr Gruppe")
		drawAtPoint:NSMakePoint(setleft, topplayer + 3.0) withAttributes:tinyAttributes];
   [NSLocalizedStringFromTable(@"Siege", @"Matchblatt", @"Siege fŸr Gruppe")
		drawAtPoint:NSMakePoint(winleft, topplayer + 3.0) withAttributes:tinyAttributes];
   
	/* player-info of the players */

   if (otherMatches) {
      actPlayerHeight = MATCH_HEIGHT+6.0;
      otherbase = MATCH_HEIGHT+4.5;
   } else {
      actPlayerHeight = MATCH_HEIGHT;
      otherbase = MATCH_HEIGHT+1.0;
   } // if
   
   max = [players count];
   [aPath moveToPoint:NSMakePoint(titleleft, topplayer)];
   [aPath lineToPoint:NSMakePoint(right, topplayer)];
   [aPath relativeLineToPoint:NSMakePoint(0.0, - max*actPlayerHeight)];
   [aPath moveToPoint:NSMakePoint(rankleft, topplayer)];
   [aPath relativeLineToPoint:NSMakePoint(0.0, - max*actPlayerHeight)];
   [aPath moveToPoint:NSMakePoint(setleft, topplayer)];
   [aPath relativeLineToPoint:NSMakePoint(0.0, - max*actPlayerHeight)];
   [aPath moveToPoint:NSMakePoint(winleft, topplayer)];
   [aPath relativeLineToPoint:NSMakePoint(0.0, - max*actPlayerHeight)];
   [aPath moveToPoint:NSMakePoint(titleleft, topplayer)];
   [aPath relativeLineToPoint:NSMakePoint(0.0, - max*actPlayerHeight)];
   [aPath stroke];

   for(i=0; i<max; i++) {
      float textBase = topplayer - base - i*actPlayerHeight;
      [NSBezierPath strokeLineFromPoint: NSMakePoint(titleleft, topplayer - (i+1)*actPlayerHeight)
										  toPoint: NSMakePoint(right, topplayer - (i+1)*actPlayerHeight)];
		
      if (![[players objectAtIndex:i] present]) {
			[[NSColor colorWithCalibratedWhite:0.5 alpha:0.0] set];
			// not present, bright
         NSBezierPath *path = [NSBezierPath bezierPath];
         [path moveToPoint: NSMakePoint(infoleft, textBase)];
         [path relativeLineToPoint: NSMakePoint(100, -10)];
         [path stroke];
      } else if ([[players objectAtIndex:i] wo]) {
			[[NSColor colorWithCalibratedWhite:0.25 alpha:0.0] set];
			// present but WO, less bright
         NSBezierPath *path = [NSBezierPath bezierPath];
         [path moveToPoint: NSMakePoint(infoleft, textBase)];
         [path relativeLineToPoint: NSMakePoint(100, -10)];
         [path stroke];
      } else {
			[[NSColor blackColor] set];
			// everything ok, the usual black
      } // if
      [[[players objectAtIndex:i] longName]
             drawAtPoint:NSMakePoint(infoleft, textBase)
			 withAttributes:smallAttributes];
      [[[players objectAtIndex:i] club]
	     drawAtPoint:NSMakePoint(clubleft, textBase)
	  withAttributes:smallAttributes];
		
      if ([series rankSel] != (SEL)nil) {
			[[series rankingStringFor:[players objectAtIndex:i]]
					drawAtPoint:NSMakePoint(classleft, textBase)
				withAttributes:smallAttributes];
      }
      [@":" drawAtPoint:NSMakePoint(setmid, textBase)
		withAttributes:smallAttributes];
      if (otherMatches) {
			NSArray *openMatches = [[players objectAtIndex:i] openMatches];
			long j, max = [openMatches count];
			
			for(j=0; j<max; j++) {
				[[(Series *) [[openMatches objectAtIndex:j] series] seriesName]
						 drawAtPoint:NSMakePoint(infoleft+j*20.0, topplayer - otherbase - i*actPlayerHeight)
					 withAttributes:otherMatchesAttributes];
			} // for
      } // if
   } // for

/* top-info for the matches */

   [NSLocalizedStringFromTable(@"Saetze", @"Matchblatt", @"SŠtze fŸr Gruppe")
				 drawAtPoint:NSMakePoint(setsLeft+36, topmatch + 14.0)
			 withAttributes:smallAttributes];

   for(i=0; i<5; i++) {
      [[NSString stringWithFormat:@"%ld.", i+1]
	       drawAtPoint:NSMakePoint(setsLeft + i*MATCH_SET_WIDTH + 5, topmatch + 3.0)
	    withAttributes:smallAttributes];
   } // for

   [NSLocalizedStringFromTable(@"Sieger", @"Matchblatt", @"Sieger fŸr Gruppe")
			drawAtPoint:NSMakePoint(winLeft, topmatch + 14.0)
	   withAttributes:smallAttributes];

   /****************************   draw the matches   ************************/
   
   maxMatches = [matches count];
   for(i=0; i<maxMatches; i++)
   {  float top = topmatch - i*MATCH_HEIGHT;
   
      [[matches objectAtIndex:i] drawForMatchSheetAt:top];
   } // for
   
   /****************************   lines for matches   ***********************/
   
   max = [players count];
   for(i=max-1; i>=0; i--) {
      float x = MATCH_RIGHT - (max - i)*MATCH_WIN_WIDTH;

      [[NSString stringWithFormat:@"%c", (char)('a' + i)]
	    drawAtPoint: NSMakePoint(x + 3.0, topmatch + 3.0)
	 withAttributes:smallAttributes];
      [NSBezierPath strokeLineFromPoint: NSMakePoint(x, topmatch)
				toPoint: NSMakePoint(x, topmatch - MATCH_HEIGHT*maxMatches)];
   } // for

   for(i=1; i<=5; i++) {
     float x = MATCH_RIGHT - max*MATCH_WIN_WIDTH - i*MATCH_SET_WIDTH;

      [NSBezierPath strokeLineFromPoint:NSMakePoint(x, topmatch)
				toPoint:NSMakePoint(x, topmatch - MATCH_HEIGHT*maxMatches)];
   } // for
   [NSBezierPath strokeLineFromPoint:NSMakePoint(MATCH_LEFT, topmatch)
			     toPoint:NSMakePoint(MATCH_LEFT, topmatch - maxMatches*MATCH_HEIGHT)];

   [NSBezierPath strokeLineFromPoint:NSMakePoint(MATCH_LEFT + MATCH_MATCHUP_WIDTH, topmatch)
			     toPoint:NSMakePoint(MATCH_LEFT + MATCH_MATCHUP_WIDTH,
			                         topmatch - maxMatches*MATCH_HEIGHT)];
   [NSBezierPath strokeLineFromPoint:NSMakePoint(MATCH_LEFT, topmatch - maxMatches*MATCH_HEIGHT)
			     toPoint:NSMakePoint(MATCH_RIGHT, topmatch - maxMatches*MATCH_HEIGHT)];

   [NSBezierPath setDefaultLineWidth:2.0];
   [NSBezierPath strokeRect:NSMakeRect(winLeft, topmatch - maxMatches*MATCH_HEIGHT,
				       max*MATCH_WIN_WIDTH, maxMatches*MATCH_HEIGHT)];
   [NSBezierPath setDefaultLineWidth:1.0];

   [NSLocalizedStringFromTable(@"Bei Sieggleichheit entscheiden Satz- und Punktverhaeltnis", @"Matchblatt",
										 @"Sieggleichheit fŸr Gruppe")
		drawAtPoint:NSMakePoint(infoleft, even) withAttributes:smallAttributes];
   [NSLocalizedStringFromTable(@"(Berechnung am Turniertisch)", @"Matchblatt", @"Berechnung fŸr Gruppe")
		drawAtPoint:NSMakePoint(infoleft, even - 12.0) withAttributes:smallAttributes];
   
   return self;
} // matchSheet

- result:(BOOL)show;
// read the result of the group from the user
// (display if show, otherwise silent)
{
   if (show) {
      [TournamentDelegate.shared.groupResult results:self];
   } else {
      [TournamentDelegate.shared.groupResult setGroupForEvaluation:self];
      [TournamentDelegate.shared.groupResult rankDecided:self];
   } // if
   
   return self;
} // result

- drawAsOpen:(const NSRect)cellFrame inView:aView withAttributes:(NSDictionary *)attributes;
// draw the browser-entry for the open-browser
// requires background to handle highlighting decently
{
   const float base = NSMinY(cellFrame)+ 1;
   const float seriesPos = NSMinX(cellFrame) + 1;
   const float groupPos = NSMinX(cellFrame) + 53;
   const float prio = NSMinX(cellFrame) + NSWidth(cellFrame) - 40.0;
   const float dependentMatches = prio - 40.0;
   long i, max = [players count], dependentMatchesSum = 0;

   for (i=0; i<max; i++) {
      dependentMatchesSum = dependentMatchesSum + [[players objectAtIndex:i] numberOfDependentMatches];
   }
   
   [[series seriesName] drawAtPoint:NSMakePoint(seriesPos, base) withAttributes:attributes];
   [[self description] drawAtPoint:NSMakePoint(groupPos, base) withAttributes:attributes];
   [[NSString stringWithFormat:@"%4.2f", [self tourPriority]]
          drawAtPoint:NSMakePoint(prio, base) withAttributes:attributes];
   [[NSString stringWithFormat:@"%ld", dependentMatchesSum]
          drawAtPoint:NSMakePoint(dependentMatches, base) withAttributes:attributes];

   return self;
} // drawAsOpen

- drawAsPlaying:(const NSRect)cellFrame inView:aView;
// draw the browser-entry for the playing-browser
{
   const float base = NSMinY(cellFrame) + 1.0;
   float seriesPosition = NSMinX(cellFrame) + 37.0;
   const float grp = NSMinX(cellFrame) + 40.0;
   float runNumPosition = NSMaxX(cellFrame)- 1.0;
   float timePosition = runNumPosition - 25.0;
   float tablePosition = timePosition - 35.0;
   NSString *runNumString = [NSString stringWithFormat:@"%ld", rNumber];
   NSDictionary *browserAttributes=[self browserAttributes];

   seriesPosition = seriesPosition - [[series seriesName] sizeWithAttributes:browserAttributes].width;
   runNumPosition = runNumPosition - [runNumString sizeWithAttributes:browserAttributes].width;
   timePosition = timePosition - [startTime sizeWithAttributes:browserAttributes].width;
   tablePosition = tablePosition  - [tableString sizeWithAttributes:browserAttributes].width;
   
   [[NSColor blackColor] set];
   [[series seriesName] drawAtPoint:NSMakePoint(seriesPosition, base) withAttributes:browserAttributes];
   [[self description]  drawAtPoint:NSMakePoint(grp, base) withAttributes:browserAttributes];
   [runNumString drawAtPoint:NSMakePoint(runNumPosition, base) withAttributes:browserAttributes];
   [startTime drawAtPoint:NSMakePoint(timePosition, base) withAttributes:browserAttributes];
   [tableString drawAtPoint:NSMakePoint(tablePosition, base) withAttributes:browserAttributes];
   
   return self;
}

- checkMatches;
// checks if all matches are played and displays the result.
{  long i=0, max = [matches count];
   
   while ((i<max) && ([[matches objectAtIndex:i] winner] != nil))
   {
      i++;
   } // while
   if (i==max)
   {
      [[TournamentDelegate.shared.matchController matchBrowser] removeMatch:self];
      [self result:NO];
   } // if
   
   return self;
      
} // checkMatches

- finishedDrawing;
// enter the group into players matches list and the ready matches into
// the matchBrowser
{
   [self makeMatches];
   
   return self;
} // finishedDrawing

- (long)round;
// dummy, to implement protocol, very early round,
{
   return 128;
} // round

- (IBAction) allMatchSheets:(id)sender;
// print all the MatchSheets of the group
{  long i=1, max = [matches count];
   
   for(i=0; i<max; i++)
   {
		 Match *match = [matches objectAtIndex:i];
		 if (![match finished]) {
			 [match print:nil];
		 }
   }
} // allMatchSheets

- (BOOL)wo;
// always returns NO for group
{
   return NO;
} // wo

- (long)printWOPlayersInto:text;
/* in: text: SmallTextController to append the players to which are WO
 what: prints the WO players and returns their number
 */
{  long max = [players count], i, count=0;
   
   for(i=0; i<max; i++)
   {
      SinglePlayer *plAti = (SinglePlayer *)[players objectAtIndex:i];
      
      if ([plAti wo])
      {
         NSString *buffer = [NSString stringWithFormat:@"g%ld\t%@\t%@\n",
				number, [plAti longName], [plAti club]];
			[text appendText:buffer];
			count++;
      } // if
   } // for
   
   return count;
} // printWOPlayersInto

- (long)printNPPlayersInto:text;
/* in: text: SmallTextController to append the players to which are WO
 what: prints the not present players and returns their number
 */
{  long max = [players count], i, count=0;
   
   for(i=0; i<max; i++)
   {
      SinglePlayer *plAti = (SinglePlayer *)[players objectAtIndex:i];
      
      if (![plAti present])
      {
         NSString *buffer=[NSString stringWithFormat:@"\tg%ld\t%@\t%@\n",
			 number, [plAti longName], [plAti club]];
			[text appendText:buffer];
			count++;
      } // if
   } // for
   
   return count;
} // printNPPlayersInto

- (void)print:(id)sender;
{
	[TournamentDelegate.shared.matchViewController setPortraitMatch:self];
}

- (NSDictionary*)textAttributes {
   return [NSDictionary dictionaryWithObject:
      [NSFont fontWithName:@"Helvetica" size:stringsize] forKey:NSFontAttributeName];
}

- (NSMutableDictionary*)browserAttributes {
   return [NSMutableDictionary dictionaryWithObject:
      [NSFont fontWithName:@"Helvetica" size:12.0] forKey:NSFontAttributeName];
}

- (NSDictionary*)largeBoldAttributes {
    return [NSDictionary dictionaryWithObject:
		[NSFont fontWithName:@"Times-Bold" size:16.0] forKey:NSFontAttributeName];
}

- (NSDictionary*)largeAttributes {
    return [NSDictionary dictionaryWithObject:
		[NSFont fontWithName:@"Times-Roman" size:16.0] forKey:NSFontAttributeName];
}

- (NSDictionary*)titleAttributes {
    return [NSDictionary dictionaryWithObject:
		[NSFont fontWithName:@"Helvetica-Bold" size:16.0] forKey:NSFontAttributeName];
}

- (NSDictionary*)smallAttributes {
	return [NSDictionary dictionaryWithObject:
[NSFont fontWithName:@"Times-Roman" size:10.0] forKey:NSFontAttributeName];
}

- (NSDictionary*)tinyAttributes {
	return [NSDictionary dictionaryWithObject:
[NSFont fontWithName:@"Times-Roman" size:8.0] forKey:NSFontAttributeName];
}

- (NSDictionary*)otherMatchesAttributes; {
	return [NSDictionary dictionaryWithObject:
[NSFont fontWithName:@"Times-Roman" size:6.0] forKey:NSFontAttributeName];
}

- (NSDictionary*)playerAttributes {
	return [NSDictionary dictionaryWithObject:
[NSFont fontWithName:@"Helvetica" size:12] forKey:NSFontAttributeName];
}

- (NSDictionary*)playerBoldAttributes {
	return [NSDictionary dictionaryWithObject:
[NSFont fontWithName:@"Helvetica-Bold" size:12] forKey:NSFontAttributeName];
}

- (id <InspectorControllerProtocol>) inspectorController;
{
   if (_groupInspector == nil) {
      _groupInspector=[[GroupInspector alloc] init];
   }
   [_groupInspector setGroup:self];

   return _groupInspector;
}

- keepResultOf:(id<Player>)pl rank:(long)rank wins:(long)wins
      setsPlus:(long)setsp minus:(long)setsm pointsPlus:(long)pointsp minus:(long)pointsm;
// store the result of player pl
{
   if ([players indexOfObject:pl] != NSNotFound) {
      [_rank setObject:[NSString stringWithFormat:@"%ld.", rank]
                forKey:[pl licenceNumber]];
      [_wins setObject:[NSString stringWithFormat:@"%ld", wins]
                forKey:[pl licenceNumber]];
      if ((setsp != 0) || (setsm != 0)) {
         [_sets setObject:[NSString stringWithFormat:@"%ld:%ld", setsp, setsm]
                   forKey:[pl licenceNumber]];
      } // if
      if ((pointsp != 0) || (pointsm != 0)) {
         [_points setObject:[NSString stringWithFormat:@"%ld:%ld", pointsp, pointsm]
                     forKey:[pl licenceNumber]];
      } // if
   } // if
   
   return self;
   
} // keepResultOf

- (void)drawDetails:(float *)top firstPageBottom:(float)firstPageBottom;
{
	[self drawGroupTitleBelow:top];
	[self drawPlayersDetails:top];
	[self drawMatchesDetailsBelow:top firstPageBottom:(float)firstPageBottom];
}

- (void)drawPlayer:(long) i below:(float *)top;
{
	float bot=*top-16.0;
	float base=bot+1.0;
	id <Player> player=[players objectAtIndex:i];
	NSNumber *licence=[player licenceNumber];
	NSDictionary *attributes=[self playerBoldAttributes];
	
	[NSBezierPath strokeLineFromPoint:NSMakePoint(30, *top) toPoint:NSMakePoint(30, bot)];
	[[NSString stringWithFormat:@"%c", (char)('a'+i)] drawAtPoint:NSMakePoint(37, base)
		withAttributes:[self playerAttributes]];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(50, *top) toPoint:NSMakePoint(50, bot)];
	
	[[player longName] drawAtPoint:NSMakePoint(52, base)
															withAttributes:attributes];
   if ((![player present]) || [player wo]) {
      [[NSColor colorWithCalibratedWhite:0.2 alpha:0.8] set];
      if ([player wo]) {
         [NSBezierPath strokeLineFromPoint:NSMakePoint(52, bot+2) toPoint:NSMakePoint(98, *top-2)];
      } else {
         [NSBezierPath strokeLineFromPoint:NSMakePoint(52, bot+2) toPoint:NSMakePoint(148, *top-2)];
      }
      [[NSColor blackColor] set];
   }

	[NSBezierPath strokeLineFromPoint:NSMakePoint(200, *top) toPoint:NSMakePoint(200, bot)];
	[[player club] drawAtPoint:NSMakePoint(202, base) withAttributes:attributes];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(340, *top) toPoint:NSMakePoint(340, bot)];

	[[_wins objectForKey:licence] drawAtPoint:NSMakePoint(352, base)
														withAttributes:[self playerAttributes]];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(370, *top) toPoint:NSMakePoint(370, bot)];
	[[_sets objectForKey:licence] drawAtPoint:NSMakePoint(379, base)
														withAttributes:[self playerAttributes]];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(410, *top) toPoint:NSMakePoint(410, bot)];

	[[_points objectForKey:licence] drawAtPoint:NSMakePoint(420, base)
														withAttributes:[self playerAttributes]];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(475, *top) toPoint:NSMakePoint(475, bot)];

	[[_rank objectForKey:licence] drawAtPoint:NSMakePoint(483, base)
														withAttributes:attributes];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(500, *top) toPoint:NSMakePoint(500, bot)];
	*top=bot;
	[NSBezierPath strokeLineFromPoint:NSMakePoint(30, bot) toPoint:NSMakePoint(500, bot)];
}

- (void)drawPlayersDetails:(float *)top;
{
	long max=[players count], i;
	
	[self drawPlayersTitle:top];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(30, *top) toPoint:NSMakePoint(500, *top)];
	for (i=0; i<max; i++) {
		[self drawPlayer:i below:top];
	}
}

- (void)drawPlayersTitle:(float *)top;
{
   *top=*top-12;
   [NSLocalizedStringFromTable(@"Name Vorname", @"Matchblatt", null)
		drawAtPoint:NSMakePoint(52, *top) withAttributes:[self playerAttributes]];
   [NSLocalizedStringFromTable(@"Club", @"Matchblatt", null)
		drawAtPoint:NSMakePoint(202, *top) withAttributes:[self playerAttributes]];
   [NSLocalizedStringFromTable(@"Siege", @"Matchblatt",null)
		drawAtPoint:NSMakePoint(342, *top) withAttributes:[self textAttributes]];
   [NSLocalizedStringFromTable(@"Saetze", @"Matchblatt", null)
		drawAtPoint:NSMakePoint(377, *top) withAttributes:[self textAttributes]];
   [NSLocalizedStringFromTable(@"Punkte", @"Matchblatt", null)
		drawAtPoint:NSMakePoint(412, *top) withAttributes:[self textAttributes]];
   [NSLocalizedStringFromTable(@"Rang", @"Matchblatt", null)
		drawAtPoint:NSMakePoint(477, *top) withAttributes:[self textAttributes]];
   *top=*top-2;
}

- (void)drawMatchesDetailsBelow:(float *)top firstPageBottom:(float)firstPageBottom;
{
	long max=[matches count], i;
	
	*top=*top-10;
	
	[self drawMatchesTitleBelow:top];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(30, *top) toPoint:NSMakePoint(500, *top)];
	for (i=0; i<max; i++) {
		if (i==28) {
			*top=firstPageBottom;
			[self drawGroupTitleBelow:top];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(30, *top) toPoint:NSMakePoint(500, *top)];
		}
		[self drawMatch:i below:top];
	}
	[self drawWinsBelow:top];
	*top = *top-10;
}

- (void)drawWinsBelow:(float *)top;
{
	long max=[players count], i;
	float winsLeft=500.0 - max*15;
	float base=*top-14;
	NSBezierPath *bp=[NSBezierPath bezierPath];

	[@"Total" drawAtPoint:NSMakePoint(winsLeft-40, base)
				withAttributes:[self playerBoldAttributes]];
	for(i=0; i<max; i++) {
	   NSNumber *licence = [[players objectAtIndex:i] licenceNumber];

	   [NSBezierPath strokeLineFromPoint:NSMakePoint(winsLeft+i*15, *top)
				     toPoint:NSMakePoint(winsLeft+i*15, base-1)];
	   if ([self finished]) {
	      [[NSString stringWithFormat:@"%d", [[_wins objectForKey:licence] intValue]]
			      drawAtPoint:NSMakePoint(winsLeft+i*15+4, base)
	      withAttributes:[self playerAttributes]];
	   }
	}
	[bp moveToPoint:NSMakePoint(winsLeft, base)];
	[bp lineToPoint:NSMakePoint(500.0, base)];
	[bp lineToPoint:NSMakePoint(500.0, *top)];
	[bp stroke];
	*top=base;
}

- (void)drawGroupTitleBelow:(float *)top;
{
	*top=*top-17;
	[[self description] drawAtPoint:NSMakePoint(30.0, *top)
			 withAttributes:[self largeAttributes]];
	*top=*top-10;
}

- (void)drawMatchesTitleBelow:(float *)top;
{
	long i, max=[players count];
	float winsLeft=500.0 - max*15;
	long setCount = 5;
	if ((matches != nil) && ([matches count] > 0)) {
		setCount = [[matches objectAtIndex:0] numberOfSets];
	}
	
	float setsLeft=winsLeft-setCount*24;
	float cur=*top-12;
	float lineTop, lineBottom;
	
	[NSLocalizedStringFromTable(@"Saetze", @"Matchblatt", null)
			drawAtPoint:NSMakePoint(setsLeft+2, cur)
		withAttributes:[self playerAttributes]];
	[NSLocalizedStringFromTable(@"Gewinner ankreuzen", @"Matchblatt", null)
			drawAtPoint:NSMakePoint(435, cur)
		withAttributes:[self tinyAttributes]];
	lineTop=cur-1;
	[NSBezierPath strokeLineFromPoint:NSMakePoint(50, lineTop)
									  toPoint:NSMakePoint(500, lineTop)];
	cur = lineTop-14;
	lineBottom=lineTop-15;
	[NSBezierPath strokeLineFromPoint:NSMakePoint(50, lineTop)
									  toPoint:NSMakePoint(50, lineBottom)];
	[@"Spiel" drawAtPoint:NSMakePoint(52, cur) withAttributes:[self playerAttributes]];

	for (i=0; i<setCount; i++) {
		float setLine=setsLeft+i*24;
		
		[NSBezierPath strokeLineFromPoint:NSMakePoint(setLine, lineTop)
										  toPoint:NSMakePoint(setLine, lineBottom)];
		[[NSString stringWithFormat:@"%ld", i+1] drawAtPoint:
				 NSMakePoint(setLine+8, cur) withAttributes:[self playerAttributes]];
	}
	
	for (i=0; i<max; i++) {
		[NSBezierPath strokeLineFromPoint:NSMakePoint(winsLeft+i*15, lineTop)
										toPoint:NSMakePoint(winsLeft+i*15, lineBottom)];
		[[NSString stringWithFormat:@"%c", (char)('a'+i)] drawAtPoint:
			NSMakePoint(winsLeft+4+i*15, cur) withAttributes:[self playerAttributes]];
	}
	[NSBezierPath strokeLineFromPoint:NSMakePoint(500, lineTop)
									  toPoint:NSMakePoint(500, lineBottom)];
					
	*top = lineBottom;
}

- (void)drawMatch:(long) i below:(float *)top;
{
	long max=[players count];
	float winsLeft=500.0 - max*15;
	float matchHeight=15;
	float bottom=*top-matchHeight;

	GroupMatch *match=(GroupMatch *)[matches objectAtIndex:i];
	NSRect area = NSMakeRect(30, bottom, winsLeft-30, matchHeight);

	[match drawResultInto:area];
	
	area.origin.x=winsLeft;
	area.size.width=max*15;
	[self drawWinnerOfMatch:match into:area];
	*top=bottom;
}

- (void)drawWinnerOfMatch:(GroupMatch *)match into:(NSRect) area;
{
   long i, max=[players count];
   long first=[players indexOfObject:[match upperPlayer]];
   long second=[players indexOfObject:[match lowerPlayer]];
   NSRect rect;
   NSBezierPath *bp;

   [[NSColor colorWithCalibratedWhite:0.7 alpha:1.0] set];
   if (first > 0) {
      rect=NSMakeRect(NSMinX(area), NSMinY(area), first*15, NSHeight(area));
      [NSBezierPath fillRect:rect];
   }
   if (first < second-1) {
      rect=NSMakeRect(NSMinX(area)+(first+1)*15, NSMinY(area),
		      (second-first-1)*15, NSHeight(area));
      [NSBezierPath fillRect:rect];
   }
   if (second < max-1) {
      rect=NSMakeRect(NSMinX(area)+(second+1)*15, NSMinY(area),
		      (max-second-1)*15, NSHeight(area));
      [NSBezierPath fillRect:rect];
   }
   [[NSColor blackColor] set];
   [NSBezierPath strokeRect:area];

   for(i=0; i<max; i++) {
      [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(area)+i*15, NSMinY(area))
						     toPoint:NSMakePoint(NSMinX(area)+i*15, NSMaxY(area))];
   }

   if ([match winner] != nil) {
      long winner=([match winner] == [match upperPlayer])?first:second;

      if (![match wo]) {
	 bp=[NSBezierPath bezierPath];
	 [bp moveToPoint:NSMakePoint(NSMinX(area)+2+winner*15, NSMinY(area)+2)];
	 [bp relativeLineToPoint:NSMakePoint(11, 11)];
	 [bp relativeMoveToPoint:NSMakePoint(-11, 0)];
	 [bp relativeLineToPoint:NSMakePoint(11, -11)];
	 [bp stroke];
      } else {
	 [@"wo" drawAtPoint:NSMakePoint(NSMinX(area)+2+winner*15, NSMinY(area)+2)
             withAttributes:[self playerAttributes]];
      }
   }
}

- (long)detailPages;
{
   long numberOfPlayers=[players count];

   if (numberOfPlayers > 8) {
      return 2;
   } else if (numberOfPlayers > 0) {
      return 1;
   } else return 0;
}

- (long)umpiresFrom;
{
	return [positions count];
}

- (void)putUmpire;
{
	long i, max = [_ranking count];
	
	for(i=[self umpiresFrom]; i<max; i++) {		// rest goes to single elimination
		id<Player> player = [_ranking objectAtIndex:i];
		[player putAsUmpire];
	}
}

- (void)removeUmpire;
// we do not remove these umpires, must do it manually
{
}

- (void)takeUmpire;
   // Groups never do take umpires
{
}

- (bool)playersShouldUmpire;
{
   long i=0, max = [players count];

   while ( (i<max) && (![[players objectAtIndex:i] shouldUmpire]) ) {
      i++;
   }

   return i < max;
}

- (void)removeAllPlayersFromUmpireList;
{
   UmpireController *umpireController = [TournamentDelegate.shared.matchController umpireController];
   SinglePlayer     *currentUmpire    = [umpireController selectedUmpire];
   long i=0, max = [players count];
   
   for (i=0; i<max; i++) {
      [[players objectAtIndex:i] removeFromUmpireList];
   }

   [umpireController selectSpecificUmpire:currentUmpire];
}

- (NSString *)description;
{
	NSString *gruppeFormat = NSLocalizedStringFromTable(@"Gruppe %@", @"Tournament", @"Format fŸr Gruppe auf Turniertabelle");
   return [NSString stringWithFormat:gruppeFormat, [self identifier]];
}

- (NSString *)identifier;
{
   if ([TournamentDelegate.shared.preferences groupLetters]) {
      return [NSString stringWithFormat:@"%c", (char)number + 'A' - 1];
   } else {
      return [NSString stringWithFormat:@"%ld", number];
   } // if
}

- (NSString *)textRepresentation;
{
   return [NSString stringWithFormat:@"%@; %@", [series fullName], [self description]];
}

- (void)withdraw;
{
   [[TournamentDelegate.shared.matchController playingTableController] freeTablesOf:self];
   [[TournamentDelegate.shared.matchController playingMatchesController] removePlayable:self];
   [self setReady:YES];
	[self setTableString:@""];
}

- (float)textGray;
{
   float groupGray = 0.0;
   long i, max = [players count];
   
   for(i=0; i<max; i++)	{
      groupGray = groupGray + [[players objectAtIndex:i] seriesPriority:series];
   }
   
   return groupGray/max;
}

- (long)desiredTablePriority;
{
   return 4;
}

- (long)numberOfTables;
{
	long i, max = [players count], presentPlayers = 0;
	
	for (i=0; i<max; i++) {
		if ([[players objectAtIndex:i] present]) {
			presentPlayers++;
		}
	}
	
	return presentPlayers/2;
}

- (void)addTable:(long)tableNumber;
{
	NSString *tblString = [NSString stringWithFormat:@"%ld", tableNumber];
	if ([tableString length] == 0) {
		[self setTableString:tblString];
	} else {
		if ([tableString rangeOfString:tblString].location == NSNotFound) {
			[self setTableString:[NSString stringWithFormat:@"%@, %ld", tableString, tableNumber]];
		}
	}
}

- (SinglePlayer *)umpire;
{
   return nil;
}

- (void)appendSingleResultsAsTextTo:(NSMutableString *)text;
{
   long i, max = [matches count];

   for(i=0; i<max; i++) {
      GroupMatch *match = [matches objectAtIndex:i];

      [match appendResultsAsTextTo:text];
   }
}

- (BOOL)hasGroupPlayers;
{
	long i, max = [players count];
	
	for (i=0; i<max; i++) {
		if([[players objectAtIndex:i] isKindOfClass:[GroupPlayer class]]) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)replacePlayer:(id<Player>)player by:(id<Player>)replacement;
{
	long index = [players indexOfObject:player];
	if (index != NSNotFound) {
		[players replaceObjectAtIndex:index withObject:replacement];
		[player removeMatch:self];
		[replacement addMatch:self];
		if (![self hasGroupPlayers]) {
			[self makeMatches];
		}
		return YES;
	} else {
		return NO;
	}
}

- (void)checkForWO;
{
}

- (float)numRoundPriority;
{
	return 0.3;
}

- (long)unfinishedMatches;
{
	long i, max=[matches count], unfinishedCount = 0;
	for (i=0; i<max; i++) {
		if (![[matches objectAtIndex:i] finished]) {
			unfinishedCount++;
		}
	}
	return unfinishedCount;
}

- (void)appendMatchResultsAsXmlTo:(NSMutableString *)text;
{
	long i, max=[matches count];
	
	for (i=0; i < max; i++) {
		Match *match = (Match *)[matches objectAtIndex:i];
		
		[match appendMatchResultsAsXmlTo:text];
	}
}

- (void)gatherPlayersIn:(NSMutableSet *)allPlayers;
{
   // quick hack, to be removed TODO
   for(id<Player> player in players) {
      if ([player isKindOfClass:[WinnerPlayer class]]) {
         id<Player> actual = [((WinnerPlayer *)player) actualPlayer];
         if (actual != nil) {
            [allPlayers addObject:actual];
         }
      } else {
         [allPlayers addObject:player];
      }
   }
}

- (NSString *)shouldStart;
{
	return nil;
	// there is currently no way of scheduling groups precisely, but this should to to sort them in the browser
}

- (NSComparisonResult)prioCompare:(id<Playable>)otherPlayable;
{
	if ([[self shouldStart] length] == 0) {
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
			NSComparisonResult compResult = [[self shouldStart] compare:[otherPlayable shouldStart]];
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

// instead of playing the whole group on one table we play all the matches as separately on different tables
- (void)playSingleMatches;
{
	long i, max = [players count];
	
	for (i=0; i<max; i++) {
		[[players objectAtIndex:i] removeMatch:self];
	}
	
	max = [matches count];
	for (i=0; i<max; i++) {
		Match *match = [matches objectAtIndex:i];
		
		if (![match finished]) {
			if ([match neitherPlayerAbsent]) {
				[[match upperPlayer] addMatch:match];
				[[match lowerPlayer] addMatch:match];
			} else {
				if (![[match upperPlayer] present]) {
					[match setWinner:[match lowerPlayer]];
					[match setWO:YES];
				} else if (![[match lowerPlayer] present]) {
					[match setWinner:[match upperPlayer]];
					[match setWO:YES];
				} else if ([[match upperPlayer] wo]) {
					[match handleWoOf:[match upperPlayer] potentialWinner:[match lowerPlayer]];
					if (![match wo]) {
						[[match upperPlayer] addMatch:match];
						[[match lowerPlayer] addMatch:match];
					}
				} else if ([[match lowerPlayer] wo]) {
					[match handleWoOf:[match lowerPlayer] potentialWinner:[match upperPlayer]];
					if (![match wo]) {
						[[match upperPlayer] addMatch:match];
						[[match lowerPlayer] addMatch:match];
					}
				} else {
					NSLog(@"?? No nonattending player, should not happen");		// in this case neither player has been absent
				}
			}
		}
	}
	[[TournamentDelegate.shared.matchController matchBrowser] removeMatch:self];
}
@end
