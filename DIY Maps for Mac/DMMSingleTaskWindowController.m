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

@interface DMMSingleTaskWindowController () <DMMSliderDelegate> {
    IBOutlet DMMSlider *minScaleSlider,*maxScaleSlider;
}

@property (nonatomic, strong) NSImage *srcImage;
@property (nonatomic, strong) NSImageView *popoverContentView;

@end

@implementation DMMSingleTaskWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName {
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
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
    return self;
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
        self.srcImage = nil;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSImage *newImage = [[NSImage alloc] initWithContentsOfFile:self.task.inputFilePath];
            self.srcImage = newImage;
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

#pragma mark DMMSliderDelegate

- (NSView *)contentViewForSlider:(DMMSlider *)slider {
    if (!self.srcImage)
        return nil;
    
    static const CGFloat previewPointSize = 256;
    
    CGFloat zoomScale = pow(2, (slider == minScaleSlider)?self.minScalePower:self.maxScalePower);
    int outputWidth = MIN(floor(self.task.sourceImageSize.width * zoomScale), previewPointSize);
	int outputHeight = MIN(floor(self.task.sourceImageSize.height * zoomScale), previewPointSize);
    
	NSRect sourceImageRect;
    sourceImageRect.size.width = outputWidth / zoomScale;
    sourceImageRect.size.height = outputHeight / zoomScale;
    sourceImageRect.origin.x = (self.task.sourceImageSize.width - sourceImageRect.size.width) / 2.0f;
    sourceImageRect.origin.y = (self.task.sourceImageSize.height - sourceImageRect.size.height) / 2.0f;
    
    NSImage *previewImage = [DMImageProcessor thumbnailWithImage:self.srcImage srcRect:sourceImageRect destSize:CGSizeMake(outputWidth, outputHeight)];
    
    if (!self.popoverContentView) {
        self.popoverContentView = [NSImageView new];
        self.popoverContentView.imageFrameStyle = NSImageFrameGroove;
    }
    self.popoverContentView.frame = NSMakeRect(0, 0, outputWidth, outputHeight);
    self.popoverContentView.image = previewImage;
    
    return self.popoverContentView;
}

#pragma mark Load/Save tasks

- (void)loadTask {
    // Update Min/Max sliders
    static NSSet *vectorTypes = nil;
    if (!vectorTypes) vectorTypes = [NSSet setWithObjects:@"pdf", @"eps", @"pict", nil];
    if ([vectorTypes containsObject:[[self.task.inputFilePath pathExtension] lowercaseString]]) {
        [minScaleSlider setNumberOfTickMarks:21];
        [minScaleSlider setMinValue:-10];
        [minScaleSlider setMaxValue:10];
        [maxScaleSlider setNumberOfTickMarks:21];
        [maxScaleSlider setMinValue:-10];
        [maxScaleSlider setMaxValue:10];
    }
    else {
        [minScaleSlider setNumberOfTickMarks:11];
        [minScaleSlider setMinValue:-10];
        [minScaleSlider setMaxValue:0];
        [maxScaleSlider setNumberOfTickMarks:11];
        [maxScaleSlider setMinValue:-10];
        [maxScaleSlider setMaxValue:0];
    }

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
    _minScalePower      = [DMTask defaultMinScaleSizeIndexWithTileSizeIndex:_tileSizeIndex originalPixelSize:self.task.sourcePixelSize];
    _maxScalePower      = 0;
    [self didChangeValueForKey:@"tileSizeIndex"];
    [self didChangeValueForKey:@"outputFormatIndex"];
    [self didChangeValueForKey:@"jpgQuality"];
    [self didChangeValueForKey:@"minScalePower"];
    [self didChangeValueForKey:@"maxScalePower"];
}

@end
