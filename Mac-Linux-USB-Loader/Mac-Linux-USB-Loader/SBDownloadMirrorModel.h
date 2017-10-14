//
//  SBDownloadMirrorModel.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 5/25/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "JSONModel.h"

@protocol SBDownloadMirrorModel
@end

@interface SBDownloadMirrorModel : JSONModel

/// The URL to the ISO file of this particular distribution.
@property (strong, nonatomic) NSString *url;

/// The name of this mirror (optional).
@property (strong, nonatomic) NSString<Optional> *name;

/// The long name (i.e full name) of the country in which this mirror is located, for example, United States.
@property (strong, nonatomic) NSString *countryLong;

/// The ISO country code for the country in which this mirror is located (optional).
@property (strong, nonatomic) NSString<Optional> *countryShort;

@end
