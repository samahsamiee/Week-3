//
//  NSFileManager+Extensions.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 2/1/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "NSFileManager+Extensions.h"
#import "SBAppDelegate.h"

@implementation NSFileManager (Extensions)

NSOpenPanel *spanel;

- (NSNumber *)sizeOfFileAtPath:(NSString *)path {
	NSNumber *mySize = @([[self attributesOfItemAtPath:path error:nil] fileSize]);
	return mySize;
}

- (NSInteger)freeSpaceRemainingOnDrive:(NSString *)path error:(NSError **)userError {
	NSError *error = nil;
	NSDictionary *attr = [self attributesOfFileSystemForPath:path error:&error];
	double bytesFree = [attr[NSFileSystemFreeSize] longValue];

	if (error) {
		*userError = error;
	}

	return bytesFree;
}

- (NSURL *)setupSecurityScopedBookmarkForUSBAtPath:(NSString *)path withWindowForSheet:(NSWindow *)window {
	// Setup variables.
	NSString *targetUSBName = path.lastPathComponent.stringByDeletingPathExtension;
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSURL *outURL;

	// If we don't have a security scoped bookmark for the target USB, then create one.
	if (![prefs objectForKey:[targetUSBName stringByAppendingString:@"_USBSecurityBookmarkTarget"]]) {
	showFileDialog:
		NSLog(@"Don't have access to USB %@, showing file dialog.", targetUSBName);

		spanel = [NSOpenPanel openPanel];
		[spanel setMessage:NSLocalizedString(@"To authorize Mac Linux USB Loader to access your USB drive, please click Grant Access below.", nil)];
		[spanel setPrompt:NSLocalizedString(@"Grant Access", nil)];
		spanel.directoryURL = [NSURL URLWithString:path];
		spanel.nameFieldStringValue = @"";
		[spanel setCanChooseDirectories:YES];
		[spanel setCanChooseFiles:NO];
		[spanel setCanSelectHiddenExtension:NO];
		[spanel setTreatsFilePackagesAsDirectories:NO];
		NSInteger result = [spanel runModal];

		// Create a security scoped bookmark here so we don't ask the user again.
		if (result == NSFileHandlingPanelOKButton) {
			NSURL *url = spanel.URL;
			if ([url.path isEqualToString:path]) {
				NSData *data = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
				if (data) {
					[prefs setObject:data forKey:[targetUSBName stringByAppendingString:@"_USBSecurityBookmarkTarget"]];
					[prefs synchronize];
				}
			} else {
				goto showFileDialog;
			}
		} else {
			return nil;
		}

		// Inform the App Delegate about this new device.
		[(SBAppDelegate *)NSApp.delegate scanForSavedUSBs];
	}

	// Return an NSURL object corresponding to the bookmark.
	outURL = [NSURL URLByResolvingBookmarkData:[[NSUserDefaults standardUserDefaults]
	                                            objectForKey:[targetUSBName stringByAppendingString:@"_USBSecurityBookmarkTarget"]]
	                                   options:NSURLBookmarkResolutionWithSecurityScope
	                             relativeToURL:nil
	                       bookmarkDataIsStale:nil
	                                     error:nil];

	return outURL;
}

- (NSURL *)createSecurityScopedBookmarkForPath:(NSURL *)url {
	NSData *data = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
	if (data) {
		NSURL *returnURL = [NSURL URLByResolvingBookmarkData:data
		                                             options:NSURLBookmarkResolutionWithSecurityScope
		                                       relativeToURL:nil
		                                 bookmarkDataIsStale:nil
		                                               error:nil];
		return returnURL;
	} else {
		return nil;
	}
}

@end
