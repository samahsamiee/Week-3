//
//  SBUSBDevice.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/18/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <copyfile.h>
#import "SBUSBDevice.h"
#import "NSString+Extensions.h"

typedef NS_ENUM(unsigned int, State) {
	NotStarted = 0,
	InProgress,
	Finished,
};

@implementation SBUSBDevice {
	copyfile_state_t copyfileState;
	State state;
	NSTimer *progressTimer;

	SBDocument *attachedDocument;
	BOOL USBIsInUse;
}

#pragma mark - Class methods
+ (void)createPersistenceFileAtUSB:(NSString *)file withSize:(NSUInteger)size withWindow:(NSWindow *)window __attribute__((pure)) {
	// Initalize the NSTask.
	NSTask *task = [[NSTask alloc] init];
	task.launchPath = @"/bin/dd";
	task.arguments = @[@"if=/dev/zero", [@"of=" stringByAppendingString:file], @"bs=1m",
	                   [NSString stringWithFormat:@"count=%ld", (long)size]];
#ifdef DEBUG
	NSLog(@"command: %@ %@", task.launchPath, [task.arguments componentsJoinedByString:@" "]);
#endif

	// Launch the NSTask.
	[task launch];
	[task waitUntilExit];

	// Create the loopback file.
#ifdef DEBUG
	NSLog(@"Done USB persistence creation!");
#endif
}

+ (void)createLoopbackPersistence:(NSString *)file __attribute__((pure)) {
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *helperAppPath = [mainBundle.bundlePath
	                           stringByAppendingString:@"/Contents/Resources/Tools/mke2fs"];

	NSTask *task = [[NSTask alloc] init];
	task.launchPath = helperAppPath;
	task.arguments = @[@"-qF", @"-t", @"ext4", file];
	[task launch];
	[task waitUntilExit];
}

#pragma mark - Instance methods
- (instancetype)init {
	self = [super init];
	if (self) {
		// Add your subclass-specific initialization here.
	}
	return self;
}

- (BOOL)copyInstallationFiles:(SBDocument *)document {
	// Create an operation for the operation queue to copy over the necessary files.
	attachedDocument = document;
	USBIsInUse = YES;
	NSString *finalISOCopyPath = [NSString stringWithFormat:@"/Volumes/%@/efi/boot/boot.iso",
	                              self.name];

	dispatch_async(dispatch_get_main_queue(), ^{
	    progressTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(outputProgress:) userInfo:@{} repeats:YES];
	});

	const char *fromPath = (document.fileURL.path).UTF8String;
	const char *toPath = finalISOCopyPath.UTF8String;

	NSLog(@"from: %s to: %s", fromPath, toPath);

	NSLog(@"Will start copying");

	int returnCode;
	copyfileState = copyfile_state_alloc();
	{
		state = InProgress;

		returnCode = copyfile(fromPath, toPath, copyfileState, COPYFILE_ALL);

		if (returnCode == 0) {
			state = Finished;
			[progressTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
			progressTimer = nil;
		} else {
			NSLog(@"Did finish copying with return code %d", returnCode);
		}
	}
	copyfile_state_free(copyfileState);

	NSLog(@"Did finish copying with return code %d", returnCode);

	return YES;
}

