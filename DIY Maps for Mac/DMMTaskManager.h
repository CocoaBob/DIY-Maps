//
//  DMPTaskManager.h
//  DIY Maps
//
//  Created by CocoaBob on 16/08/13.
//
//

static NSString* const DMPTaskListDidUpdateNotification = @"DMPTaskListDidUpdateNotification";
static NSString* const DMPTaskDidUpdateNotification = @"DMPTaskDidUpdateNotification";

@class DMTask;

@interface DMMTaskManager : NSObject

@property (nonatomic, assign) BOOL isProcessing;
@property (nonatomic, assign) BOOL isSuspended;

+ (DMMTaskManager *)shared;

- (void)saveTaskList;
- (void)loadTaskList;

- (void)addNewTasksWithPaths:(NSArray *)inFilePaths;
- (void)addNewTaskWithPath:(NSString *)inFilePath;

- (NSUInteger)tasksCount;
- (NSUInteger)indexOfTask:(DMTask *)task;
- (DMTask *)taskAtIndex:(NSUInteger)index;
- (DMTask *)taskWithInputPath:(NSString *)intputPath;

- (void)addTask:(DMTask *)newTask;
- (void)removeTaskAtIndex:(NSUInteger)index;

- (void)verifyAllTasks;

- (void)startProcessing;
- (void)pauseProcessing;
- (void)continueProcessing;
- (void)skipCurrent;
- (void)stopProcessing;

@end