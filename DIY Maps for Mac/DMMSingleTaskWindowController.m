//
//  DMMSingleTaskWindowController.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/08/13.
//
//

#import "DMMSingleTaskWindowController.h"

#import "DMMAppDelegate.h"
#import "DMTask.h"
#import "DMMTaskManager.h"
#import "DMImageProcessor.h"
#import "DMMSlider.h"

#define MIN_SCALE_POWER -4
#define MAX_SCALE_POWER 4
#define PREVIEW_IMAGE_SIZE 2048
#define POPOVER_MIN_SIZE 256
#define POPOVER_MAX_SIZE 256

@interface DMMSingleTaskWindowController () <DMMSliderDelegate> {
    IBOutlet DMMSlider *minScaleSlider,*maxScaleSlider;
}

@property (nonatomic, strong) NSImage *previewImageSmall;
@property (nonatomic, strong) NSImage *previewImageLarge;
@property (nonatomic, strong) NSImageView *popoverContentView;

@end

@implementation DMMSingleTaskWindowController

- (void)awakeFromNib {
    NSMutableArray *tileSizes = [@[] mutableCopy];
    for (int i = 0; i < DMPTileSizeCount; ++i) {
        tileSizes[i] = @(256*pow(2, i));
    }
    self.tileSizeList = tileSizes;
    
    NSMutableArray *outputFormats = [@[] mutableCopy];
    for (int i = 0; i < DMPOutputFormatCount; ++i) {
        NSString *format = nil;
        switch (i) {
            case DMPOutputFormatJPG:
                format = @"JPG";
                break;
            case DMPOutputFormatPNG:
                format = @"PNG";
                break;
            default:
                format = @"Unkown Format";
                break;
        }
        outputFormats[i] = format;
    }
    self.formatList = outputFormats;
    
    [self addObserver:self forKeyPath:@"task" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"tileSizeIndex" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"outputFormatIndex" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"jpgQuality" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"minScalePower" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"maxScalePower" options:0 context:NULL];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"task"];
    [self removeObserver:self forKeyPath:@"tileSizeIndex"];
    [self removeObserver:self forKeyPath:@"outputFormatIndex"];
    [self removeObserver:self forKeyPath:@"jpgQuality"];
    [self removeObserver:self forKeyPath:@"minScalePower"];
    [self removeObserver:self forKeyPath:@"maxScalePower"];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"task"]) {
        [self loadTask];
        self.previewImageLarge = nil;
        self.previewImageSmall = nil;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self preparePreviewImages];
        });
    }
    else {
        if ([keyPath isEqualToString:@"minScalePower"]) {
            if (self.maxScalePower < self.minScalePower) {
                self.maxScalePower = self.minScalePower;
            }
            self.minScaleLabel = [DMImageProcessor stringFromSize:self.task.sourcePixelSize
                                                             scale:pow(2, self.minScalePower)];
        }
        else if ([keyPath isEqualToString:@"maxScalePower"]) {
            if (self.maxScalePower < self.minScalePower) {
                self.minScalePower = self.maxScalePower;
            }
            self.maxScaleLabel = [DMImageProcessor stringFromSize:self.task.sourcePixelSize
                                                            scale:pow(2, self.maxScalePower)];
        }
    }
}

#pragma mark Preview Image

