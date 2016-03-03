//
//  DMFileManager.m
//  DIY Maps
//
//  Created by Bob on 16/07/13.
//  Copyright (c) 2013 Bob. All rights reserved.
//

#import "DMFileManager.h"

#import "MHWDirectoryWatcher.h"

@interface DMFileManager ()

@property (nonatomic, strong) UIDocumentInteractionController *docInteractionController;

@end

@implementation DMFileManager

#pragma mark -

+ (NSString *)docPath {
    static NSString *documentPath = nil;
    if (!documentPath) {
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSURL *docFolderPathURL = [[fileMgr URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        documentPath = [docFolderPathURL path];
        
        NSError *error;
        BOOL isDir = NO;
        if (![fileMgr fileExistsAtPath:documentPath isDirectory:&isDir] || !isDir) { // If not exist or was a file, create a new one
            if (![fileMgr removeItemAtPath:documentPath error:&error]) {
                NSLog(@"%@",error);
            }
            if (![fileMgr createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"%@",error);
            }
        }
        
        [self excludeFromBackup:documentPath];
    }
    return documentPath;
}

+ (BOOL)excludeFromBackup:(NSString *)path {
    NSError *error;
    if([[NSURL fileURLWithPath:path] setResourceValue:@(YES) forKey: NSURLIsExcludedFromBackupKey error: &error]){
        return YES;
    } else {
        NSLog(@"%@",error);
        return NO;
    }
}

#pragma mark - Object Lifecycle

static DMFileManager *__sharedInstance = nil;

+ (instancetype)shared {
    if (__sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __sharedInstance = [[[self class] alloc] init];
        });
    }
    
    return __sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        // Map folder watching
        self.directoryWatcher = [MHWDirectoryWatcher directoryWatcherAtPath:[DMFileManager docPath] callback:^{
            [[DMFileManager shared] reloadFileList];
        }];
    }
    return self;
}

#pragma mark - File Names

+ (NSString *)uniqueFileName:(NSString *)fileName atFolder:(NSString *)folderPath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *baseName = [fileName stringByDeletingPathExtension];
	NSString *extensionName = [fileName pathExtension];
	NSInteger suffix = 0;
	while ([fileManager fileExistsAtPath:[folderPath stringByAppendingPathComponent:[(suffix == 0)?baseName:[baseName stringByAppendingFormat:@"_%d",suffix] stringByAppendingPathExtension:extensionName]]]) {
		suffix++;
	}
	return [folderPath stringByAppendingPathComponent:[(suffix == 0)?baseName:[baseName stringByAppendingFormat:@"_%d",suffix] stringByAppendingPathExtension:extensionName]];
}

- (NSString *)findFileNameWithBaseName:(NSString *)baseName {
    __block NSString *returnValue = nil;
    [self.sortedFileNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[(NSString *)obj stringByDeletingPathExtension] isEqualToString:baseName]) {
            returnValue = (NSString *)obj;
            *stop = YES;
        }
    }];
    return returnValue;
}

#pragma mark -

- (NSUInteger *)indexOfFileWithName:(NSString *)fileName {
    return [self.sortedFileNames indexOfObject:fileName];
}

- (void)saveSortedFileNames {
    DefaultsSet(Object, kLastSortedFileNameList, self.sortedFileNames);
}

- (void)reloadFileList {
    // Existing files
    NSString *documentFolderPath = [DMFileManager docPath];
    NSArray *allFileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentFolderPath error:NULL];
    
    // Sorted file list
    NSArray *lastSortedFileNames = DefaultsGet(object, kLastSortedFileNameList);
    if (lastSortedFileNames) {
        NSMutableArray *nonExistentFileNames = [lastSortedFileNames mutableCopy];
        [nonExistentFileNames removeObjectsInArray:allFileNames];
        NSMutableArray *existentSortedFileNames = [lastSortedFileNames mutableCopy];
        [existentSortedFileNames removeObjectsInArray:nonExistentFileNames];
        // Remove duplicates
        NSArray *existentSortedFileNamesCopy = [existentSortedFileNames copy];
        NSInteger index = [existentSortedFileNamesCopy count] - 1;
        for (id object in [existentSortedFileNamesCopy reverseObjectEnumerator]) {
            if ([existentSortedFileNames indexOfObject:object inRange:NSMakeRange(0, index)] != NSNotFound) {
                [existentSortedFileNames removeObjectAtIndex:index];
            }
            index--;
        }
        // Final list
        NSMutableArray *newFileNames = [allFileNames mutableCopy];
        [newFileNames removeObjectsInArray:existentSortedFileNames];
        allFileNames = [newFileNames arrayByAddingObjectsFromArray:existentSortedFileNames];
    }
    self.sortedFileNames = [[allFileNames pathsMatchingExtensions:@[@"map"]] mutableCopy];
    [self saveSortedFileNames];
}

