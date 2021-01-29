//
// MMMHorizontalPicker.
// Copyright (C) 2016-2021 MediaMonks. All rights reserved.
//

#import "MMMHorizontalPicker.h"

@import MMMCommonUI;

/** 
 */
@interface MMMHorizontalPickerItemContainer : UIView

@property (nonatomic, readonly) UIView *view;

- (void)invalidateCachedViewSize;

- (id)initWithView:(UIView *)view NS_DESIGNATED_INITIALIZER;

- (id)init NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

@implementation MMMHorizontalPickerItemContainer {
	CGFloat _heightUsedForCachedViewSize;
	CGSize _cachedViewSize;
}

- (id)initWithView:(UIView *)view {

	if (self = [super initWithFrame:CGRectZero]) {

		_view = view;
		[self addSubview:_view];

		[self
			mmm_addConstraintsAligningView:_view
			horizontally:MMMLayoutHorizontalAlignmentFill
			vertically:MMMLayoutVerticalAlignmentFill
		];

		_cachedViewSize = CGSizeZero;
	}

	return self;
}

- (CGSize)sizeThatFits:(CGSize)size {

	if (CGSizeEqualToSize(_cachedViewSize, CGSizeZero) || size.height != _heightUsedForCachedViewSize) {
		_cachedViewSize = [_view
			systemLayoutSizeFittingSize:size
			withHorizontalFittingPriority:UILayoutPriorityFittingSizeLevel
			verticalFittingPriority:UILayoutPriorityDefaultHigh + 1
		];
		_heightUsedForCachedViewSize = size.height;
	}

	return _cachedViewSize;
}

- (void)invalidateCachedViewSize {
	_cachedViewSize = CGSizeZero;
	_heightUsedForCachedViewSize = 0;
}

@end

//
//
//
@interface  MMMHorizontalPicker () <UIGestureRecognizerDelegate>
@end

@implementation MMMHorizontalPicker {

	// This is the current position of the picker's viewport relative to item indices, not pixels,
	// e.g. 9.8 would mean that the center of the viewport is between items #9 and #10, closer to #10.
	// Having the position defined this way allows, among other things, to change widths of the items
	// without changing the current position.
	CGFloat _viewportPosition;

	// When the _viewportPosition is changed with an animation now, then this will its handle.
	MMMAnimationHandle *_viewportPositionAnimation;

	// The current position of the horizontal center of the viewport relative to the bounds of this view.
	// This is used only while in the `render` method.
	CGFloat _viewportPositionReal;

	// The total number of items. Getting this only once per reload.
	NSInteger _numberOfItems;

	// The range of items we care about now: the ones that are visible or can become visible very soon.
	NSRange _visibleRange;

	// Views corresponding to items within _visibleRange, i.e. _visibleView.count == _visibleRange.length.
	NSMutableArray<MMMHorizontalPickerItemContainer *> *_visibleViews;

	BOOL _dragging;
	CGFloat _dragOffset;
	UIPanGestureRecognizer *_panGestureRecognizer;
	
	BOOL _delegateRespondsToUpdateView;
	BOOL _delegateRespondsToScroll;

	CGFloat _uniformWidth;
}

- (id)init {
	return [self initWithStyle:MMMHorizontalPickerStyleDefault];
}

- (id)initWithStyle:(MMMHorizontalPickerStyle)style {

	if (self = [super initWithFrame:CGRectZero]) {

		_style = style;
		_uniformWidth = 0;

		self.translatesAutoresizingMaskIntoConstraints = NO;
        
		self.clipsToBounds = NO;

		_visibleRange = NSMakeRange(0, 0);
		_visibleViews = [[NSMutableArray alloc] init];

		_panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerDidChange:)];
		_panGestureRecognizer.delegate = self;
		[self addGestureRecognizer:_panGestureRecognizer];
	}

	return self;
}

