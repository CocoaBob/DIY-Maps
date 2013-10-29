//
//  CBActivityView.m
//  DIY Maps for iOS
//
//  Created by CocoaBob on 29/10/2013.
//  Copyright (c) 2013 Bob. All rights reserved.
//

#import "CBActivityView.h"

@interface CBActivityView ()

@property (nonatomic, strong) UIView *activityView;

@end

@implementation CBActivityView

#pragma mark - Object Lifecycle

static CBActivityView *__sharedInstance = nil;

+ (instancetype)shared {
    if (__sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __sharedInstance = [[[self class] alloc] init];
        });
    }
    
    return __sharedInstance;
}

#pragma mark -

- (UIView *)activityView {
	if (!_activityView) {
        NSUInteger activityViewSize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?160:128;
		_activityView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, activityViewSize, activityViewSize)];
        _activityView.opaque = NO;
        _activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		_activityView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
		_activityView.layer.cornerRadius = 8;
		
		UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		activityIndicator.center = _activityView.center;
        [activityIndicator startAnimating];
		[_activityView addSubview:activityIndicator];
	}
	return _activityView;
}

- (void)showActivityViewWithCompletionHandler:(void(^)(void))completionHandler {
    UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
    
    self.activityView.center = mainWindow.center;
    self.activityView.alpha = 0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainWindow addSubview:self.activityView];
        [UIView animateWithDuration:0.1f
                         animations:^{
                             self.activityView.alpha = 1;
                         }
                         completion:^(BOOL finished) {
                             if (completionHandler) {
                                 completionHandler();
                             }
                         }];
    });
}

- (void)hideActivityView {
    [UIView animateWithDuration:0.1f
                     animations:^{
                         self.activityView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self.activityView removeFromSuperview];
                     }];
}

@end
