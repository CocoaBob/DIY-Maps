//
//  DMPTaskManager.m
//  DIY Maps
//
//  Created by CocoaBob on 16/08/13.
//
//

#import "DMMTaskManager.h"

#import "DMImageProcessor.h"
#import "DMMTaskOperation.h"
#import "DMTask.h"

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
        self.processQueue.maxConcurrentOperationCount = 1;
        [self.processQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
        [self.processQueue addObserver:self forKeyPath:@"isSuspended" options:0 context:NULL];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"tasks"];
    [self.processQueue removeObserver:self forKeyPath:@"operationCount"];
    [self.processQueue removeObserver:self forKeyPath:@"isSuspended"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"tasks"]) {
        [self willChangeValueForKey:@"tasksCount"];
        [self didChangeValueForKey:@"tasksCount"];
        [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskListDidUpdateNotification object:nil];
        [self saveTaskList];
    }
    else if ([keyPath isEqualToString:@"operationCount"] ||
             [keyPath isEqualToString:@"isSuspended"]) {
        if (self.isSuspended != [self.processQueue isSuspended]) {
            self.isSuspended = [self.processQueue isSuspended];
            DMMTaskOperation *operation = [self currentRunningOperation];
            if (operation) {
                if (self.isSuspended)
                    [operation pauseImageProcessing];
                else
                    [operation continueImageProcessing];
            }
        }
        self.isProcessing = self.isSuspended?YES:([self.processQueue operationCount] > 0);
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

- (NSUInteger)indexOfTask:(DMTask *)task {
    return [self.tasks indexOfObject:task];
}

- (DMTask *)taskAtIndex:(NSUInteger)index {
    if ((index + 1) > [self tasksCount]) {
        return nil;
    }
    return [self.tasks objectAtIndex:index];
}

- (DMTask *)taskWithInputPath:(NSString *)intputPath {
    __block DMTask *returnValue = nil;
    [self.tasks enumerateObjectsUsingBlock:^(DMTask *obj, NSUInteger idx, BOOL *stop) {
        if ([intputPath isEqualToString:obj.inputFilePath]) {
            returnValue = obj;
            *stop = YES;
        }
    }];
    return returnValue;
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
    _tasks = (savedData)?[[NSKeyedUnarchiver unarchiveObjectWithData:savedData] mutableCopy]:[@[] mutableCopy];
}

- (void)verifyAllTasks {
    __block BOOL updated = NO;
    [self.tasks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DMTask *aTask = (DMTask *)obj;
        if (aTask.state != DMPTaskStateRunning) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:[aTask.outputFolderPath stringByAppendingPathExtension:@"map"]]) {
                if (aTask.state != DMPTaskStateReady) {
                    updated = YES;
                    aTask.state = DMPTaskStateReady;
                }
            }
        }
    }];
    
    if (updated) {
        [self saveTaskList];
        [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskListDidUpdateNotification object:nil];
    }
}

- (DMMTaskOperation *)currentRunningOperation {
    __block DMMTaskOperation *operation = nil;
    [[self.processQueue operations] enumerateObjectsUsingBlock:^(DMMTaskOperation *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isExecuting]) {
            operation = obj;
            *stop = YES;
        }
    }];
    return operation;
}

#pragma mark Run Tasks

- (void)startProcessing {
    [self.processQueue cancelAllOperations];
    [self.tasks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DMMTaskOperation *taskOperation = [DMMTaskOperation new];
        taskOperation.task = (DMTask *)obj;
        [self.processQueue addOperation:taskOperation];
    }];
}

- (void)pauseProcessing {
    [self.processQueue willChangeValueForKey:@"isSuspended"];
    [self.processQueue setSuspended:YES];
    [self.processQueue didChangeValueForKey:@"isSuspended"];
    DMMTaskOperation *operation = [self currentRunningOperation];
    [operation pauseImageProcessing];
}

- (void)continueProcessing {
    [self.processQueue willChangeValueForKey:@"isSuspended"];
    [self.processQueue setSuspended:NO];
    [self.processQueue didChangeValueForKey:@"isSuspended"];
    DMMTaskOperation *operation = [self currentRunningOperation];
    [operation continueImageProcessing];
}

- (void)skipCurrent {
    DMMTaskOperation *operation = [self currentRunningOperation];
    if (operation) {
        [operation cancel];
    }
}

- (void)stopProcessing {
    if ([self.processQueue isSuspended]) {
        [self.processQueue willChangeValueForKey:@"isSuspended"];
        [self.processQueue setSuspended:NO];
        [self.processQueue didChangeValueForKey:@"isSuspended"];
    }
    [self.processQueue cancelAllOperations];
}

@end
