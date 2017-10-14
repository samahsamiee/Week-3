//
//  SBDocument.m
//  Mac-Linux-USB-Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBDocument.h"
#import "SBAppDelegate.h"
#import "SBEnterpriseConfigurationWriter.h"
#import "SBEnterpriseSourceLocation.h"
#import "SBUSBDevice.h"
#import "SBUSBDeviceCollectionViewRepresentation.h"

@interface SBDocument ()
// These need to be here so that we can write to readonly variables within
// this file, but prohibit others from being able to do so.
@property (strong) IBOutlet NSView *sideView;
@property (weak) IBOutlet NSTabView *tabView;
@property (weak) IBOutlet NSCollectionView *usbDriveSelector;
@property (weak) IBOutlet NSPopUpButton *enterpriseSourceSelector;
@property (weak) IBOutlet NSPopUpButton *distributionSelectorPopup;
@property (weak) IBOutlet NSButton *isMacVersionCheckBox;
@property (weak) IBOutlet NSButton *isLegacyUbuntuVersionCheckBox;
@property (weak) IBOutlet NSButton *shouldSkipBootMenuCheckbox;
@property (weak) IBOutlet NSButton *forwardButton;
@property (weak) IBOutlet NSButton *backwardsButton;
@end

@implementation SBDocument {
	NSMutableDictionary *usbDictionary;
	NSMutableDictionary *enterpriseSourcesDictionary;

	NSString *originalForwardButtonString;
	NSString *originalBackwardsButtonString;
	BOOL installationOperationStarted;
}

#pragma mark - Document class crap
- (instancetype)init {
	self = [super init];
	if (self) {
		// Add your subclass-specific initialization here.
		self.usbArrayForContentView = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSString *)windowNibName {
	return @"SBDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
	[super windowControllerDidLoadNib:aController];
	[self useVisualEffectViewIfPossible];

	originalForwardButtonString = self.forwardButton.title;
	originalBackwardsButtonString = self.backwardsButton.title;
	self.backwardsButton.enabled = NO;

	// If the user opens the document by dragging the file from the Dock, the main screen will still be open.
	// We hide it here for a better user experience.
	[((SBAppDelegate *)NSApp.delegate).window orderOut:nil];

	[self setupUSBDriveSelector];
	[self detectDistributionFamily];
	[self distributionTypePopupChanged:self.distributionSelectorPopup];

	[self.enterpriseSourceSelector selectItemWithTitle:[[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultEnterpriseSourceLocation"]];
}

- (void)useVisualEffectViewIfPossible {
	if (NSClassFromString(@"NSVisualEffectView") != nil) {
		// Grab everything currently in the window.
		NSView *oldView = self.sideView;
		NSRect frame = oldView.frame;

		// Create and swap the frames.
		self.sideView = [[NSVisualEffectView alloc] initWithFrame:frame];
		[self fillView:oldView withView:self.sideView];
		[self.sideView addSubview:oldView.subviews[0]];
	}
}

- (void)fillView:(NSView *)oldView withView:(NSView*)view {
	view.frame = oldView.bounds;
	[view setTranslatesAutoresizingMaskIntoConstraints:NO];
	
	[oldView addSubview:view];
	[oldView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
	                                            options:0
	                                            metrics:nil
	                                            views:NSDictionaryOfVariableBindings(view)]];

	[oldView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
	                                            options:0
	                                            metrics:nil
	                                            views:NSDictionaryOfVariableBindings(view)]];
}

#pragma mark - USB and distribution detection
- (void)detectDistributionFamily {
	SBLinuxDistribution family = [SBAppDelegate distributionTypeForISOName:self.fileURL.absoluteString.lowercaseString];
	NSString *isoName = self.fileURL.path.lowercaseString.lastPathComponent;
	[self.distributionSelectorPopup selectItemWithTag:family];

	// If this is Linux Mint or a legacy Mac ISO of Ubuntu, check the
	// first check box since we need it so that the correct kernel path will be written.
	if ([isoName containsSubstring:@"linuxmint"] ||
	    [isoName containsSubstring:@"linux mint"] ||
	    [isoName containsSubstring:@"elementary"] || // for Loki, and possibly Freya
	    [isoName containsSubstring:@"+mac"]) {
		(self.isMacVersionCheckBox).state = NSOnState;
	} else {
		(self.isMacVersionCheckBox).state = NSOffState;
	}
}

- (void)setupUSBDriveSelector {
	// Grab the list of USB devices from the App Delegate and setup the USB selector.
	[(SBAppDelegate *)NSApp.delegate detectAndSetupUSBs];
	usbDictionary = [NSMutableDictionary dictionaryWithDictionary:((SBAppDelegate *)NSApp.delegate).usbDictionary];
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:usbDictionary.count];

	for (NSString *usb in usbDictionary) {
		SBUSBDeviceCollectionViewRepresentation *rep = [[SBUSBDeviceCollectionViewRepresentation alloc] init];
		SBUSBDevice *deviceRep = usbDictionary[usb];
		rep.name = deviceRep.name;
		rep.usbDevice = deviceRep;

		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:deviceRep.path];
		icon.size = NSMakeSize(512, 512);
		rep.image = icon;

		[array addObject:rep];
	}

	[arrayController addObjects:array];

	// Grab the Enterprise sources from the App Delegate.
	[array removeAllObjects];
	enterpriseSourcesDictionary = [NSMutableDictionary dictionaryWithDictionary:((SBAppDelegate *)NSApp.delegate).enterpriseInstallLocations];
	for (NSString *usb in enterpriseSourcesDictionary) {
		[array insertObject:[enterpriseSourcesDictionary[usb] name] atIndex:0];
	}

	[self.enterpriseSourceSelector addItemsWithTitles:array];
}

