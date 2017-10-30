#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "GMAppleDouble+ZKAdditions.h"
#import "GMAppleDouble.h"
#import "NSData+ZKAdditions.h"
#import "NSDate+ZKAdditions.h"
#import "NSDictionary+ZKAdditions.h"
#import "NSFileHandle+ZKAdditions.h"
#import "NSFileManager+ZKAdditions.h"
#import "NSString+ZKAdditions.h"
#import "ZipKit.h"
#import "ZKArchive.h"
#import "ZKCDHeader.h"
#import "ZKCDTrailer.h"
#import "ZKCDTrailer64.h"
#import "ZKCDTrailer64Locator.h"
#import "ZKDataArchive.h"
#import "ZKDefs.h"
#import "ZKFileArchive.h"
#import "ZKLFHeader.h"
#import "ZKLog.h"

FOUNDATION_EXPORT double ZipKitVersionNumber;
FOUNDATION_EXPORT const unsigned char ZipKitVersionString[];

