//
//  SBDistributionDownloaderWindowController.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 5/9/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <WebKit/WebKit.h>
#import <JSONModel/JSONModel.h>
#import <JSONHTTPClient.h>
#import "SBDownloadableDistributionModel.h"

typedef NS_ENUM(NSUInteger, ISODownloadCompletionOperation) {
	ISODownloadCompletionOperationOpenDocument = 0,
	ISODownloadCompletionOperationShowInFinder,
	ISODownloadCompletionOperationDoNothing
};

@interface SBDistributionDownloaderWindowController : NSWindowController <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate>

- (IBAction)downloadDistroButtonPressed:(id)sender;
- (IBAction)closeDownloadDistroSheetPressed:(id)sender;
- (IBAction)commenceDownload:(id)sender;
- (IBAction)viewInProgressDownloads:(id)sender;

@property NSInteger numberOfActiveDownloadOperations;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;

@end
