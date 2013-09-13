//
//  ScaleableMapView.h
//  ScaleableMapView
//
//  Created by Bob on 11/9/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CBMapFile.h"

@class CBMapView;

typedef double CBLocationDegrees;

typedef struct {
    CBLocationDegrees latitude;
    CBLocationDegrees longitude;
} CBLocationCoordinate2D;

CG_INLINE CBLocationCoordinate2D CBLocationCoordinate2DMake(CBLocationDegrees latitude, CBLocationDegrees longitude) {
    CBLocationCoordinate2D l; l.latitude = latitude; l.longitude = longitude; return l;
}

typedef struct {
    CBLocationDegrees latitudeDelta;
    CBLocationDegrees longitudeDelta;
} CBCoordinateSpan;

typedef struct {
	CBLocationCoordinate2D center;
	CBCoordinateSpan span;
} CBCoordinateRegion;

@protocol CBAnnotation <NSObject,NSCopying>
@optional
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@required
@property (nonatomic, assign) CBLocationCoordinate2D coordinate;
@property (nonatomic, assign) CGPoint position;//Relative position to the width/height of the map, 0.000000f-1.000000f.
@end

#pragma mark -

@interface CBAnnotationView : UIImageView

@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic) BOOL canShowCallout;
@property (strong, nonatomic) UIView *leftCalloutAccessoryView;
@property (strong, nonatomic) UIView *rightCalloutAccessoryView;
@property (nonatomic) CGPoint centerOffset;
@property (nonatomic) CGPoint calloutOffset;
@property (nonatomic, readonly) NSString *reuseIdentifier;
@property (nonatomic, strong) id <CBAnnotation> annotation;

- (id)initWithImage:(UIImage *)image annotation:(id <CBAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
- (void)prepareForReuse;

@end

#pragma mark -

@protocol CBMapViewDelegate <NSObject>
@optional
- (void)mapView:(CBMapView *)mapView annotationView:(CBAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
- (CBAnnotationView *)mapView:(CBMapView *)mapView viewForAnnotation:(id <CBAnnotation>)annotation;
@end

#pragma mark -

@class CBDoubleTapAndPanGestureRecognizer;

@interface CBMapView : UIView

@property (nonatomic, strong) CBMapFile *mapFile;

@property (nonatomic, weak) id<CBMapViewDelegate> delegate;

@property ( nonatomic, getter=isZoomEnabled) BOOL zoomEnabled;
@property ( nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;

@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, strong) CBDoubleTapAndPanGestureRecognizer *doubleTapAndPanGestureRecognizer;

- (void)setRegion:(CBCoordinateRegion)region animated:(BOOL)animated;
- (void)setCenterCoordinate:(CBLocationCoordinate2D)coordinate animated:(BOOL)animated;
- (void)zoomToRect:(CGRect)mapRect animated:(BOOL)animate;
- (CGRect)visibleMapRect;

@end

@interface CBMapView (MapAnnotations)

- (CBAnnotationView *)dequeueReusableAnnotationViewWithIdentifier:(NSString *)identifier;
- (void)selectAnnotation:(id <CBAnnotation>)annotation animated:(BOOL)animated;
- (void)deselectAnnotation:(id <CBAnnotation>)annotation animated:(BOOL)animated;
@property (nonatomic, copy) NSArray *selectedAnnotations;

- (void)addAnnotation:(id <CBAnnotation>)annotation;
- (void)addAnnotations:(NSArray *)annotations;
- (void)removeAnnotation:(id <CBAnnotation>)annotation;
- (void)removeAnnotations:(NSArray *)annotations;
@property (nonatomic, readonly) NSArray *annotations;

@end