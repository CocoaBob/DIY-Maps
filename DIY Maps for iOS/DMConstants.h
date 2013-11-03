//
//  DMConstants.h
//  DIY Maps
//
//  Created by Bob on 16/07/13.
//  Copyright (c) 2013 Bob. All rights reserved.
//

#define kLastSortedFileNameList @"kLastSortedFileNameList"
#define kLastOpenedMapFilePath @"kLastOpenedMapFilePath"
#define kLastOpenedMapVisibleRect @"kLastOpenedMapVisibleRect"

#define kThemeNormalColor [UIColor colorWithRed:12.0/255.0 green:95.0/255.0 blue:254.0/255.0 alpha:1.0]
#define kThemeHighlightedColor [UIColor colorWithRed:186.0/255.0 green:213.0/255.0 blue:247.0/255.0 alpha:1.0]

#define IS_PAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define DefaultsGet(type, key) ([[NSUserDefaults standardUserDefaults] type##ForKey:key])
#define DefaultsSet(Type, key, value) do {\
[[NSUserDefaults standardUserDefaults] set##Type:value forKey:key];\
[[NSUserDefaults standardUserDefaults] synchronize];\
} while (0)

static NSString *const kGoogleMapsAPIKey = @"AIzaSyBNOm4mAMrtKbYQpXHsnIhSy7pCsl77hXk";