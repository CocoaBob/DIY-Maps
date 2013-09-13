//
//  UINavigationBar+DropShadow.m
//
//  Created by CocoaBob on 07/17/13.
//
//
//  Inspired by UINavigationBar+JTDropShadow
//  http://ioscodesnippet.com/post/10437516225/adding-drop-shadow-on-uinavigationbar
//
//  Get the latest version from here:
//  https://github.com/CocoaBob/CBDropShadow
//
//  iOS 5.0+ and ARC are Required.
//
//  Distributed under the MIT License (MIT)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the “Software”), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "UINavigationBar+CBDropShadow.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@implementation UINavigationBar (CBDropShadow)

static char HasDroppedShadow;

- (BOOL)hasDroppedShadow {
    return [(NSNumber *)objc_getAssociatedObject(self, &HasDroppedShadow) boolValue];
}

- (void)dropShadowWithOffset:(CGSize)offset
                      radius:(CGFloat)radius
                       color:(UIColor *)color 
                     opacity:(CGFloat)opacity
                    animated:(BOOL)animated {
    if (![self hasDroppedShadow]) {
        [self willChangeValueForKey:@"hasDroppedShadow"];
        objc_setAssociatedObject(self, &HasDroppedShadow, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"hasDroppedShadow"];
        
        // Set animations
        [self.layer removeAnimationForKey:@"shadowOpacity"];
        if (animated) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
            animation.duration = 0.25f;
            [self.layer addAnimation:animation forKey:@"shadowOpacity"];
        }
        
        // Create a shadow path for better performance
        CGPathRef shadowPathRef = CGPathCreateWithRect(self.bounds, NULL);
        self.layer.shadowPath = shadowPathRef;
        CFRelease(shadowPathRef);
        
        // Update values
        self.layer.shadowColor = color.CGColor;
        self.layer.shadowOffset = offset;
        self.layer.shadowRadius = radius;
        self.layer.shadowOpacity = opacity;
        self.clipsToBounds = NO;
    }
}

- (void)hideShadowAnimated:(BOOL)animated {
    if ([self hasDroppedShadow]) {
        [self willChangeValueForKey:@"hasDroppedShadow"];
        objc_setAssociatedObject(self, &HasDroppedShadow, [NSNumber numberWithBool:NO], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"hasDroppedShadow"];
        
        // Set animations
        [self.layer removeAnimationForKey:@"shadowOpacity"];
        if (animated) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
            animation.duration = 0.25f;
            [self.layer addAnimation:animation forKey:@"shadowOpacity"];
        }
        // Update values
        self.layer.shadowOpacity = 0;
    }
}

@end