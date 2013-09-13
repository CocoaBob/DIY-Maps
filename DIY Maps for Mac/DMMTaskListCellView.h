//
//  DMPTaskListCellView.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 18/08/13.
//
//

#import "DMTask.h"

@interface DMMTaskListCellView : NSTableCellView

@property (nonatomic, weak) IBOutlet NSTextField *textField2;
@property (nonatomic, weak) IBOutlet NSButton *actionButton;
@property (nonatomic, assign) DMPTaskState taskState;

@end
