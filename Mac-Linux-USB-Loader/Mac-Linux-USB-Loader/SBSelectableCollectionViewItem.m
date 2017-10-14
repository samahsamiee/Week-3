//
//  SBSelectableCollectionViewItem.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 3/20/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBSelectableCollectionViewItem.h"
#import "SBSelectableCollectionView.h"

@interface SBSelectableCollectionViewItem ()

@end

@implementation SBSelectableCollectionViewItem

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Initialization code here.
	}
	return self;
}

- (void)setSelected:(BOOL)flag {
	super.selected = flag;
	((SBSelectableCollectionView *)self.view).selected = flag;
	[(SBSelectableCollectionView *)self.view setNeedsDisplay : YES];
}

@end
