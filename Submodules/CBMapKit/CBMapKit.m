//
//  ScaleableMapView.m
//  ScaleableMapView
//
//  Created by Bob on 11/9/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

#import "CBMapKit.h"
#import "Base64.h"
#import "CBDoubleTapAndPanGestureRecognizer.h"

@interface CBAnnotationView ()

@end

@implementation CBAnnotationView

@synthesize annotation = _annotation;
@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize centerOffset = _centerOffset,calloutOffset;
@synthesize canShowCallout,enabled,selected = _selected;
@synthesize leftCalloutAccessoryView,rightCalloutAccessoryView;

- (id)initWithImage:(UIImage *)image annotation:(id <CBAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithImage:image];
    if (self) {
        [self prepareForReuse];
        self.annotation = annotation;
        _reuseIdentifier = reuseIdentifier;
    }
    return self;
}

//- (id)copyWithZone:(NSZone *)zone {
//    CBAnnotationView *copy = [[CBAnnotationView allocWithZone:zone] initWithAnnotation:self.annotation reuseIdentifier:self.reuseIdentifier];
//    copy.image = [[self.image copy] autorelease];
//    copy.leftCalloutAccessoryView = self.leftCalloutAccessoryView;
//    copy.rightCalloutAccessoryView = self.rightCalloutAccessoryView;
//    return copy;
//}

- (void)setCenterOffset:(CGPoint)centerOffset {
    _centerOffset = centerOffset;
    self.center = CGPointMake(self.center.x + self.centerOffset.x, self.center.y + self.centerOffset.y);
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:CGRectMake(frame.origin.x + self.centerOffset.x, frame.origin.y + self.centerOffset.y, frame.size.width, frame.size.height)];
}


- (void)prepareForReuse {
    self.annotation = nil;
    self.canShowCallout = YES;
    self.enabled = YES;
    self.selected = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    if (selected) {
        // Show Callout Pop-Up
    }
    else {
        // Dismiss Callout Pop-Up
    }
}

@end

#pragma mark -

@interface CBMapContentView : UIView {
    CATiledLayer *__weak tiledLayer;
}
@property (weak, nonatomic, readonly) CATiledLayer *tiledLayer;
@property (nonatomic, strong) CBMapFile *mapFile;
@end

@implementation CBMapContentView

@synthesize tiledLayer;
@synthesize mapFile;

+ (Class)layerClass {
    return [CATiledLayer class];  
}

+ (CFTimeInterval)fadeDuration {
    return 0.25f;
}


- (CATiledLayer *)tiledLayer {
    return (CATiledLayer *)self.layer;
}

- (void)didMoveToWindow {
    self.contentScaleFactor = 1.0f;//For retina displays
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    [super drawLayer:layer inContext:ctx];
    
    CGRect rect = CGRectIntegral(CGContextGetClipBoundingBox(ctx));
    CGFloat scale = CGContextGetCTM(ctx).a;
    
    CGSize tileSize = self.tiledLayer.tileSize;
    CGFloat reciprocalScale = 1 / scale;
    tileSize.width *= reciprocalScale;
    tileSize.height *= reciprocalScale;
    
    int col = floorf((CGRectGetMaxX(rect) - reciprocalScale) / tileSize.width);
    int row = floorf((CGRectGetMaxY(rect) - reciprocalScale) / tileSize.height);
    
    CGFloat adjustedScale = pow(2, nearbyint(log2(scale)));
    
    UIImage *tileImage = [self.mapFile tileImageForScale:adjustedScale indexX:col indexY:row];
    if(tileImage) {
        CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
        CGContextTranslateCTM(ctx, 0.0, rect.size.height);
        CGContextScaleCTM(ctx, 1.0, -1.0);
        rect = CGContextGetClipBoundingBox(ctx);
        CGContextDrawImage(ctx, rect, [tileImage CGImage]);
    }
}

@end

#pragma mark -

@interface CBMapScrollView : UIScrollView
@end

