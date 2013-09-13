//
//  DMPAppDelegate.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/08/13.

#import "DMMAppDelegate.h"

#import "DMTask.h"
#import "DMMTaskManager.h"
#import "DMMTaskListWindowController.h"
#import "DMMSingleTaskWindowController.h"

@interface DMMAppDelegate()

@property (nonatomic, strong) DMMTaskListWindowController *taskListWindowController;

@end

@implementation DMMAppDelegate

+ (DMMAppDelegate *)shared {
    return [NSApp delegate];
}

#pragma NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSDictionary *appInfoPList = [[NSBundle mainBundle] infoDictionary];
    NSLog(@"============================");
    NSLog(@"%@ Version %@",appInfoPList[@"CFBundleDisplayName"],appInfoPList[@"CFBundleVersion"]);
    NSLog(@"============================");

    self.taskListWindowController = [[DMMTaskListWindowController alloc] initWithWindowNibName:@"DMMTaskListWindowController"];
    [self.taskListWindowController.window makeMainWindow];
    [self.taskListWindowController.window makeKeyAndOrderFront:nil];

    self.singleTaskWindowController = [[DMMSingleTaskWindowController alloc] initWithWindowNibName:@"DMPSingleTaskWindowController"];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    [[DMMTaskManager shared] addNewTaskWithPath:filename];
	return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
    [[DMMTaskManager shared] addNewTasksWithPaths:filenames];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	if(flag==NO){
        [self.taskListWindowController.window makeKeyAndOrderFront:nil];
	}
	return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return NO;
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    [[DMMTaskManager shared] verifyAllTasks];
}

#pragma mark Actions

- (IBAction)openDocument:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.allowsMultipleSelection = YES;
	panel.canChooseDirectories = NO;
	panel.canChooseFiles = YES;
    [panel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            if (panel.URLs.count > 0) {
                [[DMMTaskManager shared] addNewTasksWithPaths:panel.URLs];
            }
        }
    }];
}

@end
