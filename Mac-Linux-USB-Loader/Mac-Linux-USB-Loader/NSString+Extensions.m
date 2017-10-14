//
//  NSString+Extensions.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 3/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "NSString+Extensions.h"

@implementation NSString (Extensions)

- (BOOL)containsSubstring:(NSString *)substring {
	return [self rangeOfString:substring].location != NSNotFound;
}

@end
