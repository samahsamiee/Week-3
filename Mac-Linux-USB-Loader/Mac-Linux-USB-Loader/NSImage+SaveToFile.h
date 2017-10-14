//
//  NSImage+SaveToFile.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 8/18/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSImage (SaveToFile)
- (void)saveAsPNGWithName:(NSString *)fileName;
@end
