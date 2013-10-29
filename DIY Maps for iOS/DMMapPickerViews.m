//
//  DMMapPickerViews.m
//  DIY Maps
//
//  Created by CocoaBob on 16/07/13.
//  Copyright (c) 2013 Bob. All rights reserved.
//

#import "DMMapPickerViews.h"

#import <QuartzCore/QuartzCore.h>
#import "CBColorMaskedButton.h"
#import "DMFileManager.h"
#import "ZKRevealingTableViewCell.h"
#import "DMMapViewController.h"

typedef NS_ENUM(NSUInteger, CBDirection) {
    CBDirectionLeft = 0,
    CBDirectionRight,
    CBDirectionTop,
    CBDirectionBottom
};

typedef NS_ENUM(NSUInteger, BackViewStatus) {
    BackViewStatusNormal = 0,
    BackViewStatusRenaming,
    BackViewStatusDeleting
};

@interface DMMapPickerCellBackView () <UITextFieldDelegate>
@property (nonatomic, strong) NSMutableArray *normalStatusButtons;
@property (nonatomic, strong) UITextField *editingTextField;
@property (nonatomic, strong) UILabel *deletingLabel;
@property (nonatomic, strong) CBColorMaskedButton *cancelButton,*okButton;
@property (nonatomic, assign) BackViewStatus currentStatus;
@end

@implementation DMMapPickerCellBackView

