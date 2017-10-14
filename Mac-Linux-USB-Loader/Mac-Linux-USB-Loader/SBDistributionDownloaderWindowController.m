//
//  SBDistributionDownloaderWindowController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 5/9/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "DownloadOperation.h"
#import "SBDistributionDownloaderWindowController.h"
#import "SBAppDelegate.h"
#import "SBDownloadMirrorModel.h"
#import "SBDownloadableDistributionModel.h"
#import "SBDistributionDownloaderDownloadsDataSource.h"
#import "SBDistributionDownloaderTableCellView.h"

#define SBAccessoryViewEdgeOffset 25

@interface SBDistributionDownloaderWindowController ()

// Properties related to the distribution downloader UI
@property (strong) IBOutlet NSView *accessoryView;
@property (weak) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSPanel *downloadSettingsPanel;
@property (weak) IBOutlet NSPopUpButton *distroMirrorCountrySelector;
@property (weak) IBOutlet NSImageView *distroImageView;
@property (weak) IBOutlet NSTextField *distroNameLabel;
@property (weak) IBOutlet NSTextField *distroISOPathLabel;
@property (weak) IBOutlet NSButton *downloadDistroButton;
@property (weak) IBOutlet NSButton *viewInFinderButton;
@property (weak) IBOutlet NSButton *viewMoreInfoButton;
@property (weak) IBOutlet NSButton *accessoryViewButton;
@property (weak) IBOutlet NSProgressIndicator *spinner;

@property (strong) IBOutlet NSPopover *downloadQueuePopover;
@property (strong) IBOutlet SBDistributionDownloaderDownloadsDataSource *downloadQueueDataSource;
@property (weak) IBOutlet NSTableView *downloadQueueTableView;

@property (strong) id activity;
@property (strong) NSUserDefaults *defaults;

@property (weak) IBOutlet WebView *webView;

// Properties related to the distribution download operation
@property (atomic, strong) id jsonRecieved;
@property NSInteger numberOfFinishedJsonRequests;
@property (atomic, strong) SBDownloadableDistributionModel *downloadDistroModel;
@property (atomic, strong) NSMutableDictionary *modelDictionary;
@property (strong) NSLock *mdLock;
@property (atomic, strong) NSMutableDictionary *imageDictionary;
@property (strong) NSLock *idLock;

@end

@implementation SBDistributionDownloaderWindowController

#pragma mark - Object Setup
- (instancetype)initWithWindow:(NSWindow *)window {
	self = [super initWithWindow:window];
	self.modelDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
	self.imageDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
	self.mdLock = [[NSLock alloc] init];
	self.idLock = [[NSLock alloc] init];
	if (self) {
		// Setup our operation queues and get default values.
		self.defaults = [NSUserDefaults standardUserDefaults];
		NSInteger concurrentOperationsCount = [self.defaults integerForKey:@"SimultaneousDownloadOperationsNumber"];

		self.downloadQueue = [[NSOperationQueue alloc] init];
		self.downloadQueue.maxConcurrentOperationCount = concurrentOperationsCount;
	}
	return self;
}

- (void)awakeFromNib {
	// Setup the UI.
	[self.downloadDistroButton setEnabled:NO];
	[self.viewMoreInfoButton setTransparent:YES];
	(self.downloadQueuePopover).behavior = NSPopoverBehaviorTransient;
	(self.downloadQueueDataSource).prefsViewController = self;
	(self.downloadQueueDataSource).tableView = self.downloadQueueTableView;
	(self.tableView).doubleAction = @selector(tableViewDoubleClickAction);
	[self.webView setDrawsBackground:NO];

	self.distroISOPathLabel.stringValue = @"";
	self.viewInFinderButton.enabled = NO;
	self.viewInFinderButton.transparent = YES;
}

