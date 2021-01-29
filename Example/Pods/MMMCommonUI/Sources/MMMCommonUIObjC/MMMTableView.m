//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMTableView.h"

@implementation MMMTableView {
	MMMScrollViewShadows *_shadows;
	dispatch_source_t _reloadSource;
}

- (id)initWithSettings:(MMMScrollViewShadowsSettings *)settings style:(UITableViewStyle)style {
	
	if (self = [super initWithFrame:CGRectMake(0, 0, 320, 400) style:style]) {

		self.translatesAutoresizingMaskIntoConstraints = NO;

		_shadows = [[MMMScrollViewShadows alloc] initWithScrollView:self settings:settings];
	}

	return self;
}

- (id)initWithSettings:(MMMScrollViewShadowsSettings *)settings {
	return [self initWithSettings:settings style:UITableViewStylePlain];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[_shadows layoutSubviews];
}

- (void)mmm_preferredSizeCouldChangeForSubview:(UIView *)subview {

	if (!_shouldHandlePotentialCellSizeChanges) {
		// Not opted in, nothing to do.
		return;
	}

	// We want to coalesce multiple notifications into a single `reloadData` call.
	if (!_reloadSource) {
		_reloadSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_OR, 0, 0, dispatch_get_main_queue());
		if (_reloadSource) {
			MMMTableView * __weak weakSelf = self;
			dispatch_source_set_event_handler(_reloadSource, ^{
				[weakSelf reloadData];
			});
			dispatch_activate(_reloadSource);
		}
	}

	dispatch_source_merge_data(_reloadSource, 1);
}

@end