@implementation CBMapScrollView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = YES;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		self.scrollEnabled = YES;
		self.pagingEnabled = NO;
		self.scrollsToTop = NO;
		self.bounces = YES;
		self.alwaysBounceVertical = YES;
		self.alwaysBounceHorizontal = YES;
		self.bouncesZoom = YES;
		self.opaque = YES;
		self.decelerationRate = 0.3f;
    }
    return self;
}

- (void)layoutSubviews {
    UIView *zoomingView = [self.delegate viewForZoomingInScrollView:self];
    CGPoint newCenter;
    newCenter.x = MAX(CGRectGetWidth(zoomingView.frame), CGRectGetWidth(self.bounds)) / 2.0f;
    newCenter.y = MAX(CGRectGetHeight(zoomingView.frame), CGRectGetHeight(self.bounds)) / 2.0f;
    zoomingView.center = newCenter;
}

@end

#pragma mark -

// CBAnnotationContainerView contains all the annotation views
@interface CBAnnotationContainerView : UIView
@property (nonatomic, assign) CGFloat latitudeMapCenter,longitudeMapCenter;
@property (nonatomic, assign) CGFloat rotationRadians,pointsPerDegree;
@property (nonatomic, strong) CBMapContentView *mapContentView;
@end

@implementation CBAnnotationContainerView

@synthesize latitudeMapCenter,longitudeMapCenter;
@synthesize rotationRadians,pointsPerDegree;
@synthesize mapContentView = _mapContentView;


-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    id hitView = [super hitTest:point withEvent:event];
    if (hitView == self) return nil;
    else return hitView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!isnan(self.pointsPerDegree) && self.pointsPerDegree != 0) {
        UIScrollView *scrollView = (UIScrollView *)[self.mapContentView superview];
        CGFloat mapWidth = scrollView.contentSize.width / scrollView.zoomScale;
        CGFloat mapHeight = scrollView.contentSize.height / scrollView.zoomScale;
        CGPoint mapCenterPoint = CGPointMake(mapWidth / 2.0f, mapHeight / 2.0f);
        for (UIView *subView in self.subviews) {
            if ([subView isKindOfClass:[CBAnnotationView class]]) {
                CBAnnotationView *annotationView = (CBAnnotationView *)subView;
                
                CGPoint annotationCenterPointOnContentView = CGPointZero;
                CGPoint annotationPosition = annotationView.annotation.position;
                if (!CGPointEqualToPoint(annotationPosition, CGPointZero)) {
                    annotationCenterPointOnContentView = CGPointMake(mapWidth * annotationPosition.x, mapHeight * annotationPosition.y);
                }
                else {
                    CBLocationCoordinate2D annotationCoordinate = annotationView.annotation.coordinate;
                    double deltaLatitude = annotationCoordinate.latitude - self.latitudeMapCenter;
                    double deltaLongitude = annotationCoordinate.longitude - self.longitudeMapCenter;
                    
                    double coordinateRadian = atan(deltaLatitude/deltaLongitude);
                    if (deltaLongitude <= 0) {
                        coordinateRadian = M_PI + coordinateRadian;
                    }
                    double coordinateRadianInMapCoordinates = coordinateRadian - self.rotationRadians;
                    
                    double distanceToMapCenter = self.pointsPerDegree * sqrt(pow(deltaLatitude, 2)+pow(deltaLongitude, 2));
                    
                    annotationCenterPointOnContentView = CGPointMake(mapCenterPoint.x + cos(coordinateRadianInMapCoordinates)*distanceToMapCenter, mapCenterPoint.y - sin(coordinateRadianInMapCoordinates)*distanceToMapCenter);
                    
                }
                CGPoint annotationCenterPoint = [self convertPoint:annotationCenterPointOnContentView fromView:self.mapContentView];
                annotationCenterPoint = CGPointMake(nearbyint(annotationCenterPoint.x), nearbyint(annotationCenterPoint.y));
                
                if ([scrollView isZoomBouncing]) {
                    [UIView beginAnimations:nil context:NULL];
                    [UIView setAnimationDuration:[CATransaction animationDuration]];
                    [UIView setAnimationDuration:0.15f];
                    [annotationView setCenter:annotationCenterPoint];
                    [UIView commitAnimations];
                }
                else {
                    [annotationView setCenter:annotationCenterPoint];
                }
            }
        }
    }
}

