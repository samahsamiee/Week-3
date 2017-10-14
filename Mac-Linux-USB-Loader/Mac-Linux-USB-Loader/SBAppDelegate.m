//
//  SBAppDelegate.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Sparkle/Sparkle.h>

#import "SBAppDelegate.h"
#import "SBGeneralPreferencesViewController.h"
#import "SBEnterprisePreferencesViewController.h"
#import "SBDistributionDownloaderPreferencesViewController.h"
#import "SBUpdatePreferencesViewController.h"
#import "SBEnterpriseSourceLocation.h"

#define SBClearAllMenuItemTag 552345

const NSString *SBBundledEnterpriseVersionNumber = @"0.4.0";

@interface SBAppDelegate () {
	SBUSBSetupWindowController *usbSetupWindowController;
	SBPersistenceManagerWindowController *persistenceSetupWindowController;
	SBAboutWindowController *aboutWindowController;
	SBDistributionDownloaderWindowController *downloaderWindowController;
	RHPreferencesWindowController *preferencesWindowController;

	__weak IBOutlet SPUStandardUpdaterController *updater;
}
// These need to be here so that we can write to readonly variables within
// this file, but prohibit others from being able to do so.
@property (nonatomic, strong) NSMutableDictionary<NSString *, SBUSBDevice *> *usbDictionary;
@property (nonatomic, strong) NSMutableDictionary<NSString *, SBEnterpriseSourceLocation *> *enterpriseInstallLocations;
@property (nonatomic, strong) NSString *pathToApplicationSupportDirectory;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *supportedDistributionsAndVersions;
@property (nonatomic, strong) NSArray<NSString *> *supportedDistributions;

@property (weak) IBOutlet NSTableView *operationsTableView;
@property (weak) IBOutlet NSTextField *applicationVersionString;
@property (weak) IBOutlet NSMenu *registeredDevicesMenu;

- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)showAboutWindow:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)showProjectWebsite:(id)sender;
- (IBAction)reportBug:(id)sender;
@end

@implementation SBAppDelegate
@synthesize window;

#pragma mark - Object Setup

- (instancetype)init {
	self = [super init];
	if (self) {
		// Setup code goes here.
		self->fileManager = [NSFileManager new];
		self.pathToApplicationSupportDirectory = self->fileManager.applicationSupportDirectory;

		self.supportedDistributions = @[@"Ubuntu", @"Linux Mint", @"Elementary OS", @"Debian", @"Zorin OS", @"Kali Linux"];
		self.supportedDistributionsAndVersions = @{ @"Ubuntu": @"17.04",
		                                            @"Linux Mint": @"18.1",
		                                            @"Elementary OS": @"Freya",
													@"Debian": @"8.7.1",
		                                            @"Zorin OS": @"12",
		                                            @"Kali Linux": @"" };
	}
	return self;
}

#pragma mark - Application Setup

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	/* Set window properties. */
	[self setupWelcomeScreenUI];

	/* Make the table respond to our double click operations. */
	(self.operationsTableView).doubleAction = @selector(userSelectedOperationFromTable);

	/* Set the application version label string. */
	(self.applicationVersionString).stringValue = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Version", nil), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];

	/* Setup the rest of the application. */
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self applicationSetup];
	});
}

