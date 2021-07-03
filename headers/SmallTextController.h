
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

@interface SmallTextController:NSObject
{
    NSTextView *text;
    NSWindow *window;
    long titleLength;
    NSDictionary *titleAttributes;
    NSMutableDictionary *textAttributes;
}

- init;
- (IBAction)showWindow:(id)sender;
- (IBAction)print:(id)sender;
- (void)clearText;
- (NSString *)pureText;
- (void)setTitleText:(NSString *)aString;
- (void)appendText:(NSString *)aString;
- (void)appendAttributed:(NSAttributedString *)string;

@end
