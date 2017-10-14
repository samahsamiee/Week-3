//
//  SBUSBDeviceCollectionViewRepresentation.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 3/19/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBUSBDevice.h"

@interface SBUSBDeviceCollectionViewRepresentation : NSObject

@property (strong) NSString *name;
@property (strong) SBUSBDevice *usbDevice;
@property (strong) NSImage *image;

@end
