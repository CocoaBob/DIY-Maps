//
//  CBStyleKit.m
//  CBStyleKit
//
//  Created by CocoaBob on 17/07/13.
//  Copyright (c) 2013 CocoaBob. All rights reserved.
//

#import "CBStyleKit.h"

@interface CBStyleKit ()

@end

@implementation CBStyleKit

+ (void)setStyleIOS7 {
    UIColor *normalColor = kThemeNormalColor;
    UIColor *highlightedColor = kThemeHighlightedColor;
    UIColor *backgroundColor = [UIColor colorWithWhite:0.973 alpha:1.0f];

    // Common background images
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), YES, 1);
    UIGraphicsPushContext(UIGraphicsGetCurrentContext());
    [backgroundColor setFill];
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 1, 1));
    UIGraphicsPopContext();
    UIImage *normalBGImage = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
	UIGraphicsEndImageContext();

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), YES, 1);
    UIGraphicsPushContext(UIGraphicsGetCurrentContext());
    [normalColor setFill];
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 1, 1));
    UIGraphicsPopContext();
    UIImage *hilitedBGImage = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
	UIGraphicsEndImageContext();

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 2), YES, 1);
    UIGraphicsPushContext(UIGraphicsGetCurrentContext());
    [backgroundColor setFill];
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 1, 1));
    [[UIColor colorWithWhite:0.776 alpha:1.0f] setFill];
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 1, 1, 1));
    UIGraphicsPopContext();
    UIImage *barBGImage = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)];
	UIGraphicsEndImageContext();

    // UINavigationBar Background
    [[UINavigationBar appearance] setBackgroundImage:barBGImage forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTintColor:backgroundColor];

    // UINavigationBar Shadow
    if ([[UINavigationBar new] respondsToSelector:@selector(shadowImage)]) {
        [[UINavigationBar appearance] setShadowImage:[UIImage new]];
    }

    // UINavigationBar Title
    [[UINavigationBar appearance] setTitleTextAttributes:[CBStyleKit attribForClr:[UIColor blackColor] size:0]];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:1 forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:0 forBarMetrics:UIBarMetricsLandscapePhone];

    // UINavigationBar Buttons
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[CBStyleKit backBtnImgWithSize:CGSizeMake(14, 30) color:normalColor] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[CBStyleKit backBtnImgWithSize:CGSizeMake(14, 30) color:highlightedColor] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, 0) forBarMetrics:UIBarMetricsDefault];

    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[CBStyleKit backBtnImgWithSize:CGSizeMake(14, 24) color:normalColor] forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[CBStyleKit backBtnImgWithSize:CGSizeMake(14, 24) color:highlightedColor] forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, 0) forBarMetrics:UIBarMetricsLandscapePhone];

    [[UIBarButtonItem appearance] setBackgroundImage:[UIImage new] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    [[UIBarButtonItem appearance] setTitleTextAttributes:[CBStyleKit attribForClr:normalColor size:14] forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:[CBStyleKit attribForClr:highlightedColor size:14] forState:UIControlStateHighlighted];

    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0, 2) forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0, 2) forBarMetrics:UIBarMetricsLandscapePhone];

    // UISearchBar
    [[UISearchBar appearance] setBackgroundImage:barBGImage];

    // UISearchBar search field
    CGRect searchBarImageRect = CGRectMake(0, 0, 36, 30);
    UIGraphicsBeginImageContextWithOptions(searchBarImageRect.size, NO, 1);
    UIGraphicsPushContext(UIGraphicsGetCurrentContext());
    [normalColor setStroke];
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 1.0);
    [[UIBezierPath bezierPathWithRoundedRect:CGRectInset(searchBarImageRect, 0.5, 0.5) cornerRadius:5] stroke];
    UIGraphicsPopContext();
    UIImage *searchFieldBackgroundImage = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(15, 18, 15, 18)];
	UIGraphicsEndImageContext();
    [[UISearchBar appearance] setSearchFieldBackgroundImage:searchFieldBackgroundImage forState:UIControlStateNormal];

    // UISearchBar buttons
