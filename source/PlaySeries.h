//
//  PlaySeries.h
//  Tournament
//
//  Created by Paul Trunz on Fri Dec 28 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PGSQLRecord;

extern const char *playSeriesFieldList;

extern const struct PSFieldsStruct {
   __unsafe_unretained NSString *Pass;
   __unsafe_unretained NSString *Series;
   __unsafe_unretained NSString *PartnerPass;
   __unsafe_unretained NSString *SetNumber;
   __unsafe_unretained NSString *TournamentID;
} PSFields;

@interface PlaySeries : NSObject {
	long  _pass;
	NSString *_series;
	long  _partnerPass;
	long  _setNumber;
	BOOL _isNew;
	BOOL _isEdited;
}

+ (PlaySeries *) fromRecord:(PGSQLRecord *)record;
+ (NSString *) allFields;

- init;

- (void)storeInDatabase;
- (void)insertIntoDatabase;
- (void)updateDatabase;
- (void)deleteFromDatabase;
- (void)forceDelete;

- (id)objectFor:(NSString *)identifier;
- (void)setObject:(id)anObject for:(NSString *)identifier;

- (long) pass;
- (NSString *)seriesName;
- (void) setPass:(long)pass;
- (void) setSeries:(NSString *)series;
- (void) setPartnerPass:(long)pass;
- (void) setSetNumber:(long)pass;

@end
