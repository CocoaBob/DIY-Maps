//
//  DMMapPickerViewController.m
//  ScaleableMapView
//
//  Created by Bob on 11/15/12.
//  Copyright (c) 2012 Bob. All rights reserved.
//

#import "DMMapPickerViewController.h"
#import "DMMapPickerViews.h"

#import <QuartzCore/QuartzCore.h>
#import "DMMapViewController.h"
#import "DMAppDelegate.h"

#import "BVReorderTableView.h"
#import "CBColorMaskedButton.h"
#import "CBMapKit.h"
#import "UINavigationBar+CBDropShadow.h"
#import "ZKRevealingTableViewCell.h"

@interface DMMapPickerViewController () <UIAlertViewDelegate,UIGestureRecognizerDelegate,ZKRevealingTableViewCellDelegate>

@property (nonatomic, strong) ZKRevealingTableViewCell *currentRevealedCell;
@property (nonatomic, strong) NSMutableDictionary *imageLoadingInProgress;
@property (nonatomic, strong) NSOperationQueue *imageLoadingOperationQueue;
@property (nonatomic, strong) NSCache *thumbnailCache;

@end

@implementation DMMapPickerViewController {
    UIImage *_thumbnailDefaultImage;
    CGRect _thumbnailRect;
}

static DMMapPickerViewController *sharedInstance = nil;

+ (DMMapPickerViewController *)shared {
	@synchronized(self) {
		if (!sharedInstance)
			sharedInstance = [DMMapPickerViewController new];
	}
	return sharedInstance;
}

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.wantsFullScreenLayout = NO;
        
        self.navigationItem.title = NSLocalizedString(@"Maps", nil);
        
        CBColorMaskedButton *doneButton = [[CBColorMaskedButton alloc] initWithFrame:CGRectMake(0, 0, 36, 24)];
        [doneButton setImage:[UIImage imageNamed:@"img-done"] forState:UIControlStateNormal];
        [doneButton addTarget:self action:@selector(dismissViewController) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
        
        // TableView
#if REORDER_TABLE_ENABLED
        self.tableView = [BVReorderTableView new];
#else
        self.tableView = [UITableView new];
#endif
        self.tableView.rowHeight = 100;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        // Image loading
        self.imageLoadingOperationQueue = [NSOperationQueue new];
        self.imageLoadingOperationQueue.maxConcurrentOperationCount = 1;
        self.imageLoadingInProgress = [@{} mutableCopy];
        self.thumbnailCache = [NSCache new];
        
        // Table updating
        [[DMFileManager shared] addObserver:self
                                 forKeyPath:@"sortedFileNames"
                                    options:0
                                    context:NULL];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [[self.view window] endEditing:YES];
                                                          [self updateNavigationBarShadow:YES];
                                                      }];
    }
    return self;
}

- (void)dealloc {
    [[DMFileManager shared] removeObserver:self forKeyPath:@"sortedFileNames"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.thumbnailCache removeAllObjects];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!IS_PAD) {
        [self.navigationController.navigationBar setTranslucent:YES];
    }
    
    [[DMFileManager shared] reloadFileList];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[DMFileManager shared] startWatchingDocumentFolder];
    [self loadImagesForOnscreenRows];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[DMFileManager shared] stopWatchingDocumentFolder];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"sortedFileNames"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, [CATransaction animationDuration] * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark UIScrollViewDelegate

// Manage navigation bar drop shadow
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateNavigationBarShadow:NO];
}

// Table Cell Images
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self loadImagesForOnscreenRows];
    }
}

// Table Cell Images
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadImagesForOnscreenRows];
}

// ZKRevealingTableViewCell
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self updateCurrentRevealedCell:nil];
}

#pragma mark UITableViewCell

- (void)initializeTableViewCell:(DMMapPickerCell **)tableViewCell {
    DMMapPickerCell *cell = (*tableViewCell);
    // ZKRevealingTableViewCell
    cell.delegate = self;
    cell.direction = ZKRevealingTableViewCellDirectionBoth;
    cell.shouldBounce = YES;
    
    cell.backgroundView = [DMMapPickerCellBackView new];
    
    // UITableViewCell styles
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.contentView.backgroundColor = [UIColor whiteColor];
    cell.selectedBackgroundView = [UIView new];
    cell.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    cell.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.2f];
    
    cell.accessoryView = nil;
    
    // Contents
    cell.textLabel.textColor = [UIColor colorWithWhite:0.15f alpha:1.0f];
    cell.textLabel.highlightedTextColor = [UIColor colorWithWhite:0.15f alpha:1.0f];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.shadowOffset = CGSizeMake(0, 0);
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
    
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.detailTextLabel.highlightedTextColor = [UIColor grayColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.shadowOffset = CGSizeMake(0, 0);
    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    
    cell.imageView.image = [self thumbnailDefaultImage];
    cell.imageView.layer.borderWidth = 4;
    cell.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    cell.imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    cell.imageView.layer.shadowOffset = CGSizeZero;
    cell.imageView.layer.shadowRadius = 1;
    cell.imageView.layer.shadowOpacity = 1;
    cell.imageView.clipsToBounds = NO;
}