- (IBAction)refreshUSBListing:(id)sender {
	// Refresh the list of USBs.
	[self.usbArrayForContentView removeAllObjects];

	[(SBAppDelegate *)NSApp.delegate detectAndSetupUSBs];
	[self setupUSBDriveSelector];

	// Refresh the list of Enterprise sources.
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:3];
	enterpriseSourcesDictionary = [NSMutableDictionary dictionaryWithDictionary:((SBAppDelegate *)NSApp.delegate).enterpriseInstallLocations];
	for (NSString *usb in enterpriseSourcesDictionary) {
		[array insertObject:[enterpriseSourcesDictionary[usb] name] atIndex:0];
	}

	[self.enterpriseSourceSelector removeAllItems];
	[self.enterpriseSourceSelector addItemsWithTitles:array];
}

#pragma mark - Document Plumbing
+ (BOOL)autosavesInPlace {
	return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	return YES;
}

#pragma mark - Installation Code
- (BOOL)setupInstallationInterface {
	NSIndexSet *indexSet = (self.usbDriveSelector).selectionIndexes;
	SBUSBDeviceCollectionViewRepresentation *selectedCollectionViewRep;
	SBUSBDevice *selectedUSBDrive;

	if (indexSet && indexSet.firstIndex != NSNotFound) {
		selectedCollectionViewRep = self.usbArrayForContentView[indexSet.firstIndex];
		selectedUSBDrive = selectedCollectionViewRep.usbDevice;
	} else {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"No USB drive selected.", nil)];
		[alert setInformativeText:NSLocalizedString(@"You need to select the USB drive to install to.", nil)];
		alert.alertStyle = NSWarningAlertStyle;
		[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

		return NO;
	}

	if (!selectedUSBDrive) {
		NSLog(@"We couldn't get an SBUSBDevice object from the collection view. This could be a bug...");
		return NO;
	}

	// Check to make sure that the user has selected an Enterprise source.
	NSInteger selectedEnterpriseSourceIndex = (self.enterpriseSourceSelector).indexOfSelectedItem;
	NSString *selectedEnterpriseSourceName = (self.enterpriseSourceSelector).titleOfSelectedItem;
	SBEnterpriseSourceLocation *sourceLocation = ((SBAppDelegate *)NSApp.delegate).enterpriseInstallLocations[selectedEnterpriseSourceName];

	if (selectedEnterpriseSourceIndex == -1 || sourceLocation == nil) {
		if ([sourceLocation.name isEqualToString:@""]) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
			[alert setMessageText:NSLocalizedString(@"No Enterprise source file selected.", nil)];
			[alert setInformativeText:NSLocalizedString(@"You need to select the source of the Enterprise binaries that will be copied to this USB drive.", nil)];
			alert.alertStyle = NSWarningAlertStyle;
			[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

			return NO;
		}
	}

	// If all's good, then call the next step.
	return [self verifyInstallationSettings:selectedUSBDrive andEnterpriseSourceLocation:sourceLocation];
}

