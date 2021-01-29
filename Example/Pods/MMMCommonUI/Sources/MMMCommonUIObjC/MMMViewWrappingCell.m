//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMViewWrappingCell.h"

#import "MMMLayout.h"

@implementation MMMViewWrappingCell

- (id)initWithView:(UIView *)view reuseIdentifier:(NSString *)reuseIdentifier inset:(UIEdgeInsets)inset {

	if (self = [super initWithReuseIdentifier:reuseIdentifier]) {

		NSAssert([view isKindOfClass:[UIView class]], @"");

		self.selectionStyle = UITableViewCellSelectionStyleNone;

		self.opaque = view.opaque;
		self.backgroundColor = view.backgroundColor;

		_wrappedView = view;
		[(UIView *)_wrappedView setTranslatesAutoresizingMaskIntoConstraints:NO];
		[self.contentView addSubview:_wrappedView];

		[self.contentView mmm_setHuggingHorizontal:UILayoutPriorityDefaultLow vertical:UILayoutPriorityRequired];
		[self.contentView mmm_setCompressionResistanceHorizontal:UILayoutPriorityDefaultLow vertical:UILayoutPriorityRequired];

		[self.contentView
			mmm_addConstraintsAligningView:_wrappedView
			horizontally:MMMLayoutHorizontalAlignmentFill
			vertically:MMMLayoutVerticalAlignmentFill
			insets:inset
		];
	}

	return self;
}

- (id)initWithView:(UIView *)view reuseIdentifier:(NSString *)reuseIdentifier {
	return [self initWithView:view reuseIdentifier:reuseIdentifier inset:UIEdgeInsetsZero];
}

@end
