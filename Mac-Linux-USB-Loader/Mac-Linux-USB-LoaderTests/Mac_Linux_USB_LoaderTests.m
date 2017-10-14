//
//  Mac_Linux_USB_LoaderTests.m
//  Mac-Linux-USB-LoaderTests
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "SBEnterpriseConfigurationWriter.h"
#import "SBUSBDevice.h"

@interface Mac_Linux_USB_LoaderTests : XCTestCase

@end

@implementation Mac_Linux_USB_LoaderTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCreateKaliConfigurationFile {
	//XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
	SBUSBDevice *device = [[SBUSBDevice alloc] init];
	device.path = NSTemporaryDirectory();
	NSString *directory = [device.path stringByAppendingPathComponent:@"/efi/boot/"];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];

	NSString *fileName = [directory stringByAppendingPathComponent:@"enterprise.cfg"];
	NSLog(@"Writing to: %@", device.path);

	[SBEnterpriseConfigurationWriter writeConfigurationFileAtUSB:device distributionFamily:SBDistributionKali isMacUbuntu:NO containsLegacyUbuntuVersion:NO shouldSkipBootMenu:NO];
	if (![[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:NULL]) {
		XCTFail(@"File doesn't exist.");
	} else if (![[NSWorkspace sharedWorkspace] openFile:fileName withApplication:@"TextEdit"]) {
		XCTFail(@"Quarantine bit is set");
	}
}

- (void)testCreateUbuntuConfigurationFile {
	//XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
	SBUSBDevice *device = [[SBUSBDevice alloc] init];
	device.path = NSTemporaryDirectory();
	NSString *directory = [device.path stringByAppendingPathComponent:@"/efi/boot/"];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];

	NSString *fileName = [directory stringByAppendingPathComponent:@"enterprise.cfg"];
	NSLog(@"Writing to: %@", device.path);

	[SBEnterpriseConfigurationWriter writeConfigurationFileAtUSB:device distributionFamily:SBDistributionUbuntu isMacUbuntu:NO containsLegacyUbuntuVersion:NO shouldSkipBootMenu:NO];
	if (![[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:NULL]) {
		XCTFail(@"File doesn't exist.");
	} else if (![[NSWorkspace sharedWorkspace] openFile:fileName withApplication:@"TextEdit"]) {
		XCTFail(@"Quarantine bit is set");
	}
}

- (void)testCreateTailsConfigurationFile {
	//XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
	SBUSBDevice *device = [[SBUSBDevice alloc] init];
	device.path = NSTemporaryDirectory();
	NSString *directory = [device.path stringByAppendingPathComponent:@"/efi/boot/"];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];

	NSString *fileName = [directory stringByAppendingPathComponent:@"enterprise.cfg"];
	NSLog(@"Writing to: %@", device.path);

	[SBEnterpriseConfigurationWriter writeConfigurationFileAtUSB:device distributionFamily:SBDistributionTails isMacUbuntu:NO containsLegacyUbuntuVersion:NO shouldSkipBootMenu:NO];
	if (![[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:NULL]) {
		XCTFail(@"File doesn't exist.");
	} else if (![[NSWorkspace sharedWorkspace] openFile:fileName withApplication:@"TextEdit"]) {
		XCTFail(@"Quarantine bit is set");
	}
}

- (void)testCreateGenericConfigurationFile {
	//XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
	SBUSBDevice *device = [[SBUSBDevice alloc] init];
	device.path = NSTemporaryDirectory();
	NSString *directory = [device.path stringByAppendingPathComponent:@"/efi/boot/"];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];

	NSString *fileName = [directory stringByAppendingPathComponent:@"enterprise.cfg"];
	NSLog(@"Writing to: %@", device.path);

	[SBEnterpriseConfigurationWriter writeConfigurationFileAtUSB:device distributionFamily:SBDistributionUnknown isMacUbuntu:NO containsLegacyUbuntuVersion:NO shouldSkipBootMenu:NO];
	if (![[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:NULL]) {
		XCTFail(@"File doesn't exist.");
	} else if (![[NSWorkspace sharedWorkspace] openFile:fileName withApplication:@"TextEdit"]) {
		XCTFail(@"Quarantine bit is set");
	}
}

@end
