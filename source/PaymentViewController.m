//
//  PaymentViewController.m
//  Tournament
//
//  Created by Paul Trunz on Fri Feb 15 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "PaymentViewController.h"
#import "PaymentView.h"


@implementation PaymentViewController

- (instancetype)init;
{
   self=[super init];
   paymentWindow=nil;
   scrollView=nil;
   _paymentView=[[PaymentView alloc] initWithFrame:NSMakeRect(0,0,1,1)];
   // needs to have *some* size in order to be shown ...
   return self;
}

- (void)show:sender;
{
   if (paymentWindow == nil) {
      [[NSBundle mainBundle] loadNibNamed:@"PaymentView" owner:self topLevelObjects:nil];
      [_paymentView fetchAllPlayersAndSeries];
      [scrollView setHasVerticalScroller:YES];
      [scrollView setHasHorizontalScroller:YES];
      [scrollView setDocumentView:_paymentView];
      [scrollView setNeedsDisplay:YES];
   }
   [_paymentView setNeedsDisplay:YES];
   [paymentWindow makeKeyAndOrderFront:sender];
}

- (void)print:sender;
{
   [_paymentView print:sender];
}

- (BOOL)acceptsFirstResponder;
{
   return YES;
}

@end