//    [[UISearchBar appearance] setImage:nil forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
//    [[UISearchBar appearance] setImage:nil forSearchBarIcon:UISearchBarIconSearch state:UIControlStateHighlighted];
//    [[UISearchBar appearance] setImage:nil forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
//    [[UISearchBar appearance] setImage:nil forSearchBarIcon:UISearchBarIconClear state:UIControlStateHighlighted];
//    [[UISearchBar appearance] setImage:nil forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
//    [[UISearchBar appearance] setImage:nil forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateHighlighted];
//    [[UISearchBar appearance] setImage:nil forSearchBarIcon:UISearchBarIconResultsList state:UIControlStateNormal];
//    [[UISearchBar appearance] setImage:nil forSearchBarIcon:UISearchBarIconResultsList state:UIControlStateHighlighted];

    // UISearchBar Scope bar
    [[UISearchBar appearance] setScopeBarBackgroundImage:barBGImage];
    [[UISearchBar appearance] setScopeBarButtonBackgroundImage:normalBGImage forState:UIControlStateNormal];
    [[UISearchBar appearance] setScopeBarButtonBackgroundImage:hilitedBGImage forState:UIControlStateSelected];
    [[UISearchBar appearance] setScopeBarButtonTitleTextAttributes:[CBStyleKit mAttribForClr:normalColor] forState:UIControlStateNormal];
    [[UISearchBar appearance] setScopeBarButtonTitleTextAttributes:[CBStyleKit mAttribForClr:highlightedColor] forState:UIControlStateHighlighted];
    [[UISearchBar appearance] setScopeBarButtonDividerImage:hilitedBGImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal];
    [[UISearchBar appearance] setScopeBarButtonDividerImage:hilitedBGImage forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal];
    [[UISearchBar appearance] setScopeBarButtonDividerImage:hilitedBGImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected];

    // UISegmentedControl
    [[UISegmentedControl appearance] setBackgroundImage:normalBGImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UISegmentedControl appearance] setBackgroundImage:hilitedBGImage forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [[UISegmentedControl appearance] setDividerImage:hilitedBGImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UISegmentedControl appearance] setDividerImage:hilitedBGImage forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UISegmentedControl appearance] setDividerImage:hilitedBGImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [[UISegmentedControl appearance] setTitleTextAttributes:[CBStyleKit attribForClr:normalColor] forState:UIControlStateNormal];
    [[UISegmentedControl appearance] setTitleTextAttributes:[CBStyleKit attribForClr:highlightedColor] forState:UIControlStateHighlighted];
}

#pragma mark Utilities

// Image size must be {14,24} or {14,30}
+ (UIImage *)backBtnImgWithSize:(CGSize)imageSize color:(UIColor *)strokeColor {
    CGFloat strokeHeight = 18;
    CGFloat strokeWidth = 9;
    CGFloat drawingHeight = imageSize.height;
    CGFloat drawingWidth = imageSize.width;
    CGFloat leftMarginSize = 3;
    CGFloat verticalMarginSize = (drawingHeight - strokeHeight)/2.0;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(drawingWidth, drawingHeight), NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(ctx);
    CGMutablePathRef normalBackArrowPathRef = CGPathCreateMutable();
    CGPathMoveToPoint(normalBackArrowPathRef, NULL, leftMarginSize + strokeWidth, drawingHeight - verticalMarginSize);
    CGPathAddLineToPoint(normalBackArrowPathRef, NULL, leftMarginSize, drawingHeight / 2.0);
    CGPathAddLineToPoint(normalBackArrowPathRef, NULL, leftMarginSize + strokeWidth, verticalMarginSize);
    CGContextAddPath(ctx, normalBackArrowPathRef);
    [strokeColor setStroke];
    CGContextSetLineWidth(ctx, 3);
    CGContextStrokePath(ctx);
    UIGraphicsPopContext();
    CGPathRelease(normalBackArrowPathRef);
    UIImage *image = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(0, 13, 0, 1)];
	UIGraphicsEndImageContext();
    return image;
}

+ (NSDictionary *)attribForFnt:(UIFont *)font Clr:(UIColor *)color shdwClr:(UIColor *)shadowColor shdwOfst:(UIOffset)shadowOffset {
    return @{UITextAttributeFont:font,
             UITextAttributeTextColor:color,
             UITextAttributeTextShadowColor:shadowColor,
             UITextAttributeTextShadowOffset:[NSValue valueWithUIOffset:shadowOffset]};
}

+ (NSDictionary *)mAttribForClr:(UIColor *)color {
    return [CBStyleKit attribForFnt:[UIFont fontWithName:@"HelveticaNeue-Medium" size:0]
                                 Clr:color
                             shdwClr:[UIColor clearColor]
                            shdwOfst:UIOffsetMake(0, 0)];
}

+ (NSDictionary *)mAttribForClr:(UIColor *)color size:(CGFloat)fontSize {
    return [CBStyleKit attribForFnt:[UIFont fontWithName:@"HelveticaNeue-Medium" size:fontSize]
                                 Clr:color
                             shdwClr:[UIColor clearColor]
                            shdwOfst:UIOffsetMake(0, 0)];
}

+ (NSDictionary *)attribForClr:(UIColor *)color {
    return [CBStyleKit attribForFnt:[UIFont fontWithName:@"HelveticaNeue" size:0]
                                 Clr:color
                             shdwClr:[UIColor clearColor]
                            shdwOfst:UIOffsetMake(0, 0)];
}

+ (NSDictionary *)attribForClr:(UIColor *)color size:(CGFloat)fontSize {
    return [CBStyleKit attribForFnt:[UIFont fontWithName:@"HelveticaNeue" size:fontSize]
                                 Clr:color
                             shdwClr:[UIColor clearColor]
                            shdwOfst:UIOffsetMake(0, 0)];
}

@end

