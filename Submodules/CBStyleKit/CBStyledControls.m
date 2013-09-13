//
//  CBStyledControls.m
//  CBStyledKit
//
//  Created by CocoaBob on 03/08/13.
//  Copyright (c) 2013 Wizzer. All rights reserved.
//

#import "CBStyledControls.h"
#import <QuartzCore/QuartzCore.h>

@implementation CBStyledLabel

- (void)customize {
    self.backgroundColor = [UIColor clearColor];
    self.font = [UIFont fontWithName:@"HelveticaNeue" size:17];
}

- (id)initWithFrame:(CGRect)aRect {
    self = [super initWithFrame:aRect];
    if (self) {
        [self customize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        [self customize];
    }
    return self;
}

@end

@implementation CBStyledTextField

- (void)customize {
    self.backgroundColor = [UIColor clearColor];
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    self.borderStyle = UITextBorderStyleNone;
    self.returnKeyType = UIReturnKeyDone;
    self.layer.borderColor = kThemeNormalColor.CGColor;
    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = 5.0f;
    self.layer.shadowColor = [UIColor clearColor].CGColor;
    self.clipsToBounds = YES;
}

- (id)init {
    self = [super init];
    if (self) {
        [self customize];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self customize];
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 5, 0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 5, 0);
}

@end

@implementation CBStyledButton

- (void)customize {
    self.backgroundColor = [UIColor clearColor];
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:15];
    self.titleLabel.shadowOffset = CGSizeZero;
    [self setTitleColor:kThemeNormalColor forState:UIControlStateNormal];
    [self setTitleColor:kThemeHighlightedColor forState:UIControlStateHighlighted];
    self.layer.borderColor = kThemeNormalColor.CGColor;
    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = 5.0f;
    self.layer.shadowColor = [UIColor clearColor].CGColor;
    self.clipsToBounds = YES;
}

- (id)init {
    self = [super init];
    if (self) {
        [self customize];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self customize];
}

@end

@interface CBStyledColorMaskedButton ()

@property (nonatomic, strong) NSMutableDictionary *maskColors;

@end

@implementation CBStyledColorMaskedButton

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupColors];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupColors];
    }
    return self;
}

- (void)setupColors {
    UIColor *defaultNormalColor = kThemeNormalColor;
    UIColor *defaultHighlightedColor = kThemeHighlightedColor;
    self.maskColors = [@{@(UIControlStateNormal):defaultNormalColor,
                       @(UIControlStateHighlighted):defaultHighlightedColor} mutableCopy];
}

- (UIColor *)maskColorForState:(UIControlState)state {
    return self.maskColors[@(state)];
}

- (void)setMaskColor:(UIColor *)color forState:(UIControlState)state {
    self.maskColors[@(state)] = color;
    [self updateMaskedImageForState:state];
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    UIImage *maskedImage = [self maskedImage:image forState:state];
    [super setImage:maskedImage forState:state];
    if (state == UIControlStateNormal) {
        if ([self imageForState:UIControlStateHighlighted] == maskedImage) {
            [super setImage:[self maskedImage:image forState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
        }
        if ([self imageForState:UIControlStateDisabled] == maskedImage) {
            [super setImage:[self maskedImage:image forState:UIControlStateDisabled] forState:UIControlStateDisabled];
        }
        if ([self imageForState:UIControlStateSelected] == maskedImage) {
            [super setImage:[self maskedImage:image forState:UIControlStateSelected] forState:UIControlStateSelected];
        }
    }
}

- (UIImage *)maskedImage:(UIImage *)sourceImage forState:(UIControlState)state {
    UIImage *maskedImage = nil;
    UIColor *maskColor = self.maskColors[@(state)];
    if (sourceImage && maskColor) {
        CGSize imageSize = sourceImage.size;
        CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, [UIScreen mainScreen].scale);
        [maskColor setFill];
        CGContextFillRect(UIGraphicsGetCurrentContext(), imageRect);
        [sourceImage drawInRect:imageRect blendMode:kCGBlendModeDestinationIn alpha:1.0f];
        maskedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return maskedImage;
}

- (void)updateMaskedImageForState:(UIControlState)state {
    [self setImage:[self imageForState:state] forState:state];
}

@end