//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMLayout.h"

@import MMMCommonCore;

#import "MMMCommonUI.h"
#import <objc/runtime.h>

//
//
//
@implementation MMMLayoutUtils

+ (CGRect)rectWithSize:(CGSize)size anchor:(CGPoint)anchor withinRect:(CGRect)targetRect anchor:(CGPoint)targetAnchor {
	return MMMPixelIntegralRect(CGRectMake(
		targetRect.origin.x + targetRect.size.width * targetAnchor.x - size.width * anchor.x,
		targetRect.origin.y + targetRect.size.height * targetAnchor.y - size.height * anchor.y,
		size.width,
		size.height
	));
}

+ (CGRect)rectWithSize:(CGSize)size withinRect:(CGRect)targetRect anchor:(CGPoint)anchor {
	return MMMPixelIntegralRect(CGRectMake(
		targetRect.origin.x + (targetRect.size.width - size.width) * anchor.x,
		targetRect.origin.y + (targetRect.size.height - size.height) * anchor.y,
		size.width,
		size.height
	));
}

+ (CGRect)rectWithSize:(CGSize)size withinRect:(CGRect)targetRect contentMode:(UIViewContentMode)contentMode {

	switch (contentMode) {

		case UIViewContentModeScaleToFill:
			// Not much sense using this routine with this mode, but well, maybe it's coming from the corresponding property of UIView here
			return targetRect;

		case UIViewContentModeScaleAspectFit:
		case UIViewContentModeScaleAspectFill:
			{
				double scaleX = targetRect.size.width / size.width;
				double scaleY = targetRect.size.height / size.height;
				double scale = (contentMode == UIViewContentModeScaleAspectFit) ? MIN(scaleX, scaleY) : MAX(scaleX, scaleY);
				CGFloat resultWidth = size.width * scale;
				CGFloat resultHeight = size.height * scale;
				return MMMPixelIntegralRect(
					CGRectMake(
						targetRect.origin.x + (targetRect.size.width - resultWidth) * 0.5f,
						targetRect.origin.y + (targetRect.size.height - resultHeight) * 0.5f,
						resultWidth,
						resultHeight
					)
				);
			}

		case UIViewContentModeRedraw:
			NSAssert(NO, @"UIViewContentModeRedraw does not make any sense for %s", sel_getName(_cmd));
			return targetRect;

		case UIViewContentModeCenter:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(0.5, 0.5)];

		case UIViewContentModeTop:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(0.5, 0)];

		case UIViewContentModeBottom:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(0.5, 1)];

		case UIViewContentModeLeft:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(0, 0.5)];

		case UIViewContentModeRight:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(1, 0.5)];

		case UIViewContentModeTopLeft:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(0, 0)];

		case UIViewContentModeTopRight:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(1, 0)];

		case UIViewContentModeBottomLeft:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(0, 1)];

		case UIViewContentModeBottomRight:
			return [self rectWithSize:size withinRect:targetRect anchor:CGPointMake(1, 1)];
	}
}

+ (CGRect)rectWithSize:(CGSize)size atPoint:(CGPoint)point anchor:(CGPoint)anchor {
	return MMMPixelIntegralRect(CGRectMake(
		point.x - size.width * anchor.x,
		point.y - size.height * anchor.y,
		size.width,
		size.height
	));
}

+ (CGRect)rectWithSize:(CGSize)size center:(CGPoint)center {
	return [self rectWithSize:size atPoint:center anchor:CGPointMake(.5f, .5f)];
}

@end

CGFloat const MMMGolden = 1.47093999 * 1.10; // 110% adjusted.
CGFloat const MMMInverseGolden = 1 / MMMGolden;

//
//
//
@implementation MMMSpacerView

