//
//  DMPTaskListRowView.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 18/08/13.
//
//

#import "DMMTaskListRowView.h"

@implementation DMMTaskListRowView

- (void)drawProgress {
    if (self.taskState == DMPTaskStateRunning) {
        NSRect progressRect = NSMakeRect(0, 1, NSWidth([self bounds]) * self.progress, NSHeight([self bounds])-2);
        [[NSColor colorWithCalibratedWhite:0 alpha:0.1] setFill];
        NSRectFillUsingOperation(progressRect, NSCompositeSourceOver);
    }
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    CGFloat colorValue = (self.row & 1)?0.8:0.9;
    switch (self.taskState) {
        default:
        case DMPTaskStateReady:
            [[NSColor colorWithCalibratedWhite:(self.row & 1)?0.95:0.98 alpha:1] setFill];
            break;
        case DMPTaskStateRunning:
            [[NSColor colorWithCalibratedRed:colorValue green:colorValue blue:1 alpha:1] setFill];
            break;
        case DMPTaskStateError:
            [[NSColor colorWithCalibratedRed:1 green:colorValue blue:colorValue alpha:1] setFill];
            break;
        case DMPTaskStateSuccessful:
            [[NSColor colorWithCalibratedRed:colorValue green:1 blue:colorValue alpha:1] setFill];
            break;
    }
    NSRectFill(dirtyRect);
    [self drawProgress];
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    if ([NSApp isActive]) {
        if ((self.row & 1)) {
            [[NSColor colorWithCalibratedRed:0.1726 green:0.3647 blue:0.8 alpha:1] setFill];
        }
        else {
            [[NSColor colorWithCalibratedRed:0.227 green:0.396 blue:0.8 alpha:1] setFill];
        }
    }
    else {
        CGFloat colorValue = (self.row & 1)?0.78:0.82;
        [[NSColor colorWithCalibratedWhite:colorValue alpha:1] setFill];
    }
    NSRectFill(dirtyRect);
    [self drawProgress];
}

@end
