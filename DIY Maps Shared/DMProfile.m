//
//  DMProfile.m
//  DIY Maps
//
//  Created by CocoaBob on 24/08/13.
//
//

#import "DMProfile.h"

#import "DDXML.h"

@implementation DMProfile

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> {\nimgExt\t\t\t: %@\nmapWidth\t\t: %f\nmapHeight\t\t: %f\ntileSize\t\t: %f\nminScalePower\t: %f\nmaxScalePower\t: %f\n}",
            NSStringFromClass([self class]), self,
            self.imgExt,
            self.mapWidth,
            self.mapHeight,
            self.tileSize,
            self.minScalePower,
            self.maxScalePower];
}

+ (DMProfile *)profileWithXMLData:(NSData *)xmlData {
    if (!xmlData)
        return nil;
    
    NSError *error = nil;
    DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithData:xmlData options:0 error:&error];
    if (error) {
        NSLog(@"%@\n%@",[error localizedDescription],[NSThread callStackSymbols]);
        return nil;
    }
    else {
        // Get XML Data
        DDXMLElement *mapInfo = [[[xmlDoc rootElement] elementsForName:DMProfileMap] lastObject];
        DMProfile *profile = [DMProfile new];
        profile.imgExt = [[mapInfo attributeForName:DMProfileMapImageExtension] stringValue];
        profile.mapWidth = [[[mapInfo attributeForName:DMProfileMapWidth] stringValue] doubleValue];
        profile.mapHeight= [[[mapInfo attributeForName:DMProfileMapHeight] stringValue] doubleValue];
        profile.tileSize = [[[mapInfo attributeForName:DMProfileMapTileSize] stringValue] doubleValue];
        profile.minScalePower = [[[mapInfo attributeForName:DMProfileMapMinScalePower] stringValue] doubleValue];
        profile.maxScalePower = [[[mapInfo attributeForName:DMProfileMapMaxScalePower] stringValue] doubleValue];
        return profile;
    }
}

- (NSData *)xmlData {
    // Generate XML
    DDXMLElement *mapElement = [[DDXMLElement alloc] initWithName:DMProfileMap];
    [mapElement setAttributes:@[[DDXMLNode attributeWithName:DMProfileMapImageExtension stringValue:self.imgExt],
                                [DDXMLNode attributeWithName:DMProfileMapWidth stringValue:[@(self.mapWidth) stringValue]],
                                [DDXMLNode attributeWithName:DMProfileMapHeight stringValue:[@(self.mapHeight) stringValue]],
                                [DDXMLNode attributeWithName:DMProfileMapTileSize stringValue:[@(self.tileSize) stringValue]],
                                [DDXMLNode attributeWithName:DMProfileMapMinScalePower stringValue:[@(self.minScalePower) stringValue]],
                                [DDXMLNode attributeWithName:DMProfileMapMaxScalePower stringValue:[@(self.maxScalePower) stringValue]]]];
    
    DDXMLElement *packageElement = [[DDXMLElement alloc] initWithName:DMProfilePack];
    [packageElement setAttributes:@[[DDXMLNode attributeWithName:DMProfilePackVersion stringValue:@"1.0"],
                                    [DDXMLNode attributeWithName:DMProfilePackUserID stringValue:[[NSUUID UUID] UUIDString]]]];
	
    DDXMLElement *rootElement = [[DDXMLElement alloc] initWithName:DMProfileRoot];
    [rootElement setChildren:@[packageElement,
                               mapElement]];
    
    // Write XML
    NSError *error = nil;
    DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithXMLString:[rootElement XMLString] options:0 error:&error];
    if (error) {
        NSLog(@"%@\n%@",[error localizedDescription],[NSThread callStackSymbols]);
        return nil;
    }
    else {
        return [xmlDoc XMLData];
    }
}

@end