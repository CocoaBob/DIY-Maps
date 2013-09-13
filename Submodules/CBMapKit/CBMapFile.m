//
//  MapFile.m
//  ScaleableMapView
//
//  Created by Bob on 11/9/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

#import "CBMapFile.h"

#import "ZipFile.h"
#import "DMProfile.h"

@interface CBMapFile()

@property (nonatomic, strong) ZipFile *zipFile;
@property (nonatomic, strong) NSString *zipFileRootFolderPath;

@end

@implementation CBMapFile

// Public
@synthesize zipFile;
@synthesize mapFormat;
@synthesize mapWidth,mapHeight,minScale,maxScale,tileSize;
@synthesize latitudeTopLeft,longitudeTopLeft,latitudeBottomRight,longitudeBottomRight;

// Private
@synthesize zipFileRootFolderPath;

+ (CBMapFile *)mapFileWithPath:(NSString *)filePath {
    ZipFile *aZipFile = [[ZipFile alloc] initWithFileAtPath:filePath];
    if (aZipFile) {
        CBMapFile *aMapFile = [CBMapFile new];
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
        NSString *firstFilePath = [zipFile firstFilePath];
        firstFilePath = [firstFilePath pathComponents][0];
        self.zipFileRootFolderPath = firstFilePath;
        
        NSData *mapProfileData = [self.zipFile readWithFilePath:[self.zipFileRootFolderPath stringByAppendingPathComponent:@"profile.xml"] maxLength:NSUIntegerMax];
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

- (void)setZipFile:(ZipFile *)newValue {
    @synchronized(self) {
        if (zipFile) {
            [zipFile close];
        }
        zipFile = newValue;
        [self openZipFile];
    }
}

- (UIImage *)tileImageForScale:(CGFloat)mapScale indexX:(NSInteger)indexX indexY:(NSInteger)indexY {
    UIImage *returnValue = nil;
    @synchronized(self){
        if ([self openZipFile]) {
            NSString *mapScaleString = [NSString stringWithFormat:@"%f",mapScale];
            NSString *mapaIndexX = [NSString stringWithFormat:@"%d",indexX];
            NSString *mapaIndexY = [NSString stringWithFormat:@"%d",indexY];
            NSString *imageFileName = [NSString stringWithFormat:@"%@-%@-%@-%@.%@",@"map",mapScaleString,mapaIndexX,mapaIndexY,self.mapFormat];
            NSString *tileImagePath = [self.zipFileRootFolderPath stringByAppendingPathComponent:imageFileName];
            NSData *imageData = [self.zipFile readWithFilePath:tileImagePath maxLength:NSUIntegerMax];
            if (imageData) {
                returnValue = [UIImage imageWithData:imageData];
            }
        }
    }
    return returnValue;
}

- (UIImage *)previewImage {
    return [self tileImageForScale:pow(2, self.minScale) indexX:0 indexY:0];
}

@end