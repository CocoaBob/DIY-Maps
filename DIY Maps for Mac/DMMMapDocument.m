//
//  DMMMapDocument.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 08/12/13.
//
//

#import "DMMMapDocument.h"
#import "CBMapFile.h"

@implementation DMMMapDocument

- (NSString *)windowNibName {
    return @"DMMMapDocument";
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
    
    self.mapFile = [CBMapFile mapFileWithPath:[absoluteURL path]];
    
    return YES;
}

@end
