//
//  SBEnterpriseSourceLocation.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 2/15/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBEnterpriseSourceLocation : NSObject <NSCoding>

/// The name of the Enterprise source location.
@property (strong) NSString *name;
/// The path to the Enterprise source location.
@property (strong) NSString *path;
/// The version of the Enterprise executable at this location.
@property (strong) NSString *version;
/// A security scoped bookmark to access the Enterprise installation directory.
@property (strong) NSURL *securityScopedBookmark;
/// A boolean indicating whether this location should be removable.
@property (assign) BOOL deletable;

/**
 * Initializes a new SBEnterpriseSourceLocation object immediately after memory for it has been allocated.
 * It is configured with the passed name and path variables.
 *
 * @param name The name (for user reference) of the source location.
 * @param path The path of the source location.
 * @param deletable Whether can user should be able to delete this source.
 */
- (instancetype)initWithName:(NSString *)name andPath:(NSString *)path shouldBeVolatile:(BOOL)deletable;

/**
 * Initializes a new SBEnterpriseSourceLocation object immediately after memory for it has been allocated.
 * It is configured with the passed name, version, volatility, and path variables. If you don't want to use
 * this version, you can use the shorter version initWithName:andPath:shouldBeVolatile.
 *
 * @param name The name (for user reference) of the source location.
 * @param path The path of the source location.
 * @param version An NSString object containing a version number for the program.
 * @param bookmark A security scoped bookmark to access the directory containing this source.
 * @param deletable Whether can user should be able to delete this source.
 */
- (instancetype)initWithName:(NSString *)name withPath:(NSString *)path withVersionNumber:(NSString *)version withSecurityScopedBookmark:(NSURL *)bookmark shouldBeVolatile:(BOOL)deletable NS_DESIGNATED_INITIALIZER;

@end
