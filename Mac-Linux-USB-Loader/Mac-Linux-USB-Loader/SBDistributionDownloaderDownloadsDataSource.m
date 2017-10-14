//
//  SBDistributionDownloaderDownloadsDataSource.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 7/25/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBDistributionDownloaderDownloadsDataSource.h"
#import "SBDistributionDownloaderTableCellView.h"
#import "DownloadOperation.h"

@implementation SBDistributionDownloaderDownloadsDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return self.prefsViewController.numberOfActiveDownloadOperations;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSLog(@"Updating current downloads table.");
	NSOperationQueue *queue = self.prefsViewController.downloadQueue;
	DownloadOperation *downloadOperation = queue.operations[row];

	SBDistributionDownloaderTableCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	(result.nameLabel).stringValue = (downloadOperation.path).lastPathComponent.stringByDeletingPathExtension;
	result.controller = self.prefsViewController;
	result.currentDownloadProcessId = row;

	return result;
}

- (void)userSelectedOperationFromTable {
	NSInteger clickedRow = (self.tableView).clickedRow;
	NSOperationQueue *queue = self.prefsViewController.downloadQueue;
	DownloadOperation *downloadOperation = queue.operations[clickedRow];

	NSLog(@"User selected index %ld in table.", clickedRow);

	NSURL *url = [NSURL fileURLWithPath:downloadOperation.path];
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {}];
}

@end
