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

@property (nonatomic, strong) NSTimer *elapseTimer;

@end

@implementation DMMTaskManager {
    NSUInteger numberOfTiles, numberOfTilesCompleted;
}

static DMMTaskManager *__sharedInstance = nil;

+ (instancetype)shared {
    if (__sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __sharedInstance = [[[self class] alloc] init];
        });
    }
    
    return __sharedInstance;
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
            if (self.currentRunningOperation) {
                if (self.isSuspended)
                    [self.currentRunningOperation pauseImageProcessing];
                else
                    [self.currentRunningOperation continueImageProcessing];
            }
        }
        self.isProcessing = self.isSuspended?YES:([self.processQueue operationCount] > 0);
    }
}

#pragma mark - Task Management

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
    if (index >= [self tasksCount]) {
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

- (void)insertTask:(DMTask *)newTask atIndex:(NSUInteger)index {
    [self willChangeValueForKey:@"tasks"];
    [self.tasks insertObject:newTask atIndex:index];
    [self didChangeValueForKey:@"tasks"];
}

- (void)insertTasks:(NSArray *)newTasks atIndex:(NSUInteger)index {
    [self willChangeValueForKey:@"tasks"];
    [newTasks enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.tasks insertObject:obj atIndex:index];
    }];
    [self didChangeValueForKey:@"tasks"];
}

- (void)removeTasksAtIndexes:(NSIndexSet *)indexes {
    [self willChangeValueForKey:@"tasks"];
    [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx < [self tasksCount]) {
            if (![self isTaskRunning:self.tasks[idx]]) {
                [self.tasks removeObjectAtIndex:idx];
            }
        }
    }];
    [self didChangeValueForKey:@"tasks"];
}

- (void)removeTaskAtIndex:(NSUInteger)index {
    [self willChangeValueForKey:@"tasks"];
    if (index < [self tasksCount]) {
        if (![self isTaskRunning:self.tasks[index]]) {
            [self.tasks removeObjectAtIndex:index];
        }
    }
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
    [self.tasks enumerateObjectsUsingBlock:^(DMTask *obj, NSUInteger idx, BOOL *stop) {
        if (obj.status == DMTaskStatusError || obj.status == DMTaskStatusSuccessful) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:[obj.outputFolderPath stringByAppendingPathExtension:@"map"]]) {
                updated = YES;
                obj.status = DMTaskStatusReady;
            }
        }
    }];
    
    if (updated) {
        [self saveTaskList];
        [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskListDidUpdateNotification object:nil];
    }
}

- (BOOL)isTaskRunning:(DMTask *)task {
    if (!self.currentRunningOperation) {
        return NO;
    }
    return (self.currentRunningOperation.task == task);
}

#pragma mark - Run Tasks

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
    if (self.currentRunningOperation) {
        [self.currentRunningOperation pauseImageProcessing];
    }
}

- (void)continueProcessing {
    [self.processQueue willChangeValueForKey:@"isSuspended"];
    [self.processQueue setSuspended:NO];
    [self.processQueue didChangeValueForKey:@"isSuspended"];
    if (self.currentRunningOperation) {
        [self.currentRunningOperation continueImageProcessing];
    }
}

- (void)skipCurrent {
    if (self.currentRunningOperation) {
        [self.currentRunningOperation cancel];
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
