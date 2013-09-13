//
//  DMPSingleTaskWindowController.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/08/13.
//
//

@class DMTask;

@interface DMMSingleTaskWindowController : NSWindowController

@property (nonatomic, strong) DMTask *task;

@property (nonatomic, strong) NSArray *tileSizeList;
@property (nonatomic, strong) NSArray *formatList;

@property (nonatomic, assign) NSUInteger tileSizeIndex;
@property (nonatomic, assign) NSUInteger outputFormatIndex;
@property (nonatomic, assign) CGFloat jpgQuality;
@property (nonatomic, assign) CGFloat minScalePower,maxScalePower;
@property (nonatomic, strong) NSString *minScaleLabel,*maxScaleLabel;

- (IBAction)finishSetting:(id)sender;

@end
