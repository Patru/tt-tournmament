//
//  PaymentView.m
//  Tournament
//
//  Created by Paul Trunz on Wed Feb 06 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "PaymentView.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"
#import <PGSQLKit/PGSQLKit.h>


@implementation PaymentView

- (id)initWithFrame:(NSRect)frame {
   self = [super initWithFrame:frame];
   if (self) {
      SinglePlayer *totalPlayer = [[SinglePlayer alloc] init];
      [totalPlayer setPName:@"Gesamt"];
      [totalPlayer setFirstName:@"Total"];
      [totalPlayer setClub:@""];
      sumOfAllPlayers2 = [[TournamentPlayer alloc] initWithPlayer:totalPlayer];
      playersInTournament2 = [[NSMutableArray alloc] init];
   }
   return self;
}

const float pageHeight = 780.0;
const float pageWidth  = 520.0;

- (void)drawRect:(NSRect)rect
{
   float top = [self totalPages] * pageHeight;
   float playerHeight = pageHeight/[self maxPlayersOnPage];
   long minPlayer = floor( (top-(rect.origin.y+rect.size.height))/playerHeight );
   long maxPlayer = ceil( (top-rect.origin.y)/playerHeight );
   long i, max = [playersInTournament2 count];

   if (minPlayer >= max) {
      minPlayer = max - 1;
   } else if (minPlayer < 0) {
      minPlayer = 0;
   }
   if (maxPlayer >= max) {
      maxPlayer = max - 1;
   }
   
   [self setFrameSize:NSMakeSize(pageWidth,top)];

   for (i=minPlayer; i<= maxPlayer; i++) {
      [[playersInTournament2 objectAtIndex:i] drawAt:NSMakePoint(10, top-i*playerHeight)];
   }
}

- (void) addPlayer2:(TournamentPlayer *)aTournamentPlayer;
{
   long i=[playersInTournament2 count];
   [sumOfAllPlayers2 addWithPaymentsOf:aTournamentPlayer];
   
   while ( (i > 0) && ( ([[[playersInTournament2 objectAtIndex:i-1] club]
                          caseInsensitiveCompare:aTournamentPlayer.club]
                         == NSOrderedDescending)
                       || ( ([[[playersInTournament2 objectAtIndex:i-1] club]
                              compare:[aTournamentPlayer club]] == NSOrderedSame)
                           && ([[[playersInTournament2 objectAtIndex:i-1] longName]
                                compare:[aTournamentPlayer longName]] == NSOrderedDescending) ) ) ) {
                          i--;
                       }
   [playersInTournament2 insertObject:aTournamentPlayer atIndex:i];
}

- (long) maxPlayersOnPage
{
   return 8;		// constant for now
}

- (long) totalPages;
{
   return ([playersInTournament2 count] + [self maxPlayersOnPage] - 1)
          /[self maxPlayersOnPage];
}

- (void) fetchAllPlayersAndSeries;
{
   TournamentPlayer *tourPlayer = nil;
   PGSQLConnection *database=[TournamentDelegate.shared database];
   NSString *participationsSQL = [NSString stringWithFormat:@"SELECT Licence, Series FROM PlaySeries WHERE TournamentID ='%@' ORDER BY Licence, Series", TournamentDelegate.shared.preferences.tournamentId];
   
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:participationsSQL];
   long previousLicence = 0;
   while (![rs isEOF]) {
      PGSQLRecord *participation = [rs moveNext];
      long currentLicence = [[participation fieldByName:@"Licence"] asLong];
      NSString *seriesName = [[participation fieldByName:@"Series"] asString];
      
      if (currentLicence != previousLicence) {
         if (tourPlayer != nil) {
            [self addPlayer2:tourPlayer];
         }
         previousLicence=currentLicence;
         tourPlayer = [TournamentPlayer playerWithLicence:currentLicence];
      }
      SeriesController2 *serController = [TournamentDelegate.shared seriesController];
      Series *ser = [serController seriesWithName:seriesName];
      if (ser != nil) {
         [tourPlayer add:ser];
      } else {
         NSLog(@"%@ nicht gefunden fuer %ld", seriesName, currentLicence);
      }
   }
   if (tourPlayer != nil) {
      [self addPlayer2:tourPlayer];
   }
   [playersInTournament2 addObject:sumOfAllPlayers2];
}

- (void)print:(id)sender
{
   NSPrintInfo *printInfo=[[NSPrintInfo sharedPrintInfo] copy];
   NSPrintOperation *printOperation=nil;

   [printInfo setPaperName:@"A4"];
   [printInfo setOrientation:NSPaperOrientationPortrait];
   [printInfo setLeftMargin:24.0];
   [printInfo setRightMargin:24.0];
   [printInfo setTopMargin:20.0];
   [printInfo setBottomMargin:20.0];
   printOperation=[NSPrintOperation printOperationWithView:self printInfo:printInfo];
   [printOperation setShowsPrintPanel:YES];
   // TODO: try this: [printOperation setShowsProgressPanel:YES];
   [printOperation runOperation];
}

- (BOOL)knowsPageRange:(NSRangePointer)range;
{
   range->location=1;
   range->length=[self totalPages];

   return YES;
}

- (NSRect)rectForPage:(long)pageNumber
{
   NSRect rect = NSMakeRect(0, ([self totalPages]-pageNumber)*pageHeight,
			    pageWidth, pageHeight);
   return rect;
}

@end