- (void)setupWelcomeScreenUI {
	// Make the window background white.
	self.window.backgroundColor = NSColor.whiteColor;
	self.window.movableByWindowBackground = NO;

	// Remove the standard window buttons.
	[[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
	[[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];

	// If we're on Yosemite or higher, make the UI more modern.
	// Otherwise, keep with the current look.
	NSOperatingSystemVersion opVer = [NSProcessInfo processInfo].operatingSystemVersion;
	if (opVer.minorVersion >= 10) {
		self.window.styleMask = self.window.styleMask | NSFullSizeContentViewWindowMask;
		self.window.titleVisibility = NSWindowTitleHidden;
		self.window.titlebarAppearsTransparent = YES;
		self.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
		self.operationsTableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleSourceList;
		self.operationsTableView.usesAlternatingRowBackgroundColors = NO;
		[self.window layoutIfNeeded];
	}
}

- (void)applicationSetup {
	// Register default defaults.
	NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
	[NSUserDefaults.standardUserDefaults registerDefaults:dictionary];

	// Customize the update channel based on the user's settings.
	if ([NSUserDefaults.standardUserDefaults boolForKey:@"UserOnBetaUpdateChannel"]) {
		NSString *feedString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SUBetaFeedURL"];
		NSURL *feedURL = [NSURL URLWithString:feedString];
		updater.updater.feedURL = feedURL;
	}

	// Load the list of Enterprise installation sources.
	[self setupEnterpriseInstallationLocations];

	// Scan for saved USBs.
	[self scanForSavedUSBs];

	// Check if enough time has passed to where we need to clear all caches, but only if the user has indicated
	// that they want this behavior to happen.
	BOOL shouldClearCaches = [NSUserDefaults.standardUserDefaults boolForKey:@"PeriodicallyClearCaches"];
	if (shouldClearCaches) {
		const NSInteger clearCachesUpdateInterval = 5184000; // 60 days (i.e two months) in seconds
		NSDate *lastCheckedDate = [NSUserDefaults.standardUserDefaults objectForKey:@"LastCacheClearCheckTime"];
		if (lastCheckedDate) {
			// We have a previous date.
			NSInteger interval = (NSInteger)fabs(lastCheckedDate.timeIntervalSinceNow);
			if (interval > clearCachesUpdateInterval) {
				// Delete all caches.
				NSLog(@"Clearing all caches and old ISO downloads...");
				[NSThread detachNewThreadSelector:@selector(purgeCachesAndOldFiles) toTarget:self withObject:nil];

				// Save the date now as the starting point for the two-month count to clear caches.
				[NSUserDefaults.standardUserDefaults setObject:[NSDate date] forKey:@"LastCacheClearCheckTime"];
			}
		} else {
			// User has just opened the application or has cleared defaults. Save the date now as the starting
			// point for the two-month count to clear caches.
			[NSUserDefaults.standardUserDefaults setObject:[NSDate date] forKey:@"LastCacheClearCheckTime"];
		}
	}
}

- (void)scanForSavedUSBs {
	NSInteger detectedKeys = 0;
	[self.registeredDevicesMenu removeAllItems];
	NSDictionary *preferences = [NSUserDefaults.standardUserDefaults dictionaryRepresentation];
	NSEnumerator *keys = [preferences keyEnumerator];

	// Add the 'Clear All' menu item and separator.
	NSMenuItem *clearAllMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Clear All", nil) action:@selector(deleteStoredUSBDevice:) keyEquivalent:@""];
	clearAllMenuItem.tag = SBClearAllMenuItemTag;
	[self.registeredDevicesMenu addItem:clearAllMenuItem];
	[self.registeredDevicesMenu addItem:NSMenuItem.separatorItem];

	// Enumerate and find all registered USBs.
	NSString *key;
	while ((key = [keys nextObject])) {
		if ([key hasSuffix:@"_USBSecurityBookmarkTarget"]) {
			// create the menu item with the USB's title.
			// we don't have to worry about getting an NSNotFound here because we already
			// know that the target string exists
			NSRange targetStr = [key rangeOfString:@"_USBSecurityBookmarkTarget"];
			NSString *usbTitle = [key substringToIndex:targetStr.location];
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:usbTitle action:@selector(deleteStoredUSBDevice:) keyEquivalent:@""];
			[self.registeredDevicesMenu addItem:item];
			detectedKeys++;
		}
	}

	// Tell the user if there are no detected devices.
	if (detectedKeys == 0) {
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"No Registered Devices", nil) action:NULL keyEquivalent:@""];
		[self.registeredDevicesMenu addItem:item];
	}
}

- (void)purgeCachesAndOldFiles {
	/* First, purge all caches and unneeded data that we can re-obtain. */
	NSString *path = self->fileManager.cacheDirectory;
	NSFileManager *fm = [[NSFileManager alloc] init];
	NSDirectoryEnumerator *en = [fm enumeratorAtPath:path];
	NSError *err = nil;
	BOOL res;

	// Deal with caches.
	NSString *file;
	NSString *completePath;
	while (file = [en nextObject]) {
		res = [fm removeItemAtPath:[path stringByAppendingPathComponent:file] error:&err];
		if (!res && err) {
			NSLog(@"Couldn't erase cached file at path: %@", err.localizedFailureReason);
		}
	}

	// Tell the distribution downloader to re-download its data, otherwise
	// we'll get some very ugly errors. We do this by setting the date of the
	// last check to the lowest possible value, to ensure that the data will
	// always be re-downloaded.
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:@"LastMirrorUpdateCheckTime"];

	// Deal with ISOs.
	path = self.pathToApplicationSupportDirectory;
	en = [fm enumeratorAtPath:path];
	while (file = [en nextObject]) {
		completePath = [path stringByAppendingPathComponent:file];
		SBLogObject(completePath);

		[fm removeItemAtPath:completePath error:&err];
		if (err) {
			NSLog(@"Couldn't erase cached file at path: %@ (%@)", completePath, err.localizedFailureReason);
		}
	}
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
	[self.window makeKeyAndOrderFront:nil];
	return YES;
}