- (void)fillTableViewCell:(DMMapPickerCell **)tableCell withIndexPath:(NSIndexPath *)indexPath {
    (*tableCell).backgroundView.tag = indexPath.row;
    
    NSString *fileName = ([DMFileManager shared].sortedFileNames)[indexPath.row];
    (*tableCell).textLabel.text = [fileName stringByDeletingPathExtension];
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[[DMFileManager docPath] stringByAppendingPathComponent:fileName] error:NULL];
    (*tableCell).detailTextLabel.text = [NSString stringWithFormat:@"%@ MB",[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:[fileAttributes fileSize]/1000000.0f] numberStyle:NSNumberFormatterDecimalStyle]];
    
    (*tableCell).imageView.image = [self thumbnailImageWithFileName:fileName];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[DMFileManager shared].sortedFileNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
#if REORDER_TABLE_ENABLED
    if ([[[DMFileManager shared].sortedFileNames objectAtIndex:indexPath.row] isKindOfClass:[NSString class]] &&
        [[[DMFileManager shared].sortedFileNames objectAtIndex:indexPath.row] isEqualToString:@"DUMMY"]) {
        static NSString *BlankRowCellIdentifier = @"BlankRowCellIdentifier";
        DMMapPickerCell *blankCell = [tableView dequeueReusableCellWithIdentifier:BlankRowCellIdentifier];
        if (blankCell == nil) {
            blankCell = [[DMMapPickerCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:BlankRowCellIdentifier];
            [self initializeTableViewCell:&blankCell];
            blankCell.textLabel.text = @"";
            blankCell.detailTextLabel.text = @"";
            blankCell.imageView.image = nil;
            blankCell.accessoryType = UITableViewCellAccessoryNone;
        }
        return blankCell;
    }
#endif
    
    static NSString *MapFileCellIdentifier = @"MapFileCellIdentifier";
    DMMapPickerCell *mapFileCell = [tableView dequeueReusableCellWithIdentifier:MapFileCellIdentifier];
    if (mapFileCell == nil) {
        mapFileCell = [[DMMapPickerCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:MapFileCellIdentifier];
        [self initializeTableViewCell:&mapFileCell];
    }
    [self fillTableViewCell:&mapFileCell withIndexPath:indexPath];
    
    return mapFileCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSString *movedMapFileName = ([DMFileManager shared].sortedFileNames)[sourceIndexPath.row];
    [[DMFileManager shared].sortedFileNames removeObjectAtIndex:sourceIndexPath.row];
    [[DMFileManager shared].sortedFileNames insertObject:movedMapFileName atIndex:destinationIndexPath.row];
    [[DMFileManager shared] saveSortedFileNames];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *fileName = ([DMFileManager shared].sortedFileNames)[indexPath.row];
    NSString *filePath = [[DMFileManager docPath] stringByAppendingPathComponent:fileName];
    [DMMapViewController loadMapFile:filePath];
    DefaultsSet(Object, kLastOpenedMapVisibleRect, NSStringFromCGRect([[[DMMapViewController shared] mapView] visibleMapRect]));
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark ZKRevealingTableViewCellDelegate

- (void)updateCurrentRevealedCell:(ZKRevealingTableViewCell *)newValue {
    if (newValue != self.currentRevealedCell) {
        [self.currentRevealedCell setRevealing:NO];
        @try {
            [self.currentRevealedCell setRevealing:NO];
        }
        @catch (NSException *exception) {
            NSLog(@"%s %@",__func__,[exception reason]);
        }
        self.currentRevealedCell = newValue;
#if REORDER_TABLE_ENABLED
        BOOL canReorder = (self.currentRevealedCell == nil);
        ((BVReorderTableView *)self.tableView).canReorder = canReorder;
#endif
    }
}

- (BOOL)cellShouldReveal:(ZKRevealingTableViewCell *)cell {
    [(DMMapPickerCellBackView *)cell.backgroundView resetToNormalStatus];
	return YES;
}

- (void)cellDidReveal:(ZKRevealingTableViewCell *)cell {
    [self updateCurrentRevealedCell:cell];
}

- (void)cellDidBeginPan:(ZKRevealingTableViewCell *)cell {
    [self updateCurrentRevealedCell:nil];
}

#if REORDER_TABLE_ENABLED
#pragma mark BVReorderTableViewDelegate

- (id)saveObjectAndInsertBlankRowAtIndexPath:(NSIndexPath *)indexPath {
    id object = [[DMFileManager shared].sortedFileNames objectAtIndex:indexPath.row];
    [[DMFileManager shared].sortedFileNames replaceObjectAtIndex:indexPath.row withObject:@"DUMMY"];
    return object;
}

- (void)moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    id object = [[DMFileManager shared].sortedFileNames objectAtIndex:fromIndexPath.row];
    [[DMFileManager shared].sortedFileNames removeObjectAtIndex:fromIndexPath.row];
    [[DMFileManager shared].sortedFileNames insertObject:object atIndex:toIndexPath.row];
}

- (void)finishReorderingWithObject:(id)object atIndexPath:(NSIndexPath *)indexPath; {
    [[DMFileManager shared].sortedFileNames replaceObjectAtIndex:indexPath.row withObject:object];
    [[DMFileManager shared] saveSortedFileNames];
    // do any additional cleanup here
}

#endif

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

#pragma mark -

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)updateNavigationBarShadow:(BOOL)reDrop {
    if (self.tableView.contentOffset.y > (- self.tableView.contentInset.top + 3)) {
        if (reDrop) {
            [self.navigationController.navigationBar hideShadowAnimated:NO];
        }
        [self.navigationController.navigationBar dropShadowWithOffset:CGSizeZero
                                                               radius:3
                                                                color:[UIColor blackColor]
                                                              opacity:0.33f
                                                             animated:YES];
    }
    else {
        [self.navigationController.navigationBar hideShadowAnimated:YES];
    }
}

