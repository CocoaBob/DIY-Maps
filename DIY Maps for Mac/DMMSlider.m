//
//  DMMSlider.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 15/09/13.
//
//

#import "DMMSlider.h"
#import "SMDoubleSliderCell.h"

@implementation SMDoubleSliderCell (KnobRect)

- (NSRect)loKnobRect {
    NSRect	loKnobRect;
    double	saveValue;

    // Adjust the current value of the slider, get the rectangle, then reset the current value.
    saveValue = _value;
    _value = [self doubleLoValue];
    loKnobRect = [self knobRectFlipped:[[self controlView] isFlipped]];
    _value = saveValue;

    return loKnobRect;
}

- (NSRect)hiKnobRect {
    return [self knobRectFlipped:[[self controlView] isFlipped]];
}

@end

#pragma mark -

@interface DMMSlider () <NSPopoverDelegate>

@property (nonatomic, strong) NSPopover *popover;

@end

@implementation DMMSlider

- (void)initialize {
    self.popover = [NSPopover new];
    self.popover.appearance = NSPopoverAppearanceMinimal;
    self.popover.contentViewController = [NSViewController new];
    self.popover.contentViewController.view = [NSView new];
    self.popover.delegate = self;
}

- (void)awakeFromNib {
    [self initialize];
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)updateTrackingAreas {
    [[self trackingAreas] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self removeTrackingArea:obj];
    }];
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                                options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

#pragma mark - Mouse

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    [self hidePopover:YES];// Mouse Up
}

- (void)mouseExited:(NSEvent *)theEvent {
    [super mouseExited:theEvent];
    [self hidePopover:YES];
}

#pragma mark - NSSlider

- (BOOL)sendAction:(SEL)theAction to:(id)theTarget {
    BOOL returnValue = [super sendAction:theAction to:theTarget];
    [self showPopover:NO];
    return returnValue;
}

#pragma mark - Popover

- (void)showPopover:(BOOL)animated {
    self.shouldShowPopover = YES;
    if (![self.delegate respondsToSelector:@selector(contentViewForSlider:)]) {
        return;
    }
    
    [[self.popover.contentViewController.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSView *contentView = [self.delegate contentViewForSlider:self];
    if (!contentView)
        return;
    
    self.popover.contentSize = contentView.frame.size;
    [self.popover.contentViewController.view addSubview:contentView];
    self.popover.animates = animated;

    // To get the correct knob rect
    NSRect knobRect = [self trackingLoKnob]?[self.cell loKnobRect]:[self.cell hiKnobRect];
    NSRectEdge preferredEdge;
    if (((SMDoubleSliderCell *)self.cell).sliderType==NSCircularSlider) {
        NSPoint tickMartCenter = NSMakePoint(NSMidX(knobRect), NSMidY(knobRect));
        NSPoint viewCenter = NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds));
        CGFloat cutoffValue = sqrtf(((viewCenter.x-tickMartCenter.x)*(viewCenter.x-tickMartCenter.x)+(viewCenter.y-tickMartCenter.y)*(viewCenter.y-tickMartCenter.y))/2);
        if (viewCenter.x-tickMartCenter.x>cutoffValue) {
            preferredEdge = NSMinXEdge;
        } else if (tickMartCenter.y-viewCenter.y>cutoffValue) {
            preferredEdge = NSMaxYEdge;
        } else if (tickMartCenter.x-viewCenter.x>cutoffValue) {
            preferredEdge = NSMaxXEdge;
        } else {
            preferredEdge = NSMinYEdge;
        }
    } else if (self.isVertical) {
        if (self.tickMarkPosition==NSTickMarkLeft) {
            preferredEdge = NSMinXEdge;
        } else {
            preferredEdge = NSMaxXEdge;
        }
    } else {
        if (self.tickMarkPosition==NSTickMarkBelow) {
            preferredEdge = self.isFlipped?NSMaxYEdge:NSMinYEdge;
        } else {
            preferredEdge = self.isFlipped?NSMinYEdge:NSMaxYEdge;
        }
    }
    
    [self.popover showRelativeToRect:knobRect ofView:self preferredEdge:preferredEdge];
}

- (void)hidePopover:(BOOL)animated {
    self.shouldShowPopover = NO;
    if (self.popover.isShown) {
        self.popover.animates = animated;
        [self.popover close];
    }
}

- (void)updatePopoverContentView {
    if (self.shouldShowPopover && !self.popover.isShown) {
        [self showPopover:NO];
    }
}

@end
