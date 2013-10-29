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
@class DMMTaskOperation;

@interface DMMTaskManager : NSObject

@property (nonatomic, strong) DMMTaskOperation *currentRunningOperation;
@property (nonatomic, assign) BOOL isProcessing;
@property (nonatomic, assign) BOOL isSuspended;

+ (instancetype)shared;

- (void)saveTaskList;
- (void)loadTaskList;

- (void)addNewTasksWithPaths:(NSArray *)inFilePaths;
- (void)addNewTaskWithPath:(NSString *)inFilePath;

- (NSUInteger)tasksCount;
- (NSUInteger)indexOfTask:(DMTask *)task;
- (DMTask *)taskAtIndex:(NSUInteger)index;
- (DMTask *)taskWithInputPath:(NSString *)intputPath;

- (void)addTask:(DMTask *)newTask;
- (void)insertTask:(DMTask *)newTask atIndex:(NSUInteger)index;
- (void)insertTasks:(NSArray *)newTasks atIndex:(NSUInteger)index;
- (void)removeTasksAtIndexes:(NSIndexSet *)indexes;
- (void)removeTaskAtIndex:(NSUInteger)index;

- (void)verifyAllTasks;
- (BOOL)isTaskRunning:(DMTask *)task;

- (void)startProcessing;
- (void)pauseProcessing;
- (void)continueProcessing;
- (void)skipCurrent;
- (void)stopProcessing;

@end