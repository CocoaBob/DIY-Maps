//
//  ScaleableMapView.m
//  ScaleableMapView
//
//  Created by Bob on 11/9/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

#import "DMMapView.h"

#import "Base64.h"
#import "CBDoubleTapAndPanGestureRecognizer.h"
#import "DMMapFile.h"

@interface CBMapContentView : UIView {
    CATiledLayer *__weak tiledLayer;
}

@property (weak, nonatomic, readonly) CATiledLayer *tiledLayer;
@property (nonatomic, strong) DMMapFile *mapFile;

@end

@implementation CBMapContentView

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

@interface DMMapView () <UIScrollViewDelegate>

- (void)loadMapData;
- (void)updateMinMaxZoomScale;
- (CGRect)visibleMapRectWithCenter:(CGPoint)centerPoint zoomScale:(CGFloat)zoomScale;

@end

@implementation DMMapView {
    CBMapContentView *mapContentView;
}

- (void)initialization {
    
    // Scroll View
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
    self.delegate = self;
    
    self.zoomEnabled = YES;
    self.scrollEnabled = YES;
    
    // Map Content View
    mapContentView = [[CBMapContentView alloc] initWithFrame:self.bounds];
    mapContentView.autoresizingMask = UIViewAutoresizingNone;
    mapContentView.backgroundColor = [UIColor clearColor];
    [self addSubview:mapContentView];
    
    // Map Gesture Recognizers
    self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGesture:)];
    self.doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    self.doubleTapGestureRecognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:self.doubleTapGestureRecognizer];
    
    self.doubleTapAndPanGestureRecognizer = [[CBDoubleTapAndPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapAndPanGesture:)];
    [self addGestureRecognizer:self.doubleTapAndPanGestureRecognizer];
    
    // Map View
    UIImage *bgImage = [DMMapView embeddedImageNamed:@"bgImage"];
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
}

- (void)layoutSubviews {
    UIView *zoomingView = [self.delegate viewForZoomingInScrollView:self];
    CGPoint newCenter;
    newCenter.x = MAX(CGRectGetWidth(zoomingView.frame), CGRectGetWidth(self.bounds)) / 2.0f;
    newCenter.y = MAX(CGRectGetHeight(zoomingView.frame), CGRectGetHeight(self.bounds)) / 2.0f;
    zoomingView.center = newCenter;
}

#pragma mark Properties

// Only called when rotating the screen
- (void)setFrame:(CGRect)frame {
    if (!CGRectEqualToRect(self.frame, frame)) {
        CGPoint visibleContentCenterBeforeRotation = CGPointZero;
        
        // Before new frame, remember the rotation center
        if (mapContentView.frame.size.width > self.frame.size.width &&
            mapContentView.frame.size.height > self.frame.size.height) {
            CGRect visibleRect = [self visibleMapRect];
            visibleContentCenterBeforeRotation = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect));
        }
        else {
        }
        
        [super setFrame:frame];

        // After new frame
        BOOL keepMinZoomLevel = self.zoomScale == self.minimumZoomScale;
        [self updateMinMaxZoomScale];
        // Restore the rotation center
        if (mapContentView.frame.size.width > self.frame.size.width &&
            mapContentView.frame.size.height > self.frame.size.height) {
            [self zoomToRect:[self visibleMapRectWithCenter:visibleContentCenterBeforeRotation zoomScale:self.zoomScale] animated:NO];
        }
        else {
            // If it was min scale, or the new min scale is larger, set to the min scale
            if (keepMinZoomLevel || self.minimumZoomScale > self.zoomScale)
                [self setZoomScale:self.minimumZoomScale animated:NO];
        }
    }
}

- (void)setMapFile:(DMMapFile *)newValue {
    @synchronized (self){
        _mapFile = newValue;
    }
    [self loadMapData];
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
    if (!self.decelerating && !self.dragging) {
        CGPoint contentOffset = [self contentOffset];
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
            [self setContentOffset:contentOffset animated:NO];
        }
    }
}

#pragma mark Action

- (void)handleDoubleTapGesture:(id)sender {
	CGPoint tapLocation = [(UIGestureRecognizer *)sender locationInView:mapContentView];
    if (self.zoomScale == self.maximumZoomScale) {
        CGFloat newZoomScale = self.maximumZoomScale / 2;
        [self zoomToRect:[self visibleMapRectWithCenter:[mapContentView convertPoint:CGPointMake(self.frame.size.width / 2.0f, self.frame.size.height / 2.0f) fromView:self] zoomScale:newZoomScale] animated:YES];
    }
    else {
        CGFloat newZoomScale = pow(2, floor(log2(self.zoomScale))) * 2.0f;
        [self zoomToRect:[self visibleMapRectWithCenter:tapLocation zoomScale:newZoomScale] animated:YES];
    }
}

- (void)handleDoubleTapAndPanGesture:(id)sender {
    CBDoubleTapAndPanGestureRecognizer *gesture = sender;
    if (gesture.state == UIGestureRecognizerStateChanged) {
        self.zoomScale *= gesture.scale;
    }
}

#pragma mark Routines

- (void)loadMapData {
    if (self.mapFile) {
        // Update scroll view
        CGSize mapSize = CGSizeMake([self.mapFile mapWidth], [self.mapFile mapHeight]);
        self.zoomScale = 1;
        self.contentSize = mapSize;
        
    	mapContentView.mapFile = self.mapFile;
        mapContentView.frame = CGRectMake(0, 0, mapSize.width, mapSize.height);
        mapContentView.tiledLayer.tileSize = CGSizeMake(self.mapFile.tileSize, self.mapFile.tileSize);
        mapContentView.tiledLayer.levelsOfDetail = self.mapFile.maxScale - self.mapFile.minScale + 1;
        mapContentView.tiledLayer.levelsOfDetailBias = self.mapFile.maxScale - 0;
        mapContentView.tiledLayer.shouldRasterize = NO;
        
        [self updateMinMaxZoomScale];
        self.zoomScale = self.minimumZoomScale;

        [mapContentView setNeedsDisplay];
    }
}

- (void)updateMinMaxZoomScale {
    CGSize mapSize = CGSizeMake([self.mapFile mapWidth], [self.mapFile mapHeight]);
    self.maximumZoomScale = pow(2, self.mapFile.maxScale);// * ([[UIScreen mainScreen] scale]==2?1:2);
    CGFloat bestFitScreenZoomScale = MIN(CGRectGetWidth(self.frame)/mapSize.width, CGRectGetHeight(self.frame)/mapSize.height);
    self.minimumZoomScale = MIN(bestFitScreenZoomScale, self.maximumZoomScale);
}

- (CGRect)visibleMapRectWithCenter:(CGPoint)centerPoint zoomScale:(CGFloat)zoomScale {
    CGSize destSize;
    destSize.width = CGRectGetWidth(self.bounds) / zoomScale;
    destSize.height = CGRectGetHeight(self.bounds) / zoomScale;
    
    CGRect destRect;
    destRect.origin.x = centerPoint.x - destSize.width / 2.0f;
    destRect.origin.y = centerPoint.y - destSize.height / 2.0f;
    destRect.size = destSize;
    
    return destRect;
}

- (CGRect)visibleMapRect {
    return [mapContentView convertRect:self.bounds fromView:self];
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