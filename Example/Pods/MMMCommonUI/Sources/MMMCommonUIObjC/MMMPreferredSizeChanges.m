//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMPreferredSizeChanges.h"

@implementation UIView (MMMPreferredSizeCouldChange)

- (void)mmm_setPreferredSizeCouldChange {

	UIView *next = self.superview;

	while (next) {

		if ([next conformsToProtocol:@protocol(MMMPreferredSizeChanges)]) {
			[(id<MMMPreferredSizeChanges>)next mmm_preferredSizeCouldChangeForSubview:self];
			break;
		}

		// It makes no sense to bubble higher than containers that usually don't have preferred size anyway.
		// (Checking for a scroll view here because UITableView and UICollectionView are scroll views as well.)
		if ([next isKindOfClass:[UIScrollView class]]) {
			break;
		}

		next = next.superview;
	}
}

@end