- (id)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.973 alpha:1];
        
        [self addObserver:self forKeyPath:@"currentStatus" options:0 context:NULL];
        
        // Normal Status Buttons
        self.normalStatusButtons = [@[] mutableCopy];
        
        CBColorMaskedButton *renameButton = [[CBColorMaskedButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        [renameButton setImage:[UIImage imageNamed:@"img-pencil"] forState:UIControlStateNormal];
        [renameButton addTarget:self action:@selector(doRename:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:renameButton];
        [self.normalStatusButtons addObject:renameButton];
        
        CBColorMaskedButton *deleteButton = [[CBColorMaskedButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        [deleteButton setImage:[UIImage imageNamed:@"img-trash"] forState:UIControlStateNormal];
        [deleteButton addTarget:self action:@selector(doDelete:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:deleteButton];
        [self.normalStatusButtons addObject:deleteButton];
        
        CBColorMaskedButton *settingButton = [[CBColorMaskedButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        [settingButton setImage:[UIImage imageNamed:@"img-wrench"] forState:UIControlStateNormal];
        [settingButton addTarget:self action:@selector(doSetting:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:settingButton];
        [self.normalStatusButtons addObject:settingButton];
        
        // Editing Status Buttons
        self.editingTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 260, 30)];
        self.editingTextField.delegate = self;
        self.editingTextField.backgroundColor = [UIColor clearColor];
        self.editingTextField.textAlignment = UITextAlignmentCenter;
        self.editingTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.editingTextField.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
        self.editingTextField.textColor = kThemeNormalColor;
        self.editingTextField.borderStyle = UITextBorderStyleNone;
        self.editingTextField.returnKeyType = UIReturnKeyDone;
        self.editingTextField.layer.borderColor = kThemeNormalColor.CGColor;
        self.editingTextField.layer.borderWidth = 1.0f;
        self.editingTextField.layer.cornerRadius = 4.0f;
        self.editingTextField.layer.shadowColor = [UIColor clearColor].CGColor;
        self.editingTextField.clipsToBounds = NO;
        [self addSubview:self.editingTextField];
        
        self.deletingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 260, 36)];
        self.deletingLabel.numberOfLines = 2;
        self.deletingLabel.backgroundColor = [UIColor clearColor];
        self.deletingLabel.textAlignment = UITextAlignmentCenter;
        self.deletingLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
        self.deletingLabel.textColor = kThemeNormalColor;
        self.deletingLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.deletingLabel];
        
        self.cancelButton = [[CBColorMaskedButton alloc] initWithFrame:CGRectMake(0, 0, 130, 24)];
        [self.cancelButton setImage:[UIImage imageNamed:@"img-cancel"] forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(doCancel:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.cancelButton];
        
        self.okButton = [[CBColorMaskedButton alloc] initWithFrame:CGRectMake(0, 0, 130, 24)];
        [self.okButton setImage:[UIImage imageNamed:@"img-check"] forState:UIControlStateNormal];
        [self.okButton addTarget:self action:@selector(doOK:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.okButton];
        
        // Initial state
        [self setNormalControlsHidden:NO];
        [self setSettingControlsWithStatus:BackViewStatusNormal];
        self.currentStatus = BackViewStatusNormal;
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"currentStatus"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"currentStatus"]) {
        [self setNeedsLayout];
    }
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [[self window] endEditing:YES];
    [self doOK:nil];
    return YES;
}

#pragma mark UIView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *returnValue = [super hitTest:point withEvent:event];
    if (![returnValue isKindOfClass:[UITextField class]]) {
        [[self window] endEditing:YES];
    }
    if (returnValue == self) {
        UIView *tableCell = [self superview];
        UIView *tableView = [tableCell superview];
        return tableView;
    }
    else {
        return returnValue;
    }
}

- (void)layoutSubviews {
    CGFloat cellWidth = CGRectGetWidth(self.bounds);
    CGFloat cellHeight = CGRectGetHeight(self.bounds);
    if (self.currentStatus == BackViewStatusNormal) {
        CGFloat buttonInterval = cellWidth/([self.normalStatusButtons count] + 1);
        CGFloat buttonIntervalPercentage = buttonInterval / cellWidth;
        CGFloat buttonWidth = MIN(buttonInterval, cellHeight * 2);
        CGRect buttonRect = CGRectMake(0, 0, buttonWidth, cellHeight);
        
        [self.normalStatusButtons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            ((UIView *)obj).bounds = buttonRect;
            [self placeSubView:(UIView *)obj atPercentage:buttonIntervalPercentage * (idx + 1)];
        }];
    }
    else if (self.currentStatus == BackViewStatusRenaming ||
             self.currentStatus == BackViewStatusDeleting) {
        CGFloat centerX = cellWidth / 2.0;
        CGFloat centerY = cellHeight / 2.0;
        [self.editingTextField setCenter:CGPointMake(centerX, centerY - 15)];
        [self.deletingLabel setCenter:CGPointMake(centerX, centerY - 18)];
        [self.cancelButton setCenter:CGPointMake(centerX - 65, centerY + 27)];
        [self.okButton setCenter:CGPointMake(centerX + 65, centerY + 27)];
    }
}

#pragma mark Subview positions

- (void)placeSubView:(UIView *)subView atPercentage:(CGFloat)percentage {
    CGRect boundsRect = [self bounds];
    [subView setCenter:CGPointMake(nearbyint(CGRectGetWidth(boundsRect) * percentage), CGRectGetHeight(boundsRect) / 2.0)];
}

- (void)hideSubView:(UIView *)subView direction:(CBDirection)direction {
    CGRect superViewFrame = [[subView superview] frame];
    CGPoint oldCenter = subView.center;
    CGPoint newCenter = oldCenter;
    switch (direction) {
        case CBDirectionLeft:
            newCenter.x -= CGRectGetWidth(superViewFrame);
            break;
        case CBDirectionRight:
            newCenter.x += CGRectGetWidth(superViewFrame);
            break;
        case CBDirectionTop:
            newCenter.y += CGRectGetHeight(superViewFrame);
            break;
        case CBDirectionBottom:
            newCenter.y -= CGRectGetHeight(superViewFrame);
            break;
    }
    [subView setCenter:newCenter];
}

- (void)setNormalControlsHidden:(BOOL)isHidden {
    [self.normalStatusButtons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(UIView *)obj setHidden:isHidden];
    }];
}

