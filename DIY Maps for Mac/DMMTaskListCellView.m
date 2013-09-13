//
//  DMPTaskListCellView.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 18/08/13.
//
//

#import "DMMTaskListCellView.h"

@implementation DMMTaskListCellView

- (void)awakeFromNib {
    [self.textField2 bind:@"textColor" toObject:self.textField withKeyPath:@"textColor" options:nil];
    [self addObserver:self forKeyPath:@"taskState" options:0 context:NULL];
}

- (void)dealloc {
    [self.textField2 unbind:@"textColor"];
    [self removeObserver:self  forKeyPath:@"taskState"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"taskState"]) {
        switch (self.taskState) {
            case DMPTaskStateRunning:
                [self.actionButton setImage:[NSImage imageNamed:NSImageNameStopProgressTemplate]];
                break;
            case DMPTaskStateSuccessful:
                [self.actionButton setImage:[NSImage imageNamed:NSImageNameRevealFreestandingTemplate]];
                break;
            default:
            case DMPTaskStateReady:
            case DMPTaskStateError:
                [self.actionButton setImage:[NSImage imageNamed:NSImageNameActionTemplate]];
                break;
        }
    }
}

@end