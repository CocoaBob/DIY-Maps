//
//  DMProfile.h
//  DIY Maps
//
//  Created by CocoaBob on 24/08/13.
//
//

static NSString* const DMProfileRoot = @"DIYMaps";
static NSString* const DMProfileMap = @"Map";
static NSString* const DMProfileMapImageExtension = @"ext";
static NSString* const DMProfileMapWidth = @"w";
static NSString* const DMProfileMapHeight = @"h";
static NSString* const DMProfileMapTileSize = @"tile";
static NSString* const DMProfileMapMinScalePower = @"min";
static NSString* const DMProfileMapMaxScalePower = @"max";
static NSString* const DMProfilePack = @"Pack";
static NSString* const DMProfilePackVersion = @"v";
static NSString* const DMProfilePackUserID = @"uid";

@interface DMProfile : NSObject

@property (nonatomic, strong) NSString *imgExt;
@property (nonatomic, assign) CGFloat mapWidth,mapHeight,tileSize;
@property (nonatomic, assign) int minScalePower,maxScalePower;

+ (DMProfile *)profileWithXMLData:(NSData *)xmlData;
- (NSData *)xmlData;

@end