- (id)init {

	if (self = [super initWithFrame:CGRectZero]) {

		self.translatesAutoresizingMaskIntoConstraints = NO;

		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];

		// It's not visible anyway, but let's further hide it just in case
		self.hidden = YES;

		// TODO: these make no sense as we don't have intrinsic content
		[self setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
		[self setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
		[self setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
		[self setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
	}

	return self;
}

- (CGSize)intrinsicContentSize {
	return CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
}

@end

//
//
//

@implementation MMMContainerView

- (id)init {

	if (self = [super initWithFrame:CGRectZero]) {
		self.translatesAutoresizingMaskIntoConstraints = NO;
	}

	return self;
}

@end

//
//
//

#pragma mark - Auto Layout helpers shared between UIView and UILayoutGuide

static inline BOOL MMMLayoutUtilsIsKindOfCenterAlignment(MMMLayoutAlignment alignment) {
	return alignment == MMMLayoutAlignmentGolden || alignment == MMMLayoutAlignmentCenter;
}

static CGFloat MMMLayoutUtilsMultiplierForAlignment(MMMLayoutAlignment alignment) {
	switch (alignment) {
		case MMMLayoutAlignmentGolden:
			return MMMCenterMultiplierForRatio(MMMInverseGolden);
		case MMMLayoutAlignmentCenter:
			return 1;
		default:
			NSCAssert(NO, @"");
			return 1;
	}
}

// This is to be reused with views and guides.
static NSArray<NSLayoutConstraint *> * _MMMConstraintsAligning(
	id viewOrGuide,
	id inViewOrGuide,
	MMMLayoutHorizontalAlignment horizontalAlignment,
	MMMLayoutVerticalAlignment verticalAlignment,
	UIEdgeInsets insets
) {

	// Renaming to keep the code below intact.
	id view = viewOrGuide;
	id self = inViewOrGuide;

	NSMutableArray *result = [[NSMutableArray alloc] init];

	//
	// Horizontal constraints.
	//
	if (horizontalAlignment == MMMLayoutHorizontalAlignmentLeft) {

		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeLeft
			relatedBy:NSLayoutRelationEqual
			toItem:inViewOrGuide attribute:NSLayoutAttributeLeft
			multiplier:1 constant:insets.left
		]];

		// The right edge of the subview should stay within this view.
		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeRight
			relatedBy:NSLayoutRelationLessThanOrEqual
			toItem:self attribute:NSLayoutAttributeRight
			multiplier:1 constant:-insets.right
		]];

	} else if (MMMLayoutUtilsIsKindOfCenterAlignment(MMMLayoutAlignmentFromHorizontalAlignment(horizontalAlignment))) {

		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeCenterX
			relatedBy:NSLayoutRelationEqual
			toItem:self attribute:NSLayoutAttributeCenterX
			multiplier:MMMLayoutUtilsMultiplierForAlignment(MMMLayoutAlignmentFromHorizontalAlignment(horizontalAlignment))
			constant:(insets.left - insets.right) * .5 // TODO: should not we use a multiplier as well?
		]];

		// It should be centered, but in addition the edges should stay within the subview.
		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeLeft
			relatedBy:NSLayoutRelationGreaterThanOrEqual
			toItem:self attribute:NSLayoutAttributeLeft
			multiplier:1 constant:insets.left
		]];
		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeRight
			relatedBy:NSLayoutRelationLessThanOrEqual
			toItem:self attribute:NSLayoutAttributeRight
			multiplier:1 constant:-insets.right
		]];

	} else if (horizontalAlignment == MMMLayoutHorizontalAlignmentRight) {

		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeRight
			relatedBy:NSLayoutRelationEqual
			toItem:self attribute:NSLayoutAttributeRight
			multiplier:1 constant:-insets.right
		]];

		// Again, it's not only the right edge should be pinned, but the left edge must be within this view as well.
		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeLeft
			relatedBy:NSLayoutRelationGreaterThanOrEqual
			toItem:self attribute:NSLayoutAttributeLeft
			multiplier:1 constant:insets.left
		]];

	} else if (horizontalAlignment == MMMLayoutHorizontalAlignmentFill) {

		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeLeft
			relatedBy:NSLayoutRelationEqual
			toItem:self attribute:NSLayoutAttributeLeft
			multiplier:1 constant:insets.left
		]];
		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeRight
			relatedBy:NSLayoutRelationEqual
			toItem:self attribute:NSLayoutAttributeRight
			multiplier:1 constant:-insets.right
		]];

	} else if (horizontalAlignment == MMMLayoutHorizontalAlignmentNone ) {

		// Don't need to add anything.

	} else {
		NSCAssert(NO, @"");
	}

	//
	// Vertical constraints.
	//
	if (verticalAlignment == MMMLayoutVerticalAlignmentTop) {

		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeTop
			relatedBy:NSLayoutRelationEqual
			toItem:self attribute:NSLayoutAttributeTop
			multiplier:1 constant:insets.top
		]];

		// Again, we pin the top, but ensuring the bottom is within this view.
		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeBottom
			relatedBy:NSLayoutRelationLessThanOrEqual
			toItem:self attribute:NSLayoutAttributeBottom
			multiplier:1 constant:-insets.bottom
		]];

	} else if (MMMLayoutUtilsIsKindOfCenterAlignment(MMMLayoutAlignmentFromVerticalAlignment(verticalAlignment))) {

		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeCenterY
			relatedBy:NSLayoutRelationEqual
			toItem:self attribute:NSLayoutAttributeCenterY
			multiplier:MMMLayoutUtilsMultiplierForAlignment(MMMLayoutAlignmentFromVerticalAlignment(verticalAlignment))
			constant:(insets.top - insets.bottom) * .5 // TODO: should not we use a multiplier as well?
		]];

		// Again, ensuring the subview stays within this view vertically.
		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeTop
			relatedBy:NSLayoutRelationGreaterThanOrEqual
			toItem:self attribute:NSLayoutAttributeTop
			multiplier:1 constant:insets.top
		]];
		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeBottom
			relatedBy:NSLayoutRelationLessThanOrEqual
			toItem:self attribute:NSLayoutAttributeBottom
			multiplier:1 constant:-insets.bottom
		]];

	} else if (verticalAlignment == MMMLayoutVerticalAlignmentBottom) {

		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeBottom
			relatedBy:NSLayoutRelationEqual
			toItem:self attribute:NSLayoutAttributeBottom
			multiplier:1 constant:-insets.bottom
		]];

		// The top can be anywhere, but should not stick out.
		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeTop
			relatedBy:NSLayoutRelationGreaterThanOrEqual
			toItem:self attribute:NSLayoutAttributeTop
			multiplier:1 constant:insets.top
		]];

	} else if (verticalAlignment == MMMLayoutVerticalAlignmentFill) {

		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeTop
			relatedBy:NSLayoutRelationEqual
			toItem:self attribute:NSLayoutAttributeTop
			multiplier:1 constant:insets.top
		]];

		[result addObject:[NSLayoutConstraint
			constraintWithItem:view attribute:NSLayoutAttributeBottom
			relatedBy:NSLayoutRelationEqual
			toItem:self attribute:NSLayoutAttributeBottom
			multiplier:1 constant:-insets.bottom
		]];

	} else if (verticalAlignment == MMMLayoutVerticalAlignmentNone) {

		// Don't need to add anything.

	} else {
		NSCAssert(NO, @"");
	}

	return result;
}

static NSArray<NSLayoutConstraint *> * _MMMConstraintsHorizontallyCentering(
	id viewOrGuide,
	id inViewOrGuide,
	CGFloat minPadding,
	CGFloat maxWidth
) {

	NSMutableArray *result = [[NSMutableArray alloc] init];

	NSDictionary *views = @{ @"view" : viewOrGuide };
	NSDictionary *metrics = @{ @"minPadding" : @(minPadding) };

	[result addObjectsFromArray:[NSLayoutConstraint
		constraintsWithVisualFormat:@"H:|-(>=minPadding,minPadding@249)-[view]-(>=minPadding,minPadding@249)-|"
		options:0 metrics:metrics views:views
		identifier:@"MMM-Text-SidePaddings"
	]];

	[result addObject:[NSLayoutConstraint
		constraintWithItem:viewOrGuide attribute:NSLayoutAttributeCenterX
		relatedBy:NSLayoutRelationEqual
		toItem:inViewOrGuide attribute:NSLayoutAttributeCenterX
		multiplier:1 constant:0
		identifier:@"MMM-Text-CenterX"
	]];

	if (maxWidth > 0) {
		[result addObject:[NSLayoutConstraint
			constraintWithItem:viewOrGuide attribute:NSLayoutAttributeWidth
			relatedBy:NSLayoutRelationLessThanOrEqual
			toItem:nil attribute:NSLayoutAttributeNotAnAttribute
			multiplier:1 constant:maxWidth
			identifier:@"MMM-Text-MaxWidth"
		]];
	}

	return result;
}


//
//
//
@implementation UILayoutGuide (MMMTempleMMMCommonUI)

- (id)initWithIdentifier:(NSString *)identifier {
	if (self = [super init]) {
		self.identifier = identifier;
	}
	return self;
}

