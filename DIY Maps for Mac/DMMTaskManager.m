//
//  DMPTaskManager.m
//  DIY Maps
//
//  Created by CocoaBob on 16/08/13.
//
//

#import "DMMTaskManager.h"

#import "DMImageProcessor.h"
#import "DMMAppDelegate.h"
#import "DMTask.h"
#import "DMProfile.h"

#import <ZipKit/ZKFileArchive.h>
#import <ZipKit/ZKDefs.h>

@interface DMMTaskManager ()

@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, strong) NSOperationQueue *processQueue;

@property (nonatomic, strong) DMTask *currentTask;
@property (nonatomic, strong) NSImage *currentImage;

@end

@implementation DMMTaskManager {
    NSUInteger numberOfTiles, numberOfTilesCompleted;
}

static DMMTaskManager *sharedInstance = nil;

+ (DMMTaskManager *)shared {
	@synchronized(self) {
		if (!sharedInstance)
			sharedInstance = [DMMTaskManager new];
	}
	return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        [self addObserver:self forKeyPath:@"tasks" options:0 context:NULL];
        [self loadTaskList];
        self.processQueue = [NSOperationQueue new];
        self.processQueue.maxConcurrentOperationCount = [[NSProcessInfo processInfo] processorCount];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"tasks"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"tasks"]) {
        [self willChangeValueForKey:@"tasksCount"];
        [self didChangeValueForKey:@"tasksCount"];
        [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskListDidUpdateNotification object:nil];
        [self saveTaskList];
    }
}

#pragma mark Task Management

- (void)addNewTasksWithPaths:(NSArray *)inFilePaths {
    [inFilePaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *filePath = [obj isKindOfClass:[NSURL class]]?[(NSURL *)obj path]:(NSString *)obj;
        [self addNewTaskWithPath:filePath];
    }];
}

- (void)addNewTaskWithPath:(NSString *)inFilePath {
    __block BOOL alreadyExists = NO;
    [self.tasks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DMTask *task = (DMTask *)obj;
        if ([task.inputFilePath isEqualToString:inFilePath]) {
            alreadyExists = YES;
            *stop = YES;
        }
    }];
    if (!alreadyExists) {
        DMTask *newTask = [DMTask new];
        newTask.inputFilePath = inFilePath;
        newTask.outputFolderPath = [inFilePath stringByDeletingPathExtension];
        NSImage *tempImage = [[NSImage alloc] initWithContentsOfFile:newTask.inputFilePath];
        if (tempImage) {
            newTask.sourceImageSize = CGSizeMake ([tempImage size].width, [tempImage size].height);
            newTask.sourcePixelSize = [DMImageProcessor pixelDimensionsOfImage:tempImage];
            
            [self addTask:newTask];
        }
    }
}

- (NSUInteger)tasksCount {
    return [self.tasks count];
}

- (DMTask *)taskAtIndex:(NSUInteger)index {
    if ((index + 1) > [self tasksCount]) {
        return nil;
    }
    return [self.tasks objectAtIndex:index];
}

- (NSUInteger)indexOfTask:(DMTask *)task {
    return [self.tasks indexOfObject:task];
}

- (void)addTask:(DMTask *)newTask {
    [self willChangeValueForKey:@"tasks"];
    [self.tasks addObject:newTask];
    [self didChangeValueForKey:@"tasks"];
}

- (void)removeTaskAtIndex:(NSUInteger)index {
    if ((index + 1) > [self tasksCount]) {
        return;
    }
    [self willChangeValueForKey:@"tasks"];
    [self.tasks removeObjectAtIndex:index];
    [self didChangeValueForKey:@"tasks"];
}

- (void)saveTaskList {
    DefaultsSet(Object, @"TaskList", [NSKeyedArchiver archivedDataWithRootObject:self.tasks]);
}

- (void)loadTaskList {
    NSData *savedData = DefaultsGet(object, @"TaskList");
    self.tasks = (savedData)?[[NSKeyedUnarchiver unarchiveObjectWithData:savedData] mutableCopy]:[@[] mutableCopy];
}

- (void)verifyAllTasks {
    [self.tasks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DMTask *aTask = (DMTask *)obj;
        if (aTask.state == DMPTaskStateSuccessful ||
            aTask.state == DMPTaskStateRunning) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:[aTask.outputFolderPath stringByAppendingPathExtension:@"map"]]) {
                aTask.state = DMPTaskStateReady;
            }
        }
    }];
    [self saveTaskList];
    [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskListDidUpdateNotification object:nil];
}

#pragma mark Run Tasks

- (void)runTaskAtIndex:(NSUInteger)index {
    DMTask *nextTask = [self taskAtIndex:index];
    if (nextTask) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:nextTask.inputFilePath] &&
            (nextTask.state == DMPTaskStateReady || nextTask.state == DMPTaskStateRunning)) {
            self.isProcessing = YES;
            self.isSuspended = NO;
            self.isCancelled = NO;
            self.currentTask = nextTask;
            self.currentTask.state = DMPTaskStateRunning;
            self.currentTask.progress = 0;
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
            if (![[NSFileManager defaultManager] fileExistsAtPath:self.currentTask.outputFolderPath])
                [[NSFileManager defaultManager] createDirectoryAtPath:self.currentTask.outputFolderPath withIntermediateDirectories:YES attributes:nil error:NULL];
            
            // Write map profile
            NSString *profilePath = [self.currentTask.outputFolderPath stringByAppendingPathComponent:@"profile.xml"];
            NSData *profileData = [[self.currentTask mapProfile] xmlData];
            if (profileData) {
                NSError *error = nil;
                [profileData writeToFile:profilePath options:NSDataWritingAtomic error:&error];
                if (error) {
                    NSLog(@"%@\n%@",[error localizedDescription],[NSThread callStackSymbols]);
                }
            }
            
            // Generate slices for each scale level
            for (double currentScale = [self.currentTask minScalePower]; currentScale <= [self.currentTask maxScalePower]; ++currentScale) {
                [self sliceImageForZoomScale:pow(2, currentScale)];
            }
        }
        else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self runTaskAtIndex:index+1];
            });
        }
    }
}

