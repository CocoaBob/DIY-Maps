//
//  NSString+SBRXCallbackURL.h
//  XCallbackURLParserDemo
//
//  Created by Sebastian Rehnby on 8/8/13.
//  Copyright (c) 2013 Sebastian Rehnby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SBRXCallbackURL)

- (NSString *)sbr_URLEncode;
- (NSString *)sbr_URLDecode;

@end
