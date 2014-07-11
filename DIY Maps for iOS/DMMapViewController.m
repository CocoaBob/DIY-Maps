//
//  MapViewController.m
//  ScaleableMapView
//
//  Created by Bob on 11/15/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

#import "DMMapViewController.h"

#import "CBColorMaskedButton.h"
#import "DMMapPickerViewController.h"
#import "DMMapView.h"
#import "DMMapFile.h"

#import "CBDoubleTapAndPanGestureRecognizer.h"

#pragma mark -

@interface DMMapViewController() <UIGestureRecognizerDelegate, DMMapViewDelegate>

@property (nonatomic, strong) UINavigationController *mapPickerViewNavigationController;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation DMMapViewController

+ (void)loadMapFile:(NSString *)filePath {
    DMMapFile *mapFile = [DMMapFile mapFileWithPath:filePath];
    if (mapFile) {
        DefaultsSet(Object, kLastOpenedMapFilePath, filePath);
        [[DMMapViewController shared].cbMapView setMapFile:mapFile];
        [DMMapViewController shared].navigationItem.title = [[filePath lastPathComponent] stringByDeletingPathExtension];
    }
}

#pragma mark - Object Lifecycle

static DMMapViewController *__sharedInstance = nil;

+ (instancetype)shared {
    if (__sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __sharedInstance = [[[self class] alloc] init];
        });
    }
    
    return __sharedInstance;
}

#pragma mark Life Cycles

- (id)init {
    self = [super init];
    if (self) {
        // Full Screen Settings
        self.wantsFullScreenLayout = YES;
        if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
            self.edgesForExtendedLayout = UIRectEdgeAll;
        if ([self respondsToSelector:@selector(extendedLayoutIncludesOpaqueBars)])
            self.extendedLayoutIncludesOpaqueBars = YES;
        if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)])
            self.automaticallyAdjustsScrollViewInsets = NO;
        
        // Google Maps View
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:48.8567
                                                                longitude:2.3508
                                                                     zoom:15];
        self.gmsMapView = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
        self.gmsMapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.gmsMapView.hidden = YES;
        self.gmsMapView.accessibilityElementsHidden = NO;
        self.gmsMapView.settings.compassButton = YES;
        self.gmsMapView.settings.myLocationButton = YES;
        self.gmsMapView.settings.indoorPicker = YES;
        self.gmsMapView.settings.consumesGesturesInView = NO;
        [self.view addSubview:self.gmsMapView];

        // CB Map View
        self.cbMapView = [[DMMapView alloc] initWithFrame:self.view.bounds];
        self.cbMapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.cbMapView.hidden = NO;
        [self.view addSubview:self.cbMapView];
        
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapTapped:)];
        self.tapGestureRecognizer.numberOfTapsRequired = 1;
        self.tapGestureRecognizer.numberOfTouchesRequired = 1;
        [self.tapGestureRecognizer requireGestureRecognizerToFail:self.cbMapView.doubleTapAndPanGestureRecognizer];
        [self.view addGestureRecognizer:self.tapGestureRecognizer];
        
        CBColorMaskedButton *listButton = [[CBColorMaskedButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        [listButton setImage:[UIImage imageNamed:@"img-list"] forState:UIControlStateNormal];
        [listButton addTarget:self action:@selector(showMapPickerView:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:listButton];
        
        CBColorMaskedButton *mapButton = [[CBColorMaskedButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        [mapButton setImage:[UIImage imageNamed:@"img-layer"] forState:UIControlStateNormal];
        [mapButton addTarget:self action:@selector(toggleGoogleMaps:) forControlEvents:UIControlEventTouchUpInside];
        UILongPressGestureRecognizer *mapButtonLongPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(toggleCalibrateMode:)];
        [mapButton addGestureRecognizer:mapButtonLongPressGR];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:mapButton];
    }
    return self;
}

#pragma mark UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setTranslucent:YES];
    self.cbMapView.mapDelegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.cbMapView.mapDelegate = nil;
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - UI Control

- (void)toggleFullScreen:(BOOL)isFullScreen {
    BOOL wasFullScreen = (self.cbMapView.mapFile == nil)?YES:[[UIApplication sharedApplication] isStatusBarHidden];
    if (isFullScreen != wasFullScreen) {
        [[UIApplication sharedApplication] setStatusBarHidden:isFullScreen withAnimation:UIStatusBarAnimationFade];
        [self.navigationController setNavigationBarHidden:isFullScreen animated:YES];
    }
}

- (void)toggleUI {
    BOOL statusBarWasHidden = (self.cbMapView.mapFile == nil)?YES:[[UIApplication sharedApplication] isStatusBarHidden];// Always display toolbar no file is open
    [self toggleFullScreen:!statusBarWasHidden];
}

#pragma mark - DMMapViewDelegate

- (void)mapView:(DMMapView *)mapView willMove:(CGRect)oldVisibleMapRect {
    [self toggleFullScreen:YES];
}

- (void)mapView:(DMMapView *)mapView didMove:(CGRect)newVisibleMapRect {
    DefaultsSet(Object, kLastOpenedMapVisibleRect, NSStringFromCGRect([self.cbMapView visibleMapRect]));
}

- (void)mapView:(DMMapView *)mapView willZoom:(CGFloat)oldZoomScale {
    [self toggleFullScreen:YES];
}

- (void)mapView:(DMMapView *)mapView didZoom:(CGFloat)newZoomScale {
    [self toggleFullScreen:YES];
    DefaultsSet(Object, kLastOpenedMapVisibleRect, NSStringFromCGRect([self.cbMapView visibleMapRect]));
}

#pragma mark - Actions

- (IBAction)mapTapped:(id)sender {
    [self toggleUI];
}

- (IBAction)showMapPickerView:(id)sender {
    if (!self.mapPickerViewNavigationController) {
        self.mapPickerViewNavigationController = [[UINavigationController alloc] initWithRootViewController:[DMMapPickerViewController shared]];
    }
    self.mapPickerViewNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:self.mapPickerViewNavigationController
                       animated:YES
                     completion:nil];
}

