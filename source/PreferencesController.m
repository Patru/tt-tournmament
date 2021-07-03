
#import "PreferencesController.h"
#import "Tournament-Swift.h"

@implementation PreferencesController
static NSString *SMALL_PAPER_LANDSCAPE = @"TourA6PaperLandscape";
static NSString *SMALL_PAPER_PORTRAIT = @"TourA6PaperPortrait";
static NSString *DATE_OF_SERIES_FOR_EXPORT = @"TourDateOfSeriesForExport";
static NSString *DATE_FROM = @"TourDateFrom";
static NSString *DATE_TO = @"TourDateTo";
static NSString *REGION = @"TourRegion";
static NSString *TYPE = @"TourType";
static NSString *NUM_MATCH_PORTRAIT = @"TourNumMatchPortrait";
static NSString *NUM_MATCH_LANDSCAPE = @"TourNumMatchLandscape";
static NSString *MATCH_WIDTH_PORTRAIT = @"TourMatchWidthPortrait";
static NSString *MATCH_WIDTH_LANDSCAPE = @"TourMatchWidthLandscape";
static NSString *FIRST_WIDTH_PORTRAIT = @"TourFirstWidthPortrait";
static NSString *FIRST_WIDTH_LANDSCAPE = @"TourFirstWidthLandscape";
static NSString *TABLE_PORTRAIT = @"TourTablePortrait";
static NSString *TABLE_LANDSCAPE = @"TourTableLandscape";
static NSDateFormatter *CLICK_TT_DATE = nil;
const float longPageSize = 792.0;
const float shortPageSize = 520.0;

- init;
{
   commercialImage = nil;

   return self;
} // init

- (NSString *)tourTitle;
{
   return [[TournamentDelegate.shared tournament] title];
} // tourTitle

- (NSString *)tourDate;
{
   return [[TournamentDelegate.shared tournament] dateRange];
} // tourDate

- (NSString *)subTitle;
{
   return [[TournamentDelegate.shared tournament] subtitle];
} // subTitle

- (NSString *)referee;
{
   return [[TournamentDelegate.shared tournament] referee];
} // referee

- (NSString *)associations;
{
   return [[TournamentDelegate.shared tournament] associations];
} // associations

- (NSString *)uploadCommand;
{
   return [[TournamentDelegate.shared tournament] upload];
}

- (float)matchWidth;
{
	if ([self landscape]) {
		return [matchWidthLandscape floatValue];
	} else {
		return [matchWidthPortrait floatValue];
	}
}

- (float)firstWidth;
{
	if ([self landscape]) {
		return [firstWidthLandscape floatValue];
	} else {
		return [firstWidthPortrait floatValue];
	}
}

- (NSInteger) matchesLandscape;
{
	if ([matchesLandscape intValue] > 0) {
		return [matchesLandscape intValue];
	} else {
		return 19; // this is most certainly not the value you want, but with 0 you will get ... nothing at all
	}
}

- (NSInteger) matchesPortrait;
{
	if ([matchesPortrait intValue] > 0) {
		return [matchesPortrait intValue];
	} else {
		return 19; // this is most certainly not the value you want, but with 0 you will get ... nothing at all
	}
}

- (float) lineDelta;
{
	if ([self landscape]) {
		return 36.0*12.0/[self matchesLandscape];
	} else {
		return 58.0*12.0/[self matchesPortrait];
	}
}

- (BOOL)groupLetters;
{
   return [groupLetters intValue] == 1;
} // groupLetters

- (BOOL)printImmediately;
{
   return [printImmediately intValue] == 1;
} // printImmediately

- (BOOL)tourNumbers;
{
   return ([tourNumbers intValue] == 1);
} // tourNumbers

+ (NSDateFormatter *)clickTTFormat;
{
   if (CLICK_TT_DATE == nil) {
      CLICK_TT_DATE = [[NSDateFormatter alloc] init];
      [CLICK_TT_DATE setDateFormat: @"yyyy-MM-dd"];
   }
   
   return CLICK_TT_DATE;
}

