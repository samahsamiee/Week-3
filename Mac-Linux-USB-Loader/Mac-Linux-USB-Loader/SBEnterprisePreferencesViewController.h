//
//  SBEnterprisePreferencesViewController.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 2/14/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>

@interface SBEnterprisePreferencesViewController : NSViewController <RHPreferencesViewControllerProtocol, NSTableViewDataSource, NSTableViewDelegate>

- (IBAction)addSourceLocationButtonPressed:(id)sender;
- (IBAction)hideSourceLocationButtonPressed:(id)sender;
- (IBAction)removeSourceLocationButtonPressed:(id)sender;
- (IBAction)showSourcePathSelectorDialog:(id)sender;
- (IBAction)confirmSourceLocationInformation:(id)sender;

@end
