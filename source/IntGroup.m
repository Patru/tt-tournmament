/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a group of a series that is played with groups.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 6.3.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import "IntGroup.h"
//#import "IntGroupSeries.h"
#import "GroupMatch.h"
#import "GroupPlayer.h"
//#import "GroupResult.h"
//#import <gruppe.h>
#import "MatchConstants.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

@implementation IntGroup
/* The Group-class manages all the things related to a group of 3 to 8 players,
   first the Round Robin matches, subsequently the propagation to single
   elimintation
 */

/*
-initFromPositions:(NSArray *)pos series:(Series *)ser number:(int)num;
{  int i;

   [super initFromPositions:pos series:ser number:num];
   
   originalPlayers = nil;
   for(i=0; i<INT_GROUP_PLAYERS; i++)
   {
      wins[i] = @"";
      sets[i] = @"";
      points[i] = @"";
      rank[i] = @"";
   } // for
   
   return self;
} // init
*/

- makeMatches;
// inserts the necessary matches into the list matches
{  int i, max = [matches count], maxPl = [players count], modeLen;
   const char *mode;
   int tables[2];		// tables for this group
   NSString *times = [[self series] times];
   int tableStart;		// index for first table
   int odd = [self number]%2;
   int upperHalf = ([self number] - 1)/2;
   	// the upper half is different too!
   int twoMatchesFirst = ([self number]%2 + upperHalf)%2;
   	// two matches in the first round for groups A and D,
	// one match for groups
   if (odd)
   {
      tableStart = (([self number]-1)/2)*3;
   }
   else
   {
      tableStart = (([self number] - 2)/2)*3 + 1;
   } // if
//   tables[0] = [[self series] tables1][tableStart];
//   tables[1] = [[self series] tables1][tableStart + 1];
   
   originalPlayers = [players copy];

   /*************** if matches existed remove them from table ***************/
   
   [matches removeAllObjects];
   
   /************* determine mode by looking at number of players ************/
   
   if (maxPl <= 4)
   {
      mode = "acbdadbcabcd";
   }
   else if (maxPl <= 6)
   {
      mode = "adbecfaedfbcafcebdacbfdeabcdef";
   }
   else if (maxPl <= 8)
   {
      mode = "ahbgcfdedhcebfagghcdbeafchbdaefgfhbcadegbhacdgefehabcgdf";
   }
   else
   {
      mode = "";
   } // if
   modeLen = strlen(mode);
   for(i=0; i<modeLen; i=i+2)
   {
      int pl1 = mode[i] - 'a';
      int pl2 = mode[i + 1] - 'a';
      
      if ((maxPl >= pl1) && (maxPl >= pl2) &&
          ([[players objectAtIndex:pl1] present]) &&
	  ([[players objectAtIndex:pl2] present]))
      {  int idx = i/2;
      
         [matches addObject:[[GroupMatch alloc]
			     initFrom:mode[i] and:mode[i+1] of:self]];
	 if (idx%3 == 0)
	 {
	    if (twoMatchesFirst)		// groups A and C
	    {
	       [[[matches lastObject] setShouldStart:[times[(idx/3)*2] UTF8String]]
		  setTable:tables[0]];
	    }
	    else		// groups B and D
	    {
	       [[[matches lastObject] setShouldStart:[times[(idx/3)*2] UTF8String]]
		  setTable:tables[1-upperHalf]];
	    } // if
	 }
	 else if (idx%3 == 1)
	 {
	    if (twoMatchesFirst)		// groups A and C
	    {
	       [[[matches lastObject] setShouldStart:[times[((idx-1)/3)*2] UTF8String]]
		  setTable:tables[1]];
	    }
	    else		// groups B and D
	    {
	       [[[matches lastObject] setShouldStart:[times[((idx-1)/3)*2+1] UTF8String]]
		  setTable:tables[0]];
	    } // if
	 }
	 else if (idx%3 == 2)
	 {
	    if (twoMatchesFirst)		// groups A and C
	    {
	       [[[matches lastObject] setShouldStart:[times[((idx-2)/3)*2+1] UTF8String]]
		  setTable:tables[0 + upperHalf]];
	    }
	    else		// groups B and D
	    {
	       [[[matches lastObject] setShouldStart:[times[((idx-2)/3)*2+1] UTF8String]]
		  setTable:tables[1]];
	    } // if
	 } // if
      } // if
   } // for

   max = [matches count];
   for(i=0; i<max; i++)
   {
      [TourDelegate.shared number:[matches objectAtIndex:i]];
   } // for   
   return self;
} // makeMatches

