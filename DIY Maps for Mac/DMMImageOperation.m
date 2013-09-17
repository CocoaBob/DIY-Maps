//
//  DMMImageOperation.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 14/09/13.
//
//

#import "DMMImageOperation.h"

#import "DMImageProcessor.h"

@implementation DMMImageOperation {
    BOOL mIsExecuting,mIsFinished;
}

#pragma mark NSOperation Overritten

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return mIsExecuting;
}

- (BOOL)isFinished {
    return mIsFinished;
}

- (void)start {
    if (self.isCancelled) {
        [self doFinish];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    mIsExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self processImage];
}

#pragma mark -

- (void)doFinish {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    mIsExecuting = NO;
    mIsFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)processImage {
    if (self.isCancelled) {
        [self doFinish];
        return;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.outputPath]) {
        NSImage *thumbnail = [DMImageProcessor thumbnailWithImage:self.srcImage
                                                          cropRect:self.sourceRect
                                                         outputSize:self.destinationSize];
        
        if (self.isCancelled) {
            [self doFinish];
            return;
        }
        NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[thumbnail TIFFRepresentation]];
        
        if (self.isCancelled) {
            [self doFinish];
            return;
        }
        if (imageRep) {
            NSData *imageData = nil;
            if (self.outputFormat == DMOutputFormatPNG)
                imageData = [imageRep representationUsingType:NSPNGFileType properties:nil];
            else
                imageData = [imageRep representationUsingType:NSJPEGFileType properties:@{NSImageCompressionFactor:@(self.jpgQuality)}];
            
            if (self.isCancelled) {
                [self doFinish];
                return;
            }
            if (imageData) {
                [imageData writeToFile:self.outputPath options:0 error:NULL];
            }
        }
    }
    [self doFinish];
}

@end
