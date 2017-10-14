//
//  SBDistributionDownloaderPreferencesViewController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 7/4/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBDistributionDownloaderPreferencesViewController.h"

@interface SBDistributionDownloaderPreferencesViewController ()

@end

@implementation SBDistributionDownloaderPreferencesViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Initialization code here.
	}
	return self;
}

- (NSString *)identifier {
	return NSStringFromClass(self.class);
}

- (NSImage *)toolbarItemImage {
	return [NSImage imageNamed:@"DistributionDownloader"];
}

- (NSString *)toolbarItemLabel {
	return NSLocalizedString(@"Downloader", nil);
}

@end
