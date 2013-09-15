//
//  DMPTask.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/08/13.
//
//

typedef NS_ENUM(NSUInteger, DMPTaskState) {
    DMPTaskStateReady,
    DMPTaskStateRunning,
    DMPTaskStateError,
    DMPTaskStateSuccessful
};

typedef NS_ENUM (NSUInteger, DMPTileSize) {
    DMPTileSizeTiny,       // 256
    DMPTileSizeSmall,      // 512
    DMPTileSizeDefault,    // 1024
    DMPTileSizeLarge,      // 2048
    DMPTileSizeCount
};

typedef NS_ENUM(NSUInteger, DMPOutputFormat) {
    DMPOutputFormatJPG,
    DMPOutputFormatPNG,
    DMPOutputFormatCount
};

@class DMProfile;

@interface DMTask : NSObject

@property (nonatomic, assign) int minScalePower,maxScalePower;
@property (nonatomic, assign) double jpgQuality;
#if TARGET_OS_IPHONE
@property (nonatomic, assign) CGSize sourcePixelSize, sourceImageSize;
#elif TARGET_OS_MAC
@property (nonatomic, assign) NSSize sourcePixelSize, sourceImageSize;
#endif
@property (nonatomic, strong) NSString *inputFilePath,*outputFolderPath;
@property (nonatomic, assign) DMPTileSize tileSizeIndex;
@property (nonatomic, assign) DMPOutputFormat outputFormatIndex;

@property (nonatomic, assign) DMPTaskState state;
@property (nonatomic, assign) float progress;
@property (nonatomic, strong) NSString *logs;

+ (NSString *)fileExtensionFromFormat:(DMPOutputFormat)inValue;
+ (int)tileSizeFromSizeIndex:(DMPTileSize)inValue;
+ (int)defaultMinScalePowerWithTileSizeIndex:(int)tileSizeIndex originalPixelSize:(CGSize)originalPixelSize;

- (DMProfile *)mapProfile;

@end