- (void)preparePreviewImages {
    NSImage *srcImage = [[NSImage alloc] initWithContentsOfFile:self.task.inputFilePath];
    
    // Prepare large preview image
    CGFloat maxZoomScale = pow(2, [self possibleMaxScalePower]);
    CGFloat maxWidth = floor(self.task.sourceImageSize.width * maxZoomScale);
    CGFloat maxHeight = floor(self.task.sourceImageSize.height * maxZoomScale);
    int outputWidth = MIN(maxWidth, PREVIEW_IMAGE_SIZE);
	int outputHeight = MIN(maxHeight, PREVIEW_IMAGE_SIZE);
    
	NSRect sourceImageRect;
    sourceImageRect.size.width = outputWidth / maxZoomScale;
    sourceImageRect.size.height = outputHeight / maxZoomScale;
    sourceImageRect.origin.x = (self.task.sourceImageSize.width - sourceImageRect.size.width) / 2.0f;
    sourceImageRect.origin.y = (self.task.sourceImageSize.height - sourceImageRect.size.height) / 2.0f;
    
    self.previewImageLarge = [DMImageProcessor thumbnailWithImage:srcImage
                                                          srcRect:sourceImageRect
                                                         destSize:CGSizeMake(outputWidth, outputHeight)];
    [minScaleSlider updatePopoverContentView];
    [maxScaleSlider updatePopoverContentView];
    
    // Prepare small preview image
    if ((maxWidth <= PREVIEW_IMAGE_SIZE && maxHeight <= PREVIEW_IMAGE_SIZE) ||
        maxZoomScale == 1) {
        self.previewImageSmall = self.previewImageLarge;
    }
    else {
        outputWidth = MIN(self.task.sourceImageSize.width, PREVIEW_IMAGE_SIZE);
        outputHeight = MIN(self.task.sourceImageSize.height, PREVIEW_IMAGE_SIZE);
        
        sourceImageRect.size.width = outputWidth;
        sourceImageRect.size.height = outputHeight;
        sourceImageRect.origin.x = (self.task.sourceImageSize.width - outputWidth) / 2.0f;
        sourceImageRect.origin.y = (self.task.sourceImageSize.height - outputHeight) / 2.0f;
        
        self.previewImageSmall = [DMImageProcessor thumbnailWithImage:srcImage
                                                              srcRect:sourceImageRect
                                                             destSize:CGSizeMake(outputWidth, outputHeight)];
    }
    [minScaleSlider updatePopoverContentView];
    [maxScaleSlider updatePopoverContentView];
}

#pragma mark Min/Max Scale

- (int)possibleMinScalePower {
    int returnValue = MIN_SCALE_POWER;
    while ((self.task.sourcePixelSize.width * pow(2, returnValue)) < POPOVER_MIN_SIZE ||
           (self.task.sourcePixelSize.height * pow(2, returnValue)) < POPOVER_MIN_SIZE) {
        ++returnValue;
    }
    if (returnValue > 0) {
        returnValue = 0;
    }
    return returnValue;
}

- (int)possibleMaxScalePower {
    static NSSet *vectorTypes = nil;
    if (!vectorTypes) vectorTypes = [NSSet setWithObjects:@"pdf", @"eps", @"pict", nil];
    int returnValue = [vectorTypes containsObject:[[self.task.inputFilePath pathExtension] lowercaseString]]?MAX_SCALE_POWER:0;
    return returnValue;
}

#pragma mark DMMSliderDelegate

- (NSView *)contentViewForSlider:(DMMSlider *)slider {
    int currentScalePower = ((slider == minScaleSlider)?self.minScalePower:self.maxScalePower);
    if ((currentScalePower > 0 && !self.previewImageLarge) ||
        !self.previewImageSmall) {
        return nil;
    }
    
    int maxScalePower = [self possibleMaxScalePower];
    NSImage *previewImage;
    CGFloat zoomScale;
    if (currentScalePower > 0) {
        previewImage = self.previewImageLarge;
        zoomScale = pow(2,currentScalePower - maxScalePower);
    }
    else {
        previewImage = self.previewImageSmall;
        zoomScale = pow(2, currentScalePower);
    }
    NSSize previewImageSize = previewImage.size;
    int outputWidth = MIN(floor(previewImageSize.width * zoomScale), POPOVER_MAX_SIZE);
	int outputHeight = MIN(floor(previewImageSize.height * zoomScale), POPOVER_MAX_SIZE);
    
	NSRect sourceImageRect;
    sourceImageRect.size.width = outputWidth / zoomScale;
    sourceImageRect.size.height = outputHeight / zoomScale;
    sourceImageRect.origin.x = (previewImageSize.width - sourceImageRect.size.width) / 2.0f;
    sourceImageRect.origin.y = (previewImageSize.height - sourceImageRect.size.height) / 2.0f;
    
    NSImage *displayImage = [DMImageProcessor thumbnailWithImage:previewImage srcRect:sourceImageRect destSize:CGSizeMake(outputWidth, outputHeight)];
    
    if (!self.popoverContentView) {
        self.popoverContentView = [NSImageView new];
        self.popoverContentView.imageFrameStyle = NSImageFrameGroove;
    }
    self.popoverContentView.frame = NSMakeRect(0, 0, outputWidth, outputHeight);
    self.popoverContentView.image = displayImage;
    
    return self.popoverContentView;
}

