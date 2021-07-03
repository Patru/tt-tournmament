//
//  PaymentViewController.h
//  Tournament
//
//  Created by Paul Trunz on Fri Feb 15 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PaymentViewController : NSObject
{
	id  paymentWindow;
	id  scrollView;
	id _paymentView;
}

- (instancetype)init;
- (void)show:sender;
- (void)print:sender;
- (BOOL)acceptsFirstResponder;
@end