@end

#pragma mark -

// CBScrollContainerView contains CBAnnotationContainerView
@interface CBScrollContainerView : UIView
@property (nonatomic, readonly) CBAnnotationContainerView *annotationContainerView;
@end

@implementation CBScrollContainerView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _annotationContainerView = [[CBAnnotationContainerView alloc] initWithFrame:self.bounds];
        _annotationContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_annotationContainerView];
    }
    return self;
}

-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    id hitView = [super hitTest:point withEvent:event];
    if (hitView == self) return nil;
    else return hitView;
}

@end

#pragma mark -

@interface CBMapView () <UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *reusableAnnotationViews;
@property (nonatomic, strong) NSMutableArray *annotations;
@property (nonatomic, strong) NSMutableArray *selectedAnnotations;

- (void)loadMapData;
- (void)updateMinMaxZoomScale;
- (CGRect)visibleMapRectWithCenter:(CGPoint)centerPoint zoomScale:(CGFloat)zoomScale;
- (void)addAnnotationView:(CBAnnotationView *)annotationView;

@end

@implementation CBMapView {
    CBMapContentView *mapContentView;
    CBMapScrollView *scrollView;
    CBScrollContainerView *scrollContainerView;
    NSMutableDictionary *reusableAnnotationViews;
}

@synthesize delegate;
@synthesize mapFile;
@synthesize zoomEnabled,scrollEnabled;
@synthesize annotations = _annotations,selectedAnnotations = _selectedAnnotations;
@synthesize reusableAnnotationViews;

- (void)initialization {
    self.reusableAnnotationViews = [NSMutableDictionary dictionary];
    
    // Map Scroll View
    scrollView = [[CBMapScrollView alloc] initWithFrame:self.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.delegate = self;
    self.zoomEnabled = YES;
    self.scrollEnabled = YES;
    
    // Map Content View
    mapContentView = [[CBMapContentView alloc] initWithFrame:self.bounds];
    mapContentView.autoresizingMask = UIViewAutoresizingNone;
    mapContentView.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:mapContentView];
    [mapContentView addObserver:self forKeyPath:@"frame" options:0 context:NULL];
    
    [self addSubview:scrollView];
    
    // Map Scroll Container View
    scrollContainerView = [[CBScrollContainerView alloc] initWithFrame:self.bounds];
    scrollContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:scrollContainerView];
    
    // Map Gesture Recognizers
    self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGesture:)];
    self.doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    self.doubleTapGestureRecognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:self.doubleTapGestureRecognizer];
    
    self.doubleTapAndPanGestureRecognizer = [[CBDoubleTapAndPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapAndPanGesture:)];
    [self addGestureRecognizer:self.doubleTapAndPanGestureRecognizer];
    
    // Map View
    UIImage *bgImage = [CBMapView embeddedImageNamed:@"bgImage"];
    self.backgroundColor = [UIColor colorWithPatternImage:bgImage];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)dealloc {
    self.mapFile = nil;
    [mapContentView removeObserver:self forKeyPath:@"frame"];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"frame"]) {
        [scrollContainerView.annotationContainerView layoutSubviews];
    }
}

#pragma mark Properties

// Only called when rotating the screen
- (void)setFrame:(CGRect)frame {
    if (!CGRectEqualToRect(self.frame, frame)) {
        CGPoint visibleContentCenterBeforeRotation = CGPointZero;
        
        // Before new frame, remember the rotation center
        if (mapContentView.frame.size.width > scrollView.frame.size.width &&
            mapContentView.frame.size.height > scrollView.frame.size.height) {
            CGRect visibleRect = [self visibleMapRect];
            visibleContentCenterBeforeRotation = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect));
        }
        else {
        }
        
        [super setFrame:frame];

        // After new frame
        BOOL keepMinZoomLevel = scrollView.zoomScale == scrollView.minimumZoomScale;
        [self updateMinMaxZoomScale];
        // Restore the rotation center
        if (mapContentView.frame.size.width > scrollView.frame.size.width &&
            mapContentView.frame.size.height > scrollView.frame.size.height) {
            [scrollView zoomToRect:[self visibleMapRectWithCenter:visibleContentCenterBeforeRotation zoomScale:scrollView.zoomScale] animated:NO];
        }
        else {
            // If it was min scale, or the new min scale is larger, set to the min scale
            if (keepMinZoomLevel || scrollView.minimumZoomScale > scrollView.zoomScale)
                [scrollView setZoomScale:scrollView.minimumZoomScale animated:NO];
        }
    }
}

