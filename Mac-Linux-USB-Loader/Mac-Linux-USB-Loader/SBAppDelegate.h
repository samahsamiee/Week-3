//
//  SBAppDelegate.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RHPreferences/RHPreferences.h>
#import <DiskArbitration/DiskArbitration.h>
#import "SBUSBSetupWindowController.h"
#import "SBPersistenceManagerWindowController.h"
#import "SBUSBDevice.h"
#import "SBAboutWindowController.h"
#import "SBDistributionDownloaderWindowController.h"

/// An enumeration containing the various operations the user can do from the menu screen.
typedef NS_ENUM (NSInteger, SBWelcomeScreenOperation) {
	/// Show a file chooser to create a new live USB.
	SBWelcomeScreenOperationCreateUSB = 0,
	/// Show the USB setup window.
	SBWelcomeScreenOperationSetupUSB,
	/// Show the persistence setup window.
	SBWelcomeScreenOperationSetupPersistence,
	/// Show the distribution downloader.
	SBWelcomeScreenOperationDistributionDownloader
};

@interface SBAppDelegate : NSObject {
	__unsafe_unretained NSWindow *window;

	RHPreferencesWindowController *_preferencesWindowController;

	/// An instance of NSFileManager to be used by this instance.
	NSFileManager *fileManager;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;

/// A dictionary containing the keys of plugged in USB devices with the values of those keys being instances of SBUSBDevice.
@property (nonatomic, strong, readonly) NSMutableDictionary *usbDictionary;
/// A dictionary containing the keys of registered Enterprise source locations with the values of those keys being instances
/// of SBEnterpriseSourceLocation. This dictionary's contents are stored on-disk.
@property (nonatomic, strong, readonly) NSMutableDictionary *enterpriseInstallLocations;
/// The path to the application's application support directory.
@property (nonatomic, strong, readonly) NSString *pathToApplicationSupportDirectory;
/// A dictionary containing a list of supported distributions and their minimum supported versions.
@property (nonatomic, strong, readonly) NSDictionary *supportedDistributionsAndVersions;
/// An array of supported distributions to be used as keys for the supportedDistributionsAndVersions property.
@property (nonatomic, strong, readonly) NSArray *supportedDistributions;

- (BOOL)writeEnterpriseSourceLocationsToDisk:(NSString *)path;
- (void)readEnterpriseSourceLocationsFromDisk:(NSString *)path;

- (void)scanForSavedUSBs;
- (void)detectAndSetupUSBs;

- (void)purgeCachesAndOldFiles;

+ (NSString *)distributionStringForEquivalentEnum:(SBLinuxDistribution)dist;

/**
 * Given a file name corresponding to a Linux distribution ISO, returns an indicator of which distribution
 * was selected. This method disregards the path of the file and operates on the file name only.
 *
 * @param file The path to the file that should be used.
 */
+ (SBLinuxDistribution)distributionTypeForISOName:(NSString *)fileName;

@end