- (BOOL)verifyInstallationSettings:(SBUSBDevice *)selectedUSBDrive andEnterpriseSourceLocation:(SBEnterpriseSourceLocation *)sourceLocation {
	// Get an NSFileManager object.
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *error = nil;

	// Get the names of files.
	NSString *targetUSBMountPoint = selectedUSBDrive.path;

	// Set the size of the file to be the max value of the progress bar.
	NSString *enterprisePath = [sourceLocation.path stringByAppendingPathComponent:@"bootX64.efi"];
	NSString *grubPath = [sourceLocation.path stringByAppendingPathComponent:@"boot.efi"];
	if (![manager fileExistsAtPath:enterprisePath isDirectory:NULL] || ![manager fileExistsAtPath:grubPath isDirectory:NULL]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"Can't install to this USB device.", nil)];
		[alert setInformativeText:NSLocalizedString(@"The installation failed because the Enterprise source that you have selected is either incomplete or missing.", nil)];
		alert.alertStyle = NSWarningAlertStyle;
		[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

		// Bail.
		return NO;
	}

	double fileSize = [manager sizeOfFileAtPath:self.fileURL.path].doubleValue + [manager sizeOfFileAtPath:grubPath].doubleValue + [manager sizeOfFileAtPath:enterprisePath].doubleValue;
	(self.installationProgressBar).maxValue = fileSize;

	// If the user has a FAT32 filesystem, then we can't have files larger than 4 GB.
	if (selectedUSBDrive.fileSystem == SBUSBDriveFileSystemFAT32 && fileSize > 4 * 1073741824.f) {
		// The selected file is too big for this file system, warn the user then bail.
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"File too big", nil)];
		alert.informativeText = NSLocalizedString(@"The ISO file that you have selected is too big to fit on the selected USB drive. Files on a FAT32 volume cannot be larger than 4 GB.", nil);
		alert.alertStyle = NSWarningAlertStyle;
		[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

		return NO;
	}

	// Verify that the user has enough free space on the selected drive (assume config file is 500 bytes).
	NSInteger selectedDriveFreeSpace = [manager freeSpaceRemainingOnDrive:targetUSBMountPoint error:&error];
	if (selectedDriveFreeSpace < (fileSize + 500)) {
		// The selected drive lacks enough free space, tell the user then bail.
		NSString *formattedByteCount = [NSByteCountFormatter stringFromByteCount:selectedDriveFreeSpace countStyle:NSByteCountFormatterCountStyleFile];

		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"Not enough free space", nil)];
		alert.informativeText = [NSString localizedStringWithFormat:NSLocalizedString(@"The USB drive that you have selected does not have enough free space. At least %@ of space is required.", nil), formattedByteCount];
		alert.alertStyle = NSWarningAlertStyle;
		[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

		return NO;
	}

	return [self beginFileCopy:selectedUSBDrive];
}

- (BOOL)beginFileCopy:(SBUSBDevice *)selectedUSBDrive {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *targetUSBName = selectedUSBDrive.name;
	NSString *targetUSBMountPoint = selectedUSBDrive.path;
	NSString *installDirectory = [targetUSBMountPoint stringByAppendingPathComponent:@"/efi/boot/"];
	NSString *selectedEnterpriseSourceName = (self.enterpriseSourceSelector).titleOfSelectedItem;

	NSError *error = nil;

get_bookmarks:
	;/* STEP 2: Get user permission to install files. We'll only need to do this once. */
	NSURL *outURL = [manager setupSecurityScopedBookmarkForUSBAtPath:targetUSBMountPoint withWindowForSheet:self.windowForSheet];

	if (!outURL) {
		NSString *bookmarkName = [targetUSBName stringByAppendingString:@"_USBSecurityBookmarkTarget"];
		if ([[NSUserDefaults standardUserDefaults] objectForKey:bookmarkName] != nil) {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:bookmarkName];
			goto get_bookmarks;
		} else {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
			[alert setMessageText:NSLocalizedString(@"Couldn't get security scoped bookmarks.", nil)];
			[alert setInformativeText:NSLocalizedString(@"The USB device that you have selected cannot be accessed because the system denied access to the resource.", nil)];
			alert.alertStyle = NSWarningAlertStyle;
			[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

			// Bail.
			return NO;
		}
	} else {
#ifdef DEBUG
		NSLog(@"Obtained security scoped bookmark for USB %@.", targetUSBName);
#endif
	}

	/* STEP 3: Start copying files. */
	[outURL startAccessingSecurityScopedResource];
	installationOperationStarted = YES;

	// Disable GUI elements.
	[self.usbDriveSelector setHidden:YES];
	[self.enterpriseSourceSelector setEnabled:NO];

	// Create the required directories on the USB drive.
	BOOL result = [manager createDirectoryAtPath:installDirectory withIntermediateDirectories:YES attributes:nil error:&error];
	if (!result) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		alert.messageText = error.localizedDescription;
		alert.informativeText = error.localizedFailureReason;
		alert.alertStyle = NSWarningAlertStyle;
		[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

		// Bail.
		return NO;
	}

	// Write out the Enterprise configuration file.
	SBLinuxDistribution distribution = [self.distributionSelectorPopup selectedTag];
	[SBEnterpriseConfigurationWriter writeConfigurationFileAtUSB:selectedUSBDrive distributionFamily:distribution isMacUbuntu:(self.isMacVersionCheckBox).state == NSOnState containsLegacyUbuntuVersion:(self.isLegacyUbuntuVersionCheckBox).state == NSOnState shouldSkipBootMenu:(self.shouldSkipBootMenuCheckbox).state == NSOnState];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		SBEnterpriseSourceLocation *sourceLocation = ((SBAppDelegate *)NSApp.delegate).enterpriseInstallLocations[selectedEnterpriseSourceName];
		[selectedUSBDrive copyEnterpriseFiles:self withEnterpriseSource:sourceLocation];
		[selectedUSBDrive copyInstallationFiles:self];

		dispatch_async(dispatch_get_main_queue(), ^{
			/* STEP 4: Restore access to the disabled buttons. */
			[self setIsDocumentUIEnabled:YES];

			// Stop accessing the security bookmark.
			[outURL stopAccessingSecurityScopedResource];

			// Tell the user.
			[NSApp requestUserAttention:NSInformationalRequest];
			[self.tabView selectTabViewItemAtIndex:2];
			[self.forwardButton setEnabled:NO];

			NSUserNotification *userNotification = [[NSUserNotification alloc] init];
			userNotification.title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Finished Installing: ", nil), (self.fileURL.path).lastPathComponent.stringByDeletingPathExtension];
			userNotification.informativeText = NSLocalizedString(@"You are now ready to use your USB drive!", nil);
			[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];

			// Open the Enterprise configuration file if required.
			if (distribution == SBDistributionUnknown) {
				NSError *error = nil;

				if ([selectedUSBDrive openConfigurationFileWithError:&error]) {
					[NSApp presentError:error];
				}
			}
		});
	});

	return YES;
}