- (BOOL)exactResults;
{
   return ([exactResults intValue] == 1);
} // exactResults

- (BOOL)umpires;
{
   return ([umpires intValue] == 1);
} // umpires

- (BOOL)landscape;
{
   return ([landscape intValue] == 1);
} // landscape

- (BOOL)otherMatches;
{
   return ([otherMatches intValue] == 1);
} // otherMatches

- (BOOL)groupDetails;
{
   return ([groupDetails intValue] == 1);
} // otherMatches

- (int) startDepot;
   /* amount of depot for starting number */
{
   return [startDepot intValue];
} // startDepot

- (NSString *) tournamentIdClickTt;
{
	return [tournamentIdClickTt stringValue];
}

- (NSString *) dateOfSeriesForExport;
{
   return [[PreferencesController clickTTFormat] stringFromDate:TournamentDelegate.shared.tournament.dateForExport];
}

- (NSString *) dateFrom
{
   return [[PreferencesController clickTTFormat] stringFromDate:[[TournamentDelegate.shared tournament] dateFrom]]
;
}

- (NSString *) dateTo;
{
	return [[PreferencesController clickTTFormat] stringFromDate:[[TournamentDelegate.shared tournament] dateTo]];
}

- (NSString *) region;
{
	return [[TournamentDelegate.shared tournament] region];
}

- (NSString *) type;
{
	return [[TournamentDelegate.shared tournament] type];
}

