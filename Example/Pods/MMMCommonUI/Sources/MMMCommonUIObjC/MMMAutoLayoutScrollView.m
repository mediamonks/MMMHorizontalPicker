//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMAutoLayoutScrollView.h"

#import "MMMAnimations.h"
#import "MMMCommonUI.h"
#import "MMMLayout.h"
#import "MMMScrollViewShadows.h"

//
// Note that it's not much different from a bare view, but having it in a separate class makes it look nicer in the hierarchy browser
//
@implementation MMMAutoLayoutScrollViewContentView

 - (id)init {

	if (self = [super initWithFrame:CGRectZero]) {
		self.opaque = NO;
		self.translatesAutoresizingMaskIntoConstraints = NO;
	}

	return self;
 }

@end

/** A view that is used for additional clipping of scroll view's contents in case shadows do not sit flush
 * with the edges of their scroll view. (Again, a normal UIView, but handy to have its own class name when
 * browsing the hierarchies.) */
@interface MMMAutoLayoutScrollViewClippingView : UIView
@end

@implementation MMMAutoLayoutScrollViewClippingView
@end

//
//
//
@implementation MMMAutoLayoutScrollView {

	// YES, if we don't expect subviews or constraints added anymore.
	BOOL _hierarchyLocked;

	MMMScrollViewShadows *_shadows;
	
	NSLayoutConstraint *_heightConstraint;

	// Need additional clipping in case the shadows are not flush with the scroll view's frame.
	MMMAutoLayoutScrollViewClippingView *_clippingView;
}

- (id)init {
	return [self initWithSettings:[[MMMScrollViewShadowsSettings alloc] init]];
}

- (id)initWithSettings:(MMMScrollViewShadowsSettings *)settings {

	if (self = [super initWithFrame:CGRectMake(0, 0, 320, 400)]) {

		self.translatesAutoresizingMaskIntoConstraints = NO;

		self.showsHorizontalScrollIndicator = self.showsVerticalScrollIndicator = NO;

		if (@available(iOS 11.0, *)) {
			// The default 'Automatic' behavior can cause a layout calculation loop as described
			// in `adjustMinHeightConstraintTakingInsetsIntoAccount` below.
			self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
		}

		_shadows = [[MMMScrollViewShadows alloc] initWithScrollView:self settings:settings];

		// We need additional content clipping in case shadows might be not flush with the scroll view frame.
		if ([_shadows mightNeedClippingView]) {
			_clippingView = [[MMMAutoLayoutScrollViewClippingView alloc] init];
			_clippingView.translatesAutoresizingMaskIntoConstraints = YES;
			[self addSubview:_clippingView];
		}

		_contentView = [[MMMAutoLayoutScrollViewContentView alloc] init];
		[(_clippingView ?: self) addSubview:_contentView];

		//
		// Layout
		//
		[self
			mmm_addConstraintsAligningView:_contentView
			horizontally:MMMLayoutHorizontalAlignmentFill
			vertically:MMMLayoutVerticalAlignmentFill
		];

		// We want to stretch the content view to fill the bounds in case its natural size is smaller than the scroll view's.
		[self addConstraint:[NSLayoutConstraint
			constraintWithItem:_contentView attribute:NSLayoutAttributeWidth
			relatedBy:NSLayoutRelationEqual
			toItem:self attribute:NSLayoutAttributeWidth
			multiplier:1 constant:0
			priority:UILayoutPriorityRequired
			identifier:@"MMM-ContentView-Width"
		]];

		_heightConstraint = [NSLayoutConstraint
			constraintWithItem:_contentView attribute:NSLayoutAttributeHeight
			relatedBy:NSLayoutRelationGreaterThanOrEqual
			toItem:self attribute:NSLayoutAttributeHeight
			multiplier:1 constant:0
			priority:UILayoutPriorityDefaultLow + 1
			identifier:@"MMM-ContentView-Minimum-Height"
		];
		_heightConstraint.active = YES;
		
		// Let's lock the hierarchy to be able to catch common misuse issues earlier.
		_hierarchyLocked = YES;
	}

	return self;
}

- (void)adjustMinHeightConstraintTakingInsetsIntoAccount {

	/*
	 * There is a circular dependency with adjustedContentInset that makes the app freeze. It occurs when
	 * contentInsetAdjustmentBehavior is Automatic or ScrollableAxes.
	 *
	 * Example: a full screen scroll view on iPhone X with its content view requiring little space.
	 *
	 * 1) Our initial constraints cause the actual height of the content view to become equal to the screen height and
	 * thus the system adjusts the top content inset to 44pt so the content view can be fully scrolled back and forth
	 * from behind the status bar area.
	 *
	 * 2) Then we come here and change the height constraint allowing the content view to be 44pt smaller than the frame
	 * of the scroll view.
	 *
	 * 3) The content view of this size does not underlap the top safe area anymore and is always visible without
	 * scrolling, so the insets do not need to be adjusted now, i.e. they are set back to 0pt.
	 *
	 * 4) This triggers our code here again adjusting the minimum height constraint to that of the whole scroll view,
	 * and we are back at step #1.
	 */
	UIEdgeInsets contentInsets;
	if (@available(iOS 11.0, *)) {
		if (self.contentInsetAdjustmentBehavior == UIScrollViewContentInsetAdjustmentNever
			|| self.contentInsetAdjustmentBehavior == UIScrollViewContentInsetAdjustmentAlways
		) {
			contentInsets = self.adjustedContentInset;
		} else {
			contentInsets = self.contentInset;
		}
	} else {
		contentInsets = self.contentInset;
	}

	_heightConstraint.constant = - (contentInsets.top + contentInsets.bottom);
}

- (void)layoutSubviews {

	[self adjustMinHeightConstraintTakingInsetsIntoAccount];

	[super layoutSubviews];

	[_shadows layoutSubviewsWithClippingView:_clippingView];
}

#pragma mark - A bit of diagnostics

- (void)setContentInsetAdjustmentBehavior:(UIScrollViewContentInsetAdjustmentBehavior)contentInsetAdjustmentBehavior {
	NSAssert(
		contentInsetAdjustmentBehavior == UIScrollViewContentInsetAdjustmentNever || contentInsetAdjustmentBehavior == UIScrollViewContentInsetAdjustmentAlways,
		@"`contentInsetAdjustementBehavior` set to 'Automatic' or similar can cause calculation dependency loops with `adjustedContentInset`. Use either 'Always' or 'Never' instead."
	);
	[super setContentInsetAdjustmentBehavior:contentInsetAdjustmentBehavior];
}

- (void)addSubview:(UIView *)view {
	NSAssert(
		!_hierarchyLocked || [NSStringFromClass([view class]) hasPrefix:@"UI"],
		@"Add your subviews into `contentView` and not into %@ directly", self.class
	);
	[super addSubview:view];
}

- (void)addConstraints:(NSArray<__kindof NSLayoutConstraint *> *)constraints {
	NSAssert(!_hierarchyLocked, @"Add your constraints into `contentView` and not into %@ directly", self.class);
	[super addConstraints:constraints];
}

- (void)addConstraint:(NSLayoutConstraint *)constraint {
	NSAssert(!_hierarchyLocked, @"Add your constraints into `contentView` and not into %@ directly", self.class);
	[super addConstraint:constraint];
}

#pragma mark

@end
