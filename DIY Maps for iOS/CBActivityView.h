//
//  CBActivityView.h
//  DIY Maps for iOS
//
//  Created by CocoaBob on 29/10/2013.
//  Copyright (c) 2013 Bob. All rights reserved.
//

@interface CBActivityView : NSObject

+ (instancetype)shared;

- (void)showActivityViewWithCompletionHandler:(void(^)(void))completionHandler;
- (void)hideActivityView;

@end