- (IBAction) revert:(id)sender;
{
	NSString *s;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
//	s = [defaults stringForKey:@"TourTitle"];
//	if (s != nil) {
//		[tourTitle setStringValue:s];
//	} // if
//	
//	s = [defaults stringForKey:@"TourSubTitle"];
//	if (s != nil) {
//		[subTitle setStringValue:s];
//	} // if
//	
//	s = [defaults stringForKey:@"TourDate"];
//	if (s != nil) {
//		[tourDate setStringValue:s];
//	} // if
//	
//	s = [defaults stringForKey:@"TourChiefUmpire"];
//	if (s != nil) {
//		[referee setStringValue:s];
//	} // if
//	
//	s = [defaults stringForKey:@"TourAssociations"];
//	if (s != nil) {
//		[associations setStringValue:s];
//	} // if
//	
//	s = [defaults stringForKey:@"TourUploadCommand"];
//	if (s != nil) {
//		[uploadCommand setStringValue:s];
//	} // if
		
	s = [defaults stringForKey:FIRST_WIDTH_PORTRAIT];
	if (s != nil) {
		[firstWidthPortrait setStringValue:s];
	}
	
	s = [defaults stringForKey:FIRST_WIDTH_LANDSCAPE];
	if (s != nil) {
		[firstWidthLandscape setStringValue:s];
	}
	
//	s = [defaults stringForKey:@"TourCommercial"];
//	if (s != nil) {
//		[commercial setStringValue:s];
//	} // if
	
	if ([defaults boolForKey:@"TourGroupLetters"]) {
		[groupLetters setIntValue:1];
	} else {
		[groupLetters setIntValue:0];
	} // if
	
	if ([defaults boolForKey:@"TourPrintImmediately"]) {
		[printImmediately setIntValue:1];
	} else {
		[printImmediately setIntValue:0];
	} // if
	
   [tournaments removeObjects:[tournaments arrangedObjects]];
   [tournaments addObjects:[Tournament all]];

	s = [defaults stringForKey:@"TournamentID"];
	if (s != nil) {
//		[tournamentID setStringValue:s];
      
      __block long index = 0;
      [[tournaments arrangedObjects] enumerateObjectsUsingBlock:^(Tournament *tour, NSUInteger idx, BOOL *stop) {
         if ([[tour id] isEqualToString:s]) {
            index = idx;
            *stop = true;
         }
      }];
      [tournaments setSelectionIndex:index];
	} // if
	
	NSData *data = [defaults objectForKey:SMALL_PAPER_LANDSCAPE];
	if (data != nil) {
		NSDictionary *dict = [NSUnarchiver unarchiveObjectWithData:data];
		smallPaperLandscape = [[NSPrintInfo alloc] initWithDictionary:dict];
      [self visualizePaperSize:smallPaperLandscape in:smallPaperLandscapeText];
	}
	
	data = [defaults objectForKey:SMALL_PAPER_PORTRAIT];
	if (data != nil) {
		NSDictionary *dict = [NSUnarchiver unarchiveObjectWithData:data];
		smallPaperPortrait = [[NSPrintInfo alloc] initWithDictionary:dict];
      [self visualizePaperSize:smallPaperPortrait in:smallPaperPortraitText];
	}
	
	[tourNumbers setIntValue:[defaults boolForKey:@"TourNumbers"]];
	[exactResults setIntValue:[defaults boolForKey:@"TourExactResults"]];
//	[umpires setIntValue:[defaults boolForKey:@"TourUmpires"]];
	[landscape setIntValue:[defaults boolForKey:@"TourLandscape"]];
	[otherMatches setIntValue:[defaults boolForKey:@"TourOtherMatches"]];
	[groupDetails setIntValue:[defaults boolForKey:@"TourGroupDetails"]];
	
	s = [defaults stringForKey:@"TourStartDepot"];
	if (s != nil) {
		[startDepot setStringValue:s];
	} // if
		
	s=[defaults stringForKey:DATE_OF_SERIES_FOR_EXPORT];
	if (s != nil) {
		[dateOfSeriesForExport setStringValue:s];
	}
	
	s=[defaults stringForKey:DATE_FROM];
	if (s != nil) {
		[dateFrom setStringValue:s];
	}
	
	s=[defaults stringForKey:DATE_TO];
	if (s != nil) {
		[dateTo setStringValue:s];
	}
	
	s=[defaults stringForKey:REGION];
	if (s != nil) {
		[region setStringValue:s];
	}
	
	s=[defaults stringForKey:TYPE];
	if (s != nil) {
		[type setStringValue:s];
	}
	
	[matchesPortrait setIntValue:(int)[defaults integerForKey:NUM_MATCH_PORTRAIT]];
	[matchesLandscape setIntValue:(int)[defaults integerForKey:NUM_MATCH_LANDSCAPE]];
	[matchWidthPortrait setFloatValue:[defaults floatForKey:MATCH_WIDTH_PORTRAIT]];
	if ([matchesPortrait floatValue] == 0.0) {
		[matchWidthPortrait setIntValue:(int)[defaults integerForKey:@"TourGameWidth"]];
	}
	[matchWidthLandscape setFloatValue:[defaults floatForKey:MATCH_WIDTH_LANDSCAPE]];
	if ([matchesLandscape floatValue] == 0.0) {
		[matchWidthLandscape setIntValue:(int)[defaults integerForKey:@"TourGameWidth"]];
	}
	[firstWidthPortrait setFloatValue:[defaults floatForKey:FIRST_WIDTH_PORTRAIT]];
	[firstWidthLandscape setFloatValue:[defaults floatForKey:FIRST_WIDTH_LANDSCAPE]];
	[tablePortrait setIntValue:(int)[defaults integerForKey:TABLE_PORTRAIT]];
	[tableLandscape setIntValue:(int)[defaults integerForKey:TABLE_LANDSCAPE]];
} // revert

- (IBAction) save:(id)sender;
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
//	[defaults setObject:[tourTitle stringValue] forKey:@"TourTitle"];
//	[defaults setObject:[subTitle stringValue] forKey:@"TourSubTitle"];
//	[defaults setObject:[tourDate stringValue] forKey:@"TourDate"];
	[defaults setObject:[firstWidthPortrait stringValue] forKey:FIRST_WIDTH_PORTRAIT];
	[defaults setObject:[firstWidthLandscape stringValue] forKey:FIRST_WIDTH_LANDSCAPE];