- (NSArray<NSLayoutConstraint *> *)mmm_constraintsAligningView:(UIView *)view
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
	insets:(UIEdgeInsets)insets
{
	return _MMMConstraintsAligning(view, self, horizontalAlignment, verticalAlignment, insets);
}

- (NSArray<NSLayoutConstraint *> *)mmm_constraintsAligningGuide:(UILayoutGuide *)guide
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
	insets:(UIEdgeInsets)insets
{
	return _MMMConstraintsAligning(guide, self, horizontalAlignment, verticalAlignment, insets);
}

- (NSArray<NSLayoutConstraint *> *)mmm_constraintsHorizontallyCenteringView:(UIView *)view
	minPadding:(CGFloat)minPadding
	maxWidth:(CGFloat)maxWidth
{
	return _MMMConstraintsHorizontallyCentering(view, self, minPadding, maxWidth);
}

@end


#pragma mark - MMMSafeAreaLayoutGuide

/// A struct-like object to store some things related to mmm_safeAreaLayoutGuide on UIView.
@interface MMMSafeAreaLayoutGuideState : NSObject

@property (nonatomic, readwrite, weak) UILayoutGuide *layoutGuide;
@property (nonatomic, readwrite, weak) NSLayoutConstraint *top;
@property (nonatomic, readwrite, weak) NSLayoutConstraint *left;
@property (nonatomic, readwrite, weak) NSLayoutConstraint *bottom;
@property (nonatomic, readwrite, weak) NSLayoutConstraint *right;

@end

@implementation MMMSafeAreaLayoutGuideState
@end

//
//
//
@implementation UIView (MMMTempleMMMCommonUI)

static inline NSLayoutConstraint *_MMMSafeAreaLayoutGuideConstraint(UIView *view, UILayoutGuide *guide, NSLayoutAttribute attr) {
	NSLayoutConstraint *result = [NSLayoutConstraint
		constraintWithItem:guide attribute:attr
		relatedBy:NSLayoutRelationEqual
		toItem:view attribute:attr
		multiplier:1 constant:0
	];
	result.identifier = @"mmm_safeAreaLayoutGuide";
	result.active = YES;
	return result;
}

