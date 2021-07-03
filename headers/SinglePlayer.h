/*****************************************************************************
     Use: Control a table tennis tournament.
          Stores a single player, the basic resource of TT.
Language: Objective-C                 System: MacOS X
  Author: Paul Trunz, Copyright 2001
 History: 16.9.2001, Patru: started port from NeXTStep
    Bugs: -not very well documented
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "Player.h"
#import "InspectorController.h"

extern const char * playerFieldList;

@class Match;
@class PGSQLRecord;

extern const struct SPFieldsStruct {
   __unsafe_unretained NSString *Licence;
   __unsafe_unretained NSString *Name;
   __unsafe_unretained NSString *FirstName;
   __unsafe_unretained NSString *Category;
   __unsafe_unretained NSString *Club;
   __unsafe_unretained NSString *DateOfBirth;
   __unsafe_unretained NSString *Ranking;
   __unsafe_unretained NSString *WomanRanking;
   __unsafe_unretained NSString *EloPoints;
} SPFields;

@interface SinglePlayer : NSObject <Player>
{
	NSString *name;		// name of the player (that was easy, no?)
	NSString *firstName;		// really just the first name
	NSString *category;		// by age, U13, U15, U
	NSString *club;			// which club does he come from?
	NSString *dateOfBirth;	// the date as a string? lets see
	NSString *longName;		// not archived !
	NSString *shortName;		// not archived !
	NSNumber *_licence;		// licence of the player
	long     ranking;			// current ranking of the player
	float    dayRanking;		// adjusted ranking for this day
	long     womanRanking;  // 0 for men
	long     elo;
	float    persPriority;		// personal, usually 0
	NSMutableArray *openMatches;		// list of possible matches
	BOOL     ready;			// is the player ready to play?
	Match    *umpiresMatch;		// the player currently umpires this match
	BOOL     validLicence;		// valid licence in database?
   bool     _isNew;
   bool     _isEdited;
}

+ (NSString *) allFields;
+ (instancetype) fromRecord:(PGSQLRecord *)record;

// standardmethods

- init;
- (unsigned long) hash;
- (BOOL) isEqual:anObject;

// set- und get-methods

- (id)objectFor:(NSString *)identifier;
- (void)setObject:(id)anObject for:(NSString *)identifier;

- (void)setPName:(NSString *)newName;
- (void)setFirstName:(NSString *)newFirstName;
- (void)setClub:(NSString *)newClub;
- (void)setCategory:(NSString *)newCategory;
- (void)setUmpiresMatch:(Match *)aMatch;
- (void)setLicence:(long)newLicence;
- (void)setRanking:(long)newRanking;
- (void)setElo:(long)newElo;
- (void)setDayRanking:(float)newDayRanking;
- (void)adjustDayRanking:(float)adjustRanking;
- (void)setWomanRanking:(long)newWomanRanking;
- (void)setReady:(BOOL)aFlag;
- (void)setPresent:(BOOL)aFlag;
- (void)setWO:(BOOL)aFlag;
- (void)setDateOfBirth:(NSString *)date;

- (NSString *)pName;
- (NSString *)firstName;
- (NSString *)club;
- (NSString *)drawClub;
- (NSString *)description;
- (id)partner;
- (id)umpiresMatch;
- (NSString *)category;
- (long)licence;
- (NSNumber *)licenceNumber;
- (long)ranking;
- (float)dayRanking;
- (long)womanRanking;
- (long)mixedRanking;
- (long)elo;
- (float) tourPriority;
- (float)persPriority;
- (NSArray *)openMatches;
- (BOOL)ready;
- (BOOL)present;
- (BOOL)wo;
- (NSString *)sex;

- (NSDictionary*)longNameAttributes;
- (NSDictionary*)shortNameAttributes;
- (id <InspectorControllerProtocol>) inspectorController;

- (void)createLongName;
/* what: create (or follow) the unique string with name and firstName
 change: longName
*/
- (NSString *)longName;
- (void)createShortName;
/* what: initial try, just use as many letters as possible from name
 change: shortName
*/
- (void)setShortName:(NSString *)aAtom;
/* in: aAtom; the string for use as a short name, already uniqued 
 what: uses aAtom as shortName
*/
- (NSString *)shortName;
- (BOOL)uniqueShortName:(SinglePlayer *) pl;
/* In: pl; player with the same shortName as self.
 what: creates shortNames for self and for pl which differ.
       The shortName's for self and pl are set to these.
 uses: letters from firstName, club and licence if necessary.
  ret: NO if the players *are* equal, YES if distinction was possible

  caution, this function does not produce globally unique names, just the
  two names in question will not be the same when YES is returned.
  If the function is called with three players alternately, a loop is possible.
*/

- (void)storeInDatabase;
- (void)insertIntoDatabase;
- (void)updateDatabase;
- (void)appendAsHTMLRowTo:(NSMutableString *)html forSeries:(id <drawableSeries>) series;
- (void)appendPersonXmlTo:(NSMutableString *)text;

@end
