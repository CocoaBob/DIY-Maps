//
//  DMPImageProcessor.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 13/09/13.
//
//

@interface DMImageProcessor : NSObject

+ (DMImageProcessor *)shared;

#if TARGET_OS_IPHONE
+ (UIImage *)thumbnailWithImage:(UIImage *)inImage srcRect:(CGRect)srcRect destSize:(CGSize)destSize;
+ (CGSize)pixelDimensionsOfImage:(UIImage*)image;
#elif TARGET_OS_MAC
+ (NSImage *)thumbnailWithImage:(NSImage *)inImage cropRect:(CGRect)srcRect outputSize:(CGSize)destSize;
+ (CGSize)pixelDimensionsOfImage:(NSImage*)image;
#endif
+ (NSString *)stringFromSize:(CGSize)pixelSize scale:(CGFloat)zoomScale;

@end