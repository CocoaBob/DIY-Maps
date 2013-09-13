//
//  DMPAppDelegate.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/08/13.

@class DMTask;
@class DMMSingleTaskWindowController;

@interface DMMAppDelegate : NSObject

@property (nonatomic, strong) IBOutlet NSWindow *window;
@property (nonatomic, strong) DMMSingleTaskWindowController *singleTaskWindowController;

+ (DMMAppDelegate *)shared;

- (IBAction)openDocument:(id)sender;

@end