- (void)setSettingControlsWithStatus:(BackViewStatus)status {
    [self.editingTextField setHidden:(status != BackViewStatusRenaming)];
    [self.deletingLabel setHidden:(status != BackViewStatusDeleting)];
    [self.cancelButton setHidden:!(status != BackViewStatusNormal)];
    [self.okButton setHidden:!(status != BackViewStatusNormal)];
}

- (void)resetToNormalStatus {
    self.currentStatus = BackViewStatusNormal;
    [UIView animateWithDuration:0.25f
                     animations:^{
                         [self setNormalControlsHidden:NO];
                         [self setSettingControlsWithStatus:BackViewStatusNormal];
                     }];
}

#pragma mark Actions

- (IBAction)doRename:(id)sender {
    self.editingTextField.text = [[DMFileManager shared].sortedFileNames[self.tag] stringByDeletingPathExtension];
    [UIView animateWithDuration:0.25f
                     animations:^{
                         [self setNormalControlsHidden:YES];
                         [self setSettingControlsWithStatus:BackViewStatusRenaming];
                         self.currentStatus = BackViewStatusRenaming;
                     } completion:^(BOOL finished) {
                         [self.editingTextField becomeFirstResponder];
                     }];
}

- (IBAction)doDelete:(id)sender {
    NSString *fileName = [[DMFileManager shared].sortedFileNames[self.tag] stringByDeletingPathExtension];
    self.deletingLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Delete \"%@\"?", nil),fileName];
    [UIView animateWithDuration:0.25f
                     animations:^{
                         [self setNormalControlsHidden:YES];
                         [self setSettingControlsWithStatus:BackViewStatusDeleting];
                         self.currentStatus = BackViewStatusDeleting;
                     }];
}

- (IBAction)doSetting:(id)sender {
    [self endEditing:YES];
    NSString *fileBaseName = [[DMFileManager shared].sortedFileNames[self.tag] stringByDeletingPathExtension];
    [[DMFileManager shared] shareFileWithBaseName:fileBaseName senderView:sender];
}

- (IBAction)doCancel:(id)sender {
    [self endEditing:YES];
    @try {
        [(ZKRevealingTableViewCell *)[self superview] setRevealing:NO];
    }
    @catch (NSException *exception) {
        NSLog(@"%s %@",__func__,[exception reason]);
    }
    [self resetToNormalStatus];
}

- (IBAction)doOK:(id)sender {
    [self endEditing:YES];
    NSString *fileBaseName = [[DMFileManager shared].sortedFileNames[self.tag] stringByDeletingPathExtension];
    if (self.currentStatus == BackViewStatusRenaming) {
        [[DMFileManager shared] renameOldBaseName:fileBaseName toNewBaseName:self.editingTextField.text];
    }
    else if (self.currentStatus == BackViewStatusDeleting) {
        [[DMFileManager shared] deleteFileWithBaseName:fileBaseName];
        if ([[DMFileManager shared].sortedFileNames count] > 0) {
            NSString *filePath = [[DMFileManager docPath] stringByAppendingPathComponent:[DMFileManager shared].sortedFileNames[0]];
            [DMMapViewController loadMapFile:filePath];
        }
    }
    @try {
        [(ZKRevealingTableViewCell *)[self superview] setRevealing:NO];
    }
    @catch (NSException *exception) {
        NSLog(@"%s %@",__func__,[exception reason]);
    }
    [self resetToNormalStatus];
}

@end

#pragma mark -

@implementation DMMapPickerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self addObserver:self forKeyPath:@"isRevealing" options:0 context:NULL];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"isRevealing"];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *returnValue = [super hitTest:point withEvent:event];
    if (![returnValue isKindOfClass:[UITextField class]]) {
        [[self window] endEditing:YES];
    }
    return returnValue;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isRevealing"]) {
        if ([self.backgroundView isKindOfClass:[DMMapPickerCellBackView class]]) {
            if (![self isRevealing]) {
                [(DMMapPickerCellBackView *)self.backgroundView resetToNormalStatus];
                [(DMMapPickerCellBackView *)self.backgroundView endEditing:YES];
            }
        }
    }
}

@end