#pragma mark Load/Save tasks

- (void)loadTask {
    // Update Min/Max sliders
    int sliderMinValue = [self possibleMinScalePower];
    int sliderMaxValue = [self possibleMaxScalePower];
    [minScaleSlider setNumberOfTickMarks:sliderMaxValue - sliderMinValue + 1];
    [minScaleSlider setMinValue:sliderMinValue];
    [minScaleSlider setMaxValue:sliderMaxValue];
    [maxScaleSlider setNumberOfTickMarks:sliderMaxValue - sliderMinValue + 1];
    [maxScaleSlider setMinValue:sliderMinValue];
    [maxScaleSlider setMaxValue:sliderMaxValue];
    
    // Load values
    [self willChangeValueForKey:@"tileSizeIndex"];
    [self willChangeValueForKey:@"outputFormatIndex"];
    [self willChangeValueForKey:@"jpgQuality"];
    [self willChangeValueForKey:@"minScalePower"];
    [self willChangeValueForKey:@"maxScalePower"];
    _tileSizeIndex      = self.task.tileSizeIndex;
    _outputFormatIndex  = self.task.outputFormatIndex;
    _jpgQuality         = self.task.jpgQuality;
    _minScalePower      = self.task.minScalePower;
    _maxScalePower      = self.task.maxScalePower;
    [self didChangeValueForKey:@"tileSizeIndex"];
    [self didChangeValueForKey:@"outputFormatIndex"];
    [self didChangeValueForKey:@"jpgQuality"];
    [self didChangeValueForKey:@"minScalePower"];
    [self didChangeValueForKey:@"maxScalePower"];
}

- (void)saveTask {
    self.task.tileSizeIndex     = self.tileSizeIndex;
    self.task.outputFormatIndex = self.outputFormatIndex;
    self.task.jpgQuality        = self.jpgQuality;
    self.task.minScalePower     = self.minScalePower;
    self.task.maxScalePower     = self.maxScalePower;
    [[DMMTaskManager shared] saveTaskList];
    [[NSNotificationCenter defaultCenter] postNotificationName:DMPTaskDidUpdateNotification object:self.task];
}

#pragma mark Actions

- (IBAction)finishSetting:(id)sender {
    if (((NSButton *)sender).tag == 1)
        [self saveTask];
    [NSApp endSheet:self.window];
    [self.window orderOut:nil];
}

- (IBAction)setDefaultValues:(id)sender {
    [self willChangeValueForKey:@"tileSizeIndex"];
    [self willChangeValueForKey:@"outputFormatIndex"];
    [self willChangeValueForKey:@"jpgQuality"];
    [self willChangeValueForKey:@"minScalePower"];
    [self willChangeValueForKey:@"maxScalePower"];
    _tileSizeIndex      = 2;
    _outputFormatIndex  = 0;
    _jpgQuality         = 0.7;
    _minScalePower      = [DMTask defaultMinScalePowerWithTileSizeIndex:_tileSizeIndex originalPixelSize:self.task.sourcePixelSize];
    _maxScalePower      = 0;
    [self didChangeValueForKey:@"tileSizeIndex"];
    [self didChangeValueForKey:@"outputFormatIndex"];
    [self didChangeValueForKey:@"jpgQuality"];
    [self didChangeValueForKey:@"minScalePower"];
    [self didChangeValueForKey:@"maxScalePower"];
}

@end
