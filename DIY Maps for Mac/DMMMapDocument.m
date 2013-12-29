//
//  DMMMapDocument.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 08/12/13.
//
//

#import "DMMMapDocument.h"
#import "DMMapFile.h"

@implementation DMMMapDocument

- (NSString *)windowNibName {
    return @"DMMMapDocument";
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
    
    self.mapFile = [DMMapFile mapFileWithPath:[absoluteURL path]];
    
    return YES;
}

@end