- (void)layoutSubviews {

	[super layoutSubviews];

	[self render];

	[super layoutSubviews];
}

- (void)setDelegate:(id<MMMHorizontalPickerDelegate>)delegate {

	[self recyleEverything];

	_delegate = delegate;
	_numberOfItems = 0;
	
	_delegateRespondsToUpdateView = [_delegate respondsToSelector:@selector(horizontalPicker:updateView:centerProximity:)];
	_delegateRespondsToScroll = [_delegate respondsToSelector:@selector(horizontalPicker:didScroll:)];
	
	[self reload];
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets {

	if (!UIEdgeInsetsEqualToEdgeInsets(_contentInsets, contentInsets)) {
		_contentInsets = contentInsets;
		[self setNeedsRender];
	}
}

- (void)reload {

	BOOL wasAnimating = _viewportPositionAnimation.inProgress;
	[self cancelViewportPositionAnimation];

	[self recyleEverything];

	_numberOfItems = [_delegate numberOfItemsForHorizontalPicker:self];

	if (_dragging) {
		[self setNeedsRender];
	} else {
		[self snapViewportPosition:[self clampViewportPosition:_viewportPosition] animated:wasAnimating];
	}
}

#pragma mark -

- (void)recyleView:(MMMHorizontalPickerItemContainer *)container {

	[container removeFromSuperview];

	if ([_delegate respondsToSelector:@selector(horizontalPicker:recycleView:)])
		[_delegate horizontalPicker:self recycleView:container.view];
}

- (MMMHorizontalPickerItemContainer *)viewForItemWithIndex:(NSInteger)index {

	if (NSLocationInRange(index, _visibleRange)) {

		// We know this one already.
		return _visibleViews[index - _visibleRange.location];

	} else {

		// Don't have it, let's ask the delegate.
		UIView *view = [_delegate horizontalPicker:self viewForItemWithIndex:index];
		NSAssert(view != nil, @"");

		MMMHorizontalPickerItemContainer *container = [[MMMHorizontalPickerItemContainer alloc] initWithView:view];
		[self addSubview:container];

		if ([_delegate respondsToSelector:@selector(horizontalPicker:prepareView:)]) {
			[_delegate horizontalPicker:self prepareView:view];
		}

		return container;
	}
}

- (CGFloat)widthForItemContainer:(MMMHorizontalPickerItemContainer *)container {
	CGSize s = [self viewportBounds].size;
	switch (_style) {
		case MMMHorizontalPickerStyleDefault:
		case MMMHorizontalPickerStyleUniform:
			return [container sizeThatFits:CGSizeMake(0, s.height)].width;
		case MMMHorizontalPickerStylePaged:
			return s.width;
	}
}

- (CGRect)viewportBounds {
	return UIEdgeInsetsInsetRect(self.bounds, _contentInsets);
}

- (void)setPositionForView:(UIView *)view left:(CGFloat)left width:(CGFloat)width {

	CGRect b = [self viewportBounds];

	// Rounding to avoid a freeze encountered on iPad caused by a fractional height causing safe area insets
	// to update and causing layout change again, etc.
	// Not using CGIntegralRect() because we don't want the fractional position to trigger width change.
	view.mmm_rect = CGRectMake(MMMPixelRound(_viewportPositionReal + left), MMMPixelRound(CGRectGetMinY(b)), ceilf(width), ceilf(b.size.height));
}

#pragma mark -

- (void)setViewportPosition:(CGFloat)viewportPosition {
	[self setViewportPosition:viewportPosition animated:NO];
}

- (CGFloat)clampViewportPosition:(CGFloat)position {

	if (_numberOfItems == 0)
		return 0;
	else if (position < 0.5) {
		return 0.5;
	} else if (position >= _numberOfItems - 1 + .5) {
		return _numberOfItems - 1 + .5;
	} else {
		return position;
	}
}

- (void)cancelViewportPositionAnimation {
	[_viewportPositionAnimation cancel];
	_viewportPositionAnimation = nil;
}

- (void)snapViewportPosition:(CGFloat)position animated:(BOOL)animated {

	[self cancelViewportPositionAnimation];

	// Snapping to the center of the current item. Can snap differently or disable snapping here.
	CGFloat newViewportPosition = [self clampViewportPosition:position];
	newViewportPosition = floor(newViewportPosition) + .5;
	if (_numberOfItems == 0)
		newViewportPosition = 0;

	if (animated) {

		CGFloat startPosition = _viewportPosition + _dragOffset;

		typeof(self) __weak weakSelf = self;
		_viewportPositionAnimation = [[MMMAnimator shared]
			addAnimationWithDuration:0.2
			updateBlock:^(MMMAnimationHandle *item, CGFloat time) {
				typeof(self) strongSelf = weakSelf;
				if (strongSelf) {
					strongSelf->_viewportPosition = [MMMAnimation
						interpolateFrom:startPosition to:newViewportPosition
						time:time
						startTime:0 duration:1
						curve:MMMAnimationCurveEaseOut
					];
					[strongSelf setNeedsRender];
				}
			}
			doneBlock:^(MMMAnimationHandle *item, BOOL cancelled) {
				typeof(self) strongSelf = weakSelf;
				if (strongSelf) {
					[strongSelf updateCurrentItemIndex];
				}
			}
		];

	} else {

		_viewportPosition = newViewportPosition;
		[self updateCurrentItemIndex];
		[self setNeedsRender];
	}
}

- (void)updateCurrentItemIndex {

	NSInteger itemIndex = (NSInteger)floorf(_viewportPosition);

	// It should not be out of bounds, but just in case.
	itemIndex = MIN(itemIndex, _numberOfItems - 1);
	itemIndex = MAX(itemIndex, 0);

	if (_currentItemIndex != itemIndex) {

		_currentItemIndex = itemIndex;

		[_delegate horizontalPickerDidChangeCurrentItemIndex:self];
	}
}

- (void)setCurrentItemIndex:(NSInteger)currentItemIndex {
	[self setCurrentItemIndex:currentItemIndex animated:NO];
}

- (void)setCurrentItemIndex:(NSInteger)currentItemIndex animated:(BOOL)animated {

	if (_numberOfItems == 0) {

		[self setViewportPosition:0 animated:NO];

	} else {

		NSInteger index = currentItemIndex;
		index = MAX(index, 0);
		index = MIN(index, _numberOfItems - 1);
		[self setViewportPosition:index + 0.5 animated:animated];
	}
}

- (void)setSpacing:(CGFloat)spacing {
	if (_spacing != spacing) {
		_spacing = spacing;
		[self setNeedsRender];
	}
}

- (void)setPrototypeView:(UIView *)prototypeView {

	if (_prototypeView != prototypeView) {
	
		[_prototypeView removeFromSuperview];
	
		_prototypeView = prototypeView;
		
		if (_prototypeView) {
	
			_prototypeView.hidden = YES;
			[self addSubview:_prototypeView];
			
			[NSLayoutConstraint activateConstraint:[NSLayoutConstraint 
				constraintWithItem:_prototypeView attribute:NSLayoutAttributeWidth 
				relatedBy:NSLayoutRelationLessThanOrEqual 
				toItem:self attribute:NSLayoutAttributeWidth 
				multiplier:1 constant:-(_contentInsets.left + _contentInsets.right)
			]];
			
			if (_style == MMMHorizontalPickerStylePaged) {
			
				[NSLayoutConstraint activateConstraint:[NSLayoutConstraint 
					constraintWithItem:_prototypeView attribute:NSLayoutAttributeWidth 
					relatedBy:NSLayoutRelationEqual 
					toItem:self attribute:NSLayoutAttributeWidth 
					multiplier:1 constant:-(_contentInsets.left + _contentInsets.right)
					priority:UILayoutPriorityDefaultLow + 1
				]];
			}
			
			[NSLayoutConstraint activateConstraint:[NSLayoutConstraint 
				constraintWithItem:_prototypeView attribute:NSLayoutAttributeHeight 
				relatedBy:NSLayoutRelationLessThanOrEqual 
				toItem:self attribute:NSLayoutAttributeHeight
				multiplier:1 constant:-(_contentInsets.top + _contentInsets.bottom)
			]];
			
			[NSLayoutConstraint activateConstraint:[NSLayoutConstraint 
				constraintWithItem:_prototypeView attribute:NSLayoutAttributeHeight 
				relatedBy:NSLayoutRelationEqual 
				toItem:self attribute:NSLayoutAttributeHeight
				multiplier:1 constant:-(_contentInsets.top + _contentInsets.bottom)
				priority:UILayoutPriorityDefaultLow - 1
			]];
		}
	}
}

/** This is called only internally. */
- (void)setViewportPosition:(CGFloat)viewportPosition animated:(BOOL)animated {

	[self cancelViewportPositionAnimation];

	CGFloat newViewportPosition = [self clampViewportPosition:viewportPosition];

	if (animated) {

		CGFloat startPosition = _viewportPosition;

		typeof(self) __weak weakSelf = self;
		_viewportPositionAnimation = [[MMMAnimator shared]
			addAnimationWithDuration:0.2
			updateBlock:^(MMMAnimationHandle *item, CGFloat time) {
				typeof(self) strongSelf = weakSelf;
				if (strongSelf) {
					strongSelf->_viewportPosition = [MMMAnimation
						interpolateFrom:startPosition to:newViewportPosition
						time:time
						startTime:0 duration:1
						curve:MMMAnimationCurveEaseOut
					];
					[strongSelf setNeedsRender];
				}
			}
			doneBlock:^(MMMAnimationHandle *item, BOOL cancelled) {
				typeof(self) strongSelf = weakSelf;
				if (strongSelf) {
					[strongSelf updateCurrentItemIndex];
				}
			}
		];

	} else {
		if (_viewportPosition != newViewportPosition) {
			_viewportPosition = newViewportPosition;
			[self setNeedsRender];
			[self updateCurrentItemIndex];
		}
	}
}

- (void)setNeedsRender {
	// We "render" when it's time to layout.
	[self setNeedsLayout];
}

- (CGFloat)viewportPositionOffsetForRealOffset:(CGFloat)offset {

	if (_numberOfItems == 0) {
		NSAssert(NO, @"");
		return 0;
	}

	// For simplicity we'll use the the central item's width when converting offsets,
	// which might cause scrolling to be a bit funky when items have too large difference in width.
	// TODO: we can improve this if it becomes a problem

	NSInteger itemIndex = (NSInteger)floor(_viewportPosition);
	itemIndex = MAX(itemIndex, 0);
	itemIndex = MIN(itemIndex, _numberOfItems - 1);

	MMMHorizontalPickerItemContainer *view = [self viewForItemWithIndex:itemIndex];
	CGFloat width = [self widthForItemContainer:view];

	// It is possible that we've just created a brand new view instead of reusing one of the cached.
	// It needs to be properly disposed of.
	if (!NSLocationInRange(itemIndex, _visibleRange)) {
		[self recyleView:view];
	}

	return -offset / width;
}

- (void)recyleEverything {

	for (NSInteger i = 0; i < _visibleViews.count; i++) {
		[self recyleView:_visibleViews[i]];
	}

	[_visibleViews removeAllObjects];
	_visibleRange = NSMakeRange(0, 0);
}

- (CGFloat)bouncedViewportPosition:(CGFloat)viewportPosition min:(CGFloat)min max:(CGFloat)max {

	if (viewportPosition < min)
		return min + (viewportPosition - min) / 3;
	else if (viewportPosition > max)
		return max + (viewportPosition - max) / 3;
	else
		return viewportPosition;
}

- (void)render {

	CGRect b = self.bounds;
	if (!_delegate || _numberOfItems == 0 || b.size.width <= 0 || b.size.height <= 0) {
		[self recyleEverything];
		return;
	}
    
	// Illustration for the code below:
	//
	//   v--------viewport--------v
	//
	// 3 [ 4     5   |  6    7    ]  <- item indexes
	// [-[][----][---|-][---][--] ]  <- item views, can have different widths
	//   [           |            ]
	//       _viewportPosition
	//           e.g. 5.7

	BOOL uniform = _style == MMMHorizontalPickerStyleUniform;
	if (uniform && _uniformWidth == 0) {
		for (NSUInteger index = 0; index < _numberOfItems; index++) {
			UIView *itemView = [_delegate horizontalPicker:self viewForItemWithIndex:index];
			MMMHorizontalPickerItemContainer *container = [[MMMHorizontalPickerItemContainer alloc] initWithView:itemView];
			if ([_delegate respondsToSelector:@selector(horizontalPicker:prepareView:)]) {
				[_delegate horizontalPicker:self prepareView:itemView];
			}

			CGFloat width = [self widthForItemContainer:container];
			_uniformWidth = MAX(_uniformWidth, width);
		}
	}

	NSMutableArray<MMMHorizontalPickerItemContainer *> *visibleViews = [[NSMutableArray alloc] init];

	// Viewport position temporarily adjusted while dragging/bouncing.
	CGFloat effectiveViewportPosition = [self bouncedViewportPosition:_viewportPosition + _dragOffset min:.5 max:_numberOfItems - 0.5];

	// Assuming viewport bounds to be aligned with the bounds of the view.
	CGRect viewportBounds = self.bounds;

	// We assume that the position of the viewport's center coincides with the center of the bounds, but it does not have to be this way.
	_viewportPositionReal = CGRectGetMidX(viewportBounds);

	// How much real space spans from the center of the viewport to the left and to the right.
	CGFloat viewportLeft = CGRectGetMinX(viewportBounds) - _viewportPositionReal;
	CGFloat viewportRight = CGRectGetMaxX(viewportBounds) - _viewportPositionReal;

	// Indices of the first and the last visible items.
	NSInteger leftItemIndex;
	NSInteger rightItemIndex;

	// TODO: a lot of code is duplicated below, let's make it more compact

	if (effectiveViewportPosition < 0) {

		//
		// The center of the viewport is before the left edge of the first item, which will be our width reference.
		//

		// The first item will be in our range of visible items even if later it turns out to be too far to the right.
		leftItemIndex = rightItemIndex = 0;
		MMMHorizontalPickerItemContainer *view = [self viewForItemWithIndex:rightItemIndex];
		CGFloat width = uniform ? _uniformWidth : [self widthForItemContainer:view];
		// Signed offset in pixels from the left edge of the first item to the center of the viewport.
		CGFloat offset = -effectiveViewportPosition * width;

		// Collect all the items visible after the first one.
		do {

			[self setPositionForView:view left:offset width:width];
			[visibleViews addObject:view];

			offset += width + _spacing;

			// Bail out if the next item won't be visible or if there is no next item.
			if (offset >= viewportRight || rightItemIndex >= _numberOfItems - 1)
				break;

			rightItemIndex++;
			view = [self viewForItemWithIndex:rightItemIndex];
			width = uniform ? _uniformWidth : [self widthForItemContainer:view];

		} while (true);

	} else if (effectiveViewportPosition >= _numberOfItems) {

		//
		// The center of the viewport is after the right edge of the last item,
		// handling it similar to the above.
		//
		leftItemIndex = rightItemIndex = _numberOfItems - 1;

		MMMHorizontalPickerItemContainer *view = [self viewForItemWithIndex:rightItemIndex];
		CGFloat width = uniform ? _uniformWidth : [self widthForItemContainer:view];
		CGFloat offset = ((_numberOfItems - 1) - effectiveViewportPosition) * (width + _spacing);

		do {

			[self setPositionForView:view left:offset width:width];
			// TODO: might do addObject, and then reverse the array
			[visibleViews insertObject:view atIndex:0];

			if (offset <= viewportLeft || leftItemIndex <= 0)
				break;

			leftItemIndex--;

			view = [self viewForItemWithIndex:leftItemIndex];
			width = uniform ? _uniformWidth : [self widthForItemContainer:view];
			offset -= width + _spacing;

		} while (true);

	} else {

		//
		// OK, now the most common case: the center of the viewport intersects an item.
		// We begin with that item and then go to the left collecting visibe views,
		// then we go to the right doing the same starting with the one after the intersected item.
		//

		leftItemIndex = (NSInteger)floor(effectiveViewportPosition);
		NSAssert(0 <= leftItemIndex && leftItemIndex < _numberOfItems, @"");

		// Let's set up the current item first.
		MMMHorizontalPickerItemContainer *view = [self viewForItemWithIndex:leftItemIndex];
		CGFloat width = uniform ? _uniformWidth : [self widthForItemContainer:view];
		CGFloat leftOffset = -(effectiveViewportPosition - leftItemIndex) * width;

		// These two are used below, just grabbing them now before leftItemIndex and offset change.
		rightItemIndex = leftItemIndex + 1;
		CGFloat rightOffset = leftOffset + width + _spacing;

		// OK, let's try to go to the left.
		do {

			[self setPositionForView:view left:leftOffset width:width];
			// TODO: might do addObject, and then reverse the array
			[visibleViews insertObject:view atIndex:0];

			if (leftItemIndex <= 0 || leftOffset <= viewportLeft)
				break;

			leftItemIndex--;
			view = [self viewForItemWithIndex:leftItemIndex];
			width = uniform ? _uniformWidth : [self widthForItemContainer:view];
			leftOffset -= width + _spacing;

		} while (true);

		// Similarly crawl to the right.
		if (rightItemIndex < _numberOfItems) {

			if (rightOffset >= viewportRight) {

				// Avoid grabbing the next item if it's already outside the viewport.
				rightItemIndex--;

			} else {

				view = [self viewForItemWithIndex:rightItemIndex];
				width = uniform ? _uniformWidth : [self widthForItemContainer:view];

				do {

					[self setPositionForView:view left:rightOffset width:width];
					[visibleViews addObject:view];

					rightOffset += width + _spacing;

					if (rightItemIndex >= _numberOfItems - 1 || rightOffset >= viewportRight)
						break;

					rightItemIndex++;
					view = [self viewForItemWithIndex:rightItemIndex];
					width = uniform ? _uniformWidth : [self widthForItemContainer:view];

				} while (true);
			}

		} else {
			rightItemIndex = _numberOfItems - 1;
		}
	}

	// The indexes we've got should be in range already.
	NSAssert(0 <= leftItemIndex && leftItemIndex < _numberOfItems, @"");
	NSAssert(0 <= rightItemIndex && rightItemIndex < _numberOfItems, @"");
	NSAssert(leftItemIndex <= rightItemIndex, @"");

	// And the visibleView should be filled in correctly.
	NSAssert(visibleViews.count == rightItemIndex - leftItemIndex + 1, @"");

	//
	// Let's check if the new visible range is different from the old one.
	//
	NSRange visibleRange = NSMakeRange(leftItemIndex, rightItemIndex - leftItemIndex + 1);
	
	if (_delegateRespondsToUpdateView) {
	
		for (NSInteger i = 0; i < visibleRange.length; i++) {
			
			NSInteger itemIndex = visibleRange.location + i;

			[_delegate 
				horizontalPicker:self 
				updateView:visibleViews[i].view 
				centerProximity:(_viewportPosition + _dragOffset) - (itemIndex + 0.5)
			];
		}
	}
	
	if (_delegateRespondsToScroll) {
		// Subtract 0.5 since we're not reporting from center here.
		[_delegate horizontalPicker:self didScroll:effectiveViewportPosition - 0.5];
	}

	if (NSEqualRanges(_visibleRange, visibleRange)) {

		// Oh, it's the same, nothing to do now then.

		// We assume that the same visible range gives us the same views.
		NSAssert([_visibleViews isEqual:visibleViews], @"");

		return;
	}

	//
	// OK, the range has changed.
	// Let's recycle the views that are not visible anymore.
	//
	//~ MMM_LOG_TRACE(@"New range of visible items: %@", NSStringFromRange(visibleRange));
	for (NSInteger i = 0; i < _visibleRange.length; i++) {
		NSInteger itemIndex = _visibleRange.location + i;
		if (!NSLocationInRange(itemIndex, visibleRange)) {
			MMMHorizontalPickerItemContainer *view = [_visibleViews objectAtIndex:i];
			[self recyleView:view];
		}
	}

	NSAssert(self.subviews.count - (_prototypeView ? 1 : 0) == visibleViews.count, @"");

	// OK, now it's official.
	_visibleRange = visibleRange;
	_visibleViews = visibleViews;
}

#pragma mark -

- (void)panGestureRecognizerDidChange:(UIPanGestureRecognizer *)panRecognizer {

	NSAssert(_panGestureRecognizer == panRecognizer, @"");

	if (_numberOfItems == 0) {
		return;
	}

	switch (_panGestureRecognizer.state) {

		case UIGestureRecognizerStatePossible:
			break;

		case UIGestureRecognizerStateBegan:

			_dragging = YES;
			[self cancelViewportPositionAnimation];
			[self setNeedsRender];
			break;

		case UIGestureRecognizerStateChanged:
			if (_dragging) {
				_dragOffset = [self viewportPositionOffsetForRealOffset:[_panGestureRecognizer translationInView:self].x];
				[self setNeedsRender];
			}
			break;

		case UIGestureRecognizerStateEnded:

			if (_dragging) {

				_dragging = NO;

				_viewportPosition += [self viewportPositionOffsetForRealOffset:[_panGestureRecognizer translationInView:self].x];
				_dragOffset = 0;
				[self setNeedsRender];

				// How long we assume the scrolling inertia will continue.
				const CGFloat inertiaTimeout = 0.1;

				[self
					snapViewportPosition:_viewportPosition + [self viewportPositionOffsetForRealOffset:[_panGestureRecognizer velocityInView:self].x * inertiaTimeout]
					animated:YES
				];
			}

			break;

		case UIGestureRecognizerStateFailed:
		case UIGestureRecognizerStateCancelled:
			if (_dragging) {
				_dragging = NO;
				_dragOffset = 0;
				[self setNeedsRender];
			}
			break;
	}
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer == _panGestureRecognizer) {
		CGPoint offset = [_panGestureRecognizer translationInView:self];
		return fabs(offset.x) > fabs(offset.y);
	} else {
		return [super gestureRecognizerShouldBegin:gestureRecognizer];
	}
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

- (CGRect)accessibilityFrame {

    return [self convertRect:self.bounds toView:nil];
}

- (UIAccessibilityTraits)accessibilityTraits {

    return UIAccessibilityTraitAdjustable;
}

- (void)accessibilityIncrement {
	
	if (_viewportPosition < _numberOfItems - 1) {
            
		[self setCurrentItemIndex:_viewportPosition + 1 animated:NO];
	}
}

- (void)accessibilityDecrement {
	
	if (_viewportPosition > 0) {
		
		[self setCurrentItemIndex:_viewportPosition - 1 animated:NO];
	}
}


@end
