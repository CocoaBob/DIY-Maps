//
//  DMMImageOperation.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 14/09/13.
//
//

#import "DMTask.h"

@interface DMMImageOperation : NSOperation

@property (nonatomic, strong) NSImage *srcImage;
@property (nonatomic, assign) CGRect sourceRect;
@property (nonatomic, assign) CGSize destinationSize;
@property (nonatomic, strong) NSString *outputPath;
@property (nonatomic, assign) DMOutputFormat outputFormat;
@property (nonatomic, assign) CGFloat jpgQuality;

@end