- (void)setupEnterpriseInstallationLocations {
	NSString *filePath = [self.pathToApplicationSupportDirectory stringByAppendingPathComponent:@"/EnterpriseInstallationLocations.plist"];
	BOOL exists = [self->fileManager fileExistsAtPath:filePath];

	if (!exists) {
		NSLog(@"Couldn't find dictionary of Enterprise source file locations. Is this the first run? Creating one now...");
		self.enterpriseInstallLocations = [[NSMutableDictionary alloc] initWithCapacity:5]; // A rather arbitary number.

		// Add the Enterprise installation located in Mac Linux USB Loader's bundle to the list of available
		// Enterprise installations.
		NSString *defaultPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"/Contents/Resources/Enterprise/"];
		SBEnterpriseSourceLocation *loc = [[SBEnterpriseSourceLocation alloc] initWithName:@"Included With Application"
																				   andPath:defaultPath
		                                                                  shouldBeVolatile:NO];
		self.enterpriseInstallLocations[@"Included With Application"] = loc;

		BOOL success = [self writeEnterpriseSourceLocationsToDisk:filePath];
		if (!success) {
			NSLog(@"Failed to create a file containing the Enterprise source locations. Check the logs for more information.");
		}
	}
	else {
#ifdef DEBUG
		NSLog(@"Found dictionary of Enterprise source file locations.");
#endif
		[self readEnterpriseSourceLocationsFromDisk:filePath];
	}
}

- (BOOL)writeEnterpriseSourceLocationsToDisk:(NSString *)path {
	// Write the file to disk.
	BOOL success = [NSKeyedArchiver archiveRootObject:self.enterpriseInstallLocations toFile:path];
	return success;
}

- (void)readEnterpriseSourceLocationsFromDisk:(NSString *)path {
	@try {
		self.enterpriseInstallLocations = [NSKeyedUnarchiver unarchiveObjectWithFile:path];

		/*
		 * Even though the path to the default Enterprise source is already set when the configuration file is
		 * written to disk, if the user moves the application bundle there is a chance that the path won't
		 * be updated, resulting in errors. So we update it here so that this won't happen.
		 */
		NSString *defaultPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"/Contents/Resources/Enterprise/"];
		SBEnterpriseSourceLocation *source = self.enterpriseInstallLocations[@"Included With Application"];

		if (!source) {
			NSLog(@"The path of the bundled Enterprise source could not have its source path updated. Perhaps there is a problem with the cached Enterprise sources list. This will almost certainly cause problems (if you're a user seeing this message, file a bug)!");
		} else {
			// If the path stored in the Enterprise source is not the one in our app bundle (i.e, the application
			// has been fixed, fix this by setting it to the correct path and writing to disk.
			if (![source.path isEqualToString:defaultPath]) {
				source.path = defaultPath;
				//SBLogObject(source.path);
				[self writeEnterpriseSourceLocationsToDisk:path];
			}
		}
	} @catch (NSException *exception) {
		NSLog(@"Couldn't decode Enterprise source file locations.");
	}
}