#pragma mark Thumbnail management

- (CGRect)thumbnailRect {
    if (CGRectEqualToRect(_thumbnailRect, CGRectZero)) {
        CGFloat rowHeight = [self.tableView rowHeight];
        CGFloat imageMargin = floorf(rowHeight * 0.2);
        CGFloat imageSize = rowHeight - imageMargin;
        _thumbnailRect = CGRectMake(0, 0, imageSize, imageSize);
    }
    return _thumbnailRect;
}

- (UIImage *)thumbnailWithFileName:(NSString *)fileName {
    UIImage *returnThumbnailImage = nil;
    CBMapFile *mapFile = [CBMapFile mapFileWithPath:[[DMFileManager docPath] stringByAppendingPathComponent:fileName]];
    if (mapFile) {
        UIImage *previewImage = [mapFile previewImage];
        if (previewImage) {
            CGRect imageRect = [self thumbnailRect];
            CGFloat imageSize = imageRect.size.width;
            
            // Begin drawing
            UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, [UIScreen mainScreen].scale);
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            
            // Draw image
            CGContextSaveGState(ctx);
            CGFloat imageProportion = previewImage.size.height / previewImage.size.width;
            CGRect drawingRect;
            if (imageProportion > 1) {
                drawingRect = CGRectMake(0, 0, imageSize, imageSize * imageProportion);
            }
            else {
                drawingRect = CGRectMake(0, 0, imageSize / imageProportion, imageSize);
            }
            drawingRect.origin.x = (imageSize - CGRectGetWidth(drawingRect))/2.0;
            drawingRect.origin.y = (imageSize - CGRectGetHeight(drawingRect))/2.0;
            [previewImage drawInRect:drawingRect];
            
            // Draw inner border
            [[UIColor lightGrayColor] setStroke];
            [[UIBezierPath bezierPathWithRect:CGRectInset(imageRect, 4.5, 4.5)] stroke];
            CGContextRestoreGState(ctx);
            
            // Get image
            returnThumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [self.thumbnailCache setObject:returnThumbnailImage forKey:fileName];
        }
    }
    return returnThumbnailImage;
}

- (UIImage *)thumbnailDefaultImage {
    if (!_thumbnailDefaultImage) {
        UIGraphicsBeginImageContextWithOptions([self thumbnailRect].size, NO, [UIScreen mainScreen].scale);
        _thumbnailDefaultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return _thumbnailDefaultImage;
}

- (void)setThumbnail:(UIImage *)thumbnail forFileName:(NSString *)fileName {
    if (thumbnail && fileName) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[DMFileManager shared].sortedFileNames indexOfObject:fileName] inSection:0];
        if ([[self.tableView indexPathsForVisibleRows] containsObject:indexPath]) {
            DMMapPickerCell *cell = (DMMapPickerCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell.imageView performSelectorOnMainThread:@selector(setImage:) withObject:thumbnail waitUntilDone:YES];
            [cell.imageView performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
        }
    }
}

- (UIImage *)thumbnailImageWithFileName:(NSString *)fileName {
    UIImage *previewThumbnail = [self.thumbnailCache objectForKey:fileName];
    if (previewThumbnail) {
        return previewThumbnail;
    }
    else {
        NSString *isLoading = self.imageLoadingInProgress[fileName];
        if (!isLoading) {
            NSBlockOperation *loadImageOperation = [NSBlockOperation blockOperationWithBlock:^{
                [self setThumbnail:[self thumbnailWithFileName:fileName] forFileName:fileName];
            }];
            [loadImageOperation setCompletionBlock:^{
                [self.imageLoadingInProgress removeObjectForKey:fileName];
            }];
            [self.imageLoadingOperationQueue addOperation:loadImageOperation];
            self.imageLoadingInProgress[fileName] = fileName;
        }
    }
    return [self thumbnailDefaultImage];
}

- (void)loadImagesForOnscreenRows {
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
}

@end
