//
//  DMFileManager.h
//  DIY Maps
//
//  Created by Bob on 16/07/13.
//  Copyright (c) 2013 Bob. All rights reserved.
//

@class MHWDirectoryWatcher;

@interface DMFileManager : NSObject

@property (nonatomic, strong) NSMutableArray *sortedFileNames;
@property (nonatomic, strong) MHWDirectoryWatcher *directoryWatcher;

+ (instancetype)shared;
+ (NSString *)docPath;

+ (void)importInbox;

- (void)saveSortedFileNames;
- (void)reloadFileList;
- (void)renameOldBaseName:(NSString *)oldBaseName toNewBaseName:(NSString *)newBaseName;
- (void)deleteFileWithBaseName:(NSString *)fileBaseName;
- (void)startWatchingDocumentFolder;
- (void)stopWatchingDocumentFolder;
- (void)shareFileWithBaseName:(NSString *)fileBaseName senderView:(UIView *)senderView;

@end