//	[defaults setObject:[startDepot stringValue] forKey:@"TourStartDepot"];
//	[defaults setObject:[commercial stringValue] forKey:@"TourCommercial"];
//	[defaults setObject:[referee stringValue] forKey:@"TourChiefUmpire"];
//	[defaults setObject:[associations stringValue] forKey:@"TourAssociations"];
	[defaults setObject:[uploadCommand stringValue] forKey:@"TourUploadCommand"];
	[defaults setBool:[printImmediately intValue] forKey:@"TourPrintImmediately"];
	[defaults setBool:[groupLetters intValue] forKey:@"TourGroupLetters"];
	[defaults setBool:[tourNumbers intValue] forKey:@"TourNumbers"];
	[defaults setBool:[exactResults intValue] forKey:@"TourExactResults"];
	[defaults setBool:[umpires intValue] forKey:@"TourUmpires"];
	[defaults setBool:[landscape intValue] forKey:@"TourLandscape"];
	[defaults setBool:[groupDetails intValue] forKey:@"TourGroupDetails"];
	[defaults setBool:[otherMatches intValue] forKey:@"TourOtherMatches"];
//	[defaults setObject:[startDepot stringValue] forKey:@"TourStartDepot"];
	[defaults setObject:[[tournaments selectedObjects][0] id] forKey:@"TournamentID"];
	NSData *data = [NSArchiver archivedDataWithRootObject:[smallPaperLandscape dictionary]];
	[defaults setObject:data forKey:SMALL_PAPER_LANDSCAPE];
	data = [NSArchiver archivedDataWithRootObject:[smallPaperPortrait dictionary]];
	[defaults setObject:data forKey:SMALL_PAPER_PORTRAIT];
//	[defaults setObject:[dateOfSeriesForExport stringValue] forKey:DATE_OF_SERIES_FOR_EXPORT];
//	[defaults setObject:[dateFrom stringValue] forKey:DATE_FROM];
//	[defaults setObject:[dateTo stringValue] forKey:DATE_TO];
//	[defaults setObject:[region stringValue] forKey:REGION];
//	[defaults setObject:[type stringValue] forKey:TYPE];
//	[defaults setInteger:[matchesPortrait intValue] forKey:NUM_MATCH_PORTRAIT];
//	[defaults setInteger:[matchesLandscape intValue] forKey:NUM_MATCH_LANDSCAPE];
//	[defaults setFloat:[matchWidthPortrait floatValue] forKey:MATCH_WIDTH_PORTRAIT];
//	[defaults setFloat:[matchWidthLandscape floatValue] forKey:MATCH_WIDTH_LANDSCAPE];
	[defaults setInteger:[tablePortrait intValue] forKey:TABLE_PORTRAIT];
	[defaults setInteger:[tableLandscape intValue] forKey:TABLE_LANDSCAPE];
}

- (IBAction) setCommercialField:(id)sender;
{
   NSOpenPanel *panel = [NSOpenPanel openPanel];

   [panel setAllowedFileTypes:NSImage.imageTypes];

   [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
      if (result == NSFileHandlingPanelOKButton) {
         
         [commercial setStringValue:[[[panel URLs] objectAtIndex:0] path]];
         commercialImage = nil;
      }
   }];
}

- (NSImage *)  commercialImage;
{
   if(commercialImage == nil) {
      commercialImage = [[NSImage alloc]
               initWithContentsOfFile:[self commercial]];
//      [commercialImage setScalesWhenResized:YES];
      [self sizeCommercial];
   } // if
   
   return commercialImage;
}

- (void)sizeCommercial;
// sizes the commercial NXImage to the space available
{  NSSize  commercialSize, actualSize;

   commercialSize.width = 180;
   commercialSize.height = 80;
   actualSize = [commercialImage size];
   if(actualSize.width/actualSize.height >
      commercialSize.width/commercialSize.height){
      commercialSize.height = commercialSize.width/actualSize.width
                              * actualSize.height;
   } else {
      commercialSize.width = commercialSize.height/actualSize.height
                             * actualSize.width;
   }
   [commercialImage setSize:commercialSize];

}// sizeCommercial

- (NSString *) tournamentID;
{
   return [[tournaments selectedObjects][0] id];
}

