//
//  SBDistributionDownloaderTableCellView.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 7/25/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBDistributionDownloaderTableCellView.h"
#import "SBDistributionDownloaderWindowController.h"

@implementation SBDistributionDownloaderTableCellView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (IBAction)stopCurrentDownload:(id)sender {
	if (!self.controller) return;

	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
	[alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
	[alert setMessageText:NSLocalizedString(@"Are you sure that you want to cancel this download operation?", nil)];
	[alert setInformativeText:NSLocalizedString(@"This operation cannot be undone.", nil)];
	alert.alertStyle = NSWarningAlertStyle;

	[alert runAsPopoverForView:self.deleteButton withCompletionBlock:^(NSInteger result) {
		if (result == NSAlertSecondButtonReturn) {
			[self.controller.downloadQueue.operations[self.currentDownloadProcessId] cancel];
		}
	}];
}

@end