- (void)showWindow:(id)sender {
	[super showWindow:sender];

	// Check if enough time has elapsed to where we need to download new JSON.
	NSInteger JSONUpdateInterval = [[NSUserDefaults standardUserDefaults] integerForKey:@"UpdateMirrorListInterval"];
	NSDate *lastCheckedDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastMirrorUpdateCheckTime"];
	if (lastCheckedDate) {
		// We have a saved date.
		NSInteger interval = (NSInteger)fabs(lastCheckedDate.timeIntervalSinceNow);
		if (interval > JSONUpdateInterval) {
			// Enough time has elapsed to where it is now time to update the JSON mirrors.
			// We do this in the background without a lot of pomp so it is transparent to the user.
			NSLog(@"%ld seconds have elapsed, updating JSON.", (long)interval);
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[self downloadJSON];
			});

			[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastMirrorUpdateCheckTime"];
		} else {
			[self loadCachedJSON];
		}
	} else {
		// We are missing the saved date, so re-save it and update the JSON mirrors.
		// We do this in the background without a lot of pomp so it is transparent to the user.
		[self downloadJSON];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastMirrorUpdateCheckTime"];
	}
}

- (void)loadCachedJSON {
	NSString *cacheDirectory = [NSFileManager defaultManager].cacheDirectory;
	__block NSString *tempFileName;

	for (NSString *distroName in((SBAppDelegate *)NSApp.delegate).supportedDistributions) {
		// Grab our JSON, but do it on a background thread so we don't slow down the GUI.
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSError *err;
			tempFileName = [NSString stringWithFormat:@"%@/%@.json", cacheDirectory, [distroName stringByReplacingOccurrencesOfString:@" " withString:@"-"]];
			NSURL *url = [NSURL fileURLWithPath:tempFileName];

			NSString *strCon = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
			if (strCon) {
			    //NSLog(@"Recieved JSON data: %@", strCon);
			    [self processJSON:strCon forDistributionNamed:distroName downloadContent:NO];
			} else {
			    dispatch_async(dispatch_get_main_queue(), ^{
					NSAlert *alert = [NSAlert alertWithError:err];
					[alert runModal];
				});
			}
		});
	}
}

- (void)downloadJSON {
	// Check if we have an Internet connection.
	SCNetworkReachabilityRef target;
	SCNetworkConnectionFlags flags = 0;
	Boolean canReachInternet;
	target = SCNetworkReachabilityCreateWithName(NULL, "google.com");
	canReachInternet = SCNetworkReachabilityGetFlags(target, &flags);
	CFRelease(target);

	if (!(canReachInternet && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired))) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
			[alert setMessageText:NSLocalizedString(@"No network connection.", nil)];
			[alert setInformativeText:NSLocalizedString(@"Mac Linux USB Loader cannot download the mirror lists because you are not connected to the Internet.", nil)];
			alert.alertStyle = NSWarningAlertStyle;
			[alert runModal];
		});

		return;
	}

	// We have an Internet connection, so proceed by downloading the JSON.
	for (NSString *distroName in ((SBAppDelegate *)NSApp.delegate).supportedDistributions) {
		NSError *err;
		NSString *temp = [NSString stringWithFormat:@"https://github.com/SevenBits/mlul-iso-mirrors/raw/master/mirrors/%@.json", [distroName stringByReplacingOccurrencesOfString:@" " withString:@"-"]];
		NSURL *url = [NSURL URLWithString:temp];

		// Start the mirror update spinner.
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.spinner startAnimation:nil];
		});

		NSString *strCon = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
		if (strCon) {
			//NSLog(@"Recieved JSON data: %@", strCon);
			[self processJSON:strCon forDistributionNamed:distroName downloadContent:YES];
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSAlert *alert = [NSAlert alertWithError:err];
				[alert runModal];
			});
		}

		// Stop the spinner.
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.spinner stopAnimation:nil];
		});
	}
}

