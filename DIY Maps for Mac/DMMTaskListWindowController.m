//
//  DMMTaskListWindowController.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/08/13.
//
//

#import "DMMTaskListWindowController.h"

#import "DMMAppDelegate.h"
#import "DMImageProcessor.h"
#import "DMMTaskManager.h"
#import "DMTask.h"
#import "DMMTaskListRowView.h"
#import "DMMTaskListCellView.h"
#import "DMMSingleTaskWindowController.h"

#pragma mark -

@interface DMMTaskListWindowController () <NSTableViewDelegate,NSTableViewDataSource> {
    IBOutlet NSTableView *taskListTableView;
    IBOutlet NSToolbarItem *playPauseButtonItem;
}

@end

@implementation DMMTaskListWindowController

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        [[DMMTaskManager shared] addObserver:self
                                forKeyPath:@"tasksCount"
                                   options:0
                                   context:NULL];
        [[DMMTaskManager shared] addObserver:self
                                forKeyPath:@"isProcessing"
                                   options:0
                                   context:NULL];
        [[DMMTaskManager shared] addObserver:self
                                forKeyPath:@"isSuspended"
                                   options:0
                                   context:NULL];
        [[NSNotificationCenter defaultCenter] addObserverForName:DMPTaskListDidUpdateNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [self reloadData];
                                                      }];
        [[NSNotificationCenter defaultCenter] addObserverForName:DMPTaskDidUpdateNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          DMTask *updatedTask = [note object];
                                                          NSUInteger taskIndex = [[DMMTaskManager shared] indexOfTask:updatedTask];
                                                          [taskListTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:taskIndex]
                                                                                       columnIndexes:[NSIndexSet indexSetWithIndex:0]];
                                                      }];
    }
    return self;
}

- (void)awakeFromNib {
    [taskListTableView setDoubleAction:@selector(doubleClickAction:)];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Drag & Drop
	[self.window registerForDraggedTypes:@[NSFilenamesPboardType]];
    
    self.isPlayButtonEnabled = [[DMMTaskManager shared] tasksCount] > 0;
}

- (void)dealloc {
    [[DMMTaskManager shared] removeObserver:self forKeyPath:@"tasksCount"];
    [[DMMTaskManager shared] removeObserver:self forKeyPath:@"isProcessing"];
    [[DMMTaskManager shared] removeObserver:self forKeyPath:@"isSuspended"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"tasksCount"]) {
        self.isPlayButtonEnabled = [[DMMTaskManager shared] tasksCount] > 0;
    }
    else if ([keyPath isEqualToString:@"isProcessing"] ||
             [keyPath isEqualToString:@"isSuspended"]) {
        BOOL isProcessing = [DMMTaskManager shared].isProcessing,isSuspended = [DMMTaskManager shared].isSuspended;
        if (isProcessing && !isSuspended) {
            [playPauseButtonItem setImage:[NSImage imageNamed:@"PauseTemplate"]];
            [self.progressIndicator startAnimation:nil];
        }
        else {
            [playPauseButtonItem setImage:[NSImage imageNamed:@"PlayTemplate"]];
            [self.progressIndicator stopAnimation:nil];
        }
        self.isStopButtonEnabled = isProcessing;
    }
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[DMMTaskManager shared] tasksCount];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [[DMMTaskManager shared] taskAtIndex:row];
}

#pragma mark NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    DMMTaskListCellView *tableCellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    DMTask *task = [[DMMTaskManager shared] taskAtIndex:row];
    [tableCellView.textField setStringValue:task.inputFilePath?[task.inputFilePath lastPathComponent]:@""];
    [tableCellView.imageView setImage:[[NSWorkspace sharedWorkspace] iconForFile:task.inputFilePath]];
    [tableCellView.actionButton setTag:row];
    tableCellView.taskState = task.state;
    NSString *originalDimension = [DMImageProcessor stringFromSize:task.sourcePixelSize scale:1];
    int tileSize = [DMTask tileSizeFromSizeIndex:task.tileSizeIndex];
    NSString *formatExtension = [[DMTask fileExtensionFromFormat:task.outputFormatIndex] uppercaseString];
    NSString *jpgQuality = (task.outputFormatIndex==DMPOutputFormatJPG)?[NSString stringWithFormat:@"@%2.0f%%",task.jpgQuality*100]:@"";
    NSString *fromDimension = (task.minScalePower<0)?[NSString stringWithFormat:@"1/%.0f",pow(2, -task.minScalePower)]:[NSString stringWithFormat:@"%.0f",pow(2, task.minScalePower)];
    NSString *toDimension = (task.maxScalePower<0)?[NSString stringWithFormat:@"1/%.0f",pow(2, -task.maxScalePower)]:[NSString stringWithFormat:@"%.0f",pow(2, task.maxScalePower)];
    [tableCellView.textField2 setStringValue:[NSString stringWithFormat:@"[%@] %d %@%@ %@->%@",originalDimension,tileSize,formatExtension,jpgQuality,fromDimension,toDimension]];
    
    DMMTaskListRowView *tableRowView = [tableView rowViewAtRow:row makeIfNecessary:NO];
    tableRowView.taskState = task.state;
    tableRowView.progress = task.progress;
    
    return tableCellView;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    static NSString *rowViewIdentifier = @"rowViewIdentifier";
    DMMTaskListRowView *tableRowView = [tableView makeViewWithIdentifier:rowViewIdentifier owner:self];
    if (!tableRowView) {
        tableRowView = [[DMMTaskListRowView alloc] initWithFrame:CGRectZero];
        tableRowView.identifier = rowViewIdentifier;
    }
    tableRowView.row = row;
    return tableRowView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    self.isDeleteButtonEnabled = [[taskListTableView selectedRowIndexes] count] > 0;
}