- (BOOL)copyEnterpriseFiles:(SBDocument *)document withEnterpriseSource:(SBEnterpriseSourceLocation *)source {
	// Create an operation for the operation queue to copy over the necessary files.
	attachedDocument = document;
	USBIsInUse = YES;
	NSString *finalEnterpriseCopyPath = [NSString stringWithFormat:@"/Volumes/%@/efi/boot/bootX64.efi",
	                              self.name];
	NSString *finalGRUBCopyPath = [NSString stringWithFormat:@"/Volumes/%@/efi/boot/boot.efi",
										 self.name];

	dispatch_async(dispatch_get_main_queue(), ^{
	    progressTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(outputProgress:) userInfo:@{} repeats:YES];
	});

	// First, copy Enterprise.
	const char *fromPath = [source.path stringByAppendingPathComponent:@"bootX64.efi"].UTF8String;
	const char *toPath = finalEnterpriseCopyPath.UTF8String;

	NSLog(@"from: %s to: %s", fromPath, toPath);

	NSLog(@"Will start copying");

	int returnCode;
	copyfileState = copyfile_state_alloc();
	{
		state = InProgress;

		returnCode = copyfile(fromPath, toPath, copyfileState, COPYFILE_ALL);

		if (returnCode == 0) {
			state = Finished;
			[progressTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
			progressTimer = nil;
		} else {
			NSLog(@"Did finish copying with return code %d", returnCode);
		}
	}
	copyfile_state_free(copyfileState);

	// Next, copy GRUB.
	fromPath = [source.path stringByAppendingPathComponent:@"boot.efi"].UTF8String;
	toPath = finalGRUBCopyPath.UTF8String;

	NSLog(@"from: %s to: %s", fromPath, toPath);

	NSLog(@"Will start copying");

	copyfileState = copyfile_state_alloc();
	{
		state = InProgress;

		returnCode = copyfile(fromPath, toPath, copyfileState, COPYFILE_ALL);

		state = Finished;
		[progressTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
		progressTimer = nil;
	}
	copyfile_state_free(copyfileState);

	NSLog(@"Did finish copying with return code %d", returnCode);

	return YES;
}

- (void)outputProgress:(NSTimer *)timer {
	switch (state) {
		case NotStarted:
			NSLog(@"Not started yet");
			break;

		case Finished:
			NSLog(@"Finished");
			break;

		case InProgress: {
			off_t copiedBytes;
			const int returnCode = copyfile_state_get(copyfileState, COPYFILE_STATE_COPIED, &copiedBytes);
			if (returnCode == 0) {
				//NSLog(@"Copied %@ so far", [NSByteCountFormatter stringFromByteCount:copiedBytes countStyle:NSByteCountFormatterCountStyleFile]);
				(attachedDocument.installationProgressBar).doubleValue = copiedBytes;
			}
			else {
				NSLog(@"Could not retrieve copyfile state");
			}

			break;
		}
	}
}

- (BOOL)enableStartupDiskSupport {
	// Create the paths to the necessary files and folders
	NSString *finalPath = [self.path stringByAppendingPathComponent:@"/System/Library/CoreServices/"];
	NSString *plistFilePath = [[NSBundle mainBundle] pathForResource:@"SystemVersion" ofType:@"plist"];
	NSError *err;
	NSFileManager *fm = [NSFileManager defaultManager];

	// Create dummy files to fool OS X
	[fm createDirectoryAtPath:finalPath withIntermediateDirectories:YES attributes:nil error:nil];
	[fm copyItemAtPath:plistFilePath toPath:[finalPath stringByAppendingPathComponent:@"SystemVersion.plist"] error:&err];
	[@"Dummy EFI boot loader to fool OS X" writeToFile:[finalPath stringByAppendingPathComponent:@"boot.efi"] atomically:YES encoding:NSASCIIStringEncoding error:&err];
	[@"Dummy kernel to fool OS X" writeToFile:[self.path stringByAppendingPathComponent:@"mach_kernel"] atomically:YES encoding:NSASCIIStringEncoding error:&err];

	// Add an app icon
	NSString *diskIconPath = [[NSBundle mainBundle] pathForResource:@"mlul-disk" ofType:@"icns"];
	[fm copyItemAtPath:diskIconPath toPath:[self.path stringByAppendingPathComponent:@".VolumeIcon.icns"] error:&err];
	//[NSTask launchedTaskWithLaunchPath:@"/usr/bin/SetFile" arguments:@[@"-a", @"C", self.path]];

	return YES;
}

- (BOOL)openConfigurationFileWithError:(NSError **)error {
	NSString *path = [self.path stringByAppendingPathComponent:@"/efi/boot/enterprise.cfg"];
	NSString *deprecatedPath = [self.path stringByAppendingPathComponent:@"/efi/boot/.MLUL-Live-USB"];
	NSURL *outURL = [[NSFileManager defaultManager] setupSecurityScopedBookmarkForUSBAtPath:self.path withWindowForSheet:nil];
	[outURL startAccessingSecurityScopedResource];
	NSFileManager *fm = [NSFileManager defaultManager];

	BOOL success = NO;

	// If the file doesn't exist, print out an error and exit.
	if (![fm fileExistsAtPath:path] && ![fm fileExistsAtPath:deprecatedPath]) {
		if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:nil];
		return NO;
	}

	// Try to open the configuration file in TextEdit.
	if (![[NSWorkspace sharedWorkspace] openFile:path withApplication:@"TextEdit"]) {
		success = [[NSWorkspace sharedWorkspace] openFile:deprecatedPath withApplication:@"TextEdit"];

		if (!success) NSLog(@"Couldn't open configuration file.");
	}
	[outURL stopAccessingSecurityScopedResource];

	if (!success && error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:EACCES userInfo:nil];
	return success;
}

@end