- (void)detectAndSetupUSBs {
	if (!self.usbDictionary) {
		self.usbDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
	} else {
		[self.usbDictionary removeAllObjects];
	}

	NSArray *volumes = [self->fileManager mountedVolumeURLsIncludingResourceValuesForKeys:nil options:0];
	BOOL isRemovable, isWritable, isUnmountable;
	NSString *description, *volumeType;

	BOOL acceptHFSDrives = [NSUserDefaults.standardUserDefaults boolForKey:@"AcceptHFSDrives"];
    BOOL acceptHardDrives = [NSUserDefaults.standardUserDefaults boolForKey:@"AcceptHardDrives"];

	for (NSURL *mountURL in volumes) {
		NSString *usbDeviceMountPoint = mountURL.path;
		if ([NSWorkspace.sharedWorkspace getFileSystemInfoForPath:usbDeviceMountPoint isRemovable:&isRemovable isWritable:&isWritable isUnmountable:&isUnmountable description:&description type:&volumeType]) {
			if (isWritable && (acceptHardDrives || (isRemovable && isUnmountable))) {
#ifdef DEBUG
				NSLog(@"Detected eligible volume at %@. Type: %@", usbDeviceMountPoint, volumeType);
#endif

				if ([usbDeviceMountPoint isEqualToString:@"/"]) {
					// Don't include the root partition in the list of external media.
					continue;
				} else {
					if ([volumeType isEqualToString:@"msdos"] ||
					    ([volumeType isEqualToString:@"hfs"] && acceptHFSDrives)) {
						SBUSBDevice *usbDevice = [[SBUSBDevice alloc] init];
						usbDevice.path = usbDeviceMountPoint;
						usbDevice.name = usbDeviceMountPoint.lastPathComponent;
						usbDevice.fileSystem = [volumeType isEqualToString:@"msdos"] ? SBUSBDriveFileSystemFAT32 : SBUSBDriveFileSystemHFS;

						self.usbDictionary[usbDevice.name] = usbDevice;
					}
				}
			} else {
#ifdef DEBUG
				NSLog(@"Volume at %@ is not eligible. Type: %@", usbDeviceMountPoint, volumeType);
#endif
			}
		} else {
#ifdef DEBUG
			NSLog(@"Couldn't get file system info for USB %@", usbDeviceMountPoint.lastPathComponent);
#endif
		}
	}
}

#pragma mark - IBActions

- (IBAction)deleteStoredUSBDevice:(NSMenuItem *)sender {
	if (sender.tag == SBClearAllMenuItemTag) {
		// delete all registered USB devices.
		NSDictionary *preferences = [NSUserDefaults.standardUserDefaults dictionaryRepresentation];
		NSEnumerator *keys = [preferences keyEnumerator];

		NSString *key;
		while ((key = [keys nextObject])) {
			if ([key hasSuffix:@"_USBSecurityBookmarkTarget"]) {
				[NSUserDefaults.standardUserDefaults removeObjectForKey:key];
			}
		}
	} else {
		// get the name of the preferences key to delete based on the USB's name.
		NSString *preferencesKeyToDelete = [sender.title stringByAppendingString:@"_USBSecurityBookmarkTarget"];
		[NSUserDefaults.standardUserDefaults removeObjectForKey:preferencesKeyToDelete];
	}

	// re-build the list of USBs.
	[NSUserDefaults.standardUserDefaults synchronize];
	[self scanForSavedUSBs];
}

- (IBAction)showPreferencesWindow:(id)sender {
	if (!self->preferencesWindowController) {
		BOOL showEnterprisePrefs = [NSUserDefaults.standardUserDefaults boolForKey:@"ShowEnterpriseSourcesPanel"];
		SBGeneralPreferencesViewController *generalPreferences = [[SBGeneralPreferencesViewController alloc] initWithNibName:@"SBGeneralPreferencesViewController" bundle:nil];
		SBEnterprisePreferencesViewController *enterprisePreferences = [[SBEnterprisePreferencesViewController alloc] initWithNibName:@"SBEnterprisePreferencesViewController" bundle:nil];
		SBDistributionDownloaderPreferencesViewController *downloaderPreferences = [[SBDistributionDownloaderPreferencesViewController alloc] initWithNibName:@"SBDistributionDownloaderPreferencesViewController" bundle:nil];
		SBUpdatePreferencesViewController *updaterPreferences = [[SBUpdatePreferencesViewController alloc] initWithNibName:@"SBUpdatePreferencesViewController" bundle:nil];

		NSArray *controllers = nil;
		if (showEnterprisePrefs) {
			controllers = @[generalPreferences, enterprisePreferences, downloaderPreferences, updaterPreferences, [RHPreferencesWindowController flexibleSpacePlaceholderController]];
		} else {
			controllers = @[generalPreferences, downloaderPreferences, updaterPreferences, [RHPreferencesWindowController flexibleSpacePlaceholderController]];
		}
		self->preferencesWindowController = [[RHPreferencesWindowController alloc] initWithViewControllers:controllers andTitle:NSLocalizedString(@"Preferences", nil)];
	}

	[self->preferencesWindowController showWindow:self];
}

- (IBAction)userSelectedToolFromDockMenu:(NSMenuItem *)sender {
	[self loadWindowControllerForTool:sender.tag];
}

- (IBAction)showAboutWindow:(id)sender {
	if (!self->aboutWindowController) {
		self->aboutWindowController = [[SBAboutWindowController alloc] initWithWindowNibName:@"SBAboutWindowController"];
	}

	[self->aboutWindowController showWindow:nil];
}