#pragma mark TableView

- (void)reloadData {
    [taskListTableView reloadData];
}

#pragma mark Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	NSPasteboard *pboard = [sender draggingPasteboard];
	if ([[pboard types] containsObject:NSFilenamesPboardType])
		return NSDragOperationCopy;
	return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	NSPasteboard *pboard = [sender draggingPasteboard];
	BOOL success = NO;
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		if (files.count > 0)	 {
            [[DMMTaskManager shared] addNewTasksWithPaths:files];
			success = YES;
		}
	}
	return success;
}

- (BOOL)wantsPeriodicDraggingUpdates {
	return NO;
}

#pragma mark Routines

- (void)showTaskPanel:(DMTask *)task {
    [[DMMAppDelegate shared].singleTaskWindowController setTask:task];
    [NSApp beginSheet:[DMMAppDelegate shared].singleTaskWindowController.window
       modalForWindow:self.window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:NULL];
}

- (void)showResultOfTask:(DMTask *)task {
    [[NSWorkspace sharedWorkspace] selectFile:[task.outputFolderPath stringByAppendingPathExtension:@"map"]
                     inFileViewerRootedAtPath:nil];
}

- (void)removeSelectedTasks {
    [[taskListTableView selectedRowIndexes] enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
        [[DMMTaskManager shared] removeTaskAtIndex:idx];
    }];
}

#pragma mark Handle Keoboard Events

- (void)keyDown:(NSEvent*)event {
    if ([event type] == NSKeyDown) {
        NSString* pressedChars = [event characters];
        if ([pressedChars length] == 1) {
            unichar pressedUnichar = [pressedChars characterAtIndex:0];
            if (pressedUnichar == NSDeleteCharacter ||
                pressedUnichar == NSDeleteFunctionKey) {
                [self removeSelectedTasks];
            }
        }
    }
}

- (void)delete:(id)sender {
    [self removeSelectedTasks];
}

#pragma mark Actions

- (IBAction)doCellButtonAction:(id)sender {
    NSInteger taskIndex = ((NSButton *)sender).tag;
    DMTask *task = [[DMMTaskManager shared] taskAtIndex:taskIndex];
    switch (task.state) {
        default:
        case DMPTaskStateReady:
        case DMPTaskStateError:
        {
            [self showTaskPanel:task];
        }
            break;
        case DMPTaskStateRunning:
        {
            task.state = DMPTaskStateReady;
            [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification object:task];
            [[DMMTaskManager shared] saveTaskList];
            [[DMMTaskManager shared] skipCurrent];
        }
            break;
        case DMPTaskStateSuccessful:
        {
            [self showResultOfTask:task];
        }
            break;
    }
}

- (IBAction)doToolbarStartPauseButtonAction:(id)sender {
    if ([DMMTaskManager shared].isSuspended) {
        [[DMMTaskManager shared] continueProcessing];
    }
    else {
        if ([DMMTaskManager shared].isProcessing) {
            [[DMMTaskManager shared] pauseProcessing];
        }
        else {
            [[DMMTaskManager shared] startProcessing];
        }
    }
}

- (IBAction)doToolbarStopButtonAction:(id)sender {
    [[DMMTaskManager shared] stopProcessing];
}

- (IBAction)doToolbarAddButtonAction:(id)sender {
    [[DMMAppDelegate shared] openDocument:nil];
}

- (IBAction)doubleClickAction:(id)sender {
    [self showTaskPanel:[[DMMTaskManager shared] taskAtIndex:[taskListTableView clickedRow]]];
}

@end
