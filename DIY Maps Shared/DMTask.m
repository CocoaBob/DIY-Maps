//
//  DMPTask.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/08/13.
//
//

#import "DMTask.h"

#import "DMProfile.h"

@interface DMTask ()

@end

@implementation DMTask

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> %@",
            NSStringFromClass([self class]), self,
            @{@"inputFilePath":self.inputFilePath,
              @"outputFolderPath":self.outputFolderPath,
#if TARGET_OS_IPHONE
              @"sourcePixelSize":NSStringFromCGSize(self.sourcePixelSize),
              @"sourceImageSize":NSStringFromCGSize(self.sourceImageSize),
#elif TARGET_OS_MAC
              @"sourcePixelSize":NSStringFromSize(self.sourcePixelSize),
              @"sourceImageSize":NSStringFromSize(self.sourceImageSize),
#endif
              @"minScalePower":@(self.minScalePower),
              @"maxScalePower":@(self.maxScalePower),
              @"outputFormat":[DMTask fileExtensionFromFormat:self.outputFormatIndex],
              @"jpgQuality":@(self.jpgQuality)}];
}

- (id)init {
    self = [super init];
    if (self) {
        self.minScalePower = -2;
        self.maxScalePower = 0;
        self.jpgQuality = 0.7;
        self.tileSizeIndex = 2;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.jpgQuality = [coder decodeFloatForKey:@"jpgQuality"];
        self.minScalePower = [coder decodeIntForKey:@"minScalePower"];
        self.maxScalePower = [coder decodeIntForKey:@"maxScalePower"];
#if TARGET_OS_IPHONE
        _sourcePixelSize = [coder decodeCGSizeForKey:@"sourcePixelSize"];
        self.sourceImageSize = [coder decodeCGSizeForKey:@"sourceImageSize"];
#elif TARGET_OS_MAC
        _sourcePixelSize = [coder decodeSizeForKey:@"sourcePixelSize"];
        self.sourceImageSize = [coder decodeSizeForKey:@"sourceImageSize"];
#endif
        self.tileSizeIndex = [coder decodeIntForKey:@"tileSizeIndex"];
        self.outputFormatIndex = [coder decodeIntForKey:@"outputFormatIndex"];
        self.inputFilePath = [coder decodeObjectForKey:@"inputFilePath"];
        self.outputFolderPath = [coder decodeObjectForKey:@"outputFolderPath"];
        self.state = [coder decodeIntForKey:@"state"];
        self.logs = [coder decodeObjectForKey:@"logs"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    if ([coder isKindOfClass:[NSKeyedArchiver class]]) {
        [coder encodeFloat:self.jpgQuality forKey:@"jpgQuality"];
        [coder encodeInt:self.minScalePower forKey:@"minScalePower"];
        [coder encodeInt:self.maxScalePower forKey:@"maxScalePower"];
#if TARGET_OS_IPHONE
        [coder encodeCGSize:self.sourcePixelSize forKey:@"sourcePixelSize"];
        [coder encodeCGSize:self.sourceImageSize forKey:@"sourceImageSize"];
#elif TARGET_OS_MAC
        [coder encodeSize:self.sourcePixelSize forKey:@"sourcePixelSize"];
        [coder encodeSize:self.sourceImageSize forKey:@"sourceImageSize"];
#endif
        [coder encodeInt:self.tileSizeIndex forKey:@"tileSizeIndex"];
        [coder encodeInt:self.outputFormatIndex forKey:@"outputFormatIndex"];
        [coder encodeObject:self.inputFilePath forKey:@"inputFilePath"];
        [coder encodeObject:self.outputFolderPath forKey:@"outputFolderPath"];
        [coder encodeInt:self.state forKey:@"state"];
        [coder encodeObject:self.logs forKey:@"logs"];
    }
    else {
        [NSException raise:NSInvalidArchiveOperationException format:@"Only supports NSKeyedArchiver coders"];
    }
}

#pragma mark Properties

- (void)setSourcePixelSize:(CGSize)inValue {
    _sourcePixelSize = inValue;
    self.minScalePower = [DMTask defaultMinScaleSizeIndexWithTileSizeIndex:self.tileSizeIndex originalPixelSize:_sourcePixelSize];
}

#pragma mark Class Methods

+ (NSString *)fileExtensionFromFormat:(DMPOutputFormat)inValue {
    switch (inValue) {
        case DMPOutputFormatJPG:
            return @"jpg";
            break;
        case DMPOutputFormatPNG:
            return @"png";
        default:
            return nil;
            break;
    }
}

+ (int)tileSizeFromSizeIndex:(DMPTileSize)inValue {
    return 256 * pow(2, inValue);
}

+ (int)defaultMinScaleSizeIndexWithTileSizeIndex:(int)tileSizeIndex originalPixelSize:(CGSize)originalPixelSize {
    int minScaleLevel = 0;
    int tileSize = [DMTask tileSizeFromSizeIndex:tileSizeIndex];
    while ((originalPixelSize.width * pow(2, minScaleLevel)) > tileSize) {
        --minScaleLevel;
    }
    while ((originalPixelSize.height * pow(2, minScaleLevel)) > tileSize) {
        --minScaleLevel;
    }
    return minScaleLevel;
}

- (DMProfile *)mapProfile {
    DMProfile *newProfile = [DMProfile new];
    newProfile.imgExt = [DMTask fileExtensionFromFormat:self.outputFormatIndex];
    newProfile.mapWidth = self.sourcePixelSize.width;
    newProfile.mapHeight = self.sourcePixelSize.height;
    newProfile.tileSize = [DMTask tileSizeFromSizeIndex:self.tileSizeIndex];
    newProfile.minScalePower = self.minScalePower;
    newProfile.maxScalePower = self.maxScalePower;
    return newProfile;
}

@end