#define FRONT_VIEW_ALPHA 0.5

- (IBAction)toggleGoogleMaps:(id)sender {
    UIView *frontView,*rearView;
    NSArray *allSubViews = [self.view subviews];
    if ([allSubViews indexOfObject:self.gmsMapView] < [allSubViews indexOfObject:self.cbMapView]) {
        frontView = self.cbMapView;
        rearView = self.gmsMapView;
    }
    else {
        frontView = self.gmsMapView;
        rearView = self.cbMapView;
    }
    [self.view bringSubviewToFront:rearView];
    
    BOOL isCalibrateMode = (frontView.alpha == FRONT_VIEW_ALPHA) || (rearView.alpha == FRONT_VIEW_ALPHA);
    if (isCalibrateMode) {
        rearView.alpha = FRONT_VIEW_ALPHA;
        frontView.alpha = 1;
    }
    else {
        rearView.hidden = NO;
        frontView.hidden = YES;
    }
}

- (IBAction)toggleCalibrateMode:(id)sender {
    UILongPressGestureRecognizer *gesture = sender;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIView *frontView,*rearView;
        NSArray *allSubViews = [self.view subviews];
        if ([allSubViews indexOfObject:self.gmsMapView] < [allSubViews indexOfObject:self.cbMapView]) {
            frontView = self.cbMapView;
            rearView = self.gmsMapView;
        }
        else {
            frontView = self.gmsMapView;
            rearView = self.cbMapView;
        }
        
        BOOL isCalibrateMode = (frontView.alpha == FRONT_VIEW_ALPHA) || (rearView.alpha == FRONT_VIEW_ALPHA);
        if (isCalibrateMode) {
            frontView.alpha = 1;
            rearView.alpha = 1;
            
            frontView.hidden = NO;
            rearView.hidden = YES;
        }
        else {
            frontView.alpha = FRONT_VIEW_ALPHA;
            rearView.alpha = 1;
            
            frontView.hidden = NO;
            rearView.hidden = NO;
        }
    }
}

@end