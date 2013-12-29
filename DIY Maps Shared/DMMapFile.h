//
//  MapFile.h
//  ScaleableMapView
//
//  Created by Bob on 11/9/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

#include "TargetConditionals.h"

@interface DMMapFile : NSObject

@property (nonatomic, strong) NSString *mapFormat;
@property (nonatomic, assign) CGFloat mapWidth,mapHeight,minScale,maxScale,tileSize;
@property (nonatomic, assign) CGFloat latitudeTopLeft,longitudeTopLeft,latitudeBottomRight,longitudeBottomRight;

+ (DMMapFile *)mapFileWithPath:(NSString *)filePath;

- (id)tileImageForScale:(CGFloat)mapScale indexX:(NSInteger)indexX indexY:(NSInteger)indexY;
- (id)previewImage;

@end