- (void)processJSON:(NSString *)json forDistributionNamed:(NSString *)distroName downloadContent:(BOOL)downloadImages {
	[self.mdLock lock];
	JSONModelError *error;
	self.downloadDistroModel = [[SBDownloadableDistributionModel alloc] initWithString:json error:&error];
	if (error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSLog(@"%@: %@", distroName, error.localizedDescription);
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
		});
	} else {
		[self.idLock lock];
		NSString *convertedName = [distroName stringByReplacingOccurrencesOfString:@" " withString:@"-"];

		NSImage *img;

		// Fetch the image from the web if we are to download them; otherwise, grab it from the cache.
		if (downloadImages) {
			NSURL *imgSourceURL = [NSURL URLWithString:self.downloadDistroModel.imageURL];
			img = [[NSImage alloc] initWithContentsOfURL:imgSourceURL];
		} else {
			// Grab the images from the cache.
			NSString *cacheDirectory = [NSFileManager defaultManager].cacheDirectory;
			NSString *imgFilePath = [[cacheDirectory stringByAppendingPathComponent:convertedName] stringByAppendingString:@".png"];
			img = [[NSImage alloc] initWithContentsOfFile:imgFilePath];
		}

		// Register the image and save it to the disk if necessary.
		if (img) {
			self.imageDictionary[convertedName] = img;

			if (downloadImages) {
				[img saveAsPNGWithName:[[[NSFileManager defaultManager].cacheDirectory stringByAppendingPathComponent:convertedName] stringByAppendingString:@".png"]]; // Cache the image to a file.
			}
		}
		[self.idLock unlock];

		// Cache the JSON to a file if needed.
		if (downloadImages) {
			[json writeToFile:[[[NSFileManager defaultManager].cacheDirectory stringByAppendingPathComponent:convertedName] stringByAppendingString:@".json"] atomically:YES encoding:NSUTF8StringEncoding error:nil]; // Cache the JSON to a file.
		}

		if (self.downloadDistroModel) self.modelDictionary[convertedName] = self.downloadDistroModel;
	}

	self.numberOfFinishedJsonRequests++;
	[self.mdLock unlock];
}

- (void)windowDidLoad {
	[super windowDidLoad];

	// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	(self.window).delegate = self;

	// Setup the accessory view.
	[self placeAccessoryView];

	// Setup delegates.
	[self.tableView setDataSource:self];
	[self.tableView setDelegate:self];
}

- (NSString *)pathForDownloadedISOOfCurrentlySelectedDistro {
	NSString *distribution = ((SBAppDelegate *)NSApp.delegate).supportedDistributions[(self.tableView).selectedRow];
	NSString *path = [[NSFileManager defaultManager].applicationSupportDirectory stringByAppendingPathComponent:@"/Downloads/"];
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.iso",
												 ((SBAppDelegate *)NSApp.delegate).supportedDistributions[(self.tableView).selectedRow],
												 ((SBAppDelegate *)NSApp.delegate).supportedDistributionsAndVersions[distribution]]];
	return path;
}

#pragma mark - Delegates

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return ((SBAppDelegate *)NSApp.delegate).supportedDistributions.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([aTableColumn.identifier isEqualToString:@"nameCol"]) {
		return ((SBAppDelegate *)NSApp.delegate).supportedDistributions[rowIndex];
	} else if ([aTableColumn.identifier isEqualToString:@"versionCol"]) {
		NSString *distribution = ((SBAppDelegate *)NSApp.delegate).supportedDistributions[rowIndex];
		return ((SBAppDelegate *)NSApp.delegate).supportedDistributionsAndVersions[distribution];
	} else {
		return @"N/A";
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return NO;
}

- (void)tableViewDoubleClickAction {
	// Get the table view selection and make sure that they selected something.
	NSInteger row = (self.tableView).selectedRow;
	if (row == -1) {
		return;
	}

	// Construct the name and path of the downloaded ISO.
	NSString *path = [self pathForDownloadedISOOfCurrentlySelectedDistro];

	// Open the URL.
	NSURL *url = [NSURL fileURLWithPath:path];
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES completionHandler: ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
		if (!document && !documentWasAlreadyOpen) {
			[self downloadDistroButtonPressed:nil];
		}
	}];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSInteger row = (self.tableView).selectedRow;
	(self.downloadDistroButton).enabled = (row != -1);
	(self.viewMoreInfoButton).transparent = (row == -1);

	if (row == -1) {
		(self.distroNameLabel).stringValue = @"";
		[self.webView.mainFrame loadHTMLString:@"" baseURL:nil];
		[self.distroImageView setImage:nil];
		(self.distroISOPathLabel).stringValue = @"";
		return;
	}

	NSString *distribution = ((SBAppDelegate *)NSApp.delegate).supportedDistributions[row];
	(self.distroNameLabel).stringValue = [NSString stringWithFormat:@"%@ %@",
	                                      ((SBAppDelegate *)NSApp.delegate).supportedDistributions[row],
	                                      ((SBAppDelegate *)NSApp.delegate).supportedDistributionsAndVersions[distribution]];


	NSString *convertedName = [distribution stringByReplacingOccurrencesOfString:@" " withString:@"-"];
	NSImage *img = self.imageDictionary[convertedName];
	if (img) self.distroImageView.image = img;

	// Check if the selected distro's ISO has been downloaded.
	// If so, show the path and the button to view it in Finder.
	NSString *ISOPath = [self pathForDownloadedISOOfCurrentlySelectedDistro];
	if ([[NSFileManager defaultManager] fileExistsAtPath:ISOPath]) {
		self.distroISOPathLabel.stringValue = ISOPath;
		self.viewInFinderButton.enabled = YES;
		self.viewInFinderButton.transparent = NO;
	} else {
		self.distroISOPathLabel.stringValue = @"";
		self.viewInFinderButton.enabled = NO;
		self.viewInFinderButton.transparent = YES;
	}

	// Load the information on the selected Linux distribution from Wikipedia
	[self doWikipediaSearch];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	// Empty
}

