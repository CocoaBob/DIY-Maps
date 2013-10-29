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
#import "DMMAppDelegate.h"
#import "DMMPreviewWindowController.h"

#import <ZipKit/ZKFileArchive.h>
#import <ZipKit/ZKDefs.h>

@interface DMMTaskOperation ()

@property (nonatomic, strong) NSImage *srcImage;
@property (nonatomic, strong) NSOperationQueue *imageProcessingQueue;
@property (nonatomic, strong) NSMutableArray *lastThreeTilesDurations;

@end

@implementation DMMTaskOperation {
    NSUInteger numberOfTiles, numberOfTilesCompleted;
    BOOL mIsExecuting,mIsFinished;
}

- (id)init {
    self = [super init];
    if (self) {
        self.lastThreeTilesDurations = [NSMutableArray new];
        
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

#pragma mark - NSOperation Overritten

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
        self.task.status != DMTaskStatusSuccessful &&
        [[NSFileManager defaultManager] fileExistsAtPath:self.task.inputFilePath]) {
        // Update status
        [self willChangeValueForKey:@"isExecuting"];
        mIsExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [DMMTaskManager shared].currentRunningOperation = self;

        // Begin the task
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
    // 1st time to call doFinish, it may be called multiple times
    if (!mIsFinished) {
        [DMMTaskManager shared].currentRunningOperation = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification object:nil];
    }
    
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    mIsExecuting = NO;
    mIsFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)doTask {
    self.task.status = DMTaskStatusLoading;
    self.task.progress = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification object:self.task];
    
    // Load the image
    self.srcImage = [[NSImage alloc] initWithContentsOfFile:self.task.inputFilePath];
    
    // Calculate tiles count
    NSUInteger tileSize = [DMTask tileSizeFromSizeIndex:self.task.tileSizeIndex];
    numberOfTiles = numberOfTilesCompleted = 0;
    for (CGFloat scale = self.task.minScalePower; scale <= self.task.maxScalePower; ++scale) {
        CGFloat zoomScale = pow(2,scale);
        CGFloat adjustedZoom = zoomScale * self.task.sourcePixelSize.width / self.task.sourceImageSize.width;
        
        // Scaled Image Size
        double scaledImageWidth = self.task.sourceImageSize.width * adjustedZoom;
        double scaledImageHeight = self.task.sourceImageSize.height * adjustedZoom;
        
        numberOfTiles += ceil (scaledImageHeight / tileSize) * ceil (scaledImageWidth / tileSize) ;
    }
    
    // Prepare output folder
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.task.outputFolderPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:self.task.outputFolderPath withIntermediateDirectories:YES attributes:nil error:NULL];
    
    // Write profile
    NSString *profilePath = [self.task.outputFolderPath stringByAppendingPathComponent:@"profile.xml"];
    NSData *profileData = [[self.task mapProfile] xmlData];
    if (!profileData) {
        [self handleError:[NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:@"No profile xml data."}]];
        return;
    }
    NSError *error = nil;
    if (![profileData writeToFile:profilePath options:NSDataWritingAtomic error:&error]) {
        if (!error)
            error = [NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Failed to write profile.xml!"}];
        [self handleError:error];
        return;
    }
    
    // Generate slices for each scale level
    self.task.status = DMTaskStatusSlicing;
    for (double currentScalePower = self.task.minScalePower; currentScalePower <= self.task.maxScalePower; ++currentScalePower) {
        [self sliceImageForZoomScale:pow(2, currentScalePower)];
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
    
    static dispatch_queue_t imageOperationCompletionQueue = nil;
    if (!imageOperationCompletionQueue) {
        imageOperationCompletionQueue = dispatch_queue_create("ImageOperationCompletionQueue", DISPATCH_QUEUE_SERIAL);
    }
    
	// Create slices
	fileY = 0;
	for (tileY = outputHeight; tileY > 0; tileY -= tileSize) {
		fileX = 0;
		for (tileX = 0.0f; tileX < outputWidth; tileX += tileSize) {
            if (self.isCancelled) {
                [self doFinish];
                return;
            }
			tileWidth = MIN((outputWidth - tileX), tileSize);
			tileHeight = MIN((tileY - 0), tileSize);
            
            NSRect sourceImageRect;
			sourceImageRect.origin.x = tileX / adjustedZoom;
			sourceImageRect.origin.y = (tileY - tileHeight) / adjustedZoom;
			sourceImageRect.size.width = tileWidth / adjustedZoom;
			sourceImageRect.size.height = tileHeight / adjustedZoom;
            
			NSString *filename = [NSString stringWithFormat:@"map-%@-%d-%d.%@", [NSString stringWithFormat:@"%f",zoomScale], fileX, fileY, [DMTask fileExtensionFromFormat:self.task.outputFormatIndex]];
            NSString *imageFilePath = [self.task.outputFolderPath stringByAppendingPathComponent:filename];
            
            DMMImageOperation *imageOperation = [DMMImageOperation new];
            __block DMMImageOperation *weakImageOperation = imageOperation;
            imageOperation.srcImage = self.srcImage;
            imageOperation.sourceRect = sourceImageRect;
            imageOperation.destinationSize = CGSizeMake(tileWidth, tileHeight);
            imageOperation.outputPath = imageFilePath;
            imageOperation.outputFormat = self.task.outputFormatIndex;
            imageOperation.jpgQuality = [self.task jpgQuality];
            [imageOperation setCompletionBlock:^{
                dispatch_async(imageOperationCompletionQueue, ^{
                    if (weakImageOperation) {
                        [self updateLastTileDuration:-[weakImageOperation.beginTime timeIntervalSinceNow]];
                        weakImageOperation = nil;
                        self.task.remainingTime = [self remainingTime];
                    }
                    [self imageOperationCompletionWithRect:sourceImageRect zoomScale:zoomScale];
                });
            }];
            [self.imageProcessingQueue addOperation:imageOperation];
			
            ++fileX;
		}
		++fileY;
	}
}

- (void)imageOperationCompletionWithRect:(CGRect)completedRect zoomScale:(CGFloat)zoomScale {
    if (self.isCancelled) {
        [self doFinish];
        return;
    }
    
    @synchronized(self) {
        ++numberOfTilesCompleted;
        self.task.progress = (float)numberOfTilesCompleted/numberOfTiles;
        [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification
                                                            object:self.task
                                                          userInfo:@{@"CompletedRect":[NSValue valueWithRect:NSRectFromCGRect(completedRect)],
                                                                     @"ZoomScale":@(zoomScale)}];
    }
    
    NSError *error;
    
    // The last tile
    if (numberOfTilesCompleted == numberOfTiles) {
        // Check if all images are processed
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.task.outputFolderPath error:&error];
        if (error) {
            [self handleError:error];
        }
        else if ([contents count] != numberOfTiles + 1) {
            [self handleError:[NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Some output images are missing!"}]];
        }
        else {
            [self createPackage];
        }
    }
}

- (void)createPackage {
    // Start to create package
    self.task.status = DMTaskStatusPacking;
    [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification object:self.task];
    
    // Create the package
    NSString *zipFilePath = [self.task.outputFolderPath stringByAppendingPathExtension:@"map"];
    ZKFileArchive *archive = [ZKFileArchive archiveWithArchivePath:zipFilePath];
    NSInteger result = [archive deflateDirectory:self.task.outputFolderPath
                                  relativeToPath:[self.task.outputFolderPath stringByDeletingLastPathComponent]
                               usingResourceFork:NO];
    if (result == zkSucceeded) {
        [[NSFileManager defaultManager] removeItemAtPath:self.task.outputFolderPath error:nil];
        [self taskDidCompleteWithStatus:DMTaskStatusSuccessful];
    }
    else {
        [self handleError:[NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Failed to create package!"}]];
    }
}

- (void)taskDidCompleteWithStatus:(DMTaskStatus)status {
    self.task.status = status;
    self.task.progress = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification object:self.task];
    [self doFinish];
}

- (void)handleError:(NSError *)error {
    if (error) {
        NSLog(@"%@ %@\n%@",[error localizedDescription],[error localizedFailureReason],[NSThread callStackSymbols]);
        self.task.logs = [NSString stringWithFormat:@"%@\n%@ %@",self.task.logs,[error localizedDescription],[error localizedFailureReason]];
    }
    [self taskDidCompleteWithStatus:DMTaskStatusError];
}

#define AVERAGE_SAMPLING_COUNT 10

- (void)updateLastTileDuration:(NSTimeInterval)tileDuration {
    while ([self.lastThreeTilesDurations count] >= AVERAGE_SAMPLING_COUNT) {
        [self.lastThreeTilesDurations removeLastObject];
    }
    [self.lastThreeTilesDurations insertObject:@(tileDuration) atIndex:0];
}

- (NSTimeInterval)remainingTime {
    if ([self.lastThreeTilesDurations count] == 0) {
        return -1;
    }
    else {
        __block NSTimeInterval sum = 0;
        [self.lastThreeTilesDurations enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
            sum += [obj doubleValue];
        }];
        NSTimeInterval average = sum / [self.lastThreeTilesDurations count];
        NSTimeInterval remaining = average * (numberOfTiles - numberOfTilesCompleted);
        return remaining;
    }
}

@end
