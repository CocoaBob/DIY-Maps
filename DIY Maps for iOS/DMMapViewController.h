//
//  MapViewController.h
//  ScaleableMapView
//
//  Created by Bob on 11/15/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

@class CBMapView;

@interface DMMapViewController : UIViewController

@property (nonatomic, strong) UIPopoverController *mapPickerPopoverController;

+ (instancetype)shared;
+ (void)loadMapFile:(NSString *)filePath;
- (CBMapView *)mapView;

@end