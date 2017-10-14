//
//  NSString+Extensions.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 3/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extensions)

/**
 * Checks if the reciever contains the given substring.
 *
 * @return YES if the reciever contains the substring, NO if it does not.
 * @param substring The string to search for
 */
- (BOOL)containsSubstring:(NSString *)substring;

@end
