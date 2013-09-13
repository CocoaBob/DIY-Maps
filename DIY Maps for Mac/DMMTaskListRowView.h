//
//  DMPTaskListRowView.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 18/08/13.
//
//

#import "DMTask.h"

@interface DMMTaskListRowView : NSTableRowView

@property (nonatomic, assign) NSInteger row;
@property (nonatomic, assign) DMPTaskState taskState;
@property (nonatomic, assign) float progress;

@end