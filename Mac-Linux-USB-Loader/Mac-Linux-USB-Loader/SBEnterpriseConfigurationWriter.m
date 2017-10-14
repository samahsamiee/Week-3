//
//  SBEnterpriseConfigurationWriter.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 10/24/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBEnterpriseConfigurationWriter.h"
#import "SBAppDelegate.h"
#import <sys/xattr.h>

@implementation SBEnterpriseConfigurationWriter

/// This is a private method.
+ (BOOL)toggleVisibilityForFile:(NSString *)filename isDirectory:(BOOL)isDirectory
{
	// Convert the pathname to HFS+
	FSRef fsRef;
	CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filename, kCFURLPOSIXPathStyle, isDirectory);

	if (!url)
	{
		NSLog(@"Error creating CFURL for %@.", filename);
		return NO;
	}

	if (!CFURLGetFSRef(url, &fsRef))
	{
		NSLog(@"Error creating FSRef for %@.", filename);
		CFRelease(url);
		return NO;
	}

	CFRelease(url);

	// Get the file's catalog info
	FSCatalogInfo *catalogInfo = (FSCatalogInfo *)malloc(sizeof(FSCatalogInfo));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	OSErr err = FSGetCatalogInfo(&fsRef, kFSCatInfoFinderInfo, catalogInfo, NULL, NULL, NULL);
#pragma clang diagnostic pop

	if (err != noErr)
	{
		NSLog(@"Error getting catalog info for %@. The error returned was: %d", filename, err);
		free(catalogInfo);
		return NO;
	}

	// Extract the Finder info from the FSRef's catalog info
	FInfo *info = (FInfo *)(&catalogInfo->finderInfo[0]);

	// Toggle the invisibility flag
	if (info->fdFlags & kIsInvisible)
		info->fdFlags &= ~kIsInvisible;
	else
		info->fdFlags |= kIsInvisible;

	// Update the file's visibility
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	err = FSSetCatalogInfo(&fsRef, kFSCatInfoFinderInfo, catalogInfo);
#pragma clang diagnostic pop

	if (err != noErr)
	{
		NSLog(@"Error setting visibility bit for %@. The error returned was: %d", filename, err);
		free(catalogInfo);
		return NO;
	}

	free(catalogInfo);
	return YES;
}

+ (void)writeConfigurationFileAtUSB:(SBUSBDevice *)device distributionFamily:(SBLinuxDistribution)family isMacUbuntu:(BOOL)isMacUbuntu containsLegacyUbuntuVersion:(BOOL)containsLegacyUbuntu shouldSkipBootMenu:(BOOL)shouldSkip {
	NSError *error;
	NSString *distributionId = [SBAppDelegate distributionStringForEquivalentEnum:family];

	NSString *path = [device.path stringByAppendingPathComponent:@"/efi/boot/enterprise.cfg"];
	NSMutableString *string = [NSMutableString stringWithCapacity:30];

	if (family != SBDistributionUnknown) {
		[string appendString:@"#This file is machine generated. Do not modify it unless you know what you are doing.\n\n"];
		if (shouldSkip) [string appendString:@"autoboot 0\n"];
		[string appendFormat:@"entry %@\n", distributionId];
		[string appendFormat:@"family %@\n", ([distributionId isEqualToString:@"Kali"] || [distributionId isEqualToString:@"Tails"]) ? @"Debian" : distributionId];

		if (family == SBDistributionUbuntu) {
			NSMutableString *kernelString = [NSMutableString stringWithString:@"kernel "];

			// I know that this seems a bit redundant, checking for legacy Ubuntu twice, but we have to because if we don't,
			// it would be impossible to have both options be enabled.
			if (isMacUbuntu) {
				[kernelString appendString:@"/casper/vmlinuz "];
				if (containsLegacyUbuntu) {
					[kernelString appendString:@"file=/cdrom/preseed/ubuntu.seed"];
				}
			} else if (containsLegacyUbuntu) {
				[kernelString appendString:@"/casper/vmlinuz.efi file=/cdrom/preseed/ubuntu.seed"];
			} else {
				[kernelString appendString:@"/casper/vmlinuz.efi "];
			}

			[kernelString appendString:@"\n"];
			[string appendString:kernelString];
		} else if (family == SBDistributionKali) {
			[string appendString:@"kernel /live/vmlinuz findiso=/efi/boot/boot.iso boot=live noconfig=sudo username=root hostname=kali\n"];
			[string appendString:@"\nentry Kali (installer)\n"];
			[string appendString:@"family Debian\ninitrd /install/gtk/initrd.gz\nkernel /install/gtk/vmlinuz findiso=/efi/boot/boot.iso boot=live noconfig=sudo username=root hostname=kali"];
		} else if (family == SBDistributionTails) {
			[string appendString:@"kernel /live/vmlinuz findiso=/efi/boot/boot.iso boot=live config live-media=removable noprompt timezone=Etc/UTC block.events_dfl_poll_msecs=1000 nox11autologin module=Tails quiet splash\n"];
		} else if (family == SBDistributionDebian) {
			[string appendString:@"kernel /live/vmlinuz findiso=/efi/boot/boot.iso boot=live config live-config quiet splash"];
		}
	} else {
		// The user has selected the "Other" option in the distribution family.
		// Put text into the configuration file telling the user how to use it.
		[string appendString:@"# enterprise.cfg\n"];
		[string appendString:@"#\n"];
		[string appendString:@"# This file is used to configure Enterprise. You need to fill out the following parameters "];
		[string appendString:@"according to how your desired Linux distribution configures its ISO file.\n\n"];
		[string appendString:@"entry Custom Linux\n"];
		[string appendString:@"kernel /path/to/kernel ...\n"];
		[string appendString:@"initrd /path/to/initrd\n"];
		[string appendString:@"# Please see https://sevenbits.github.io/Enterprise/ for more information.\n"];
	}

	// Delete the old configuration file; otherwise we can't write a new one.
	if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
		NSLog(@"Error removing old configuration file: %@", error);
	}

	// Write the new configuration file.
	BOOL success = [string writeToFile:path atomically:NO encoding:NSASCIIStringEncoding error:&error];
	if (!success) {
		NSLog(@"Error writing configuration file: %@", error);
	}

	// Hide the configuration file if the user has indicated that they desire this behavior.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:@"HideConfigurationFile"]) {
		BOOL result = [self toggleVisibilityForFile:path isDirectory:NO];
		if (result != 0) {
			NSLog(@"Failed to hide configuration file.");
		}
	}
}

@end
