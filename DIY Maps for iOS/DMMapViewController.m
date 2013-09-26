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
#import "CBMapKit.h"

#import "CBDoubleTapAndPanGestureRecognizer.h"

#pragma mark -

@interface DMMapViewController() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UINavigationController *mapPickerViewNavigationController;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation DMMapViewController

static DMMapViewController *sharedInstance = nil;

+ (DMMapViewController *)shared {
	@synchronized(self) {
		if (!sharedInstance)
			sharedInstance = [DMMapViewController new];
	}
	return sharedInstance;
}

+ (void)loadMapFile:(NSString *)filePath {
    CBMapFile *mapFile = [CBMapFile mapFileWithPath:filePath];
    if (mapFile) {
        DefaultsSet(Object, kLastOpenedMapFilePath, filePath);
        [[[DMMapViewController shared] mapView] setMapFile:mapFile];
        [DMMapViewController shared].navigationItem.title = [[filePath lastPathComponent] stringByDeletingPathExtension];
    }
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

        // Map View
        CBMapView *mapView = [[CBMapView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
        self.view = mapView;
        
        [[self mapView] addObserver:self forKeyPath:@"visibleMapRect" options:0 context:NULL];
        
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapTapped:)];
        self.tapGestureRecognizer.numberOfTapsRequired = 1;
        self.tapGestureRecognizer.numberOfTouchesRequired = 1;
        [self.tapGestureRecognizer requireGestureRecognizerToFail:mapView.doubleTapAndPanGestureRecognizer];
        [self.view addGestureRecognizer:self.tapGestureRecognizer];
        
        CBColorMaskedButton *listButton = [[CBColorMaskedButton alloc] initWithFrame:CGRectMake(0, 0, 36, 24)];
        [listButton setImage:[UIImage imageNamed:@"img-list"] forState:UIControlStateNormal];
        [listButton addTarget:self action:@selector(showMapPickerView:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:listButton];
    }
    return self;
}

- (void)dealloc {
    [[self mapView] removeObserver:self forKeyPath:@"visibleMapRect"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"visibleMapRect"]) {
        DefaultsSet(Object, kLastOpenedMapVisibleRect, NSStringFromCGRect([[self mapView] visibleMapRect]));
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

#pragma Properties

- (CBMapView *)mapView {
    return (CBMapView *)self.view;
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
    BOOL statusBarWasHidden = ([self mapView].mapFile == nil)?YES:[[UIApplication sharedApplication] isStatusBarHidden];// Always display toolbar no file is open
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

@end