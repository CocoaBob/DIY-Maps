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
#import "DMMTaskManager.h"
#import "DMMAppDelegate.h"

#define PREVIEW_SIZE 320

@implementation DMMPreviewWindowImageView

- (BOOL)mouseDownCanMoveWindow {
    return YES;
}

@end

#pragma mark -

@interface DMMPreviewWindowController ()

@property (nonatomic, assign) IBOutlet DMMPreviewWindowImageView *imageView;
@property (nonatomic, strong) DMTask *task;

@property (nonatomic, strong) NSImage *previewImage;

@end

@implementation DMMPreviewWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window setMovableByWindowBackground:YES];
    [self.window setLevel:NSFloatingWindowLevel];
    self.messageLabelString = nil;
    [[NSNotificationCenter defaultCenter] addObserverForName:DMPTaskDidUpdateNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      DMTask *updatedTask = [note object];
                                                      NSDictionary *userInfo = [note userInfo];
                                                      if (userInfo || !updatedTask) {
                                                          if (updatedTask != self.task) {
                                                              self.task  = updatedTask;
                                                              [self updateTask];
                                                          }
                                                          else {
                                                              NSRect completedRect = [userInfo[@"CompletedRect"] rectValue];
                                                              CGFloat zoomScale = [userInfo[@"ZoomScale"] doubleValue];
                                                              [self updateProgressWithRect:NSRectToCGRect(completedRect)
                                                                            zoomScalePower:log2(zoomScale)];
                                                          }
                                                      }
                                                  }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:DMPTaskDidUpdateNotification];
}

- (void)updateTask {
    NSRect oldWindowFrame = self.window.frame;
    // New Task
    if (self.task) {
        // Update time label
        self.messageLabelString = NSLocalizedString(@"Loading...", nil);
        
        // Prepare preview image
        NSImage *srcImage = [[NSImage alloc] initWithContentsOfFile:self.task.inputFilePath];
        self.previewImage = [DMImageProcessor thumbnailWithImage:srcImage
                                                        cropRect:CGRectZero
                                                      outputSize:CGSizeMake(PREVIEW_SIZE,PREVIEW_SIZE)];
        
        // Update window frame
        CGFloat imageWidth = self.previewImage.size.width;
        CGFloat imageHeight = self.previewImage.size.height;
        [self.window setFrame:NSMakeRect(NSMidX(oldWindowFrame) - imageWidth / 2.0f, NSMidY(oldWindowFrame) - imageHeight / 2.0f, imageWidth, imageHeight)
                      display:YES
                      animate:YES];
        
        // Update image view
        NSImage *blackImage = [[NSImage alloc] initWithSize:NSMakeSize(imageWidth, imageHeight)];
        [blackImage lockFocus];
        [[NSColor blackColor] setFill];
        NSRectFill(NSMakeRect(0, 0, imageWidth, imageHeight));
        [blackImage unlockFocus];
        self.imageView.image = blackImage;
    }
    // No Task
    else {
        // Update time label
        self.messageLabelString = nil;
        
        // Update image view
        self.imageView.image = nil;
        [self.imageView setNeedsDisplay];
        
        // Update window frame
        [self.window setFrame:NSMakeRect(NSMidX(oldWindowFrame) - 50, NSMidY(oldWindowFrame) - 50, 100, 100)
                      display:YES
                      animate:YES];
    }
}

- (void)updateProgressWithRect:(CGRect)updatedRect zoomScalePower:(CGFloat)zoomScalePower {
    // Update preview image
    CGFloat ratio = self.previewImage.size.width / self.task.sourceImageSize.width;
    NSRect updatedPreviewRect = NSMakeRect(floor(updatedRect.origin.x * ratio),
                                           floor(updatedRect.origin.y * ratio),
                                           ceil(updatedRect.size.width * ratio),
                                           ceil(updatedRect.size.height * ratio));
    [self.imageView.image lockFocus];
    [[NSColor blackColor] setFill];
    NSRectFill(updatedPreviewRect);
    CGFloat alpha = (CGFloat)(zoomScalePower - self.task.minScalePower + 1)/(self.task.maxScalePower - self.task.minScalePower + 1);
    [self.previewImage drawInRect:updatedPreviewRect
                             fromRect:updatedPreviewRect
                            operation:NSCompositeSourceOver
                             fraction:alpha];
    [self.imageView.image unlockFocus];
    [self.imageView setNeedsDisplay];
    
    // Update time label string
    if (self.task && self.task.beginDate) {
        NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:self.task.beginDate];
        CGFloat minutes = floor(elapsedTime/60.);
        CGFloat seconds = (int)elapsedTime % 60;
        NSTimeInterval remainingTime = elapsedTime / self.task.progress;
        CGFloat remainingMinutes = floor(remainingTime/60.);
        CGFloat remainingSeconds = (int)remainingTime % 60;
    
        if (self.task.progress <= 0) {
            self.messageLabelString = [NSString stringWithFormat:NSLocalizedString(@"Elapsed :\n%2.0f:%2.0f\nCalculating...",nil),minutes,seconds];
        }
        else {
            self.messageLabelString = [NSString stringWithFormat:NSLocalizedString(@"Elapsed :\n%2.0f:%2.0f\nRemaining :\n%2.0f:%2.0f",nil),minutes,seconds,remainingMinutes,remainingSeconds];
        }
    }
    else {
        self.messageLabelString = nil;
    }
}

@end
