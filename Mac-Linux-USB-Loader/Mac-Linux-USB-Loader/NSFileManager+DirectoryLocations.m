//
//  NSFileManager+DirectoryLocations.m
//
//  Created by Matt Gallagher on 06 May 2010
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

#import "NSFileManager+DirectoryLocations.h"

enum {
	DirectoryLocationErrorNoPathFound,
	DirectoryLocationErrorFileExistsAtLocation
};

NSString *const DirectoryLocationDomain = @"DirectoryLocationDomain";

@implementation NSFileManager (DirectoryLocations)

- (NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory
                           inDomain:(NSSearchPathDomainMask)domainMask
                appendPathComponent:(NSString *)appendComponent
                              error:(NSError **)errorOut {
	//
	// Search for the path
	//
	NSArray *paths = NSSearchPathForDirectoriesInDomains(
	        searchPathDirectory,
	        domainMask,
	        YES);
	if (paths.count == 0) {
		if (errorOut) {
			NSDictionary *userInfo =
			    @{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(
			         @"No path found for directory in domain.",
			         @"Errors",
			         nil),
			     @"NSSearchPathDirectory": @(searchPathDirectory),
			     @"NSSearchPathDomainMask": @(domainMask)};
			*errorOut =
			    [NSError
			     errorWithDomain:DirectoryLocationDomain
			                code:DirectoryLocationErrorNoPathFound
			            userInfo:userInfo];
		}
		return nil;
	}

	//
	// Normally only need the first path returned
	//
	NSString *resolvedPath = paths[0];

	//
	// Append the extra path component
	//
	if (appendComponent) {
		resolvedPath = [resolvedPath
		                stringByAppendingPathComponent:appendComponent];
	}

	//
	// Create the path if it doesn't exist
	//
	NSError *error = nil;
	BOOL success = [self
	                createDirectoryAtPath:resolvedPath
	                   withIntermediateDirectories:YES
	                                    attributes:nil
	                                         error:&error];
	if (!success) {
		if (errorOut) {
			*errorOut = error;
		}
		return nil;
	}

	//
	// If we've made it this far, we have a success
	//
	if (errorOut) {
		*errorOut = nil;
	}
	return resolvedPath;
}

- (NSString *)applicationSupportDirectory {
	NSString *executableName =
	    [NSBundle mainBundle].infoDictionary[@"CFBundleExecutable"];
	NSError *error;
	NSString *result =
	    [self
	     findOrCreateDirectory:NSApplicationSupportDirectory
	                  inDomain:NSUserDomainMask
	       appendPathComponent:executableName
	                     error:&error];
	if (!result) {
		NSLog(@"Unable to find or create application support directory:\n%@", error);
	}
	return result;
}

- (NSString *)cacheDirectory {
	NSString *executableName =
	[NSBundle mainBundle].infoDictionary[@"CFBundleExecutable"];
	NSError *error;
	NSString *result =
	[self
	 findOrCreateDirectory:NSCachesDirectory
	 inDomain:NSUserDomainMask
	 appendPathComponent:executableName
	 error:&error];
	if (!result) {
		NSLog(@"Unable to find or create application support directory:\n%@", error);
	}
	return result;
}

@end