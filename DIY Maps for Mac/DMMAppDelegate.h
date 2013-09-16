//
//  DMPAppDelegate.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/08/13.

@class DMTask;
@class DMMSingleTaskWindowController;
@class DMMPreviewWindowController;

@interface DMMAppDelegate : NSObject

@property (nonatomic, strong) IBOutlet NSWindow *window;
@property (nonatomic, strong) DMMSingleTaskWindowController *singleTaskWindowController;
@property (nonatomic, strong) DMMPreviewWindowController *previewWindowController;

+ (DMMAppDelegate *)shared;

- (IBAction)openDocument:(id)sender;

@end