- drawGroupIn:(NSRect)aFrame playerHeight:(float)playerHeight
     matchHeight:(float)matchHeight;
/* In: aFrame:       Frame to draw group in
   .   playerHeight: height of the font for the players
   .   matchHeight:  height of the font for the matches
   What: draws the player- and match information into aFrame. The title
         information has to be done beforehand
*/

{  int i, max = [matches count];
   NSMutableArray *tables = [[NSMutableArray alloc] init];
   char buf[80];
   float winWidth = 12.0;
   float left = NSMinX(aFrame);
   float idx = left + 15;
   float timex = left + 27;
   float namex = left + 33;
   float tablex = timex + 13;
   float matchx = tablex + 20;
   float player1x = matchx + 13;
   float assx = namex + 170;
   float rankx = left + NSWidth(aFrame) - 10;
   float pointsx = rankx - 56;
   float setsx = pointsx - 51;
   float winsx = setsx - 30;
   float firstWinLine = left + NSWidth(aFrame) - 6*winWidth;
   float set3x = firstWinLine - 15;
   float set2x = set3x - 30;
   float set1x = set2x - 30;
   float arbitrex = set1x - 53;
   
   float nameLine = left + 30;
   float assLine = nameLine + 170;
   float matchLine = nameLine + 20;
   float plLine = matchLine + 20;
   float rightLine = left + NSWidth(aFrame);
   float rankLine = rightLine - 30;
   float pointsLine = rankLine - 6*winWidth;
   float setsLine = pointsLine - 30;
   float winsLine = setsLine - 30;
   float set3Line = firstWinLine - 30;
   float set2Line = set3Line - 30;
   float set1Line = set2Line - 30;
   float arbitreLine = set1Line - 40;
   float player2x = (arbitreLine + player1x) / 2.0;
   float lineDeeper = 18.0;
   
   float row;					// current row
   float firstHor, secondHor, thirdHor;	// temporary storage
   float lineHeight;
   
   PSsetlinewidth(0.5);
   
   for(i=0; i<max; i++)
   {
      int tableNum = [(Match *)[matches objectAtIndex:i] table];
      
      if (tableNum != 0)
      {  int j=0, lmax=[tables count];
      
         while ((j<lmax) && ((int)[tables objectAtIndex:j]<tableNum)) j++;
	 if ((j == lmax) || ((int)[tables objectAtIndex:j]>tableNum))
            [tables insertObject:(id)tableNum atIndex:j];
	    // do nothing if you find it is already there.
      } // if
   } // for
   
   row = NSMinY(aFrame) + NSHeight(aFrame) - 42.0;

   buf[0] = '\000';
   max = [tables count];
   if (max > 0)
   {
      for (i=0; i<max; i++)
      {  char newbuf[10];
	 
	 sprintf(newbuf, "%d+", (int)[tables objectAtIndex:i]);
	 strcat(buf, newbuf);
      } // for
      buf[strlen(buf)-1] = '\000';
      
//      PSInternationalTables(NSMinX(aFrame), row, NSWidth(aFrame), 12,
//        "Tische / tables / tables", buf);
      row = row - 5.0;
   } // if
/*
   PSmoveto(nameLine, row); PSlineto(rightLine, row); PSstroke();
   firstHor = row;
   row = row - 11;
   PSselectfont("Helvetica", 6.0);
   PSmoveto(namex, row);
   PStrippleshow("NAME, Vorname", "NOM, PrŽnom", "NAME, First name");
   PSmoveto(assx, row);
   PStrippleshow("Verband", "association", "association");
   PSmoveto(winsLine + 3, row);
   PStrippleshow("Siege", "victoires", "wins");
   PSmoveto(setsLine + 3, row);
   PStrippleshow("SŠtze", "sets", "games");
   PSmoveto(pointsLine + 3, row);
   PStrippleshow("Punkte", "points", "points");
   PSmoveto(rankLine + 3, row);
   PStrippleshow("Rang", "rang", "rank");
   row = row - 19;
   PSmoveto(left, row); PSlineto(rightLine, row); PSstroke();
   secondHor = row;
   
   max = [players count];
   for (i=0; i < max; i++)
   {
      SinglePlayer *pl = (SinglePlayer *)[originalPlayers objectAtIndex:i];
      char idbuf[20];
      
      row = row - 15;
      sprintf(idbuf, "%c", i+97);
      PSgroupplayer(idx, namex, assx, winsx, setsx, pointsx, rankx, row,
        NSWidth(aFrame), 12.0, 
	idbuf, [pl longName], [pl club], wins[i], sets[i], points[i], rank[i]);
      row = row - 3.0;
      PSmoveto(left, row); PSlineto(rightLine, row); PSstroke();
   } // for

   PSmoveto(left, secondHor);PSlineto(left, row); PSstroke();
   PSmoveto(nameLine, firstHor);PSlineto(nameLine, row); PSstroke();
   PSmoveto(assLine, firstHor);PSlineto(assLine, row); PSstroke();
   PSmoveto(winsLine, firstHor);PSlineto(winsLine, row); PSstroke();
   PSmoveto(setsLine, firstHor);PSlineto(setsLine, row); PSstroke();
   PSmoveto(pointsLine, firstHor);PSlineto(pointsLine, row); PSstroke();
   PSsetlinewidth(1.0);
   PSmoveto(rankLine, firstHor);PSlineto(rankLine, row);
   PSlineto(rightLine, row); PSlineto(rightLine, firstHor); PSclosepath();
   PSstroke();
   PSmoveto(rankLine, secondHor); PSlineto(rightLine, secondHor); PSstroke();
   PSsetlinewidth(0.5);
   
   row = row - 15;
   PSmoveto(set1Line + 3, row);
   PSselectfont("Helvetica", 6.0);
   PStrippleshow("SŠtze", "sets", "games");
   PSmoveto(firstWinLine + 3, row);
   PStrippleshow("Gewinner ankreuzen", "indiquez le vainqueur",
                 "mark the winner");
   row = row - 19;
   firstHor = row;
   PSmoveto(left, row); PSlineto(rightLine, row); PSstroke();
   row = row - 11;
   PSmoveto(left+3, row);
   PStrippleshow("Zeit", "temps", "time");
   PSmoveto(nameLine + 3, row);
   PStrippleshow("Tisch", "table", "table");
   row = row - 8;
   PSselectfont("Helvetica", 12.0);
   PSmoveto(matchLine + 3, row);
   PSshow("Spiel / jeu / match");
   PSmoveto(arbitreLine + 3, row);
   PSshow("Arbitre");
   PSmoveto(set1x, row);
   PScshow("1");
   PSmoveto(set2x, row);
   PScshow("2");
   PSmoveto(set3x, row);
   PScshow("3");
   
   for(i=0; i<6; i++)
   {
      char buf[10];
      
      sprintf(buf, "%c", 'a' + i);
      PSmoveto(firstWinLine + (i + 0.5)*winWidth, row);
      PScshow(buf);
   } // for
   row = row - 11;
   secondHor = row;
   
   lineHeight = (row - NSMinY(aFrame) - 10)/16;
   
   PSselectfont("Helvetica", matchHeight);
   max = [matches count];
   for(i=0; i<max; i++)
   {  GroupMatch *mtch = (GroupMatch *)[matches objectAtIndex:i];
      char tableString[20];
      
      sprintf(tableString, "%d", [mtch table]);
      PSgroupmatch(timex, tablex, matchx, player1x, player2x, arbitrex,
        set1x, set2x, set3x, firstWinLine, row - lineDeeper, lineHeight,
	winWidth, lineHeight-lineDeeper, 6, matchHeight,
	[mtch shouldStart], tableString, [mtch matchupString],
	[[mtch upperPlayer] longName], [[mtch lowerPlayer] longName],
	"", [mtch stringSet:0], [mtch stringSet:1], [mtch stringSet:2],
	[mtch stringWinner]);
      PSmoveto(left, row); PSlineto(rightLine, row); PSstroke();
      row = row - lineHeight;
   } // for
   
   thirdHor = row;
   
   PSmoveto(left, row); PSlineto(rightLine, row); PSstroke();
   PSmoveto(matchLine, firstHor); PSlineto(matchLine, row); PSstroke();
   PSmoveto(plLine, secondHor); PSlineto(plLine, row); PSstroke();
   PSmoveto(arbitreLine, firstHor); PSlineto(arbitreLine, row); PSstroke();
   PSmoveto(set1Line, firstHor); PSlineto(set1Line, row); PSstroke();
   PSmoveto(set2Line, firstHor); PSlineto(set2Line, row); PSstroke();
   PSmoveto(set3Line, firstHor); PSlineto(set3Line, row); PSstroke();
   row = row - lineHeight;
   for(i=1; i<6; i++)
   {  int ver = firstWinLine + i*winWidth;
   
      PSmoveto(ver, firstHor); PSlineto(ver, row); PSstroke();
   } // for
   
   PSsetlinewidth(2.0);
   PSmoveto(left, firstHor); PSlineto(left, thirdHor);
   PSlineto(nameLine, thirdHor); PSlineto(nameLine, firstHor);
   PSclosepath(); PSstroke();
   PSmoveto(left, secondHor); PSlineto(nameLine, secondHor); PSstroke();
   PSmoveto(firstWinLine, firstHor); PSlineto(firstWinLine, row);
   PSlineto(rightLine, row); PSlineto(rightLine, firstHor);
   PSclosepath(); PSstroke();
   PSmoveto(firstWinLine, secondHor); PSlineto(rightLine, secondHor);
   PSstroke();
   PSmoveto(firstWinLine, thirdHor); PSlineto(rightLine, thirdHor); PSstroke();
   
   PSselectfont("Helvetica", 7);
   PSmoveto(left + 10, row + 16.0); 
   PSshow("Bei Sieggleichheit entscheiden Satz- und PunktverhŠltnis "
          "aus den Spielen der sieggleichen Spieler");

   PSmoveto(left + 10, row + 8.0); 
   PSshow("A l'ŽgalitŽ des victoires decideront les proportions des sets et "
          "des points parmi les joueurs ˆ l'ŽgalitŽ");

   PSmoveto(left + 10, row + 0.0); 
   PSshow("In case of equal victories the ratio of games and points "
          "from matches among the equal players decides the ranking");

   PSselectfont("Helvetica-Bold", 16.0);
   PSmoveto(set2Line + 10, row + 4.0); PSshow("Total");
*/

   return self;
   
} // drawGroupIn

