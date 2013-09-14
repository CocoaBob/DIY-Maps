//
//  DMFileManager.m
//  DIY Maps
//
//  Created by Bob on 16/07/13.
//  Copyright (c) 2013 Bob. All rights reserved.
//

#import "DMFileManager.h"

#import "MHWDirectoryWatcher.h"

@implementation DMFileManager

static DMFileManager *sharedInstance = nil;

+ (DMFileManager *)shared {
	@synchronized(self) {
		if (!sharedInstance)
			sharedInstance = [DMFileManager new];
	}
	return sharedInstance;
}

+ (NSString *)docPath {
    static NSString *documentPath = nil;
    if (!documentPath) {
        documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    }
    return documentPath;
}

#pragma mark -

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

@end
