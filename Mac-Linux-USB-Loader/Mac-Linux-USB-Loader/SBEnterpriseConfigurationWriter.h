//
//  SBEnterpriseConfigurationWriter.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 10/24/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SBUSBDevice.h"

@interface SBEnterpriseConfigurationWriter : NSObject

/**
 * Writes the Enterprise configuration for the given distribution to the specified USB device.
 */
+ (void)writeConfigurationFileAtUSB:(SBUSBDevice *)device distributionFamily:(SBLinuxDistribution)family isMacUbuntu:(BOOL)isMacUbuntu containsLegacyUbuntuVersion:(BOOL)containsLegacyUbuntu shouldSkipBootMenu:(BOOL)shouldSkip;

@end
