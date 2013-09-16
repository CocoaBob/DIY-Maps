//
//  DMMSlider.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 15/09/13.
//
//

#import "SMDoubleSlider.h"

@class DMMSlider;

@protocol DMMSliderDelegate <NSObject>

- (NSView *)contentViewForSlider:(DMMSlider *)slider;

@end

@interface DMMSlider : SMDoubleSlider

@property (nonatomic, assign) IBOutlet id<DMMSliderDelegate> delegate;
@property (nonatomic, assign) BOOL shouldShowPopover;

- (void)updatePopoverContentView;

@end
