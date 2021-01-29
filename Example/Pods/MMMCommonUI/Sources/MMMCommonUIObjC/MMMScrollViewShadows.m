//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMScrollViewShadows.h"

#import "MMMAnimations.h"
#import "MMMCommonUI.h"

//
//
//
@implementation MMMScrollViewShadowsSettings

- (id)init {

	if (self = [super init]) {

		_shadowAlpha = .3;
		_shadowCurvature = 0.5;

		_topShadowEnabled = NO;
		_topShadowHeight = 5;
		_topShadowShouldUseContentInsets = NO;

		_bottomShadowEnabled = NO;
		_bottomShadowHeight = 10;
		_bottomShadowShouldUseContentInsets = NO;
	}

	return self;
}

- (id)copyWithZone:(NSZone *)zone {

	MMMScrollViewShadowsSettings *result = [[MMMScrollViewShadowsSettings alloc] init];

	result.shadowAlpha = self.shadowAlpha;
	result.shadowCurvature = self.shadowCurvature;

	result.topShadowEnabled = self.topShadowEnabled;
	result.topShadowHeight = self.topShadowHeight;
	result.topShadowShouldUseContentInsets = self.topShadowShouldUseContentInsets;

	result.bottomShadowEnabled = self.bottomShadowEnabled;
	result.bottomShadowHeight = self.bottomShadowHeight;
	result.bottomShadowShouldUseContentInsets = self.bottomShadowShouldUseContentInsets;

	return result;
}

@end

//
//
//

@implementation MMMScrollViewShadowView {
	MMMScrollViewShadowAlignment _alignment;
	MMMScrollViewShadowsSettings *_settings;
}

- (id)initWithAlignment:(MMMScrollViewShadowAlignment)alignment settings:(MMMScrollViewShadowsSettings *)settings {

	if (self = [super initWithFrame:CGRectZero]) {

		_alignment = alignment;
		_settings = settings;

		self.opaque = NO;
		self.contentMode = UIViewContentModeRedraw;

		self.translatesAutoresizingMaskIntoConstraints = NO;
	}

	return self;
}

- (void)drawRect:(CGRect)rect {

	CGRect b = self.bounds;

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

	const CGFloat shadowAlpha = _settings.shadowAlpha;

	NSInteger numberOfSteps = MAX(8, MIN(b.size.height * 2, 24));
	CGFloat *colors = alloca(4 * sizeof(CGFloat) * numberOfSteps);
	CGFloat *steps = alloca(sizeof(CGFloat) * numberOfSteps);
	for (NSInteger i = 0; i < numberOfSteps; i++) {
		CGFloat t = (CGFloat)i / (numberOfSteps - 1);
		steps[i] = t;
		colors[i * 4 + 0] = 0;
		colors[i * 4 + 1] = 0;
		colors[i * 4 + 2] = 0;
		colors[i * 4 + 3] = powf(
			[MMMAnimation
				interpolateFrom:shadowAlpha to:0
				time:t
				startTime:0 duration:1
				curve:MMMAnimationCurveSofterEaseOut
			],
			M_SQRT2
		);
	}

	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, steps, numberOfSteps);

	CGColorSpaceRelease(colorSpace);

	// We want the radial gradient to end at the arc passing via the center of the bottom edge and both top corners (for the top shadow view)
	CGFloat d = b.size.width * .5;
	CGFloat h = b.size.height * MAX(.01, _settings.shadowCurvature);
	CGFloat radius = (d * d + h * h) / (2 * h);

	CGPoint center;
	if (_alignment == MMMScrollViewShadowAlignmentTop) {
		center = CGPointMake(b.origin.x + d, b.origin.y + b.size.height - radius);
	} else {
		NSAssert(_alignment == MMMScrollViewShadowAlignmentBottom, @"");
		center = CGPointMake(b.origin.x + d, b.origin.y + radius);
	}

	CGContextRef c = UIGraphicsGetCurrentContext();

	CGContextDrawRadialGradient(
		c, gradient,
		center, radius - b.size.height,
		center, radius,
		0
	);

	CGGradientRelease(gradient);
}

