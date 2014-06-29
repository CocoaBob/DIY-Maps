//
//  ScaleableMapView.h
//  ScaleableMapView
//
//  Created by Bob on 11/9/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class DMMapView;

@protocol DMMapViewDelegate <NSObject>

- (void)mapView:(DMMapView *)mapView willMove:(CGRect)oldVisibleMapRect;
- (void)mapView:(DMMapView *)mapView didMove:(CGRect)newVisibleMapRect;
- (void)mapView:(DMMapView *)mapView willZoom:(CGFloat)oldZoomScale;
- (void)mapView:(DMMapView *)mapView didZoom:(CGFloat)newZoomScale;

@end

@class DMMapFile;
@class CBDoubleTapAndPanGestureRecognizer;

@interface DMMapView : UIScrollView

@property (nonatomic, weak) id<DMMapViewDelegate> mapDelegate;

@property (nonatomic, strong) DMMapFile *mapFile;

@property ( nonatomic, getter=isZoomEnabled) BOOL zoomEnabled;
@property ( nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;

@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, strong) CBDoubleTapAndPanGestureRecognizer *doubleTapAndPanGestureRecognizer;

- (void)zoomToRect:(CGRect)mapRect animated:(BOOL)animate;
- (CGRect)visibleMapRect;

@end