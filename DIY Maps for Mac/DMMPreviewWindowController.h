//
//  PreviewWindowController.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/09/13.
//
//

@class DMTask;

@interface DMMPreviewWindowRootView : NSView

@end

#pragma mark -

@interface DMMPreviewWindowController : NSWindowController

@property (nonatomic, strong) DMTask *task;

@end
