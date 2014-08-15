//
//  AppDelegate.m
//  ScaleableMapView
//
//  Created by Bob on 11/9/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

#import "DMAppDelegate.h"

#import "DMMapPickerViewController.h"
#import "DMMapViewController.h"
#import "CBStyleKit.h"
#import "DMMapView.h"

#import "NSURL+SBRXCallbackURL.h"
#import "SBRCallbackParser.h"

@implementation DMAppDelegate

+ (DMAppDelegate *)shared {
	return (DMAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSLog(@"====================");
	NSLog(@"%@ Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
	NSLog(@"Document path: %@",[DMFileManager docPath]);
	NSLog(@"====================");
    
    // x-callback-url
    SBRCallbackParser *parser = [SBRCallbackParser sharedParser];
    [parser setURLScheme:@"diymapsapp"];
    [parser addHandlerForActionName:@"pickmap"
                       handlerBlock:^BOOL(NSDictionary *parameters,
                                          NSString *source,
                                          SBRCallbackActionHandlerCompletionBlock completion) {
                           [[DMAppDelegate shared] handleURLWithAction:@"pickmap"
                                                                params:parameters];
                           completion(nil, nil, NO);
                           return YES;
                       }];
    
    // Google Maps SDK
    [GMSServices provideAPIKey:kGoogleMapsAPIKey];
    
    // Import inbox
    [DMFileManager importInbox];
    
    // Theme
    [CBStyleKit setStyleIOS7];
    
    // Open the last opened map
    NSString *lastOpenedMapPath = DefaultsGet(object, kLastOpenedMapFilePath);
    if (lastOpenedMapPath) {
        [DMMapViewController loadMapFile:lastOpenedMapPath];
        CGRect lastVisibleRect = CGRectFromString(DefaultsGet(object, kLastOpenedMapVisibleRect));
        if (!CGRectEqualToRect(lastVisibleRect, CGRectZero)) {
            [[DMMapViewController shared].cbMapView zoomToRect:lastVisibleRect animated:NO];
        }
    }
    
    // Display the UI
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[DMMapViewController shared]];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    [DMFileManager importInbox];
    
    if (![[SBRCallbackParser sharedParser] handleURL:url]) {
        [[DMAppDelegate shared] handleURLWithAction:url.host
                                             params:url.sbr_queryParameters];
    }
    return YES;
}

- (void)handleURLWithAction:(NSString *)action params:(NSDictionary *)params {
    if ([@"pickmap" isEqualToString:action]) {
        if ([DMMapViewController shared].presentedViewController) {
            [[DMMapViewController shared] dismissViewControllerAnimated:NO completion:nil];
        }
        NSString *fileName = params[@"filename"];
        NSString *filePath = [[DMFileManager docPath] stringByAppendingPathComponent:fileName];
        [DMMapViewController loadMapFile:filePath];
        DefaultsSet(Object, kLastOpenedMapVisibleRect, NSStringFromCGRect([[DMMapViewController shared].cbMapView visibleMapRect]));
    }
}

@end
