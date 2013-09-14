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
#import "DMMImageOperation.h"

#import <ZipKit/ZKFileArchive.h>
#import <ZipKit/ZKDefs.h>

@interface DMMTaskOperation ()

@property (nonatomic, strong) NSImage *srcImage;
@property (nonatomic, strong) NSOperationQueue *imageProcessingQueue;

@end

@implementation DMMTaskOperation {
    NSUInteger numberOfTiles, numberOfTilesCompleted;
    BOOL mIsExecuting,mIsFinished;
}

- (id)init {
    self = [super init];
    if (self) {
        self.imageProcessingQueue = [NSOperationQueue new];
        [self.imageProcessingQueue setMaxConcurrentOperationCount:[[NSProcessInfo processInfo] processorCount]];
        
        [self addObserver:self forKeyPath:@"isCancelled" options:0 context:NULL];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"isCancelled"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isCancelled"]) {
        [self.imageProcessingQueue cancelAllOperations];
    }
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
    
    if (self.task &&
        self.task.state != DMPTaskStateSuccessful &&
        [[NSFileManager defaultManager] fileExistsAtPath:self.task.inputFilePath]) {
        [self willChangeValueForKey:@"isExecuting"];
        mIsExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [self doTask];
    }
    else {
        [self doFinish];
    }
}

#pragma mark -

- (void)pauseImageProcessing {
    [self.imageProcessingQueue setSuspended:YES];
}

- (void)continueImageProcessing {
    [self.imageProcessingQueue setSuspended:NO];
}

- (void)doFinish {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    mIsExecuting = NO;
    mIsFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)doTask {
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

- (void)sliceImageForZoomScale:(float)zoomScale {
    if (self.isCancelled) {
        [self doFinish];
        return;
    }
    
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
            if (self.isCancelled) {
                [self doFinish];
                return;
            }
			tileWidth = ((outputWidth - tileX) < tileSize)? (outputWidth - tileX) : tileSize;
			tileHeight = ((tileY - 0) < tileSize)? (tileY - 0) : tileSize;
            
			sourceRect.origin.x = tileX / adjustedZoom;
			sourceRect.origin.y = (tileY - tileHeight) / adjustedZoom;
			sourceRect.size.width = tileWidth / adjustedZoom;
			sourceRect.size.height = tileHeight / adjustedZoom;
            
			NSString *filename = [NSString stringWithFormat:@"map-%@-%d-%d.%@", [NSString stringWithFormat:@"%f",zoomScale], fileX, fileY, [DMTask fileExtensionFromFormat:self.task.outputFormatIndex]];
            NSString *imageFilePath = [self.task.outputFolderPath stringByAppendingPathComponent:filename];
            
            DMMImageOperation *imageOperation = [DMMImageOperation new];
            imageOperation.srcImage = self.srcImage;
            imageOperation.sourceRect = sourceRect;
            imageOperation.destinationSize = CGSizeMake(tileWidth, tileHeight);
            imageOperation.outputPath = imageFilePath;
            imageOperation.outputFormat = self.task.outputFormatIndex;
            imageOperation.jpgQuality = [self.task jpgQuality];
            [imageOperation setCompletionBlock:^{
                [self imageOperationCompletion];
            }];
            [self.imageProcessingQueue addOperation:imageOperation];
			
            ++fileX;
		}
		++fileY;
	}
}

- (void)imageOperationCompletion {
    if (self.isCancelled) {
        [self doFinish];
        return;
    }
    
    @synchronized(self) {
        ++numberOfTilesCompleted;
        self.task.progress = (float)numberOfTilesCompleted/numberOfTiles;
        [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification object:self.task];
    }
    
    if (numberOfTilesCompleted == numberOfTiles) {
        NSError *error;
        DMPTaskState resultStatus = DMPTaskStateSuccessful;
        
        // Check if all images are processed
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.task.outputFolderPath
                                                                                error:&error];
        if ([contents count] != numberOfTiles + 1) {
            resultStatus = DMPTaskStateError;
        }
        else {
            // Generate final package
            NSString *zipFilePath = [self.task.outputFolderPath stringByAppendingPathExtension:@"map"];
            ZKFileArchive *archive = [ZKFileArchive archiveWithArchivePath:zipFilePath];
            NSInteger result = [archive deflateDirectory:self.task.outputFolderPath
                                          relativeToPath:[self.task.outputFolderPath stringByDeletingLastPathComponent]
                                       usingResourceFork:NO];
            if (result == zkSucceeded) {
                [[NSFileManager defaultManager] removeItemAtPath:self.task.outputFolderPath error:&error];
                if (error) {
                    NSLog(@"%@",[error localizedDescription]);
                    resultStatus = DMPTaskStateError;
                }
            }
            else {
                resultStatus = DMPTaskStateError;
            }
        }
        
        [self taskDidCompleteWithStatus:resultStatus];
    }
}

- (void)taskDidCompleteWithStatus:(DMPTaskState)status {
    self.task.state = status;
    self.task.progress = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification object:self.task];
    [self doFinish];
}

@end
