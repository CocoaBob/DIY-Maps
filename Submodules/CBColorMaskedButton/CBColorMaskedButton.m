//
//  CBColorMaskedButton.m
//  DIY Maps
//
//  Created by Bob on 18/07/13.
//  Copyright (c) 2013 Bob. All rights reserved.
//

#import "CBColorMaskedButton.h"

@interface CBColorMaskedButton ()

@property (nonatomic, strong) NSMutableDictionary *maskColors;

@end

@implementation CBColorMaskedButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIColor *defaultNormalColor = kThemeNormalColor;
        UIColor *defaultHighlightedColor = kThemeHighlightedColor;
        self.maskColors = [@{@(UIControlStateNormal):defaultNormalColor,
                           @(UIControlStateHighlighted):defaultHighlightedColor} mutableCopy];
    }
    return self;
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