- matchSheet:sender :(const NSRect *)rects :(int)rectCount;
// draw the sheet for use at the table
{  NSRect frame;
   const float titleleft = 10.0;
   const float infoleft = 20.0;
   const float left = 90.0;
   const float topplayer = 286.0;
   const float clubleft = 120.0;
   const float classleft = 205.0;
   const float winleft = 215.0;
   const float setleft = 235.0;
   const float setmid = 250.0;
   const float rankleft = 265.0;
   const float right = 286.0;
   const float topmatch = 180.0;
   const float even = 40;
   const float winLeft = MATCH_RIGHT - MATCH_WIN_WIDTH*[players count];
   const float setsLeft = winLeft - 5*MATCH_SET_WIDTH;
   const float base = 12.0;   char buf[100];
   float actPlayerHeight, otherbase;
   BOOL otherMatches = [TournamentDelefage.shared.preferences otherMatches];
   
   int i=0, max, maxMatches;

   [sender getFrame:&frame];

/* Title and other things around the important stuff */
   PSsetgray(1.0);
   PSmoveto(NSMinX(frame), NSMinY(frame));
   PSrlineto(0.0, NSHeight(frame));
   PSrlineto(NSWidth(frame), 0.0);
   PSrlineto(0.0, -NSHeight(frame));
   PSclosepath();
   PSfill();
   PSsetgray(0.0);
   PSselectfont("Helvetica-Bold", 16.0);
   PSmoveto(titleleft, 390.0);
   if ([TournamentDelefage.shared.preferences tourTitle])
      PSshow([TournamentDelefage.shared.preferences tourTitle]);
   PSmoveto(titleleft, 372.0);
   if ([TournamentDelefage.shared.preferences subTitle])
   PSshow([TournamentDelefage.shared.preferences subTitle]);

/* Specific information on location etc. */

   PSselectfont("Times-Roman", 16.0);
   PSmoveto(infoleft, 352.0);
   PSshow("Tisch:");
   PSmoveto(infoleft, 334.0);
   PSshow("Serie:");
   PSmoveto(left, 334.0);
   if ([series fullName] != NULL)
   {
      PSselectfont("Times-Bold", 16.0);
      if ([series fullName]) PSshow([series fullName]);
   } // if
   PSmoveto(infoleft, 316.0);
   PSselectfont("Times-Roman", 16.0);
   PSshow("Gruppe:");
   if (([series fullName] != NULL) || (number != 0))
   {
      sprintf(buf, "%d", number);
      PSmoveto(left, 316.0);
      PSshow(buf);
   } // if
   PSmoveto(infoleft, 300.0);
   PSshow("Spiel-Nr.:");
      if (rNumber != 0)
   {
      PSmoveto(left, 300.0);
      sprintf(buf, "%d", rNumber);
      PSshow(buf);
   } // if

/* top-info for the players */

   PSselectfont("Times-Roman", 8.0);
   PSmoveto(rankleft, topplayer + 3.0);
   PSshow("Rang");
//   PSmoveto(pointleft, topplayer + 3.0);
//   PSshow("Punkte");
   PSmoveto(setleft, topplayer + 3.0);
   PSshow("SŠtze");
   PSmoveto(winleft, topplayer + 3.0);
   PSshow("Siege");

/* player-info of the players */

   if (otherMatches)
   {
      actPlayerHeight = MATCH_HEIGHT+6.0;
      otherbase = MATCH_HEIGHT+4.5;
   }
   else
   {
      actPlayerHeight = MATCH_HEIGHT;
      otherbase = MATCH_HEIGHT+1.0;
   } // if
   
   max = [players count];
   PSmoveto(10.0, topplayer);
   PSlineto(right, topplayer);
   PSlineto(right, topplayer - max*actPlayerHeight);
   PSstroke();
   PSmoveto(rankleft, topplayer);
   PSlineto(rankleft, topplayer - max*actPlayerHeight);
   PSstroke();
   PSmoveto(setmid, topplayer);
//   PSlineto(pointleft, topplayer - max*actPlayerHeight);
//   PSstroke();
   PSmoveto(setleft, topplayer);
   PSlineto(setleft, topplayer - max*actPlayerHeight);
   PSstroke();
   PSmoveto(winleft, topplayer);
   PSlineto(winleft, topplayer - max*actPlayerHeight);
   PSstroke();
   PSmoveto(10.0, topplayer);
   PSlineto(10.0, topplayer - max*actPlayerHeight);
   PSstroke();
   
   PSselectfont("Times-Roman", 10.0);
   for(i=0; i<max; i++)
   {
      PSmoveto(10.0, topplayer - (i+1)*actPlayerHeight);
      PSlineto(right, topplayer - (i+1)*actPlayerHeight);
      PSstroke();
      if ([[players objectAtIndex:i] present])
      {
	 PSmoveto(infoleft, topplayer - base - i*actPlayerHeight);
	 if ([[players objectAtIndex:i] longName])
	    PSshow([[players objectAtIndex:i] longName]);
	 PSmoveto(clubleft, topplayer - base - i*actPlayerHeight);
	 if ([[players objectAtIndex:i] club]) PSshow([[players objectAtIndex:i] club]);
	 PSmoveto(classleft, topplayer - base - i*actPlayerHeight);
	 if ([series rankSel] != (SEL)nil)
	 {
	    sprintf(buf, "%i", [[players objectAtIndex:i] rankingInSeries:series]);
	    PSshow(buf);
	 }
	 PSmoveto(setmid, topplayer - base - i*actPlayerHeight);
	 PSshow(":");
	 if (otherMatches)
	 {  NSArray *openMatches = [[players objectAtIndex:i] openMatches];
	    int j, max = [openMatches count];
	 
	    PSselectfont("Times-Roman", 6.0);
	    for(j=0; j<max; j++)
	    {
	       PSmoveto(infoleft+j*20.0,
	                topplayer - otherbase - i*actPlayerHeight);
	       PSshow([(Series *)
	               [[openMatches objectAtIndex:j] series] seriesName]);
	    } // for
	    PSselectfont("Times-Roman", 10.0);
	 } // if
      } // if
   } // for

/* top-info for the matches */

//   PSselectfont("Times-Roman", 8.0);
   for(i=0; i<5; i++)
   {
      sprintf(buf, "%d. Satz", i + 1);
      PSmoveto(setsLeft + i*MATCH_SET_WIDTH, topmatch + 3.0);
      PSshow(buf);
   } // for
   
   PSmoveto(winLeft, topmatch + 15.0);
   PSshow("Sieger");

/* a lot of empty matches */

   PSselectfont("Times-Roman", 10.0);
   
   /****************************   draw the matches   ************************/
   
   maxMatches = [matches count];
   for(i=0; i<maxMatches; i++)
   {  float top = topmatch - i*MATCH_HEIGHT;
   
      [[matches objectAtIndex:i] draw:&top at:10.0 max:0];
   } // for
   
   /****************************   lines for matches   ***********************/
   
   max = [players count];
   for(i=max-1; i>=0; i--)
   {
      float x = MATCH_RIGHT - (max - i)*MATCH_WIN_WIDTH;
      
      PSmoveto(x + 3.0, topmatch + 3.0);
      sprintf(buf, "%c", 'a' + i);
      PSshow(buf);
      PSmoveto(x, topmatch);
      PSlineto(x, topmatch - MATCH_HEIGHT*maxMatches);
      PSstroke();
   } // for

   for(i=1; i<=5; i++)
   {  float x = MATCH_RIGHT - max*MATCH_WIN_WIDTH - i*MATCH_SET_WIDTH;
      
      PSmoveto(x, topmatch);
      PSlineto(x, topmatch - MATCH_HEIGHT*maxMatches);
      PSstroke();
   } // for
   PSmoveto(MATCH_LEFT, topmatch);
   PSlineto(MATCH_LEFT, topmatch - maxMatches*MATCH_HEIGHT);
   PSstroke();
   PSmoveto(MATCH_LEFT + MATCH_MATCHUP_WIDTH, topmatch);
   PSlineto(MATCH_LEFT + MATCH_MATCHUP_WIDTH,
            topmatch - maxMatches*MATCH_HEIGHT);
   PSstroke();
   PSmoveto(MATCH_LEFT, topmatch - maxMatches*MATCH_HEIGHT);
   PSlineto(MATCH_RIGHT, topmatch - maxMatches*MATCH_HEIGHT);
   PSstroke();
   
   PSsetlinewidth(2.0);
   PSrectstroke(winLeft, topmatch - maxMatches*MATCH_HEIGHT,
                max*MATCH_WIN_WIDTH, maxMatches*MATCH_HEIGHT);
   PSsetlinewidth(1.0);
   
   PSmoveto(infoleft, even);
   PSshow("Bei Sieggleichheit entscheiden Satz- und PunktverhŠltnis");
   PSmoveto(infoleft, even - 12.0);
   PSshow("(Berechnung am Turniertisch)");

   return self;
} // matchSheet

