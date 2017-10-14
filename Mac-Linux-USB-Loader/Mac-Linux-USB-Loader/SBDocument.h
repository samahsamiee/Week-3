//
//  SBDocument.h
//  Mac-Linux-USB-Loader
//
//  Created by SevenBits on 1/13/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SBDocument : NSDocument <NSComboBoxDelegate, NSControlTextEditingDelegate> {
	IBOutlet NSArrayController *arrayController;
}

@property (strong) NSMutableArray *usbArrayForContentView;
@property (weak) IBOutlet NSProgressIndicator *installationProgressBar;

@property (nonatomic, assign) BOOL automaticSetupCheckBoxChecked;

- (IBAction)performInstallation:(id)sender;
- (IBAction)refreshUSBListing:(id)sender;

@end
