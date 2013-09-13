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
@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, assign) BOOL isSuspended;

+ (DMMTaskManager *)shared;

- (void)saveTaskList;
- (void)loadTaskList;

- (void)addNewTasksWithPaths:(NSArray *)inFilePaths;
- (void)addNewTaskWithPath:(NSString *)inFilePath;

- (NSUInteger)tasksCount;
- (DMTask *)taskAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfTask:(DMTask *)task;
- (void)addTask:(DMTask *)newTask;
- (void)removeTaskAtIndex:(NSUInteger)index;
- (void)verifyAllTasks;

- (void)runTaskAtIndex:(NSUInteger)index;
- (void)pauseProcessing;
- (void)continueProcessing;
- (void)stopProcessing;

@end