- (void)setScrollEnabled:(BOOL)newValue {
    scrollEnabled = newValue;
    scrollView.scrollEnabled = newValue;
}

- (void)setZoomEnabled:(BOOL)newValue {
    zoomEnabled = newValue;
}

- (void)setMapFile:(CBMapFile *)newValue {
    @synchronized (self){
        mapFile = newValue;
    }
    [self loadMapData];
}

#pragma mark Map Rect/Coordinate/Region

- (void)setRegion:(CBCoordinateRegion)region animated:(BOOL)animated {
    
}

- (void)setCenterCoordinate:(CBLocationCoordinate2D)coordinate animated:(BOOL)animated {
    
}

- (void)zoomToRect:(CGRect)mapRect animated:(BOOL)animate {
    [scrollView zoomToRect:mapRect animated:animate];
}

#pragma mark Annotation Views

- (CBAnnotationView *)dequeueReusableAnnotationViewWithIdentifier:(NSString *)identifier {
    CBAnnotationView *annotationView = (self.reusableAnnotationViews)[identifier];
//    if (annotationView)
//        [annotationView prepareForReuse];
    return [annotationView copy];
}

- (void)selectAnnotation:(id <CBAnnotation>)annotation animated:(BOOL)animated {
    if (![self.selectedAnnotations containsObject:annotation]) {
        if ([self.delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
            CBAnnotationView *annotationView = [self.delegate mapView:self viewForAnnotation:annotation];
            if (annotationView)
                [annotationView setSelected:YES animated:animated];
        }
    }
}

- (void)deselectAnnotation:(id <CBAnnotation>)annotation animated:(BOOL)animated {
    if ([self.selectedAnnotations containsObject:annotation]) {
        if ([self.delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
            CBAnnotationView *annotationView = [self.delegate mapView:self viewForAnnotation:annotation];
            if (annotationView)
                [annotationView setSelected:NO animated:animated];
        }
    }
}

- (void)setSelectedAnnotations:(NSArray *)selectedAnnotations {
    @synchronized (self) {
        for (id <CBAnnotation> oneAnnotation in self.selectedAnnotations) {
            [self deselectAnnotation:oneAnnotation animated:NO];
        }
        _selectedAnnotations = selectedAnnotations?[selectedAnnotations mutableCopy]:nil;
        for (id <CBAnnotation> oneAnnotation in self.selectedAnnotations) {
            [self selectAnnotation:oneAnnotation animated:YES];
            break;
        }
    }
}

- (void)addAnnotationView:(CBAnnotationView *)annotationView {
    if (![[self.reusableAnnotationViews allKeys] containsObject:annotationView.reuseIdentifier]) {
        (self.reusableAnnotationViews)[annotationView.reuseIdentifier] = annotationView;
    }
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(annotationViewTapped:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.numberOfTouchesRequired = 1;
    [annotationView addGestureRecognizer:tapGestureRecognizer];
    
    [scrollContainerView.annotationContainerView addSubview:annotationView];
}

- (void)removeAnnotationView:(CBAnnotationView *)annotationView {
    [annotationView removeFromSuperview];
}

- (void)annotationViewTapped:(id)sender {
    UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)sender;
    CBAnnotationView *tappedAnnotationView = (CBAnnotationView *)[gestureRecognizer view];
    [self setSelectedAnnotations:nil];
    [self selectAnnotation:tappedAnnotationView.annotation animated:YES];
}

#pragma mark Annoations

- (void)addAnnotation:(id <CBAnnotation>)annotation {
    [self.annotations addObject:annotation];
    if ([self.delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
        [self addAnnotationView:[self.delegate mapView:self viewForAnnotation:annotation]];
    }
}

- (void)addAnnotations:(NSArray *)annotations {
    [self.annotations addObjectsFromArray:annotations];
    if ([self.delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
        for (id <CBAnnotation> oneAnnotation in annotations) {
            [self addAnnotationView:[self.delegate mapView:self viewForAnnotation:oneAnnotation]];
        }
    }
}

- (void)removeAnnotation:(id <CBAnnotation>)annotation {
    [self.annotations removeObject:annotation];
    if ([self.delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
        [self removeAnnotationView:[self.delegate mapView:self viewForAnnotation:annotation]];
    }
}

- (void)removeAnnotations:(NSArray *)annotations {
    [self.annotations removeObjectsInArray:annotations];
    if ([self.delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
        for (id <CBAnnotation> oneAnnotation in annotations) {
            [self removeAnnotationView:[self.delegate mapView:self viewForAnnotation:oneAnnotation]];
        }
    }
}

#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.zoomEnabled?mapContentView:nil;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self willChangeValueForKey:@"visibleMapRect"];
        [self didChangeValueForKey:@"visibleMapRect"];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView {
    [self willChangeValueForKey:@"visibleMapRect"];
    [self didChangeValueForKey:@"visibleMapRect"];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    [self willChangeValueForKey:@"visibleMapRect"];
    [self didChangeValueForKey:@"visibleMapRect"];
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    if (!scrollView.decelerating && !scrollView.dragging) {
        CGPoint contentOffset = [scrollView contentOffset];
        BOOL needResetContentOffset = NO;
        if (contentOffset.x < 0) {
            contentOffset.x = 0;
            needResetContentOffset = YES;
        }
        if (contentOffset.y < 0) {
            contentOffset.y = 0;
            needResetContentOffset = YES;
        }
        if (needResetContentOffset) {
            [scrollView setContentOffset:contentOffset animated:NO];
        }
    }
}

#pragma mark Action

- (void)handleDoubleTapGesture:(id)sender {
	CGPoint tapLocation = [(UIGestureRecognizer *)sender locationInView:mapContentView];
    if (scrollView.zoomScale == scrollView.maximumZoomScale) {
        CGFloat newZoomScale = scrollView.maximumZoomScale / 2;
        [scrollView zoomToRect:[self visibleMapRectWithCenter:[mapContentView convertPoint:CGPointMake(self.frame.size.width / 2.0f, self.frame.size.height / 2.0f) fromView:self] zoomScale:newZoomScale] animated:YES];
    }
    else {
        CGFloat newZoomScale = pow(2, floor(log2(scrollView.zoomScale))) * 2.0f;
        [scrollView zoomToRect:[self visibleMapRectWithCenter:tapLocation zoomScale:newZoomScale] animated:YES];
    }
}

- (void)handleDoubleTapAndPanGesture:(id)sender {
    CBDoubleTapAndPanGestureRecognizer *gesture = sender;
    if (gesture.state == UIGestureRecognizerStateChanged) {
        scrollView.zoomScale *= gesture.scale;
    }
}

#pragma mark Routines

- (void)loadMapData {
    if (self.mapFile) {
        // Update scroll view
        CGSize mapSize = CGSizeMake([self.mapFile mapWidth], [self.mapFile mapHeight]);
        scrollView.zoomScale = 1;
        scrollView.contentSize = mapSize;
        
    	mapContentView.mapFile = self.mapFile;
        mapContentView.frame = CGRectMake(0, 0, mapSize.width, mapSize.height);
        mapContentView.tiledLayer.tileSize = CGSizeMake(self.mapFile.tileSize, self.mapFile.tileSize);
        mapContentView.tiledLayer.levelsOfDetail = self.mapFile.maxScale - self.mapFile.minScale + 1;
        mapContentView.tiledLayer.levelsOfDetailBias = self.mapFile.maxScale - 0;
        mapContentView.tiledLayer.shouldRasterize = NO;
        
        [self updateMinMaxZoomScale];
        scrollView.zoomScale = scrollView.minimumZoomScale;

        [mapContentView setNeedsDisplay];
        
        // Coordinates
        double deltaLatitude = self.mapFile.latitudeTopLeft - self.mapFile.latitudeBottomRight;
        double deltaLongitude = self.mapFile.longitudeTopLeft - self.mapFile.longitudeBottomRight;
        if (deltaLatitude != 0 && deltaLongitude != 0) {
            scrollContainerView.annotationContainerView.latitudeMapCenter = self.mapFile.latitudeBottomRight + deltaLatitude / 2.0f;
            scrollContainerView.annotationContainerView.longitudeMapCenter = self.mapFile.longitudeBottomRight + deltaLongitude / 2.0f;
            float rotationX1Y1X2Y2 = atan(deltaLatitude/deltaLongitude);
            if (deltaLongitude <= 0) rotationX1Y1X2Y2 += M_PI;
            else if (deltaLatitude < 0) rotationX1Y1X2Y2 += (M_PI * 2);
            scrollContainerView.annotationContainerView.rotationRadians = rotationX1Y1X2Y2 - atan(self.mapFile.mapWidth/self.mapFile.mapHeight) - M_PI_2;
            scrollContainerView.annotationContainerView.pointsPerDegree = sqrt(pow(self.mapFile.mapWidth, 2)+pow(self.mapFile.mapHeight, 2))/sqrt(pow(deltaLatitude, 2)+pow(deltaLongitude, 2));
            scrollContainerView.annotationContainerView.mapContentView = mapContentView;
        }
    }
}

- (void)updateMinMaxZoomScale {
    CGSize mapSize = CGSizeMake([self.mapFile mapWidth], [self.mapFile mapHeight]);
    scrollView.maximumZoomScale = pow(2, self.mapFile.maxScale);// * ([[UIScreen mainScreen] scale]==2?1:2);
    CGFloat bestFitScreenZoomScale = MIN(CGRectGetWidth(scrollView.frame)/mapSize.width, CGRectGetHeight(scrollView.frame)/mapSize.height);
    scrollView.minimumZoomScale = MIN(bestFitScreenZoomScale, scrollView.maximumZoomScale);
}

- (CGRect)visibleMapRectWithCenter:(CGPoint)centerPoint zoomScale:(CGFloat)zoomScale {
    CGSize destSize;
    destSize.width = CGRectGetWidth(scrollView.bounds) / zoomScale;
    destSize.height = CGRectGetHeight(scrollView.bounds) / zoomScale;
    
    CGRect destRect;
    destRect.origin.x = centerPoint.x - destSize.width / 2.0f;
    destRect.origin.y = centerPoint.y - destSize.height / 2.0f;
    destRect.size = destSize;
    
    return destRect;
}

- (CGRect)visibleMapRect {
    return [mapContentView convertRect:scrollView.bounds fromView:scrollView];
}

#pragma mark Embeded Images

+ (UIImage *)embeddedImageNamed:(NSString *)name {
    NSString *imageName = [NSString stringWithFormat:@"%@%@",name,([UIScreen mainScreen].scale == 2)?@"2x":@""];
    SEL selector = NSSelectorFromString(imageName);
    UIImage *embededImage = nil;
    if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [UIImage imageWithData:[NSData dataWithBase64EncodedString:[self performSelector:selector]] scale:[UIScreen mainScreen].scale];
#pragma clang diagnostic pop
    }
    return embededImage;
}

+ (NSString *)bgImage {
    return @"iVBORw0KGgoAAAAEQ2dCSVAAIAYsuHdmAAAADUlIRFIAAAAQAAAAEAgGAAAAH/P/YQAAAB5JREFUY/j8+fN/fPjZs2d4McOoAcPCAEIKCFkwasCwMAAA+euzBAAAAABJRU5ErkJggg==";
}

+ (NSString *)bgImage2x {
    return @"iVBORw0KGgoAAAAEQ2dCSVAAIAYsuHdmAAAADUlIRFIAAAAgAAAAIAgGAAAAc3p69AAAAAlwSFlzAAAWJQAAFiUBSVIk8AAAADNJREFU7c8xEQAwDAOx8AdqAgHQgvCQRcOvPnl29zUlqRoAAAAAAACAc0A70B4AAAAAAAAAOAd8yRhKugAAAABJRU5ErkJggg==";
}

@end