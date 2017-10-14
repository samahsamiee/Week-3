//
//  SBPersistenceManagerWindowController.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/22/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SBPersistenceManagerWindowController : NSWindowController <NSComboBoxDelegate, NSControlTextEditingDelegate>

- (IBAction)createPersistenceButtonPressed:(id)sender;
- (IBAction)resetSliderButtonPressed:(id)sender;

@end
