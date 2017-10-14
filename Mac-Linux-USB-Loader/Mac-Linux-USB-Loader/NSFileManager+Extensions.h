//
//  NSFileManager+Extensions.h
//  Mac Linux USB Loader
//
//  Created by SevenBits on 2/1/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Extensions)

/**
 * A custom extension to NSFileManager that provides an easy way to get the size of a file.
 *
 * @param path The path to the target file.
 * @return The size of the file in bytes.
 */
- (NSNumber *)sizeOfFileAtPath:(NSString *)path;

/**
 * Retrieves the amount of free space in bytes that remains available on the target path.
 *
 * @param path The path whose free space should be returned
 * @param error A pointer to an NSError which will contain failure information if this operation fails
 * @return The free space left on the specified drive
 */
- (NSInteger)freeSpaceRemainingOnDrive:(NSString *)path error:(NSError **)userError;

/**
 * A custom extension to NSFileManager that provides an easy way to setup a security scoped bookmark to access
 * a user's USB drive.
 *
 * @param path The path to the USB drive to use.
 * @param withWindowForSheet In case of an error, the window to display the alert sheet from.
 * @return An NSURL object representing the security scoped bookmark, or nil if access was denied.
 */
- (NSURL *)setupSecurityScopedBookmarkForUSBAtPath:(NSString *)path withWindowForSheet:(NSWindow *)window;

/**
 * A custom extension to NSFileManager that provides an easy way to setup a security scoped bookmark to a
 * file.
 *
 * @param url The URL of the file to create the bookmark of.
 * @return An NSURL object representing the security scoped bookmark, or nil if access was denied.
 */
- (NSURL *)createSecurityScopedBookmarkForPath:(NSURL *)url;

@end
