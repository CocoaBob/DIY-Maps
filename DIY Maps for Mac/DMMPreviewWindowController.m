//
//  PreviewWindowController.m
//  DIY Maps for Mac
//
//  Created by CocoaBob on 16/09/13.
//
//

#import "DMMPreviewWindowController.h"

#import "DMTask.h"
#import "DMImageProcessor.h"

#define PREVIEW_SIZE 512

@implementation DMMPreviewWindowImageView

- (BOOL)mouseDownCanMoveWindow {
    return YES;
}

@end

#pragma mark -

@interface DMMPreviewWindowController ()

@property (nonatomic, assign) IBOutlet DMMPreviewWindowImageView *imageView;

@end

@implementation DMMPreviewWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window setMovableByWindowBackground:YES];
    [self.window setLevel:NSFloatingWindowLevel];
    [self addObserver:self forKeyPath:@"task" options:0 context:NULL];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"task"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"task" isEqualToString:keyPath]) {
        NSRect oldWindowFrame = self.window.frame;
        if (self.task) {
            NSImage *srcImage = [[NSImage alloc] initWithContentsOfFile:self.task.inputFilePath];
            [self imageView].image = [DMImageProcessor thumbnailWithImage:srcImage
                                                                 cropRect:CGRectZero
                                                               outputSize:CGSizeMake(PREVIEW_SIZE,PREVIEW_SIZE)];
            CGFloat imageWidth = [self imageView].image.size.width;
            CGFloat imageHeight = [self imageView].image.size.height;
            [self.window setFrame:NSMakeRect(NSMidX(oldWindowFrame) - imageWidth / 2.0f, NSMidY(oldWindowFrame) - imageHeight / 2.0f, imageWidth, imageHeight)
                          display:YES
                          animate:YES];
        }
        else {
            [self imageView].image = nil;
            [self.window setFrame:NSMakeRect(NSMidX(oldWindowFrame) - 50, NSMidY(oldWindowFrame) - 50, 100, 100)
                          display:YES
                          animate:YES];
        }
    }
}

@end
