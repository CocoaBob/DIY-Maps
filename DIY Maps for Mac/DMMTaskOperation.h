//
//  DMMTaskOperation.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 14/09/13.
//
//

@class DMTask;

@interface DMMTaskOperation : NSOperation

@property (nonatomic, strong) DMTask *task;

- (void)pauseImageProcessing;
- (void)continueImageProcessing;

@end
