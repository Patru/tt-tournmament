   //
//  PlaySeries.m
//  Tournament
//
//  Created by Paul Trunz on Fri Dec 28 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "PlaySeries.h"
#import <PGSQLKit/PGSQLKit.h>
#import "TournamentController.h"
#import "Tournament-Swift.h"

const struct PSFieldsStruct PSFields={
   .Series      =@"Series",
   .Pass        =@"Licence",
   .PartnerPass =@"PartnerLicence",
   .SetNumber   =@"SetNumber",
   .TournamentID=@"TournamentID"
};

@implementation PlaySeries
static NSString *allFields = nil;

+ (PlaySeries *) fromRecord:(PGSQLRecord *)record;
{
	PlaySeries *playSeries=[[PlaySeries alloc] init];

   playSeries->_pass=[[record fieldByName: PSFields.Pass] asLong];
	playSeries->_series=[[record fieldByName: PSFields.Series] asString];
	playSeries->_partnerPass=[[record fieldByName: PSFields.PartnerPass] asLong];
	playSeries->_setNumber=[[record fieldByName: PSFields.SetNumber] asLong];
	playSeries->_isNew=NO;

	return playSeries;
}

+ (NSString *) allFields;
{
   if (allFields == nil) {
      NSArray *fields = [NSArray arrayWithObjects:PSFields.Pass, PSFields.Series, PSFields.PartnerPass, PSFields.SetNumber, PSFields.TournamentID, nil];
      allFields = [fields componentsJoinedByString:@", "];
   }
   return allFields;
}

- init;
{
	_pass=0;
	_series=nil;
	_partnerPass=0;
	_setNumber=0;
	_isNew=YES;
	_isEdited=NO;

	return self;
}

- (void)storeInDatabase;
{
	if (_isNew) {
		[self insertIntoDatabase];
	} else if (_isEdited) {
		[self updateDatabase];
	}
}

- (void)insertIntoDatabase;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *insertSQL=[NSString stringWithFormat:@"INSERT INTO PlaySeries (%@) VALUES (%ld, '%@', %ld, %ld, '%@')", [PlaySeries allFields], _pass, _series, _partnerPass, _setNumber, TournamentDelegate.shared.preferences.tournamentId];
   [database execCommand:insertSQL];
   _isNew=NO;
   _isEdited=NO;
}

- (void)updateDatabase;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;

   NSString *updateSQL=[NSString stringWithFormat:@"UPDATE PlaySeries SET %@=%ld, %@=%ld WHERE %@=%ld AND %@='%@' AND %@='%@'", PSFields.PartnerPass, _partnerPass, PSFields.SetNumber, _setNumber, PSFields.Pass, _pass, PSFields.Series, _series, PSFields.TournamentID, TournamentDelegate.shared.preferences.tournamentId];

   [database execCommand:updateSQL];
   _isEdited=NO;
}

- (void)deleteFromDatabase;
{
   if (!_isNew) {
      PGSQLConnection *database=TournamentDelegate.shared.database;

      NSString *deleteSQL=[NSString stringWithFormat:@"DELETE FROM PlaySeries WHERE %@=%ld AND %@='%@' AND %@='%@'", PSFields.Pass, _pass, PSFields.Series, _series, PSFields.TournamentID, TournamentDelegate.shared.preferences.tournamentId];

      [database execCommand:deleteSQL];
   }
}

- (void)forceDelete;
{
   _isNew = NO;
   [self deleteFromDatabase];
}

- (id)objectFor:(NSString *)identifier;
{
	if ([identifier isEqualToString:PSFields.Pass]) {
		return [NSNumber numberWithLong:_pass];
	} else if ([identifier isEqualToString:PSFields.Series]) {
		return _series;
	} else if ([identifier isEqualToString:PSFields.PartnerPass]) {
		return [NSNumber numberWithLong:_partnerPass];
	} else if ([identifier isEqualToString:PSFields.SetNumber]) {
		return [NSNumber numberWithLong:_setNumber];
	} else {
		return @"dummy";
	}
}

// TODO: These two methods have to answer the same keys
- (void)setObject:(id)anObject for:(NSString *)identifier;
{
	if ([identifier isEqualToString:PSFields.Pass]) {
		_pass=[anObject longValue];
	} else if ([identifier isEqualToString:PSFields.Series]) {
		[self setSeries:anObject];
	} else if ([identifier isEqualToString:PSFields.PartnerPass]) {
		_partnerPass=[anObject longValue];
	} else if ([identifier isEqualToString:PSFields.SetNumber]) {
		_setNumber=[anObject intValue];
	}
	_isEdited=YES;
}

- (long) pass;
{
	return _pass;
}

- (void) setPass:(long)pass;
{
	_pass=pass;
}

- (void) setSeries:(NSString *)series;
{
	_series=series;
}

- (NSString *)seriesName;
{
   return _series;
}

- (void) setPartnerPass:(long)pass;
{
   _partnerPass=pass;
}

- (void) setSetNumber:(long)num;
{
   _setNumber=num;
}

@end
