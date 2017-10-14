//
//  SBEnterpriseSourceLocation.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 2/15/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBEnterpriseSourceLocation.h"

@implementation SBEnterpriseSourceLocation

- (instancetype)initWithName:(NSString *)name withPath:(NSString *)path withVersionNumber:(NSString *)version withSecurityScopedBookmark:(NSURL *)bookmark shouldBeVolatile:(BOOL)deletable {
	self = [super init];
	if (self) {
		// Add your subclass-specific initialization here.
		self.name = name;
		self.path = path;
		self.version = version;
		self.securityScopedBookmark = bookmark;
		self.deletable = deletable;
	}
	return self;
}

- (instancetype)initWithName:(NSString *)name andPath:(NSString *)path shouldBeVolatile:(BOOL)deletable {
	self = [self initWithName:name withPath:path withVersionNumber:SBBundledEnterpriseVersionNumber withSecurityScopedBookmark:nil shouldBeVolatile:deletable];
	if (self) {
		// Add your subclass-specific initialization here.
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	self = [self initWithName:[decoder decodeObjectForKey:@"name"]
					 withPath:[decoder decodeObjectForKey:@"path"]
			withVersionNumber:[decoder decodeObjectForKey:@"version"]
   withSecurityScopedBookmark:[decoder decodeObjectForKey:@"bookmark"]
			 shouldBeVolatile:[decoder decodeBoolForKey:@"deletable"]];
	if (!self) {
		return nil;
	}

	return self;
}

- (instancetype)init {
	self = [self initWithName:nil withPath:nil withVersionNumber:nil withSecurityScopedBookmark:nil shouldBeVolatile:NO];
	if (!self) {
		return nil;
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:self.name forKey:@"name"];
	[encoder encodeObject:self.path forKey:@"path"];
	[encoder encodeObject:self.version forKey:@"version"];
	[encoder encodeObject:self.securityScopedBookmark forKey:@"bookmark"];
	[encoder encodeBool:self.deletable forKey:@"deletable"];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"Name:'%@' Path:'%@' Version:'%@' Bookmark:%@ Deletable:%@", self.name, self.path, self.version, self.securityScopedBookmark, SBBool2NSString(self.deletable)];
}

@end
