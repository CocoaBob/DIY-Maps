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

@property (nonatomic, strong) NSImage *fullPreviewImage;

@end

@implementation DMMPreviewWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window setMovableByWindowBackground:YES];
    [self.window setLevel:NSFloatingWindowLevel];
    [[NSNotificationCenter defaultCenter] addObserverForName:DMPTaskDidUpdateNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      DMTask *updatedTask = [note object];
                                                      if (updatedTask != self.task) {
                                                          self.task  = updatedTask;
                                                          [self updateTask];
                                                      }
                                                      else {
                                                          NSDictionary *userInfo = [note userInfo];
                                                          NSRect completedRect = [userInfo[@"CompletedRect"] rectValue];
                                                          CGFloat zoomScale = [userInfo[@"ZoomScale"] doubleValue];
                                                          [self updateProgressWithRect:NSRectToCGRect(completedRect)
                                                                        zoomScalePower:log2(zoomScale)];
                                                      }
                                                  }];
}

- (void)updateTask {
    NSRect oldWindowFrame = self.window.frame;
    if (self.task) {
        // Prepare preview image
        NSImage *srcImage = [[NSImage alloc] initWithContentsOfFile:self.task.inputFilePath];
        self.fullPreviewImage = [DMImageProcessor thumbnailWithImage:srcImage
                                                        cropRect:CGRectZero
                                                      outputSize:CGSizeMake(PREVIEW_SIZE,PREVIEW_SIZE)];
        
        // Update window frame
        CGFloat imageWidth = self.fullPreviewImage.size.width;
        CGFloat imageHeight = self.fullPreviewImage.size.height;
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
    else {
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
    CGFloat ratio = self.fullPreviewImage.size.width / self.task.sourceImageSize.width;
    NSRect updatedPreviewRect = NSMakeRect(updatedRect.origin.x * ratio,
                                           updatedRect.origin.y * ratio,
                                           updatedRect.size.width * ratio,
                                           updatedRect.size.height * ratio);
    [self.imageView.image lockFocus];
    [[NSColor blackColor] setFill];
    NSRectFill(updatedPreviewRect);
    CGFloat alpha = (CGFloat)(zoomScalePower - self.task.minScalePower + 1)/(self.task.maxScalePower - self.task.minScalePower + 1);
    [self.fullPreviewImage drawInRect:updatedPreviewRect
                             fromRect:updatedPreviewRect
                            operation:NSCompositeSourceOver
                             fraction:alpha];
    [self.imageView.image unlockFocus];
    [self.imageView setNeedsDisplay];
}

@end
