//
//  SBUpdatePreferencesViewController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 3/14/15.
//  Copyright (c) 2015 SevenBits. All rights reserved.
//

#import <Sparkle/Sparkle.h>

#import "SBUpdatePreferencesViewController.h"

@interface SBUpdatePreferencesViewController ()

@property (strong) IBOutlet SPUStandardUpdaterController *updater;

@end

@implementation SBUpdatePreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (NSString *)identifier {
	return NSStringFromClass(self.class);
}

- (NSImage *)toolbarItemImage {
	return [NSImage imageNamed:@"SparkleUpdate"];
}

- (NSString *)toolbarItemLabel {
	return NSLocalizedString(@"Updates", nil);
}

#pragma mark - IBActions

- (IBAction)changeUpdateChannel:(NSPopUpButton *)sender {
	NSString *feedString;
	if (sender.selectedTag == 1) {
		feedString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SUBetaFeedURL"];
	} else {
		feedString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SUFeedURL"];
	}

	NSURL *feedURL = [NSURL URLWithString:feedString];
	[self.updater.updater setFeedURL:feedURL];
}

@end
