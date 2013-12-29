//
//  MapViewController.h
//  ScaleableMapView
//
//  Created by Bob on 11/15/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

@class DMMapView;

@interface DMMapViewController : UIViewController

@property (nonatomic, strong) UIPopoverController *mapPickerPopoverController;

@property (nonatomic, strong) DMMapView *cbMapView;
@property (nonatomic, strong) GMSMapView *gmsMapView;

+ (instancetype)shared;
+ (void)loadMapFile:(NSString *)filePath;

@end