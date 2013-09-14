//
//  DMMTaskOperation.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 14/09/13.
//
//

#import "DMMTaskOperation.h"

#import "DMTask.h"

@interface DMMTaskOperation ()

@property (nonatomic, strong) NSImage *srcImage;

@end

@implementation DMMTaskOperation

- (void)main {
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.task.inputFilePath] &&
        (self.task.state == DMPTaskStateReady || self.task.state == DMPTaskStateRunning)) {
        self.task.state = DMPTaskStateRunning;
        self.task.progress = 0;
        [self saveTaskList];
        
        // Load the image
        self.currentImage = [[NSImage alloc] initWithContentsOfFile:nextTask.inputFilePath];
        
        // Calculate tiles count
        NSUInteger tileSize = [DMTask tileSizeFromSizeIndex:nextTask.tileSizeIndex];
        numberOfTiles = 0;
        numberOfTilesCompleted = 0;
        for (CGFloat scale = nextTask.minScalePower; scale <= nextTask.maxScalePower; ++scale) {
            CGFloat zoomScale = pow(2,scale);
            CGFloat adjustedZoom = zoomScale * nextTask.sourcePixelSize.width / nextTask.sourceImageSize.width;
            
            // Scaled Image Size
            double scaledImageWidth = nextTask.sourceImageSize.width * adjustedZoom;
            double scaledImageHeight = nextTask.sourceImageSize.height * adjustedZoom;
            
            numberOfTiles += ceil (scaledImageHeight / tileSize) * ceil (scaledImageWidth / tileSize) ;
        }
        
        // Verify output folder path
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.task.outputFolderPath])
            [[NSFileManager defaultManager] createDirectoryAtPath:self.task.outputFolderPath withIntermediateDirectories:YES attributes:nil error:NULL];
        
        // Write map profile
        NSString *profilePath = [self.task.outputFolderPath stringByAppendingPathComponent:@"profile.xml"];
        NSData *profileData = [[self.task mapProfile] xmlData];
        if (profileData) {
            NSError *error = nil;
            [profileData writeToFile:profilePath options:NSDataWritingAtomic error:&error];
            if (error) {
                NSLog(@"%@\n%@",[error localizedDescription],[NSThread callStackSymbols]);
            }
        }
        
        // Generate slices for each scale level
        for (double currentScale = [self.task minScalePower]; currentScale <= [self.task maxScalePower]; ++currentScale) {
            [self sliceImageForZoomScale:pow(2, currentScale)];
        }
    }
}

@end