- (void)setIsDocumentUIEnabled:(BOOL)enabled {
	installationOperationStarted = !enabled;
	(self.forwardButton).enabled = enabled;
	(self.installationProgressBar).indeterminate = enabled;
	(self.installationProgressBar).doubleValue = 0.0;
	(self.distributionSelectorPopup).enabled = enabled;
	(self.isMacVersionCheckBox).enabled = enabled;
	(self.isLegacyUbuntuVersionCheckBox).enabled = enabled;
	(self.shouldSkipBootMenuCheckbox).enabled = enabled;
	(self.usbDriveSelector).hidden = !enabled;
	(self.enterpriseSourceSelector).enabled = enabled;
}

- (IBAction)performInstallation:(id)sender {
	// Disable UI components.
	[self setIsDocumentUIEnabled:NO];

	// Kick off the process.
	[self setupInstallationInterface];
}

#pragma mark - Delegates
- (IBAction)paneNavigation:(NSButton *)sender {
	NSInteger currentTab = [self.tabView indexOfTabViewItem:self.tabView.selectedTabViewItem];
	if (currentTab == NSNotFound) return;

	if (sender == self.forwardButton) {
		[self.tabView selectNextTabViewItem:sender];
		self.backwardsButton.enabled = YES;

		if (++currentTab == 1) { // if the user is on the 2nd panel
			self.forwardButton.title = NSLocalizedString(@"Perform Installation", nil);
			self.forwardButton.action = @selector(performInstallation:);

			if (installationOperationStarted) {
				self.forwardButton.enabled = NO;
			}
		}
	} else if (sender == self.backwardsButton) {
		[self.tabView selectPreviousTabViewItem:sender];
		self.forwardButton.enabled = YES;

		if (--currentTab == 0) {
			self.backwardsButton.enabled = NO;

			self.forwardButton.title = originalForwardButtonString;
			self.forwardButton.action = @selector(paneNavigation:);
		}
	}
}

- (IBAction)distributionTypePopupChanged:(NSPopUpButton *)sender {
	BOOL isUbuntuSelected = (sender.selectedTag == SBDistributionUbuntu);
	(self.isMacVersionCheckBox).transparent = (isUbuntuSelected ? NO : YES);
	(self.isMacVersionCheckBox).enabled = isUbuntuSelected;
	(self.isLegacyUbuntuVersionCheckBox).transparent = (isUbuntuSelected ? NO : YES);
	(self.isLegacyUbuntuVersionCheckBox).enabled = isUbuntuSelected;
	(self.shouldSkipBootMenuCheckbox).transparent = (sender.selectedTag == SBDistributionUnknown);
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[self setIsDocumentUIEnabled:YES];
}

@end
