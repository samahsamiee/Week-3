//
//  SBAboutWindowController.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/27/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface SBAboutWindowController : NSWindowController

- (IBAction)showAcknowledgementsButtonPressed:(id)sender;
- (IBAction)showLicenseAgreementButtonPressed:(id)sender;

@end

IB_DESIGNABLE @interface BackgroundColorView : NSView
@property (nonatomic, strong) IBInspectable NSColor *backgroundColor;
@end