- (NSPrintInfo *)smallPaperLandscape; {
	return smallPaperLandscape;
}

- (void)visualizePaperSize:(NSPrintInfo *)paperSize in:(NSTextField *)textField;
{
   NSString *name = [NSString stringWithFormat:@"%@:%ld (%@)", [paperSize paperName], (long)[paperSize orientation], [[paperSize printer] name]];
   [textField setStringValue:name];
}

- (void)setSmallPaperLandscape:(id)sender;
{
	NSPageLayout *pageLayout = [NSPageLayout pageLayout];

	if (smallPaperLandscape == nil) {
		smallPaperLandscape = [[NSPrintInfo sharedPrintInfo] copy];
	}
	
   [pageLayout beginSheetWithPrintInfo:smallPaperLandscape modalForWindow:self.view.window delegate:self didEndSelector:@selector(landscapeDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)landscapeDidEnd:(NSPageLayout *)pageLayout returnCode:(int)returnCode  contextInfo: (void *)contextInfo;
{
   if (returnCode == NSModalResponseOK) {
      smallPaperLandscape = pageLayout.printInfo;
      [smallPaperLandscape setVerticalPagination:NSFitPagination];
      [smallPaperLandscape setHorizontalPagination:NSFitPagination];
      [smallPaperLandscape setHorizontallyCentered:NO];
      [smallPaperLandscape setVerticallyCentered:NO];
      [smallPaperLandscape setLeftMargin:1.0];
      [smallPaperLandscape setRightMargin:22.0];
      [smallPaperLandscape setTopMargin:1.0];
      [smallPaperLandscape setBottomMargin:1.0];
      [self visualizePaperSize:smallPaperLandscape in:smallPaperLandscapeText];
   }
}

- (NSPrintInfo *)smallPaperPortrait; {
	return smallPaperPortrait;
}

- (void)setSmallPaperPortrait:(id)sender;
{
	if (smallPaperPortrait == nil) {
		smallPaperPortrait = [[NSPrintInfo sharedPrintInfo] copy];
	}
	
	NSPageLayout *pageLayout = [NSPageLayout pageLayout];
   [pageLayout beginSheetWithPrintInfo:smallPaperPortrait modalForWindow:self.view.window delegate:self didEndSelector:@selector(portraitDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)portraitDidEnd:(NSPageLayout *)pageLayout returnCode:(int)returnCode  contextInfo: (void *)contextInfo;
{
   if (returnCode == NSModalResponseOK) {
      smallPaperPortrait=pageLayout.printInfo;
      [smallPaperPortrait setVerticalPagination:NSFitPagination];
      [smallPaperPortrait setHorizontalPagination:NSFitPagination];
      [smallPaperPortrait setHorizontallyCentered:NO];
      [smallPaperPortrait setVerticallyCentered:NO];
      [smallPaperPortrait setLeftMargin:5.0];
      [smallPaperPortrait setRightMargin:5.0];
      [smallPaperPortrait setTopMargin:1.0];
      [smallPaperPortrait setBottomMargin:19.0];
      [self visualizePaperSize:smallPaperPortrait in:smallPaperPortraitText];
   }
}

- (double) pageWidth;
{
	if ([self landscape]) {
		return longPageSize;
	} else {
		return shortPageSize;
	}
}

- (double) pageHeight;
{
	if ([self landscape]) {
		return shortPageSize;
	} else {
		return longPageSize;
	}
}

- (NSInteger) maxMatchOnPage;
{
	if ([self landscape]) {
		return [self matchesLandscape];
	} else {
		return [self matchesPortrait];
	}
}

- (NSString *) tableString;
{
	if ([self landscape]) {
		return [tableLandscape stringValue];
	} else {
		return [tablePortrait stringValue];
	}
}

- (NSInteger) maxGroupsOnPage;
{
	if ([self landscape]) {
		return 14;
	} else {
		return 22;
	}
}

- (void)viewDidAppear;
{
   // strange that we have to do this in a view delegate, somehow the IB-settings get "overwritten"
   self.view.window.frameAutosaveName = @"TourPreferences";
}

@end
