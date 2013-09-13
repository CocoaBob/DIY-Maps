//
//  ZipFile.m
//  ZipFile
//
//  Created by Kenji Nishishiro <marvel@programmershigh.org> on 10/05/08.
//  Copyright 2010 Kenji Nishishiro. All rights reserved.
//

#import "ZipFile.h"

@implementation ZipFile

static const int CASE_SENSITIVITY = 0;
static const unsigned int BUFFER_SIZE = 8192;

- (id)initWithFileAtPath:(NSString *)path {
	NSAssert(path, @"path");
	
	if (self = [super init]) {
		path_ = path;
		unzipFile_ = NULL;
	}
	return self;
}

- (void)dealloc {
	NSAssert(!unzipFile_, @"!unzipFile_");
}

- (BOOL)isOpen {
    return !(unzipFile_ == NULL);
}

- (BOOL)open {
	NSAssert(!unzipFile_, @"!unzipFile_");
	
	unzipFile_ = unzOpen([path_ UTF8String]);
	return unzipFile_ != NULL;
}

- (void)close {
	NSAssert(unzipFile_, @"unzipFile_");
	
	unzClose(unzipFile_);
	unzipFile_ = NULL;
}

- (NSData *)readWithFilePath:(NSString *)fileName maxLength:(NSUInteger)maxLength {
	NSAssert(unzipFile_, @"unzipFile_");
	NSAssert(fileName, @"fileName");
	
	if (unzLocateFile(unzipFile_, [fileName UTF8String], CASE_SENSITIVITY) != UNZ_OK) {
		return nil;
	}
	
	if (unzOpenCurrentFile(unzipFile_) != UNZ_OK) {
		return nil;
	}
	
	NSMutableData *data = [NSMutableData data];
	NSUInteger length = 0;
	void *buffer = (void *)malloc(BUFFER_SIZE);
	while (YES) {
		unsigned size = length + BUFFER_SIZE <= maxLength ? BUFFER_SIZE : maxLength - length;
		int readLength = unzReadCurrentFile(unzipFile_, buffer, size);
		if (readLength < 0) {
			free(buffer);
			unzCloseCurrentFile(unzipFile_); 
			return nil;
		}
		if (readLength > 0) {
			[data appendBytes:buffer length:readLength];
			length += readLength;
		}
		if (readLength == 0) {
			break;
		}
	};	
	free(buffer);
	
	unzCloseCurrentFile(unzipFile_);
	
	return data;
}

- (NSArray *)filePaths {
	NSAssert(unzipFile_, @"unzipFile_");
	
	NSMutableArray *results = [NSMutableArray array];
	if (unzGoToFirstFile(unzipFile_) != UNZ_OK) {
		return nil;
	}
	while (YES) {
		unz_file_info fileInfo;
		char fileName[PATH_MAX];
		if (unzGetCurrentFileInfo(unzipFile_, &fileInfo, fileName, PATH_MAX, NULL, 0, NULL, 0) != UNZ_OK) {
			return nil;
		}
		[results addObject:@(fileName)];
		
		int error = unzGoToNextFile(unzipFile_);
		if (error == UNZ_END_OF_LIST_OF_FILE) {
			break;
		}
		if (error != UNZ_OK) {
			return nil;
		}
	}
	return results;
}

- (NSString *)firstFilePath {
	if (unzGoToFirstFile(unzipFile_) != UNZ_OK) {
		return nil;
	}
	unz_file_info fileInfo;
	char fileName[PATH_MAX];
	if (unzGetCurrentFileInfo(unzipFile_, &fileInfo, fileName, PATH_MAX, NULL, 0, NULL, 0) != UNZ_OK) {
		return nil;
	}
	return @(fileName);
}

- (BOOL)pathExists:(NSString *)filePath {
	return (unzLocateFile(unzipFile_, [filePath UTF8String], CASE_SENSITIVITY) == UNZ_OK)?YES:NO;
}

- (NSArray *)subpathsAtPath:(NSString *)path {
	NSMutableArray *results = nil;
	if (unzLocateFile(unzipFile_, [path UTF8String], CASE_SENSITIVITY) != UNZ_OK)
		return nil;
	
	while (YES) {
		int error = unzGoToNextFile(unzipFile_);
		if (error == UNZ_END_OF_LIST_OF_FILE)
			break;
		if (error != UNZ_OK)
			return nil;
		
		unz_file_info fileInfo;
		char fileName[PATH_MAX];
		if (unzGetCurrentFileInfo(unzipFile_, &fileInfo, fileName, PATH_MAX, NULL, 0, NULL, 0) != UNZ_OK)
			return nil;
		
		NSString *currentPath = @(fileName);
		if ([currentPath hasPrefix:path]) {
			if (!results) {
				results = [NSMutableArray array];
			}
			[results addObject:@(fileName)];
		}
	}
	return results;
}

@end