- (void)currentTaskDidCompleteWithStatus:(DMPTaskState)status {
    self.isProcessing = NO;
    self.currentTask.state = status;
    self.currentTask.progress = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification object:self.currentTask];
    [self saveTaskList];
    if (!self.isCancelled && !self.isSuspended) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self runTaskAtIndex:[self.tasks indexOfObject:self.currentTask]+1];
        });
    }
}

- (void)pauseProcessing {
    [self.processQueue setSuspended:YES];
    self.isSuspended = YES;
}

- (void)continueProcessing {
    [self.processQueue setSuspended:NO];
    self.isSuspended = NO;
    if (!self.isProcessing) {
        [self runTaskAtIndex:[self.tasks indexOfObject:self.currentTask]];
    }
}

- (void)stopProcessing {
    self.isProcessing = NO;
    self.isCancelled = YES;
    [self.processQueue cancelAllOperations];
}

#pragma mark Process Management

- (void)processImage:(NSDictionary *)userInfo {
    @autoreleasepool {
        if (self.isCancelled) return;
        NSString *imageFilePath = userInfo[@"imageFilePath"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:imageFilePath]) {
            NSImage *thumbnail = [DMImageProcessor thumbnailWithImage:self.currentImage
                                                               srcRect:[(NSValue *)userInfo[@"sourceRect"] rectValue]
                                                              destSize:[(NSValue *)userInfo[@"destinationSize"] sizeValue]];
            if (self.isCancelled) return;
            NSData *imageData = [thumbnail TIFFRepresentation];
            NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
            if (self.isCancelled) return;
            if (self.currentTask.outputFormatIndex == DMPOutputFormatPNG)
                imageData = [imageRep representationUsingType:NSPNGFileType properties:nil];
            else
                imageData = [imageRep representationUsingType:NSJPEGFileType properties:@{NSImageCompressionFactor:[NSNumber numberWithFloat:[self.currentTask jpgQuality]]}];
            if (self.isCancelled) return;
            [imageData writeToFile:imageFilePath options:0 error:NULL];
        }
        // Update progress
        @synchronized(self) {
            numberOfTilesCompleted++;
            self.currentTask.progress = (float)numberOfTilesCompleted/numberOfTiles;
            [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification object:self.currentTask];
        }
        
        if (numberOfTilesCompleted == numberOfTiles) {
            NSString *zipFilePath = [self.currentTask.outputFolderPath stringByAppendingPathExtension:@"map"];
            ZKFileArchive *archive = [ZKFileArchive archiveWithArchivePath:zipFilePath];
            NSInteger result = [archive deflateDirectory:self.currentTask.outputFolderPath
                                          relativeToPath:[self.currentTask.outputFolderPath stringByDeletingLastPathComponent]
                                       usingResourceFork:NO];
            DMPTaskState resultStatus = DMPTaskStateSuccessful;
            if (result == zkSucceeded) {
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:self.currentTask.outputFolderPath error:&error];
                if (error) {
                    NSLog(@"%@",[error localizedDescription]);
                    resultStatus = DMPTaskStateError;
                }
            }
            else {
                resultStatus = DMPTaskStateError;
            }
            [self currentTaskDidCompleteWithStatus:resultStatus];
        }
    }
}

- (void)sliceImageForZoomScale:(float)zoomScale {
    if (self.isCancelled) return;
    
	// Adjust zoom for difference between image size and pixel size
	CGFloat adjustedZoom = zoomScale * self.currentTask.sourcePixelSize.width / self.currentTask.sourceImageSize.width;
    
	int tileX, tileY, tileWidth, tileHeight, fileX, fileY;
	int outputWidth = floor (self.currentTask.sourcePixelSize.width * zoomScale);
	int outputHeight = floor (self.currentTask.sourcePixelSize.height * zoomScale);
    int tileSize = [DMTask tileSizeFromSizeIndex:self.currentTask.tileSizeIndex];
    
	NSRect sourceRect = NSMakeRect(0, 0, self.currentTask.sourceImageSize.width, self.currentTask.sourceImageSize.height);
    
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
            
			NSString *filename = [NSString stringWithFormat:@"map-%@-%d-%d.%@", [NSString stringWithFormat:@"%f",zoomScale], fileX, fileY, [DMTask fileExtensionFromFormat:self.currentTask.outputFormatIndex]];
            NSString *imageFilePath = [self.currentTask.outputFolderPath stringByAppendingPathComponent:filename];
            NSDictionary *userInfo = @{@"sourceRect": [NSValue valueWithRect:sourceRect],
                                       @"destinationSize": [NSValue valueWithSize:NSMakeSize(tileWidth, tileHeight)],
                                       @"imageFilePath": imageFilePath};
            [self.processQueue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(processImage:) object:userInfo]];
            
			++fileX;
		}
		++fileY;
	}
}

@end
