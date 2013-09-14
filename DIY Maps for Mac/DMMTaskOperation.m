//
//  DMMTaskOperation.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 14/09/13.
//
//

#import "DMMTaskOperation.h"

#import "DMTask.h"
#import "DMMTaskManager.h"
#import "DMProfile.h"
#import "DMImageProcessor.h"

#import <ZipKit/ZKFileArchive.h>
#import <ZipKit/ZKDefs.h>

@interface DMMTaskOperation ()

@property (nonatomic, strong) NSImage *srcImage;

@end

@implementation DMMTaskOperation {
    NSUInteger numberOfTiles, numberOfTilesCompleted;
    BOOL mIsExecuting,mIsFinished;
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return mIsExecuting;
}

- (BOOL)isFinished {
    return mIsFinished;
}

- (void)finish {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    mIsExecuting = NO;
    mIsFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)start {
    if (self.task &&
        [[NSFileManager defaultManager] fileExistsAtPath:self.task.inputFilePath] &&
        (self.task.state == DMPTaskStateReady || self.task.state == DMPTaskStateRunning)) {
        [self willChangeValueForKey:@"isExecuting"];
        mIsExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
        self.task.state = DMPTaskStateRunning;
        self.task.progress = 0;
        
        // Load the image
        self.srcImage = [[NSImage alloc] initWithContentsOfFile:self.task.inputFilePath];
        
        // Calculate tiles count
        NSUInteger tileSize = [DMTask tileSizeFromSizeIndex:self.task.tileSizeIndex];
        numberOfTiles = 0;
        numberOfTilesCompleted = 0;
        for (CGFloat scale = self.task.minScalePower; scale <= self.task.maxScalePower; ++scale) {
            CGFloat zoomScale = pow(2,scale);
            CGFloat adjustedZoom = zoomScale * self.task.sourcePixelSize.width / self.task.sourceImageSize.width;
            
            // Scaled Image Size
            double scaledImageWidth = self.task.sourceImageSize.width * adjustedZoom;
            double scaledImageHeight = self.task.sourceImageSize.height * adjustedZoom;
            
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
    else {
        [self finish];
    }
}

- (void)sliceImageForZoomScale:(float)zoomScale {
    if (self.isCancelled) return;
    
	// Adjust zoom for difference between image size and pixel size
	CGFloat adjustedZoom = zoomScale * self.task.sourcePixelSize.width / self.task.sourceImageSize.width;
    
	int tileX, tileY, tileWidth, tileHeight, fileX, fileY;
	int outputWidth = floor (self.task.sourcePixelSize.width * zoomScale);
	int outputHeight = floor (self.task.sourcePixelSize.height * zoomScale);
    int tileSize = [DMTask tileSizeFromSizeIndex:self.task.tileSizeIndex];
    
	NSRect sourceRect = NSMakeRect(0, 0, self.task.sourceImageSize.width, self.task.sourceImageSize.height);
    
	// Create slices
	fileY = 0;
	for (tileY = outputHeight; tileY > 0; tileY -= tileSize) {
		fileX = 0;
		for (tileX = 0.0f; tileX < outputWidth; tileX += tileSize) {
            if (self.isCancelled) return;
			tileWidth = ((outputWidth - tileX) < tileSize)? (outputWidth - tileX) : tileSize;
			tileHeight = ((tileY - 0) < tileSize)? (tileY - 0) : tileSize;
            
			sourceRect.origin.x = tileX / adjustedZoom;
			sourceRect.origin.y = (tileY - tileHeight) / adjustedZoom;
			sourceRect.size.width = tileWidth / adjustedZoom;
			sourceRect.size.height = tileHeight / adjustedZoom;
            
			NSString *filename = [NSString stringWithFormat:@"map-%@-%d-%d.%@", [NSString stringWithFormat:@"%f",zoomScale], fileX, fileY, [DMTask fileExtensionFromFormat:self.task.outputFormatIndex]];
            NSString *imageFilePath = [self.task.outputFolderPath stringByAppendingPathComponent:filename];
            NSDictionary *userInfo = @{@"sourceRect": [NSValue valueWithRect:sourceRect],
                                       @"destinationSize": [NSValue valueWithSize:NSMakeSize(tileWidth, tileHeight)],
                                       @"imageFilePath": imageFilePath};
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self processImage:userInfo];
            });
			++fileX;
		}
		++fileY;
	}
}

- (void)processImage:(NSDictionary *)userInfo {
    @autoreleasepool {
        if (self.isCancelled) return;
        NSString *imageFilePath = userInfo[@"imageFilePath"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:imageFilePath]) {
            NSImage *thumbnail = [DMImageProcessor thumbnailWithImage:self.srcImage
                                                              srcRect:[(NSValue *)userInfo[@"sourceRect"] rectValue]
                                                             destSize:[(NSValue *)userInfo[@"destinationSize"] sizeValue]];
            if (self.isCancelled) return;
            NSData *imageData = [thumbnail TIFFRepresentation];
            NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
            if (self.isCancelled) return;
            if (self.task.outputFormatIndex == DMPOutputFormatPNG)
                imageData = [imageRep representationUsingType:NSPNGFileType properties:nil];
            else
                imageData = [imageRep representationUsingType:NSJPEGFileType properties:@{NSImageCompressionFactor:[NSNumber numberWithFloat:[self.task jpgQuality]]}];
            if (self.isCancelled) return;
            [imageData writeToFile:imageFilePath options:0 error:NULL];
        }
        // Update progress
        @synchronized(self) {
            ++numberOfTilesCompleted;
            self.task.progress = (float)numberOfTilesCompleted/numberOfTiles;
            [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification object:self.task];
        }
        
        if (numberOfTilesCompleted == numberOfTiles) {
            NSString *zipFilePath = [self.task.outputFolderPath stringByAppendingPathExtension:@"map"];
            ZKFileArchive *archive = [ZKFileArchive archiveWithArchivePath:zipFilePath];
            NSInteger result = [archive deflateDirectory:self.task.outputFolderPath
                                          relativeToPath:[self.task.outputFolderPath stringByDeletingLastPathComponent]
                                       usingResourceFork:NO];
            DMPTaskState resultStatus = DMPTaskStateSuccessful;
            if (result == zkSucceeded) {
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:self.task.outputFolderPath error:&error];
                if (error) {
                    NSLog(@"%@",[error localizedDescription]);
                    resultStatus = DMPTaskStateError;
                }
            }
            else {
                resultStatus = DMPTaskStateError;
            }
            [self taskDidCompleteWithStatus:resultStatus];
        }
    }
}

- (void)taskDidCompleteWithStatus:(DMPTaskState)status {
    self.task.state = status;
    self.task.progress = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification object:self.task];
    [self finish];
}

@end
