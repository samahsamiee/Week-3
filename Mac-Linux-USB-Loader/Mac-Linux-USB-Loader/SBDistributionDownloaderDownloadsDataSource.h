//
//  SBDistributionDownloaderDownloadsDataSource.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 7/25/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBDistributionDownloaderWindowController.h"

@interface SBDistributionDownloaderDownloadsDataSource : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (assign) SBDistributionDownloaderWindowController *prefsViewController;
@property (assign) NSTableView *tableView;

@end
