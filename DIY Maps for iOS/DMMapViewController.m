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

@interface DMMapViewController() <UIGestureRecognizerDelegate>

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
        [self.view addSubview:self.gmsMapView];

        // CB Map View
        self.cbMapView = [[DMMapView alloc] initWithFrame:self.view.bounds];
        self.cbMapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.cbMapView.hidden = NO;
        [self.view addSubview:self.cbMapView];
        
        [self.cbMapView addObserver:self forKeyPath:@"visibleMapRect" options:0 context:NULL];
        
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
        [mapButton setImage:[UIImage imageNamed:@"img-eye"] forState:UIControlStateNormal];
        [mapButton addTarget:self action:@selector(toggleGoogleMaps:) forControlEvents:UIControlEventTouchUpInside];
        UILongPressGestureRecognizer *mapButtonLongPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(activeCalibrateMode:)];
        [mapButton addGestureRecognizer:mapButtonLongPressGR];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:mapButton];
    }
    return self;
}

- (void)dealloc {
    [self.cbMapView removeObserver:self forKeyPath:@"visibleMapRect"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"visibleMapRect"]) {
        DefaultsSet(Object, kLastOpenedMapVisibleRect, NSStringFromCGRect([self.cbMapView visibleMapRect]));
    }
}

#pragma mark UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setTranslucent:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark -

- (void)toggleUI {
    BOOL statusBarWasHidden = (self.cbMapView.mapFile == nil)?YES:[[UIApplication sharedApplication] isStatusBarHidden];// Always display toolbar no file is open
    [[UIApplication sharedApplication] setStatusBarHidden:!statusBarWasHidden withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:!statusBarWasHidden animated:YES];
}

#pragma mark Actions

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

- (IBAction)toggleGoogleMaps:(id)sender {
    UIView *invisibleMapView = (!self.gmsMapView.isHidden)?self.gmsMapView:self.cbMapView;
    UIView *visibleMapView = (invisibleMapView == self.gmsMapView)?self.cbMapView:self.gmsMapView;
    
    visibleMapView.hidden = invisibleMapView.hidden = NO;
    [self.view bringSubviewToFront:visibleMapView];
    
    if (self.gmsMapView.alpha == 0.5) {
        self.gmsMapView.alpha = 1;
        self.cbMapView.alpha = 0.5;
    }
    else {
        visibleMapView.alpha = 0;
        invisibleMapView.alpha = 1;
    }
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         visibleMapView.alpha = 1;
                     }
                     completion:^(BOOL finished) {
                         visibleMapView.hidden = NO;
                         invisibleMapView.hidden = YES;
                     }];
}

- (IBAction)activeCalibrateMode:(id)sender {
    if (self.cbMapView.isHidden) {
        self.cbMapView.hidden = NO;
        self.cbMapView.alpha = 0;
    }
    if (self.gmsMapView.isHidden) {
        self.gmsMapView.hidden = NO;
        self.gmsMapView.alpha = 0;
    }
    [self.view bringSubviewToFront:self.gmsMapView];
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.cbMapView.alpha = 1;
                         self.gmsMapView.alpha = 0.5;
                     }];
}

@end