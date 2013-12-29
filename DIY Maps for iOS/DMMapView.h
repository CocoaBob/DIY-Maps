//
//  ScaleableMapView.h
//  ScaleableMapView
//
//  Created by Bob on 11/9/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class DMMapFile;
@class CBDoubleTapAndPanGestureRecognizer;

@interface DMMapView : UIView

@property (nonatomic, strong) DMMapFile *mapFile;

@property ( nonatomic, getter=isZoomEnabled) BOOL zoomEnabled;
@property ( nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;

@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, strong) CBDoubleTapAndPanGestureRecognizer *doubleTapAndPanGestureRecognizer;

- (void)zoomToRect:(CGRect)mapRect animated:(BOOL)animate;
- (CGRect)visibleMapRect;

@end