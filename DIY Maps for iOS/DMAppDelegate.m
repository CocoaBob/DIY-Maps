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
#import "CBMapKit.h"

@implementation DMAppDelegate

+ (DMAppDelegate *)shared {
	return (DMAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSLog(@"====================");
	NSLog(@"%@ Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
	NSLog(@"Document path: %@",[DMFileManager docPath]);
	NSLog(@"====================");
    
    // Google Maps SDK
    [GMSServices provideAPIKey:kGoogleMapsAPIKey];
    
    // Import inbox
    [DMFileManager importInbox];
    
    // Theme
    [CBStyleKit setStyleIOS7];
    
    // Display the UI
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[DMMapViewController shared]];
    [self.window makeKeyAndVisible];
    
    // Open the last opened map
    NSString *lastOpenedMapPath = DefaultsGet(object, kLastOpenedMapFilePath);
    if (lastOpenedMapPath) {
        [DMMapViewController loadMapFile:lastOpenedMapPath];
        CGRect lastVisibleRect = CGRectFromString(DefaultsGet(object, kLastOpenedMapVisibleRect));
        if (!CGRectEqualToRect(lastVisibleRect, CGRectZero)) {
            [[DMMapViewController shared].cbMapView zoomToRect:lastVisibleRect animated:NO];
        }
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    [DMFileManager importInbox];
    return YES;
}

@end
