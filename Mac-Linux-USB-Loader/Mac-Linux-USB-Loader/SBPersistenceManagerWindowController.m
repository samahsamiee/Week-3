//
//  SBPersistenceManagerWindowController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/22/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBPersistenceManagerWindowController.h"
#import "SBAppDelegate.h"
#import "SBUSBDevice.h"

@interface SBPersistenceManagerWindowController ()

@property (assign) IBOutlet NSArrayController *popupValues;
@property (weak) IBOutlet NSComboBox *usbSelectorPopup;

@property (weak) IBOutlet NSBox *persistenceOptionsSetupBox;
@property (weak) IBOutlet NSSlider *persistenceVolumeSizeSlider;
@property (weak) IBOutlet NSTextField *persistenceVolumeSizeTextField;
@property (weak) IBOutlet NSProgressIndicator *spinner;
@property (weak) IBOutlet NSTextField *operationProgressLabel;
@property (weak) IBOutlet NSButton *resetSliderButton;
@property (weak) IBOutlet NSButton *refreshButton;

@property (assign) BOOL usbIsSelected;

@property id activity;

@end

@implementation SBPersistenceManagerWindowController {
	NSMutableDictionary *dict;
	NSSavePanel *spanel;
}

- (instancetype)initWithWindow:(NSWindow *)window {
	self = [super initWithWindow:window];
	if (self) {
		// Initialization code here.
	}
	return self;
}

- (void)awakeFromNib {
	[super windowDidLoad];

	// Hide the setup view until we need it.
	[self.persistenceOptionsSetupBox setHidden:YES];
	(self.operationProgressLabel).stringValue = @"";

	// Setup the USB selector.
	[self loadUSBDeviceList:nil];

	// Set up the USB persistence file size selector.
	[self.persistenceVolumeSizeSlider setContinuous:YES];
	(self.persistenceVolumeSizeTextField).integerValue = 512000000; // 512 MB
}

- (void)showWindow:(id)sender {
	[super showWindow:sender];
	[self loadUSBDeviceList:nil];
}

- (IBAction)loadUSBDeviceList:(id)sender {
	// Get the USBs from the App Delegate
	[(SBAppDelegate *)NSApp.delegate detectAndSetupUSBs];
	dict = ((SBAppDelegate *)NSApp.delegate).usbDictionary;

	// Clear the USB selector dropdown.
	[self.usbSelectorPopup removeAllItems];
	[self.popupValues removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [(self.popupValues).arrangedObjects count])]];

	// Create new USB dictionary
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:dict.count];

	for (NSString *usb in dict) {
		if ([usb containsSubstring:@" "]) continue;
		[array insertObject:[dict[usb] name] atIndex:0];
	}

	// Add USBs to popup
	[self.popupValues addObjects:array];

	[self.usbSelectorPopup addItemWithObjectValue:@"---"];
	[self.usbSelectorPopup selectItemAtIndex:0];
	[self.usbSelectorPopup addItemsWithObjectValues:array];
	[self.usbSelectorPopup setDelegate:self];
}

- (IBAction)persistenceSizeSliderWasDragged:(id)sender {
	(self.persistenceVolumeSizeTextField).integerValue = (self.persistenceVolumeSizeSlider).integerValue;
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification {
	// This will update the UI via Cocoa bindings.
	self.usbIsSelected = (self.usbSelectorPopup).indexOfSelectedItem != 0;
}

- (IBAction)createPersistenceButtonPressed:(id)sender {
	// Disable all buttons.
	[sender setEnabled:NO];
	[self.resetSliderButton setEnabled:NO];
	[self.persistenceVolumeSizeSlider setEnabled:NO];
	[self.persistenceVolumeSizeTextField setEnabled:NO];
	[self.usbSelectorPopup setEnabled:NO];
	[self.refreshButton setEnabled:NO];

	NSInteger persistenceSizeInBytes = (self.persistenceVolumeSizeSlider).integerValue / 1048576;

	NSString *selectedUSB = (self.usbSelectorPopup).objectValueOfSelectedItem;
	spanel = [NSSavePanel savePanel];
	spanel.directoryURL = [NSURL URLWithString:[dict[selectedUSB] path]];
	spanel.nameFieldStringValue = @"casper-rw";
	[spanel setCanCreateDirectories:NO];
	[spanel setCanSelectHiddenExtension:NO];
	[spanel setTreatsFilePackagesAsDirectories:NO];
	[spanel beginSheetModalForWindow:self.window completionHandler: ^(NSInteger result) {
	    if (result == NSFileHandlingPanelOKButton) {
	        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				// Tell the system that we are beginning an activity.
				if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
					if (!self.activity) {
						self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityUserInitiated reason:@"Setup Persistence"];
					}
				}

	            [self.spinner startAnimation:nil];
	            [self.operationProgressLabel setStringValue:NSLocalizedString(@"Creating persistence file...", nil)];
	            [SBUSBDevice createPersistenceFileAtUSB:spanel.URL.path withSize:persistenceSizeInBytes withWindow:self.window];
	            [self.operationProgressLabel setStringValue:NSLocalizedString(@"Creating virtual loopback filesystem...", nil)];
	            [SBUSBDevice createLoopbackPersistence:spanel.URL.path];

	            // Enable everything that was disabled.
	            dispatch_async(dispatch_get_main_queue(), ^{
	                [sender setEnabled:YES];
					[self.resetSliderButton setEnabled:YES];
	                [self.persistenceVolumeSizeSlider setEnabled:YES];
	                [self.persistenceVolumeSizeTextField setEnabled:YES];
	                [self.usbSelectorPopup setEnabled:YES];
					[self.refreshButton setEnabled:YES];

	                NSAlert *alert = [[NSAlert alloc] init];
	                [alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
	                [alert setMessageText:NSLocalizedString(@"Done creating persistence.", nil)];
	                [alert setInformativeText:NSLocalizedString(@"The persistence file has been created. You should be able to boot your selected Linux distribution with persistence on this USB drive now.", nil)];
	                alert.alertStyle = NSWarningAlertStyle;
	                [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(regularSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

	                [self.spinner stopAnimation:nil];
	                (self.operationProgressLabel).stringValue = @"";

					// Tell the system that we have finished the activity.
					if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
						[[NSProcessInfo processInfo] endActivity:self.activity];
					}
				});
			});
		} else {
	        [sender setEnabled:YES];
			[self.resetSliderButton setEnabled:YES];
	        [self.persistenceVolumeSizeSlider setEnabled:YES];
	        [self.persistenceVolumeSizeTextField setEnabled:YES];
	        [self.usbSelectorPopup setEnabled:YES];
			[self.refreshButton setEnabled:YES];
		}
	}];
}

- (IBAction)resetSliderButtonPressed:(id)sender {
	(self.persistenceVolumeSizeSlider).integerValue = (512 * 1048576);
	(self.persistenceVolumeSizeTextField).stringValue = @"512 MB";
}

- (void)regularSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	// Empty
}

@end
