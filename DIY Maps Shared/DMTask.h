//
//  DMPTask.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/08/13.
//
//

typedef NS_ENUM(NSUInteger, DMTaskStatus) {
    DMTaskStatusReady,
    DMTaskStatusLoading,
    DMTaskStatusSlicing,
    DMTaskStatusPacking,
    DMTaskStatusError,
    DMTaskStatusSuccessful
};

typedef NS_ENUM (NSUInteger, DMTileSize) {
    DMTileSizeTiny,       // 256
    DMTileSizeSmall,      // 512
    DMTileSizeDefault,    // 1024
    DMTileSizeLarge,      // 2048
    DMTileSizeCount
};

typedef NS_ENUM(NSUInteger, DMOutputFormat) {
    DMOutputFormatJPG,
    DMOutputFormatPNG,
    DMOutputFormatCount
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
@property (nonatomic, assign) DMTileSize tileSizeIndex;
@property (nonatomic, assign) DMOutputFormat outputFormatIndex;

@property (nonatomic, assign) DMTaskStatus status;
@property (nonatomic, assign) float progress;
@property (nonatomic, assign) NSTimeInterval remainingTime;
@property (nonatomic, strong) NSString *logs;

+ (NSString *)fileExtensionFromFormat:(DMOutputFormat)inValue;
+ (int)tileSizeFromSizeIndex:(DMTileSize)inValue;
+ (int)defaultMinScalePowerWithTileSizeIndex:(int)tileSizeIndex originalPixelSize:(CGSize)originalPixelSize;

- (DMProfile *)mapProfile;

@end