- (MMMSafeAreaLayoutGuideState *)_mmm_safeAreaLayoutGuideStateCreateIfNeeded:(BOOL)createIfNeeded {

	static const char * const key = "MMMSafeAreaLayoutGuideState";
	MMMSafeAreaLayoutGuideState *result = objc_getAssociatedObject(self, key);

	if (!result && createIfNeeded) {

		result = [[MMMSafeAreaLayoutGuideState alloc] init];
		objc_setAssociatedObject(self, key, result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

		UILayoutGuide *layoutGuide = [[UILayoutGuide alloc] init];
		layoutGuide.identifier = @"mmm_safeAreaLayoutGuide";
		[self addLayoutGuide:layoutGuide];
		result.layoutGuide = layoutGuide;

		result.top = _MMMSafeAreaLayoutGuideConstraint(self, layoutGuide, NSLayoutAttributeTop);
		result.left = _MMMSafeAreaLayoutGuideConstraint(self, layoutGuide, NSLayoutAttributeLeft);
		result.bottom = _MMMSafeAreaLayoutGuideConstraint(self, layoutGuide, NSLayoutAttributeBottom);
		result.right = _MMMSafeAreaLayoutGuideConstraint(self, layoutGuide, NSLayoutAttributeRight);

		// We need to be able to get `safeAreaInsetsDidChange`.
		static dispatch_once_t swizzleToken;
		dispatch_once(&swizzleToken, ^{
			Method oldMethod = class_getInstanceMethod(self.class, @selector(safeAreaInsetsDidChange));
			Method newMethod = class_getInstanceMethod(self.class, @selector(_mmm_safeAreaInsetsDidChange));
			method_exchangeImplementations(oldMethod, newMethod);
		});
	}

	return result;
}

- (UILayoutGuide *)mmm_safeAreaLayoutGuide {
	return [self _mmm_safeAreaLayoutGuideStateCreateIfNeeded:YES].layoutGuide;
}

static inline void MMMAdjustConstant(NSLayoutConstraint *c, CGFloat value) {
	CGFloat v = MMMPixelRound(value);
	// It has to be slightly larger than 1 / MMMPixelScale(), as single pixel variations will cause the oscillation.
	// However 2 / MMMPixelScale() would make it more coarse than necessary.
	const CGFloat eps = 1.5 / MMMPixelScale();
	if (fabs(c.constant - v) > eps) {
		c.constant = v;
	}
}

- (void)_mmm_safeAreaInsetsDidChange {

	MMMSafeAreaLayoutGuideState *state = [self _mmm_safeAreaLayoutGuideStateCreateIfNeeded:NO];
	if (state) {

		UIEdgeInsets insets = self.safeAreaInsets;

		MMMAdjustConstant(state.top, insets.top);
		MMMAdjustConstant(state.left, insets.left);
		MMMAdjustConstant(state.bottom, -insets.bottom);
		MMMAdjustConstant(state.right, -insets.right);

		//~ NSLog(@"_mmm_safeAreaInsetsDidChange: %@ vs %@", NSStringFromUIEdgeInsets(self.safeAreaInsets), NSStringFromUIEdgeInsets(self.mmm_safeAreaInsets));
	}

	[self _mmm_safeAreaInsetsDidChange];
}

- (UIEdgeInsets)mmm_safeAreaInsets {
	MMMSafeAreaLayoutGuideState *state = [self _mmm_safeAreaLayoutGuideStateCreateIfNeeded:NO];
	if (state) {
		return UIEdgeInsetsMake(state.top.constant, state.left.constant, -state.bottom.constant, -state.right.constant);
	} else {
		return self.safeAreaInsets;
	}
}

- (CGRect)mmm_rect {

	CGPoint anchorPoint = self.layer.anchorPoint;
	CGPoint center = self.center;
	CGRect bounds = self.bounds;
	return CGRectMake(
		center.x - anchorPoint.x * bounds.size.width,
		center.y - anchorPoint.y * bounds.size.height,
		bounds.size.width,
		bounds.size.height
	);
}

- (void)mmm_setRect:(CGRect)frame {

	CGPoint anchorPoint = self.layer.anchorPoint;
	self.center = CGPointMake(
		frame.origin.x + anchorPoint.x * frame.size.width,
		frame.origin.y + anchorPoint.y * frame.size.height
	);

	CGRect bounds = self.bounds;
	self.bounds = CGRectMake(bounds.origin.x, bounds.origin.y, frame.size.width, frame.size.height);
}

#pragma mark -

- (CGSize)mmm_size {
	return self.bounds.size;
}

- (void)mmm_setSize:(CGSize)size {
	CGRect b = self.bounds;
	b.size = size;
	self.bounds = b;
}

#pragma mark -

- (NSArray *)mmm_constraintsAligningView:(UIView *)view
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
	insets:(UIEdgeInsets)insets
{
	return _MMMConstraintsAligning(view, self, horizontalAlignment, verticalAlignment, insets);
}

- (NSArray *)mmm_constraintsAligningView:(UIView *)subview
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
{
	return [self mmm_constraintsAligningView:subview horizontally:horizontalAlignment vertically:MMMLayoutVerticalAlignmentNone insets:UIEdgeInsetsZero];
}

- (NSArray *)mmm_constraintsAligningView:(UIView *)subview
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
{
	return [self mmm_constraintsAligningView:subview horizontally:MMMLayoutHorizontalAlignmentNone vertically:verticalAlignment insets:UIEdgeInsetsZero];
}

- (NSArray<NSLayoutConstraint *> *)mmm_constraintsAligningGuide:(UILayoutGuide *)guide
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
	insets:(UIEdgeInsets)insets
{
	return _MMMConstraintsAligning(guide, self, horizontalAlignment, verticalAlignment, insets);
}

#pragma mark -

- (NSArray *)mmm_addConstraintsAligningView:(UIView *)view
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
	insets:(UIEdgeInsets)insets
{
	NSArray *result = [self mmm_constraintsAligningView:view horizontally:horizontalAlignment vertically:verticalAlignment insets:insets];
	[NSLayoutConstraint activateConstraints:result];
	return result;
}

- (NSArray *)mmm_addConstraintsAligningView:(UIView *)view
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
{
	return [self
		mmm_addConstraintsAligningView:view
		horizontally:horizontalAlignment
		vertically:verticalAlignment
		insets:UIEdgeInsetsZero
	];
}

- (NSArray *)mmm_addConstraintsAligningView:(UIView *)subview
	horizontally:(MMMLayoutHorizontalAlignment)horizontalAlignment
{
	return [self
		mmm_addConstraintsAligningView:subview
		horizontally:horizontalAlignment
		vertically:MMMLayoutVerticalAlignmentNone
		insets:UIEdgeInsetsZero
	];
}

- (NSArray *)mmm_addConstraintsAligningView:(UIView *)subview
	vertically:(MMMLayoutVerticalAlignment)verticalAlignment
{
	return [self
		mmm_addConstraintsAligningView:subview
		horizontally:MMMLayoutHorizontalAlignmentNone
		vertically:verticalAlignment
		insets:UIEdgeInsetsZero
	];
}

#pragma mark -

- (NSArray<NSLayoutConstraint *> *)mmm_constraintsHorizontallyCenteringView:(UIView *)view
	minPadding:(CGFloat)minPadding
	maxWidth:(CGFloat)maxWidth
{
	return _MMMConstraintsHorizontallyCentering(view, self, minPadding, maxWidth);
}

- (void)mmm_addConstraintsHorizontallyCenteringView:(UIView *)view
	minPadding:(CGFloat)minPadding
	maxWidth:(CGFloat)maxWidth
{
	[NSLayoutConstraint activateConstraints:[self
		mmm_constraintsHorizontallyCenteringView:view
		minPadding:minPadding
		maxWidth:maxWidth
	]];
}

- (void)mmm_addConstraintsHorizontallyCenteringView:(UIView *)view
	minPadding:(CGFloat)minPadding
{
	[self mmm_addConstraintsHorizontallyCenteringView:view minPadding:minPadding maxWidth:0];
}

#pragma mark - Old versions of the helper functions

- (MMMLayoutHorizontalAlignment)horizontalAlignmentFromContentAlignment:(UIControlContentHorizontalAlignment)alignment {
	switch (alignment) {
		case UIControlContentHorizontalAlignmentLeft:
			return MMMLayoutHorizontalAlignmentLeft;
		case UIControlContentHorizontalAlignmentCenter:
			return MMMLayoutHorizontalAlignmentCenter;
		case UIControlContentHorizontalAlignmentRight:
			return MMMLayoutHorizontalAlignmentRight;
		case UIControlContentHorizontalAlignmentFill:
			return MMMLayoutHorizontalAlignmentFill;
		default:
			NSAssert(NO, @"The alignment flag is not supported: %ld", (long)alignment);
			return MMMLayoutHorizontalAlignmentFill;
	}
}

- (MMMLayoutVerticalAlignment)verticalAlignmentFromContentAlignment:(UIControlContentVerticalAlignment)alignment {
	switch (alignment) {
		case UIControlContentVerticalAlignmentTop:
			return MMMLayoutVerticalAlignmentTop;
		case UIControlContentVerticalAlignmentCenter:
			return MMMLayoutVerticalAlignmentCenter;
		case UIControlContentVerticalAlignmentBottom:
			return MMMLayoutVerticalAlignmentBottom;
		case UIControlContentVerticalAlignmentFill:
			return MMMLayoutVerticalAlignmentFill;
	}
}

- (NSArray *)mmm_addConstraintsForSubview:(UIView *)subview
	horizontalAlignment:(UIControlContentHorizontalAlignment)horizontalAlignment
	verticalAlignment:(UIControlContentVerticalAlignment)verticalAlignment
	insets:(UIEdgeInsets)insets
{
	NSArray *result = [self
		mmm_addConstraintsAligningView:subview
		horizontally:[self horizontalAlignmentFromContentAlignment:horizontalAlignment]
		vertically:[self verticalAlignmentFromContentAlignment:verticalAlignment]
		insets:insets
	];
	return result;
}

- (NSArray *)mmm_addConstraintsForSubview:(UIView *)subview
	horizontalAlignment:(UIControlContentHorizontalAlignment)horizontalAlignment
	verticalAlignment:(UIControlContentVerticalAlignment)verticalAlignment
{
	return [self mmm_addConstraintsForSubview:subview horizontalAlignment:horizontalAlignment verticalAlignment:verticalAlignment insets:UIEdgeInsetsZero];
}

#pragma mark -

- (void)mmm_addVerticalSpaceRatioConstraintsForSubview:(UIView *)subview
	topItem:(id)topItem topAttribute:(NSLayoutAttribute)topAttribute
	bottomItem:(id)bottomItem bottomAttribute:(NSLayoutAttribute)bottomAttribute
	ratio:(CGFloat)ratio
{
	[self
		mmm_addVerticalSpaceRatioConstraintsForSubview:subview
		topItem:topItem topAttribute:topAttribute
		bottomItem:bottomItem bottomAttribute:bottomAttribute
		ratio:ratio priority:UILayoutPriorityDefaultHigh
	];
}

- (void)mmm_addVerticalSpaceRatioConstraintsForSubview:(UIView *)subview
	topItem:(id)topItem topAttribute:(NSLayoutAttribute)topAttribute
	bottomItem:(id)bottomItem bottomAttribute:(NSLayoutAttribute)bottomAttribute
	ratio:(CGFloat)ratio
	priority:(UILayoutPriority)priority
{
	NSAssert(
		topAttribute == NSLayoutAttributeBottom || topAttribute == NSLayoutAttributeCenterY || topAttribute == NSLayoutAttributeTop || bottomAttribute == NSLayoutAttributeBottom || bottomAttribute == NSLayoutAttributeCenterY || bottomAttribute == NSLayoutAttributeTop,
		@"We expect vertical attributes here"
	);

	// We need these auxiliary views because before iOS 9 we can define constraints for views only.
	MMMSpacerView *topSpacer = [[MMMSpacerView alloc] init];
	[self addSubview:topSpacer];
	MMMSpacerView *bottomSpacer = [[MMMSpacerView alloc] init];
	[self addSubview:bottomSpacer];

	// So the height of the spacers should be in the required proportion.
	[self addConstraint:[NSLayoutConstraint
		constraintWithItem:topSpacer attribute:NSLayoutAttributeHeight
		relatedBy:NSLayoutRelationEqual
		toItem:bottomSpacer attribute:NSLayoutAttributeHeight
		multiplier:ratio constant:0
		priority:priority
	]];

	// Let's anchor the aux views to the top and bottom items.
	[self addConstraint:[NSLayoutConstraint
		constraintWithItem:topSpacer attribute:NSLayoutAttributeTop
		relatedBy:NSLayoutRelationEqual
		toItem:topItem attribute:topAttribute
		multiplier:1 constant:0
	]];
	[self addConstraint:[NSLayoutConstraint
		constraintWithItem:bottomSpacer attribute:NSLayoutAttributeBottom
		relatedBy:NSLayoutRelationEqual
		toItem:bottomItem attribute:bottomAttribute
		multiplier:1 constant:0
	]];

	// And let's anchor the subview to the spacers.
	[self addConstraint:[NSLayoutConstraint
		constraintWithItem:subview attribute:NSLayoutAttributeTop
		relatedBy:NSLayoutRelationEqual
		toItem:topSpacer attribute:NSLayoutAttributeBottom
		multiplier:1 constant:0
	]];
	[self addConstraint:[NSLayoutConstraint
		constraintWithItem:subview attribute:NSLayoutAttributeBottom
		relatedBy:NSLayoutRelationEqual
		toItem:bottomSpacer attribute:NSLayoutAttributeTop
		multiplier:1 constant:0
	]];
}

- (void)mmm_addVerticalSpaceRatioConstraintsForSubview:(UIView *)subview
	item:(id)item attribute:(NSLayoutAttribute)attribute
	ratio:(CGFloat)ratio
{
	MMMSpacerView *topSpacer = [[MMMSpacerView alloc] init];
	[self addSubview:topSpacer];

	[self addConstraint:[NSLayoutConstraint
		constraintWithItem:topSpacer attribute:NSLayoutAttributeHeight
		relatedBy:NSLayoutRelationEqual
		toItem:subview attribute:NSLayoutAttributeHeight
		multiplier:ratio constant:0
	]];
	[self addConstraint:[NSLayoutConstraint
		constraintWithItem:topSpacer attribute:NSLayoutAttributeBottom
		relatedBy:NSLayoutRelationEqual
		toItem:item attribute:attribute
		multiplier:1 constant:0
	]];

	[self addConstraint:[NSLayoutConstraint
		constraintWithItem:topSpacer attribute:NSLayoutAttributeTop
		relatedBy:NSLayoutRelationEqual
		toItem:subview attribute:NSLayoutAttributeTop
		multiplier:1 constant:0
	]];
}

- (void)mmm_setVerticalCompressionResistance:(UILayoutPriority)priority {
	[self setContentCompressionResistancePriority:priority forAxis:UILayoutConstraintAxisVertical];
}

- (void)mmm_setHorizontalCompressionResistance:(UILayoutPriority)priority {
	[self setContentCompressionResistancePriority:priority forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)mmm_setVerticalHuggingPriority:(UILayoutPriority)priority {
	[self setContentHuggingPriority:priority forAxis:UILayoutConstraintAxisVertical];
}

- (void)mmm_setHorizontalHuggingPriority:(UILayoutPriority)priority {
	[self setContentHuggingPriority:priority forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)mmm_setVerticalCompressionResistance:(UILayoutPriority)compressionResistance hugging:(UILayoutPriority)hugging {
	[self setContentCompressionResistancePriority:compressionResistance forAxis:UILayoutConstraintAxisVertical];
	[self setContentHuggingPriority:hugging forAxis:UILayoutConstraintAxisVertical];
}

- (void)mmm_setHorizontalCompressionResistance:(UILayoutPriority)compressionResistance hugging:(UILayoutPriority)hugging {
	[self setContentCompressionResistancePriority:compressionResistance forAxis:UILayoutConstraintAxisHorizontal];
	[self setContentHuggingPriority:hugging forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)mmm_setCompressionResistanceHorizontal:(UILayoutPriority)horizontal vertical:(UILayoutPriority)vertical {
	[self setContentCompressionResistancePriority:horizontal forAxis:UILayoutConstraintAxisHorizontal];
	[self setContentCompressionResistancePriority:vertical forAxis:UILayoutConstraintAxisVertical];
}

- (void)mmm_setHuggingHorizontal:(UILayoutPriority)horizontal vertical:(UILayoutPriority)vertical {
	[self setContentHuggingPriority:horizontal forAxis:UILayoutConstraintAxisHorizontal];
	[self setContentHuggingPriority:vertical forAxis:UILayoutConstraintAxisVertical];
}

@end

//
//
//
@implementation NSLayoutConstraint (MMMTempleMMMCommonUI)

static inline NSLayoutAttribute _MMMOppositeAttribute(NSLayoutAttribute a) {
	switch (a) {
		case NSLayoutAttributeLeft:
			return NSLayoutAttributeRight;
    	case NSLayoutAttributeRight:
    		return NSLayoutAttributeLeft;
		case NSLayoutAttributeLeading:
			return NSLayoutAttributeTrailing;
		case NSLayoutAttributeTrailing:
			return NSLayoutAttributeLeading;
    	case NSLayoutAttributeTop:
    		return NSLayoutAttributeBottom;
    	case NSLayoutAttributeBottom:
    		return NSLayoutAttributeTop;
		// These two are special cases, we see them when align all X or Y flags are used.
		case NSLayoutAttributeCenterY:
			return NSLayoutAttributeCenterY;
		case NSLayoutAttributeCenterX:
			return NSLayoutAttributeCenterX;
		// Nothing more.
    	default:
    		NSCAssert(NO, @"We don't expect other attributes here");
    		return a;
	}
}

static inline UIView *_MMMSuperviewOrOwningView(id viewOrGuide) {
	if ([viewOrGuide isKindOfClass:[UILayoutGuide class]]) {
		return [(UILayoutGuide *)viewOrGuide owningView];
	} else if ([viewOrGuide isKindOfClass:[UIView class]]) {
		return [(UIView *)viewOrGuide superview];
	} else {
		NSCAssert(NO, @"Expected a view or a layout guide, got %@", NSStringFromClass(viewOrGuide));
		return nil;
	}
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

+(NSArray<NSLayoutConstraint *> *)mmm_constraintsWithVisualFormat:(NSString *)format
	options:(NSLayoutFormatOptions)opts
	metrics:(NSDictionary<NSString *,id> *)metrics
	views:(NSDictionary<NSString *,id> *)views
{
	if ([format rangeOfString:@"<|"].location == NSNotFound && [format rangeOfString:@"|>"].location == NSNotFound) {
		// No traces of our special symbol, so do nothing special.
		return [self constraintsWithVisualFormat:format options:opts metrics:metrics views:views];
	}

	if (![UIView instancesRespondToSelector:@selector(safeAreaLayoutGuide)]) {
		// Before iOS 11 simply use the edges of the corresponding superview.
		NSString *actualFormat = [format stringByReplacingOccurrencesOfString:@"<|" withString:@"|"];
		actualFormat = [actualFormat stringByReplacingOccurrencesOfString:@"|>" withString:@"|"];
		return [NSLayoutConstraint constraintsWithVisualFormat:actualFormat options:opts metrics:metrics views:views];
	}

	//
	// OK, iOS 11+ time.
	// For simplicity we replace our special symbols with a reference to a stub view, feed the updated format string
	// to the system, and then replace every reference to our stub view with a corresponding reference to safeAreaLayoutGuide.
	//

	UIView *stub = [[UIView alloc] init];
	static NSString * const stubKey = @"__MMMLayoutStub";
	NSString *stubKeyRef = [NSString stringWithFormat:@"[%@]", stubKey];
	NSDictionary *extendedViews = [@{ stubKey : stub } mmm_extendedWithDictionary:views];

	NSString *actualFormat = [format stringByReplacingOccurrencesOfString:@"<|" withString:stubKeyRef];
	actualFormat = [actualFormat stringByReplacingOccurrencesOfString:@"|>" withString:stubKeyRef];

	NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:actualFormat options:opts metrics:metrics views:extendedViews];

	NSMutableArray *processedConstraints = [[NSMutableArray alloc] init];
	for (NSLayoutConstraint *c in constraints) {
		UIView *firstView = c.firstItem;
		UIView *secondView = c.secondItem;
		NSLayoutConstraint *processed;
		if (firstView == stub) {
			processed = [self
				constraintWithItem:_MMMSuperviewOrOwningView(secondView).mmm_safeAreaLayoutGuide attribute:_MMMOppositeAttribute(c.firstAttribute)
				relatedBy:c.relation
				toItem:secondView attribute:c.secondAttribute
				multiplier:c.multiplier constant:c.constant
				priority:c.priority
				identifier:@"mmm_constraintsWithVisualFormat-first"
			];
		} else if (secondView == stub) {
			processed = [self
				constraintWithItem:firstView attribute:c.firstAttribute
				relatedBy:c.relation
				toItem:_MMMSuperviewOrOwningView(firstView).mmm_safeAreaLayoutGuide attribute:_MMMOppositeAttribute(c.secondAttribute)
				multiplier:c.multiplier constant:c.constant
				priority:c.priority
				identifier:@"mmm_constraintsWithVisualFormat-second"
			];
		} else {
			processed = c;
		}
		[processedConstraints addObject:processed];
	}

	return processedConstraints;
}

#pragma clang diagnostic pop

+ (void)mmm_activateConstraintsWithVisualFormat:(NSString *)format
	options:(NSLayoutFormatOptions)opts
	metrics:(NSDictionary<NSString *,id> *)metrics
	views:(NSDictionary<NSString *,id> *)views
{
	[self activateConstraints:[self mmm_constraintsWithVisualFormat:format options:opts metrics:metrics views:views]];
}

+ (void)activateConstraint:(NSLayoutConstraint *)constraint {
	[constraint setActive:YES];
}

+ (void)deactivateConstraint:(NSLayoutConstraint *)constraint {
	[constraint setActive:NO];
}

+ (instancetype)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attr1
	relatedBy:(NSLayoutRelation)relation
	toItem:(id)view2 attribute:(NSLayoutAttribute)attr2
	multiplier:(CGFloat)multiplier constant:(CGFloat)c
	priority:(UILayoutPriority)priority
{
	NSLayoutConstraint *result = [NSLayoutConstraint constraintWithItem:view1 attribute:attr1 relatedBy:relation toItem:view2 attribute:attr2 multiplier:multiplier constant:c];
	result.priority = priority;
	return result;
}

+ (instancetype)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attr1
	relatedBy:(NSLayoutRelation)relation
	toItem:(id)view2 attribute:(NSLayoutAttribute)attr2
	multiplier:(CGFloat)multiplier constant:(CGFloat)c
	identifier:(NSString *)identifier
{
	NSLayoutConstraint *result = [NSLayoutConstraint constraintWithItem:view1 attribute:attr1 relatedBy:relation toItem:view2 attribute:attr2 multiplier:multiplier constant:c];
	result.identifier = identifier;
	return result;
}

+ (instancetype)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attr1
	relatedBy:(NSLayoutRelation)relation
	toItem:(id)view2 attribute:(NSLayoutAttribute)attr2
	multiplier:(CGFloat)multiplier constant:(CGFloat)c
	priority:(UILayoutPriority)priority
	identifier:(NSString *)identifier
{
	NSLayoutConstraint *result = [NSLayoutConstraint constraintWithItem:view1 attribute:attr1 relatedBy:relation toItem:view2 attribute:attr2 multiplier:multiplier constant:c priority:priority];
	result.identifier = identifier;
	return result;
}

+ (NSArray<__kindof NSLayoutConstraint *> *)constraintsWithVisualFormat:(NSString *)format
	options:(NSLayoutFormatOptions)opts
	metrics:(NSDictionary<NSString *,id> *)metrics
	views:(NSDictionary<NSString *, id> *)views
	identifier:(NSString *)identifier
 {
	NSArray *result = [self constraintsWithVisualFormat:format options:opts metrics:metrics views:views];
	for (NSLayoutConstraint *c in result) {
		c.identifier = identifier;
	}
	return result;
}

@end

NSDictionary<NSString *, NSNumber *> *MMMDictionaryFromUIEdgeInsets(NSString *prefix, UIEdgeInsets insets) {
	NSCAssert(prefix != nil, @"");
	return @{
		[prefix stringByAppendingString:@"Top"] : @(insets.top),
		[prefix stringByAppendingString:@"Left"] : @(insets.left),
		[prefix stringByAppendingString:@"Bottom"] : @(insets.bottom),
		[prefix stringByAppendingString:@"Right"] : @(insets.right)
	};
}

//
//
//
@implementation MMMStackContainer {
	UIEdgeInsets _insets;
	MMMLayoutAlignment _alignment;
	MMMLayoutDirection _direction;
	CGFloat _spacing;
	NSMutableArray<UIView *> *_managedSubviews;
}

// Needed to behave well when nothing is added into the stack yet.
+ (BOOL)requiresConstraintBasedLayout {
	return YES;
}

- (id)initWithDirection:(MMMLayoutDirection)direction
	insets:(UIEdgeInsets)insets
	alignment:(MMMLayoutAlignment)alignment
	spacing:(CGFloat)spacing
{
	if (self = [super initWithFrame:CGRectZero]) {

		self.translatesAutoresizingMaskIntoConstraints = NO;

		_direction = direction;
		_insets = insets;
		_alignment = alignment;
		_spacing = spacing;
	}

	return self;
}

- (void)addSubview:(UIView *)view {
	NSAssert(NO, @"%@ allows to set subviews via %s only", self.class, sel_getName(@selector(setSubviews:)));
}

/** Potentially can replace this with a predicate, so different spacings can be set between items of different kinds. */
- (CGFloat)spacingBetweenItem:(UIView *)item1 andItem:(UIView *)item2 {
	return _spacing;
}

- (NSLayoutAttribute)leadingAttribute {
	return (_direction == MMMLayoutDirectionHorizontal) ? NSLayoutAttributeLeft : NSLayoutAttributeTop;
}

- (NSLayoutAttribute)oppositeDirectionLeadingAttribute {
	return (_direction == MMMLayoutDirectionHorizontal) ? NSLayoutAttributeTop : NSLayoutAttributeLeft;
}

- (NSLayoutAttribute)trailingAttribute {
	return (_direction == MMMLayoutDirectionHorizontal) ? NSLayoutAttributeRight : NSLayoutAttributeBottom;
}

- (NSLayoutAttribute)oppositeDirectionTrailingAttribute {
	return (_direction == MMMLayoutDirectionHorizontal) ? NSLayoutAttributeBottom : NSLayoutAttributeRight;
}

- (NSLayoutAttribute)centerAttribute {
	return (_direction == MMMLayoutDirectionHorizontal) ? NSLayoutAttributeCenterX : NSLayoutAttributeCenterY;
}

- (NSLayoutAttribute)oppositeDirectionCenterAttribute {
	return (_direction == MMMLayoutDirectionHorizontal) ? NSLayoutAttributeCenterY : NSLayoutAttributeCenterX;
}

- (CGFloat)leadingInset {
	return (_direction == MMMLayoutDirectionHorizontal) ? _insets.left : _insets.top;
}

- (CGFloat)oppositeLeadingInset {
	return (_direction == MMMLayoutDirectionHorizontal) ? _insets.top : _insets.left;
}

- (CGFloat)trailingInset {
	return (_direction == MMMLayoutDirectionHorizontal) ? _insets.right : _insets.bottom;
}

- (CGFloat)oppositeTrailingInset {
	return (_direction == MMMLayoutDirectionHorizontal) ? _insets.bottom : _insets.right;
}

- (void)setSubviews:(NSArray<UIView *> *)subviews {

	if ([_managedSubviews isEqualToArray:subviews]) {
		// This allows the user to rebuild the list of subviews without worrying about performance.
		return;
	}

	for (UIView *subview in _managedSubviews) {
		[subview removeFromSuperview];
	}
	_managedSubviews = [[NSMutableArray alloc] initWithArray:subviews];

	BOOL pinLeading = (_alignment == MMMLayoutAlignmentLeading) || (_alignment == MMMLayoutAlignmentFill);
	BOOL pinTrailing = (_alignment == MMMLayoutAlignmentTrailing) || (_alignment == MMMLayoutAlignmentFill);

	UIView *prevItem = nil;

	for (UIView *v in subviews) {

		[super addSubview:v];

		// Opposite direction leading.
		if (pinLeading) {
			[self addConstraint:[NSLayoutConstraint
				constraintWithItem:v attribute:[self oppositeDirectionLeadingAttribute]
				relatedBy:NSLayoutRelationEqual
				toItem:self attribute:[self oppositeDirectionLeadingAttribute]
				multiplier:1 constant:[self oppositeLeadingInset]
				priority:UILayoutPriorityRequired
				identifier:@"MMM-OppositeLeading-Pin"
			]];
		} else {
			[self addConstraint:[NSLayoutConstraint
				constraintWithItem:v attribute:[self oppositeDirectionLeadingAttribute]
				relatedBy: NSLayoutRelationGreaterThanOrEqual
				toItem:self attribute:[self oppositeDirectionLeadingAttribute]
				multiplier:1 constant:[self oppositeLeadingInset]
				identifier:@"MMM-OppositeLeading-DoublePin"
			]];
			[self addConstraint:[NSLayoutConstraint
				constraintWithItem:v attribute:[self oppositeDirectionLeadingAttribute]
				relatedBy:NSLayoutRelationEqual
				toItem:self attribute:[self oppositeDirectionLeadingAttribute]
				multiplier:1 constant:[self oppositeLeadingInset]
				priority:UILayoutPriorityDefaultLow - 1
				identifier:@"MMM-OppositeLeading-DoublePin"
			]];
		}

		// Opposite direction trailing.
		if (pinTrailing) {
			[self addConstraint:[NSLayoutConstraint
				constraintWithItem:v attribute:[self oppositeDirectionTrailingAttribute]
				relatedBy:NSLayoutRelationEqual
				toItem:self attribute:[self oppositeDirectionTrailingAttribute]
				multiplier:1 constant:-[self oppositeTrailingInset]
				priority:UILayoutPriorityRequired
				identifier:@"MMM-OppositeTrailing-Pin"
			]];
		} else {
			[self addConstraint:[NSLayoutConstraint
				constraintWithItem:v attribute:[self oppositeDirectionTrailingAttribute]
				relatedBy:NSLayoutRelationLessThanOrEqual
				toItem:self attribute:[self oppositeDirectionTrailingAttribute]
				multiplier:1 constant:-[self oppositeTrailingInset]
				identifier:@"MMM-OppositeTrailing-DoublePin"
			]];
			[self addConstraint:[NSLayoutConstraint
				constraintWithItem:v attribute:[self oppositeDirectionTrailingAttribute]
				relatedBy:NSLayoutRelationEqual
				toItem:self attribute:[self oppositeDirectionTrailingAttribute]
				multiplier:1 constant:-[self oppositeTrailingInset]
				priority:UILayoutPriorityDefaultLow - 1
				identifier:@"MMM-OppositeTrailing-DoublePin"
			]];
		}

		// Opposite direction center, if needed
		if (_alignment == MMMLayoutHorizontalAlignmentCenter) {
			[self addConstraint:[NSLayoutConstraint
				constraintWithItem:v attribute:[self oppositeDirectionCenterAttribute]
				relatedBy:NSLayoutRelationEqual
				toItem:self attribute:[self oppositeDirectionCenterAttribute]
				multiplier:1 constant:0
				identifier:@"MMM-OppositeCenter"
			]];
		}

		// Leading
		if (!prevItem) {
			// This is the topmost item, should be pinned to the top taking into account insets
			[self addConstraint:[NSLayoutConstraint
				constraintWithItem:v attribute:[self leadingAttribute]
				relatedBy:NSLayoutRelationEqual
				toItem:self attribute:[self leadingAttribute]
				multiplier:1 constant:[self leadingInset]
				identifier:@"MMM-First"
			]];
		} else {
			[self addConstraint:[NSLayoutConstraint
				constraintWithItem:v attribute:[self leadingAttribute]
				relatedBy:NSLayoutRelationEqual
				toItem:prevItem attribute:[self trailingAttribute]
				multiplier:1 constant:[self spacingBetweenItem:prevItem andItem:v]
				identifier:@"MMM-Spacer"
			]];
		}

		prevItem = v;
	}

	// Don't forget to pin the bottom of the last item
	if (prevItem) {
		[self addConstraint:[NSLayoutConstraint
			constraintWithItem:prevItem attribute:[self trailingAttribute]
			relatedBy:NSLayoutRelationEqual
			toItem:self attribute:[self trailingAttribute]
			multiplier:1 constant:-[self trailingInset]
			identifier:@"MMM-Last"
		]];
	}
}

@end

//
//
//
@implementation MMMVerticalStackContainer

- (id)initWithInsets:(UIEdgeInsets)insets
	alignment:(MMMLayoutHorizontalAlignment)alignment
	spacing:(CGFloat)spacing
{
	return [super
		initWithDirection:MMMLayoutDirectionVertical
		insets:insets
		alignment:MMMLayoutAlignmentFromHorizontalAlignment(alignment)
		spacing:spacing
	];
}

@end

@implementation MMMHorizontalStackContainer

- (id)initWithInsets:(UIEdgeInsets)insets
	alignment:(MMMLayoutVerticalAlignment)alignment
	spacing:(CGFloat)spacing
{
	return [super
		initWithDirection:MMMLayoutDirectionHorizontal
		insets:insets
		alignment:MMMLayoutAlignmentFromVerticalAlignment(alignment)
		spacing:spacing
	];
}

@end

//
//
//
@implementation MMMAutoLayoutIsolator

- (id)initWithView:(UIView *)view {

	if (self = [super initWithFrame:CGRectZero]) {

		super.translatesAutoresizingMaskIntoConstraints = NO;

		_view = view;
		_view.translatesAutoresizingMaskIntoConstraints = NO;
		[super addSubview:_view];
	}

	return self;
}

- (void)setTranslatesAutoresizingMaskIntoConstraints:(BOOL)translatesAutoresizingMaskIntoConstraints {
	NSAssert(NO, @"Don't change translatesAutoresizingMaskIntoConstraints in %@", self.class);
}

- (void)addSubview:(UIView *)view {
	NSAssert(NO, @"Don't add subviews into %@ directly", self.class);
}

- (void)layoutSubviews {
	[super layoutSubviews];
	CGSize s = self.bounds.size;
	_view.frame = CGRectMake(0, 0, s.width, s.height);
}

- (CGSize)sizeThatFits:(CGSize)size {
	// TODO: not sure about default fitting priorities here, can imagine they can make a difference sometimes
	CGSize result = [_view
		systemLayoutSizeFittingSize:size
		withHorizontalFittingPriority:size.width < 1 ? UILayoutPriorityDefaultHigh - 1 : UILayoutPriorityFittingSizeLevel
		verticalFittingPriority:size.height < 1 ? UILayoutPriorityDefaultHigh - 1 : UILayoutPriorityFittingSizeLevel
	];
	return MMMIntegralSize(result);
}

// Well, can have it compatible a bit with Auto Layout world too.
- (CGSize)intrinsicContentSize {
	return [self sizeThatFits:CGSizeZero];
}

@end

//
//
//
@implementation MMMPaddedView

- (id)initWithView:(UIView *)view insets:(UIEdgeInsets)insets {

	if (self = [super initWithFrame:CGRectZero]) {

		_view = view;
		_insets = insets;

		self.translatesAutoresizingMaskIntoConstraints = NO;

		[super addSubview:_view];

		[self
			mmm_addConstraintsAligningView:_view
			horizontally:MMMLayoutHorizontalAlignmentFill
			vertically:MMMLayoutVerticalAlignmentFill
			insets:_insets
		];
	}

	return self;
}

- (void)addSubview:(UIView *)view {
	NSAssert(NO, @"You are not supposed to add any subviews into %@", self.class);
}

@end
