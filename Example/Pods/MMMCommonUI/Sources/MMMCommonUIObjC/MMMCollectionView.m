//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMCollectionView.h"

@implementation MMMCollectionView {
	MMMScrollViewShadows *_shadows;
}

- (instancetype)initWithSettings:(MMMScrollViewShadowsSettings *)settings {

	if (self = [super initWithFrame:CGRectMake(0, 0, 320, 400) collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]]) {

		self.translatesAutoresizingMaskIntoConstraints = NO;

		_shadows = [[MMMScrollViewShadows alloc] initWithScrollView:self settings:settings];
	}

	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[_shadows layoutSubviews];
}

@end
