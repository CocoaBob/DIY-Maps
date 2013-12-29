//
//  MapFile.m
//  ScaleableMapView
//
//  Created by Bob on 11/9/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

#import "DMMapFile.h"

#import "CBZipFile.h"
#import "DMProfile.h"

@interface DMMapFile()

@property (nonatomic, strong) CBZipFile *zipFile;
@property (nonatomic, strong) NSString *zipFileRootFolderPath;

@end

@implementation DMMapFile

+ (DMMapFile *)mapFileWithPath:(NSString *)filePath {
    CBZipFile *aZipFile = [[CBZipFile alloc] initWithFileAtPath:filePath];
    if (aZipFile) {
        DMMapFile *aMapFile = [DMMapFile new];
        aMapFile.zipFile = aZipFile;
        return aMapFile;
    }
    return nil;
}

- (void)dealloc {
    self.zipFile = nil;
}

- (BOOL)openZipFile {
    if (!self.zipFile)
        return NO;
    
    if (![self.zipFile isOpen])
        [self.zipFile open];
    
    // Initialization
    if ([self.zipFile isOpen]) {
        NSString *firstFilePath = [self.zipFile firstFileName];
        firstFilePath = [firstFilePath pathComponents][0];
        self.zipFileRootFolderPath = firstFilePath;
        
        NSData *mapProfileData = [self.zipFile readWithFileName:[self.zipFileRootFolderPath stringByAppendingPathComponent:@"profile.xml"]
                                                  caseSensitive:YES
                                                      maxLength:NSUIntegerMax];
        DMProfile *profile = [DMProfile profileWithXMLData:mapProfileData];
        if (!profile)
            return NO;
        
        self.mapWidth = profile.mapWidth;
        self.mapHeight = profile.mapHeight;
        self.mapWidth = self.mapWidth>1?self.mapWidth:1;
        self.mapHeight = self.mapHeight>1?self.mapHeight:1;
        self.minScale = profile.minScalePower;
        self.maxScale = profile.maxScalePower;
        self.tileSize = profile.tileSize;
        self.mapFormat = profile.imgExt;
    }
    return YES;
}

- (void)setZipFile:(CBZipFile *)newValue {
    @synchronized(self) {
        if (_zipFile) {
            [_zipFile close];
        }
        _zipFile = newValue;
        [self openZipFile];
    }
}

- (id)tileImageForScale:(CGFloat)mapScale indexX:(NSInteger)indexX indexY:(NSInteger)indexY {
    if ([self openZipFile]) {
        if (![self.zipFile hasHashTable]) {
            [self.zipFile buildHashTable];
        }
        NSString *mapScaleString = [NSString stringWithFormat:@"%f",mapScale];
        NSString *mapaIndexX = [NSString stringWithFormat:@"%ld",(long)indexX];
        NSString *mapaIndexY = [NSString stringWithFormat:@"%ld",(long)indexY];
        NSString *imageFileName = [NSString stringWithFormat:@"%@-%@-%@-%@.%@",@"map",mapScaleString,mapaIndexX,mapaIndexY,self.mapFormat];
        NSString *tileImagePath = [self.zipFileRootFolderPath stringByAppendingPathComponent:imageFileName];
        NSData *imageData = [self.zipFile readWithFileName:tileImagePath
                                             caseSensitive:YES
                                                 maxLength:NSUIntegerMax];
        if (imageData) {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
            return [UIImage imageWithData:imageData];
#elif TARGET_OS_MAC
            return [[NSImage alloc] initWithData:imageData];
#endif
        }
    }
    return nil;
}

- (id)previewImage {
    return [self tileImageForScale:pow(2, self.minScale) indexX:0 indexY:0];
}

@end