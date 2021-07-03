
#import <appkit/appkit.h>

@interface PreferencesController:NSViewController
{
	IBOutlet NSTextField *	commercial;
	IBOutlet NSTextField *	subTitle;
	IBOutlet NSTextField *	tourDate;
	IBOutlet NSTextField *	tourTitle;
	IBOutlet NSTextField *  referee;
	IBOutlet NSTextField *  associations;
	IBOutlet NSTextField *  tournamentID;
	__weak IBOutlet NSButtonCell *groupLetters;
   __weak IBOutlet NSButtonCell *umpires;
	__weak IBOutlet NSButtonCell *printImmediately;
	__weak IBOutlet NSButtonCell *tourNumbers;
	__weak IBOutlet NSButtonCell *exactResults;
	__weak IBOutlet NSButtonCell *landscape;
	__weak IBOutlet NSButtonCell *otherMatches;
	__weak IBOutlet NSButtonCell *groupDetails;
	IBOutlet NSTextField *  startDepot;
	IBOutlet NSTextField * uploadCommand;
	IBOutlet NSTextField * emailAddress;
	IBOutlet NSTextField * smallPaperLandscapeText;
	IBOutlet NSTextField * smallPaperPortraitText;
	IBOutlet NSTextField * tournamentIdClickTt;
	IBOutlet NSTextField * dateFrom;
	IBOutlet NSTextField * dateTo;
	IBOutlet NSTextField * dateOfSeriesForExport;
	IBOutlet NSTextField * region;
	IBOutlet NSTextField * type;
	IBOutlet NSTextField * matchesPortrait;
	IBOutlet NSTextField * matchesLandscape;
	IBOutlet NSTextField * matchWidthPortrait;
	IBOutlet NSTextField * matchWidthLandscape;
	IBOutlet NSTextField * firstWidthPortrait;
	IBOutlet NSTextField * firstWidthLandscape;
	IBOutlet NSTextField * tablePortrait;
	IBOutlet NSTextField * tableLandscape;
   __weak IBOutlet NSPopUpButton *tournamentPopup;
	NSImage *commercialImage;
	NSPrintInfo *smallPaperLandscape;
	NSPrintInfo *smallPaperPortrait;
   IBOutlet NSArrayController *tournaments;
}

- (NSString *) tourTitle;
- (NSString *) subTitle;
- (NSString *) tourDate;
- (NSString *) commercial;
- (NSImage *)  commercialImage;
- (NSString *) referee;
- (NSString *) associations;
- (NSString *) tournamentID;
- (NSString *) uploadCommand;
- (float) matchWidth;
- (float) firstWidth;
- (float) lineDelta;
- (BOOL)groupLetters;
- (BOOL)printImmediately;
- (BOOL)tourNumbers;
- (BOOL)exactResults;
- (BOOL)umpires;
- (BOOL)landscape;
- (BOOL)otherMatches;
- (BOOL)groupDetails;
- (int) startDepot;

- (IBAction) revert:(id)sender;
- (IBAction) save:(id)sender;
- (IBAction) setCommercialField:(id)sender;
- (void)sizeCommercial;
- (IBAction)setSmallPaperLandscape:(id)sender;
- (IBAction)setSmallPaperPortrait:(id)sender;
- (NSPrintInfo *)smallPaperLandscape;
- (NSPrintInfo *)smallPaperPortrait;
- (NSString *) tournamentIdClickTt;
- (NSString *) dateOfSeriesForExport;
- (NSString *) dateFrom;
- (NSString *) dateTo;
- (NSString *) region;
- (NSString *) type;
- (double) pageWidth;
- (double) pageHeight;
- (NSInteger) maxMatchOnPage;
- (NSInteger) maxGroupsOnPage;
- (NSString *) tableString;
// private
- (NSInteger) matchesPortrait;
- (NSInteger) matchesLandscape;

@end
