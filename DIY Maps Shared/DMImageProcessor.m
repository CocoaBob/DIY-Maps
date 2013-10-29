//
//  DMPImageProcessor.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 13/09/13.
//
//

#import "DMImageProcessor.h"

@interface DMImageProcessor ()

@end

@implementation DMImageProcessor

+ (NSString *)stringFromSize:(CGSize)pixelSize scale:(CGFloat)zoomScale {
    return [NSString stringWithFormat:@"%.0fx%.0f",floor(pixelSize.width * zoomScale),floor(pixelSize.height * zoomScale)];
}

#pragma mark - Object Lifecycle

static DMImageProcessor *__sharedInstance = nil;

+ (instancetype)shared {
    if (__sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __sharedInstance = [[[self class] alloc] init];
        });
    }
    
    return __sharedInstance;
}

#pragma mark -

#if TARGET_OS_IPHONE

+ (CGSize)pixelDimensionsOfImage:(UIImage *)image {
	return CGSizeMake (image.size.width, image.size.height);
}

+ (UIImage *)thumbnailWithImage:(UIImage *)inImage srcRect:(CGRect)srcRect destSize:(CGSize)destSize {
    return nil;
}

#elif TARGET_OS_MAC

+ (CGSize)pixelDimensionsOfImage:(NSImage *)image {
	float width = [image size].width;
	float height = [image size].height;
    
	NSArray* reps = [image representations];
	for (NSImageRep *rep in reps) {
		if ([rep isKindOfClass: [NSBitmapImageRep class]]) {
			NSBitmapImageRep *bitmapRep = (NSBitmapImageRep*) rep;
			width = bitmapRep.pixelsWide;
			height = bitmapRep.pixelsHigh;
			break;
		}
	}
	return CGSizeMake (width, height);
}

+ (NSImage *)thumbnailWithImage:(NSImage *)inImage cropRect:(CGRect)srcRect outputSize:(CGSize)destSize {
    CGFloat imageWidth = inImage.size.width;
    CGFloat imageHeight = inImage.size.height;
    if (CGSizeEqualToSize(destSize, CGSizeZero)) {
        destSize = CGSizeMake(imageWidth, imageHeight);
    }
    if (CGRectEqualToRect(srcRect, CGRectZero)) {
        srcRect = CGRectMake(0, 0, imageWidth, imageHeight);
        CGSize newDestSize;
        newDestSize.width = MAX(1, MIN(destSize.width, destSize.height * imageWidth / imageHeight));
        newDestSize.height = MAX(1, MIN(destSize.height, destSize.width * imageHeight / imageWidth));
        destSize = newDestSize;
    }
    NSRect destRect = NSMakeRect(0, 0, destSize.width, destSize.height);
    NSImage *image = [[NSImage alloc] initWithSize:destSize];
    
    [image lockFocus];
    [[NSColor whiteColor] setFill];
    NSRectFill(destRect);
    [inImage drawInRect:destRect
               fromRect:srcRect
              operation:NSCompositeSourceOver
               fraction:1.0];
    [image unlockFocus];
    
    return image;
}

#endif

@end
