//
//  DMPAppDelegate.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/08/13.

@class DMTask;
@class DMMTaskListWindowController;
@class DMMSingleTaskWindowController;
@class DMMPreviewWindowController;

@interface DMMAppDelegate : NSObject

@property (nonatomic, strong) IBOutlet NSWindow *window;

@property (nonatomic, strong) DMMTaskListWindowController *taskListWindowController;
@property (nonatomic, strong) DMMSingleTaskWindowController *singleTaskWindowController;
@property (nonatomic, strong) DMMPreviewWindowController *previewWindowController;

+ (instancetype)shared;

- (IBAction)openDocument:(id)sender;

@end