- (IBAction)showProjectWebsite:(id)sender {
	[NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"https://www.sevenbits.tk/mlul/"]];
}

- (IBAction)showDonatePage:(id)sender {
	[NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"https://www.sevenbits.tk/mlul/support.html"]];
}

- (IBAction)reportBug:(id)sender {
	[NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"https://github.com/SevenBits/Mac-Linux-USB-Loader/issues/new"]];
}

- (IBAction)showHelp:(id)sender {
	[NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"https://github.com/SevenBits/Mac-Linux-USB-Loader/wiki"]];
}

#pragma mark - Table View Delegates

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView __attribute__((const)) {
	return 4;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTableCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	switch (row) {
		case 0:
			result.imageView.image = [NSImage imageNamed:@"AppIcon"];
			result.textField.stringValue = NSLocalizedString(@"Create Live USB", nil);
			break;

		case 1:
			result.imageView.image = [NSImage imageNamed:@"USB"];
			result.textField.stringValue = NSLocalizedString(@"Advanced USB Setup Options", nil);
			break;

		case 2:
			result.imageView.image = [NSImage imageNamed:@"Persistence"];
			result.textField.stringValue = NSLocalizedString(@"Persistence Manager", nil);
			break;

		case 3:
			result.imageView.image = [NSImage imageNamed:@"DistributionDownloader"];
			result.textField.stringValue = NSLocalizedString(@"Distribution Downloader", nil);
			break;

		default:
			break;
	}
	return result;
}

- (void)userSelectedOperationFromTable {
	NSInteger clickedRow = (self.operationsTableView).clickedRow;

	if (clickedRow != -1) { // We've selected a valid table entry.
		[self loadWindowControllerForTool:clickedRow];
	}
}

#pragma mark - Utility Functions

- (void)loadWindowControllerForTool:(SBWelcomeScreenOperation)clickedRow {
	[self.window orderOut:nil];
	switch (clickedRow) {
		case SBWelcomeScreenOperationCreateUSB:
			[NSDocumentController.sharedDocumentController openDocument:nil];
			break;

		case SBWelcomeScreenOperationSetupUSB:
			if (!self->usbSetupWindowController) {
				self->usbSetupWindowController = [[SBUSBSetupWindowController alloc] initWithWindowNibName:@"SBUSBSetupWindowController"];
			}

			[self->usbSetupWindowController showWindow:nil];
			break;

		case SBWelcomeScreenOperationSetupPersistence:
			if (!self->persistenceSetupWindowController) {
				self->persistenceSetupWindowController = [[SBPersistenceManagerWindowController alloc] initWithWindowNibName:@"SBPersistenceManagerWindowController"];
			}

			[self->persistenceSetupWindowController showWindow:nil];
			break;

		case SBWelcomeScreenOperationDistributionDownloader:
			if (!self->downloaderWindowController) {
				self->downloaderWindowController = [[SBDistributionDownloaderWindowController alloc] initWithWindowNibName:@"SBDistributionDownloaderWindowController"];
			}

			[self->downloaderWindowController showWindow:nil];
			break;

		default:
			NSLog(@"Selected table index %ld is not valid.", (long)clickedRow);
			break;
	}
}

+ (NSString *)distributionStringForEquivalentEnum:(SBLinuxDistribution)dist __attribute__((const)) {
	switch (dist) {
		case SBDistributionUbuntu:
			return @"Ubuntu";
			break;
		case SBDistributionDebian:
			return @"Debian";
			break;
		case SBDistributionTails:
			return @"Tails";
			break;
		case SBDistributionKali:
			return @"Kali";
			break;
		case SBDistributionUnknown:
		default:
			return @"Other";
			break;
	}
}

+ (SBLinuxDistribution)distributionTypeForISOName:(NSString *)path __attribute__((pure)) {
	NSString *fileName = path.lowercaseString.lastPathComponent;
	if ([fileName containsSubstring:@"tails"]) {
		return SBDistributionTails;
	} else if ([fileName containsSubstring:@"ubuntu"] ||
			   [fileName containsSubstring:@"mint"] ||
			   [fileName containsSubstring:@"elementary"]) {
		return SBDistributionUbuntu;
	} else if ([fileName containsSubstring:@"kali"]) {
		return SBDistributionKali;
	} else if ([fileName containsSubstring:@"debian"]) {
		return SBDistributionDebian;
	}

	return SBDistributionUnknown;
}

@end
