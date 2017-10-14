//
//  SBDownloadableDistributionModel.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 5/25/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "SBDownloadMirrorModel.h"

@interface SBDownloadableDistributionModel : JSONModel

/// An array of mirrors that contains this particular distribution.
@property (strong, nonatomic) NSArray<SBDownloadMirrorModel> *mirrors;

/// A URL for an image containing a logo or symbol representing this distribution.
@property (strong, nonatomic) NSString<Optional> *imageURL;

/// The URL of the distribution's website.
@property (strong, nonatomic) NSString<Optional> *websiteURL;

@end
