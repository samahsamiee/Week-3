//
//  SBDistributionDownloaderTableCellView.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 7/25/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SBDistributionDownloaderWindowController;

@interface SBDistributionDownloaderTableCellView : NSTableCellView

@property (assign) IBOutlet NSProgressIndicator *progressBar;
@property (assign) IBOutlet NSTextField *nameLabel;
@property (assign) IBOutlet NSButton *deleteButton;

@property (weak) SBDistributionDownloaderWindowController *controller;
@property NSInteger currentDownloadProcessId;

@end
