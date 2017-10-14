//
//  SBGlobals.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/28/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#ifndef Mac_Linux_USB_Loader_SBGlobals_h
#define Mac_Linux_USB_Loader_SBGlobals_h

#define SBLogObject(x) NSLog(@"%@", x)
#define SBLogBool(x) NSLog(x ? @"YES" : @"NO")
#define SBLogInteger(x) NSLog(@"%ld", x)
#define SBBool2NSString(x) (x ? @"YES" : @"NO")
#define SBCStr2NSString(x) [NSString initWithCString:x encoding:NSUTF8StringEncoding]
#define SBNSString2CStr(x) [x UTF8String]

/// The version number of the Enterprise installation that ships with this copy of Mac
/// Linux USB Loader.
extern NSString *SBBundledEnterpriseVersionNumber;

/// An enumeration containing various supported Linux distributions.
typedef NS_ENUM (NSInteger, SBLinuxDistribution) {
	/// An enum type representing the Ubuntu Linux distribution.
	SBDistributionUbuntu = 0,
	/// An enum type representing the Debian Linux distribution.
	SBDistributionDebian,
	/// An enum type representing the Tails Linux distribution.
	SBDistributionTails,
	/// An enum type representing the Kali Linux distribution.
	SBDistributionKali,
	/// An enum type representing an unsupported Linux distribution.
	SBDistributionUnknown
};

#endif
