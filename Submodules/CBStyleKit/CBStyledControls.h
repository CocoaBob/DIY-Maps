//
//  CBStyledControls.h
//  CBStyledKit
//
//  Created by CocoaBob on 03/08/13.
//  Copyright (c) 2013 Wizzer. All rights reserved.
//

@interface CBStyledLabel : UILabel

@end

@interface CBStyledTextField : UITextField

@end

@interface CBStyledColorMaskedButton : UIButton

- (UIColor *)maskColorForState:(UIControlState)state;
- (void)setMaskColor:(UIColor *)color forState:(UIControlState)state;

@end

@interface CBStyledButton : UIButton

@end