#pragma mark - UI
- (void)doWikipediaSearch {
	// Fetch Wikipedia information on the selected distribution (may not work 100% of the time).
	[self.spinner startAnimation:nil];
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSError *error;
		NSInteger selectedRowIndex = (self.tableView).selectedRow;
		NSString *selectedLinuxDistribution = ((SBAppDelegate *)NSApp.delegate).supportedDistributions[selectedRowIndex];

		NSString *language = nil;
		if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_12) {
			language = [NSLocale currentLocale].languageCode;
		} else {
			language = [NSLocale preferredLanguages][0];
		}

		// There are multiple articles on Wikipedia with the name "Ubuntu", so we have to
		// be specific and specify exactly what we want if we need to download Ubuntu's info.
		if ([selectedLinuxDistribution isEqualToString:@"Ubuntu"]) {
			if ([language isEqualToString:@"en"]) {
				selectedLinuxDistribution = @"Ubuntu (operating system)";
			} else if ([language isEqualToString:@"nl"]) {
				selectedLinuxDistribution = @"Ubuntu (Linuxdistributie)";
			} else if ([language isEqualToString:@"nb"]) {
				selectedLinuxDistribution = @"Ubuntu (operativsystem)";
			}
		}

		// Encode the distribution name by removing any spaces.
		NSString *encodedDistributionString = nil;
		if ([NSString instancesRespondToSelector:@selector(stringByAddingPercentEncodingWithAllowedCharacters:)]) {
			encodedDistributionString = [selectedLinuxDistribution stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
		} else {
			encodedDistributionString = [selectedLinuxDistribution stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		}

		// Submit the request to Wikipedia and handle the data when it gets back.
		NSString *URLString = [NSString stringWithFormat:@"https://%@.wikipedia.org/w/api.php?action=query&prop=extracts&format=json&exintro=&titles=%@", language, encodedDistributionString];
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
		NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
		if (!response) {
			NSLog(@"Failed to get a response from Wikipedia: %@", error.localizedDescription);

			dispatch_async(dispatch_get_main_queue(), ^{
				[self.webView.mainFrame loadHTMLString:NSLocalizedString(@"No information on this distribution could be found due to a network problem. You might not be connected to the Internet.", nil) baseURL:nil];
				[self.spinner stopAnimation:nil];
			});
			return;
		}

		NSDictionary *outputDictionary = [NSJSONSerialization JSONObjectWithData:response
																		 options:0
																		   error:nil];
		NSDictionary *targetDictionary = outputDictionary[@"query"][@"pages"];

		__block NSString *desiredKey = nil;
		[targetDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			// Determine if the given key is the one that we want. Since this API request should only
			// return one result, if it meets our qualifications, we can assume that it is what we want.
			desiredKey = key;
			*stop = YES;
		}];

		NSString *distroBio = [targetDictionary[desiredKey][@"extract"] copy];
		if (distroBio) {
			distroBio = [[@"<html><body>" stringByAppendingString:distroBio] stringByAppendingString:@"</body></html>"];
			//NSLog(@"%@", artistBio);

			dispatch_async(dispatch_get_main_queue(), ^{
				[self.webView.mainFrame loadHTMLString:distroBio baseURL:nil];
			});
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.webView.mainFrame loadHTMLString:NSLocalizedString(@"No information about this distribution was found in your language.", nil) baseURL:nil];
			});
		}

		// Stop the spinner.
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.spinner stopAnimation:nil];
		});

		// Make sure these things get released.
		outputDictionary = nil;
		targetDictionary = nil;
	});
}

