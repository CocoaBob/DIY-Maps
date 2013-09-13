//
//  MapFile.h
//  ScaleableMapView
//
//  Created by Bob on 11/9/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

@interface CBMapFile : NSObject

@property (nonatomic, strong) NSString *mapFormat;
@property (nonatomic, assign) CGFloat mapWidth,mapHeight,minScale,maxScale,tileSize;
@property (nonatomic, assign) CGFloat latitudeTopLeft,longitudeTopLeft,latitudeBottomRight,longitudeBottomRight;

+ (CBMapFile *)mapFileWithPath:(NSString *)filePath;

- (UIImage *)tileImageForScale:(CGFloat)mapScale indexX:(NSInteger)indexX indexY:(NSInteger)indexY;
- (UIImage *)previewImage;

@end
