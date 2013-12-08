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
#import "DMMPreviewWindowController.h"

@interface DMMAppDelegate()

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

    self.singleTaskWindowController = [[DMMSingleTaskWindowController alloc] initWithWindowNibName:@"DMMSingleTaskWindowController"];
    [self.singleTaskWindowController window];// Load the nib
    
    self.previewWindowController = [[DMMPreviewWindowController alloc] initWithWindowNibName:@"DMMPreviewWindowController"];
    [self.previewWindowController window];// Load the nib
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    [self centralOpenDocuments:@[filename]];
	return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
    [self centralOpenDocuments:filenames];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[self.taskListWindowController.window makeKeyAndOrderFront:nil];
	return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return NO;
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    [[DMMTaskManager shared] verifyAllTasks];
}

#pragma mark - Document

- (IBAction)openDocument:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.allowsMultipleSelection = YES;
	panel.canChooseDirectories = NO;
	panel.canChooseFiles = YES;
    [panel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            if (panel.URLs.count > 0) {
                [[DMMAppDelegate shared] centralOpenDocuments:panel.URLs];
            }
        }
    }];
}

- (void)displayDocument:(NSDocument *)document {
    for (NSWindowController *wc in [document windowControllers]) {
        [[wc window] orderFront:nil];
    }
}

// paths can be an array of NSString or NSURL
- (void)centralOpenDocuments:(NSArray *)paths {
    NSArray *mapFiles = [paths filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id filePath, NSDictionary *bindings) {
        NSString *filePathString = [filePath isKindOfClass:[NSURL class]]?[(NSURL *)filePath path]:(NSString *)filePath;
        return [@"map" isEqualToString:[filePathString pathExtension]];
    }]];
    
    // Open map files
    for (id filePath in mapFiles) {
        NSURL *filePathURL = [filePath isKindOfClass:[NSURL class]]?(NSURL *)filePath:[[NSURL alloc] initFileURLWithPath:(NSString *)filePath];
        
        // Check if it's already open
        BOOL isAlreadyOpen = NO;
        for (NSDocument *document in [[NSDocumentController sharedDocumentController] documents]) {
            if ([[document fileURL] isEqual:filePathURL]) {
                isAlreadyOpen = YES;
                [self displayDocument:document];
                break;
            }
        }
        if (isAlreadyOpen) {
            break;
        }
        
        // Open the map file
        NSError *error = nil;
        NSDocument *document = [[NSDocumentController sharedDocumentController] makeDocumentWithContentsOfURL:filePathURL
                                                                                                       ofType:@"com.CocoaBob.DIYMaps.map"
                                                                                                        error:&error];
        if (error) {
            NSLog(@"%@ %@",[error localizedDescription],[error localizedFailureReason]);
        }
        else if (document) {
            [[NSDocumentController sharedDocumentController] addDocument:document];
            [document makeWindowControllers];
            [self displayDocument:document];
        }
    }
    
    // Add other files into task list
    NSMutableArray *otherFiles = [paths mutableCopy];
    [otherFiles removeObjectsInArray:mapFiles];
    [[DMMTaskManager shared] addNewTasksWithPaths:otherFiles];
}

@end
