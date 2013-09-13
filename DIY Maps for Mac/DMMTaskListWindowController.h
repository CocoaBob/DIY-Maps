//
//  DMMTaskListWindowController.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/08/13.
//
//

#import "DMTask.h"

@interface DMMTaskListWindowController : NSWindowController

@property (nonatomic, assign) BOOL isDeleteButtonEnabled;
@property (nonatomic, assign) BOOL isPlayButtonEnabled;
@property (nonatomic, assign) BOOL isStopButtonEnabled;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

- (IBAction)doCellButtonAction:(id)sender;
- (void)reloadData;

@end
