//
//  CBColorMaskedButton.h
//  DIY Maps
//
//  Created by Bob on 18/07/13.
//  Copyright (c) 2013 Bob. All rights reserved.
//

@interface CBColorMaskedButton : UIButton

- (UIColor *)maskColorForState:(UIControlState)state;
- (void)setMaskColor:(UIColor *)color forState:(UIControlState)state;

@end