- (void)placeAccessoryView {
	NSOperatingSystemVersion opVer = [NSProcessInfo processInfo].operatingSystemVersion;
	// If the user is running pre-Yosemite...
	if (opVer.minorVersion <= 9) {
		NSView *themeFrame = (self.window).contentView.superview;
		NSRect c = themeFrame.frame;  // c for "container"
		NSRect aV = (self.accessoryView).frame; // aV for "accessory view"

		// Nudge the button to the left to account for the fullscreen button.
		NSRect newFrame = NSMakeRect(c.size.width - aV.size.width - SBAccessoryViewEdgeOffset, // x position
		                             c.size.height - aV.size.height, // y position
		                             aV.size.width, // width
		                             aV.size.height); // height

		(self.accessoryView).frame = newFrame;
		[self.accessoryView setNeedsDisplay:YES];
		[themeFrame addSubview:self.accessoryView];
	} else {
		//NSLog(@"Using new method");
		NSTitlebarAccessoryViewController *titleBarViewController = [[NSTitlebarAccessoryViewController alloc] init];
		titleBarViewController.view = self.accessoryViewButton;
		titleBarViewController.layoutAttribute = NSLayoutAttributeRight;
		[self.window addTitlebarAccessoryViewController:titleBarViewController];
	}
}

- (IBAction)viewInFinderButtonClicked:(id)sender {
	// Get the table view selection and make sure that they selected something.
	NSInteger row = (self.tableView).clickedRow;
	if (row == -1) {
		return;
	}

	// Construct the name and path of the downloaded ISO.
	NSString *distribution = ((SBAppDelegate *)NSApp.delegate).supportedDistributions[(self.tableView).selectedRow];
	NSString *path = [[NSFileManager defaultManager].applicationSupportDirectory stringByAppendingPathComponent:@"/Downloads/"];
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.iso",
	                                             ((SBAppDelegate *)NSApp.delegate).supportedDistributions[(self.tableView).selectedRow],
	                                             ((SBAppDelegate *)NSApp.delegate).supportedDistributionsAndVersions[distribution]]];

	// Open the URL.
	[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:path];
}

- (IBAction)downloadDistroButtonPressed:(id)sender {
	NSInteger selectedDistro = (self.tableView).selectedRow;

	NSString *temp = ((SBAppDelegate *)NSApp.delegate).supportedDistributions[selectedDistro];
	temp = [temp stringByReplacingOccurrencesOfString:@" " withString:@"-"];

	if (!self.modelDictionary[temp]) {
		// Ideally, we'd support the new sheet API, but we need to still support 10.8...
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Okay", nil)];
		[alert setMessageText:NSLocalizedString(@"Can't download this distribution.", nil)];
		[alert setInformativeText:NSLocalizedString(@"You cannot download this distribution because Mac Linux USB Loader has not finished downloading its list of mirrors.", nil)];
		alert.alertStyle = NSWarningAlertStyle;
		[alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];

		return;
	}

	self.downloadDistroModel = self.modelDictionary[temp];
	[self.distroMirrorCountrySelector removeAllItems];

	for (SBDownloadMirrorModel *model in (self.downloadDistroModel).mirrors) {
		NSString *format = [NSString stringWithFormat:@"%@ (%@)", model.countryLong, model.name];
		[self.distroMirrorCountrySelector addItemWithTitle:format];
	}

	[NSApp beginSheet:self.downloadSettingsPanel modalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)viewDistroWebsiteButtonClicked:(id)sender {
	// Get the table view selection and make sure that they selected something.
	NSInteger row = (self.tableView).selectedRow;
	if (row == -1) {
		return;
	}

	// Get the JSON model object for the selected distribution.
	NSString *distroName = ((SBAppDelegate *)NSApp.delegate).supportedDistributions[row];
	NSString *convertedName = [distroName stringByReplacingOccurrencesOfString:@" " withString:@"-"];
	SBDownloadableDistributionModel *model = self.modelDictionary[convertedName];

	// Construct the URL string and go there.
	NSString *urlString = model.websiteURL;
	if (urlString) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
	}
}