@end

@implementation MMMScrollViewShadows {
	UIScrollView * __weak _scrollView;
	MMMScrollViewShadowsSettings *_settings;
	MMMScrollViewShadowView *_topShadowView;
	MMMScrollViewShadowView *_bottomShadowView;
}

- (id)initWithScrollView:(UIScrollView *)scrollView settings:(MMMScrollViewShadowsSettings *)settings {

	if (self = [super init]) {

		_scrollView = scrollView;
		_settings = settings;

		if (_settings.topShadowEnabled) {
			_topShadowView = [[MMMScrollViewShadowView alloc] initWithAlignment:MMMScrollViewShadowAlignmentTop settings:_settings];
			[_scrollView addSubview:_topShadowView];
		}

		if (_settings.bottomShadowEnabled) {
			_bottomShadowView = [[MMMScrollViewShadowView alloc] initWithAlignment:MMMScrollViewShadowAlignmentBottom settings:_settings];
			[_scrollView addSubview:_bottomShadowView];
		}
	}

	return self;
}

- (BOOL)mightNeedClippingView {
	return _settings.topShadowShouldUseContentInsets || _settings.bottomShadowShouldUseContentInsets;
}

- (void)layoutSubviews {
	[self layoutSubviewsWithClippingView:nil];
}

- (void)layoutSubviewsWithClippingView:(nullable UIView *)clippingView {

	UIEdgeInsets contentInsets;
	if (@available(iOS 11.0, *)) {
		contentInsets = _scrollView.adjustedContentInset;
	} else {
		contentInsets = _scrollView.contentInset;
	}
	
	CGRect b = UIEdgeInsetsInsetRect(
		_scrollView.bounds,
		UIEdgeInsetsMake(
			_settings.topShadowShouldUseContentInsets ? contentInsets.top : 0,
			0,
			_settings.bottomShadowShouldUseContentInsets ? contentInsets.bottom : 0,
			0
		)
	);

	BOOL needsClipping = NO;

	if (_topShadowView) {

		CGFloat top = CGRectGetMinY(b);

		CGFloat topShadowHeight = [MMMAnimation
			interpolateFrom:0 to:_settings.topShadowHeight
			time:top
			startTime:0 duration:MAX(40, 4 * _settings.topShadowHeight)
			curve:MMMAnimationCurveEaseInOut
		];

		_topShadowView.frame = CGRectMake(CGRectGetMinX(b), top, b.size.width, topShadowHeight);

		BOOL hidden = topShadowHeight < 1;
		_topShadowView.hidden = hidden;

		if (clippingView)
			needsClipping = needsClipping || (!hidden && contentInsets.top > 0);

		if (!_topShadowView.hidden)
			[_scrollView bringSubviewToFront:_topShadowView];
	}

	if (_bottomShadowView) {

		CGFloat bottom = CGRectGetMaxY(b);

		CGFloat bottomShadowHeight = [MMMAnimation
			interpolateFrom:0 to:_settings.bottomShadowHeight
			time:_scrollView.contentSize.height - bottom
			startTime:_settings.bottomShadowHeight
			duration:MAX(40, 4 * _settings.bottomShadowHeight)
			curve:MMMAnimationCurveEaseInOut
		];

		_bottomShadowView.frame = CGRectMake(CGRectGetMinX(b), bottom - bottomShadowHeight, b.size.width, bottomShadowHeight);

		BOOL hidden = bottomShadowHeight < 1;
		_bottomShadowView.hidden = hidden;

		if (clippingView)
			needsClipping = needsClipping || (!hidden && contentInsets.bottom > 0);

		if (!_bottomShadowView.hidden)
			[_scrollView bringSubviewToFront:_bottomShadowView];
	}

	if (clippingView) {
		// Conversion is not really needed as _scrollView is actually the superview, but we don't enforce it.
		clippingView.frame = [_scrollView convertRect:b toView:clippingView.superview];
		clippingView.clipsToBounds = needsClipping;
	}
}

@end
