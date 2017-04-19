//
//  DMMConstants.h
//  DIY Maps for Mac
//
//  Created by CocoaBob on 13/09/13.

#define DefaultsGet(type, key) ([[NSUserDefaults standardUserDefaults] type##ForKey:key])
#define DefaultsSet(Type, key, value) do {\
[[NSUserDefaults standardUserDefaults] set##Type:value forKey:key];\
[[NSUserDefaults standardUserDefaults] synchronize];\
} while (0)