- (void)renameOldBaseName:(NSString *)oldBaseName toNewBaseName:(NSString *)newBaseName {
    NSString *oldFileName = [self findFileNameWithBaseName:oldBaseName];
    NSString *newFileName = [newBaseName stringByAppendingPathExtension:[oldFileName pathExtension]];
    NSUInteger *fileIndex = [self indexOfFileWithName:oldFileName];
    
    // Rename
    NSString *oldFilePath = [[DMFileManager docPath] stringByAppendingPathComponent:oldFileName];
    NSString *newFilePath = [[DMFileManager docPath] stringByAppendingPathComponent:newFileName];
    [[NSFileManager defaultManager] moveItemAtPath:oldFilePath toPath:newFilePath error:NULL];
    
    // Update table
    [self willChangeValueForKey:@"sortedFileNames"];
    [_sortedFileNames removeObjectAtIndex:fileIndex];
    [_sortedFileNames insertObject:newFileName atIndex:fileIndex];
    [self didChangeValueForKey:@"sortedFileNames"];
    
    // Update last opened file path if the same file has been renamed
    NSString *lastOpenedMapFilePath = DefaultsGet(object, kLastOpenedMapFilePath);
    if ([oldFilePath isEqualToString:lastOpenedMapFilePath]) {
        DefaultsSet(Object, kLastOpenedMapFilePath, newFilePath);
    }
    
    [[DMFileManager shared] saveSortedFileNames];
}

- (void)deleteFileWithBaseName:(NSString *)fileBaseName {
    NSString *fileName = [self findFileNameWithBaseName:fileBaseName];
    NSUInteger *fileIndex = [self indexOfFileWithName:fileName];
    [self stopWatchingDocumentFolder];
    if ([[NSFileManager defaultManager] removeItemAtPath:[[DMFileManager docPath] stringByAppendingPathComponent:fileName] error:NULL]) {
        [self willChangeValueForKey:@"sortedFileNames"];
        [self.sortedFileNames removeObjectAtIndex:fileIndex];
        [self didChangeValueForKey:@"sortedFileNames"];
    }
    [self startWatchingDocumentFolder];
}

- (void)startWatchingDocumentFolder {
    [self.directoryWatcher startWatching];
}

- (void)stopWatchingDocumentFolder {
    [self.directoryWatcher stopWatching];
}

#pragma mark - Exporting & Importing

- (void)shareFileWithBaseName:(NSString *)fileBaseName senderView:(UIView *)senderView {
    NSString *fileName = [self findFileNameWithBaseName:fileBaseName];
    NSString *filePath = [[DMFileManager docPath] stringByAppendingPathComponent:fileName];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
    if (self.docInteractionController == nil) {
        self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    }
    else {
        self.docInteractionController.URL = fileURL;
    }
    [[CBActivityView shared] showActivityViewWithCompletionHandler:^{
        [self.docInteractionController presentOpenInMenuFromRect:senderView.bounds
                                                          inView:senderView
                                                        animated:YES];
        [[CBActivityView shared] hideActivityView];
    }];
}

+ (void)importInbox {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *docFolderPath = [self docPath];
    NSString *inboxFolderPath = [docFolderPath stringByAppendingPathComponent:@"Inbox"];
    if (![fileMgr fileExistsAtPath:inboxFolderPath])
        return;
    
    NSArray *inboxContents = [fileMgr contentsOfDirectoryAtPath:inboxFolderPath error:nil];
    if (inboxContents && [inboxContents count] > 0) {
        [[CBActivityView shared] showActivityViewWithCompletionHandler:^{
            [inboxContents enumerateObjectsUsingBlock:^(NSString *contentName, NSUInteger idx, BOOL *stop) {
                if ([[contentName pathExtension] isEqualToString:@"map"]) {
                    NSString *contentPath = [inboxFolderPath stringByAppendingPathComponent:contentName];
                    BOOL isDir = NO;
                    if ([fileMgr fileExistsAtPath:contentPath isDirectory:&isDir] && !isDir) {
                        NSString *uniqueContentFilePath = [self uniqueFileName:contentName atFolder:docFolderPath];
                        [fileMgr moveItemAtPath:contentPath toPath:uniqueContentFilePath error:nil];
                    }
                }
            }];
            [[CBActivityView shared] hideActivityView];
        }];
    }
}

@end