- keepResultOf:(id<Player>)pl rank:(int)aRank wins:(int)aWins
      setsPlus:(int)setsp minus:(int)setsm pointsPlus:(int)pointsp minus:(int)pointsm;
// store the result of player pl
{
   int i=[originalPlayers indexOfObject:pl];
   char buf[20];
   
/*   if (i != NSNotFound)
   {
      sprintf(buf, "%d.", aRank);
      rank[i] = NXUniqueString(buf);
      sprintf(buf, "%d", aWins);
      wins[i] = NXUniqueString(buf);
      if ((setsp != 0) || (setsm != 0))
      {
	 sprintf(buf, "%d:%d", setsp, setsm);
	 sets[i] = NXUniqueString(buf);
      } // if
      if ((pointsp != 0) || (pointsm != 0))
      {
	 sprintf(buf, "%d:%d", pointsp, pointsm);
	 points[i] = NXUniqueString(buf);
      } // if
   } // if
*/
   
   return self;
   
} // keepResultOf

/*- write: (NXTypedStream *) s;
// write to stream s
{
   [super write:s];

   NXWriteTypes(s, "[6%][6%][6%][6%]@", wins, sets, points, rank,
      &originalPlayers);
   
   return self;
} // write

- read: (NXTypedStream *) s;
// read from stream s
{
   [super read:s];

   NXReadTypes(s, "[6%][6%][6%][6%]@", wins, sets, points, rank,
      &originalPlayers);
   
   return self;
} // read
*/

@end