- (IBAction)viewDownloadedISOInFinderButtonClicked:(NSButton *)sender {
	// Construct the name and path of the downloaded ISO.
	NSString *path = [self pathForDownloadedISOOfCurrentlySelectedDistro];
	
	// Open the file.
	[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:path];
}

- (IBAction)closeDownloadDistroSheetPressed:(id)sender {
	[NSApp endSheet:self.downloadSettingsPanel];
	[self.downloadSettingsPanel orderOut:nil];
}

- (IBAction)commenceDownload:(id)sender {
	NSInteger selectedItem = (self.distroMirrorCountrySelector).indexOfSelectedItem;
	NSAssert(selectedItem != -1, @"Selected item is %ld", (long)selectedItem);

	NSString *distribution = ((SBAppDelegate *)NSApp.delegate).supportedDistributions[(self.tableView).selectedRow];
	NSString *path = [[NSFileManager defaultManager].applicationSupportDirectory stringByAppendingPathComponent:@"/Downloads/"];
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.iso",
	                                             ((SBAppDelegate *)NSApp.delegate).supportedDistributions[(self.tableView).selectedRow],
	                                             ((SBAppDelegate *)NSApp.delegate).supportedDistributionsAndVersions[distribution]]];

	// Inform the system that we are starting this operation.
	if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
		if (!self.activity) {
			self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityUserInitiated reason:@"ISO Download"];
		}
	}

	self.numberOfActiveDownloadOperations++;
	SBDownloadMirrorModel *model = self.downloadDistroModel.mirrors[selectedItem];
	NSURL *url = [NSURL URLWithString:model.url];
	DownloadOperation *downloadOperation = [[DownloadOperation alloc] initWithURL:url path:path];
	downloadOperation.downloadCompletionBlock = ^(DownloadOperation *operation, BOOL success, NSError *error) {
		if (error) {
			NSLog(@"%s: downloadCompletionBlock error: %@", __FUNCTION__, error);
		} else {
			/* The download was completed successfully. TODO: Show a notification. */

			// Activate the button to show you the file.
			self.distroISOPathLabel.stringValue = operation.path;
			self.viewInFinderButton.enabled = YES;
			self.viewInFinderButton.transparent = NO;

			// Open the downloaded ISO file.
			ISODownloadCompletionOperation completionOperation = [self.defaults integerForKey:@"DefaultOperationUponISODownloadCompletion"];
			if (completionOperation == ISODownloadCompletionOperationOpenDocument) {
				NSURL *url = [NSURL fileURLWithPath:operation.path];
				[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES completionHandler: ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {}
				];
			} else if (completionOperation == ISODownloadCompletionOperationShowInFinder) {
				[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:path];
			}
		}

		self.numberOfActiveDownloadOperations--;
		[self.downloadQueueTableView reloadData];

		if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
			if (self.numberOfActiveDownloadOperations == 0) {
				[[NSProcessInfo processInfo] endActivity:self.activity];
				self.activity = nil;
			}
		}
	};
	downloadOperation.downloadProgressBlock = ^(DownloadOperation *operation, long long progressContentLength, long long expectedContentLength) {
		CGFloat progress = (expectedContentLength > 0 ? (CGFloat)progressContentLength / (CGFloat)expectedContentLength : (progressContentLength % 1000000l) / 1000000.0f);
		//NSLog(@"%@: %f", operation, progress);

		NSInteger row = operation.correspondingTableViewRow;
		SBDistributionDownloaderTableCellView *cellView = [self.downloadQueueTableView viewAtColumn:0 row:row makeIfNecessary:YES];
		(cellView.progressBar).doubleValue = progress * 100;
	};
	downloadOperation.correspondingTableViewRow = self.numberOfActiveDownloadOperations - 1;

	[self.downloadQueue addOperation:downloadOperation];
	[self closeDownloadDistroSheetPressed:nil];
	[self.downloadQueueTableView reloadData];
}

- (IBAction)viewInProgressDownloads:(id)sender {
	[self.downloadQueuePopover showRelativeToRect:(self.accessoryViewButton).bounds ofView:self.accessoryViewButton preferredEdge:NSMaxYEdge];
}

@end
