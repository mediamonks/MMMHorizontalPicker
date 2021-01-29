//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMKeyboard.h"

#import "MMMObserverHub.h"

@implementation MMMKeyboard {
	MMMObserverHub<id<MMMKeyboardObserver>> *_observerHub;
	MMMObserverHub<id<MMMKeyboardObserver>> *_earlyObserverHub;
	CGRect _endFrame;
}

+ (instancetype)shared {

	static MMMKeyboard *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[MMMKeyboard alloc] init];
	});
	return shared;
}

- (id)init {

	if (self = [super init]) {

		_observerHub = [[MMMObserverHub alloc] initWithObservable:self];
		_earlyObserverHub = [[MMMObserverHub alloc] initWithObservable:self];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	}

	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (CGRect)boundsNotCoveredByKeyboardForView:(UIView *)view {

	CGRect bounds = view.bounds;

	if (_state == MMMKeyboardStateUnknown || _state == MMMKeyboardStateHidden) {
		// Well, the keyboard is hidden (or we assume it is)
		return bounds;
	}

	CGRect keyboardFrame = [view convertRect:_endFrame fromView:nil];
	if (CGRectGetMaxY(bounds) <= CGRectGetMinY(keyboardFrame)) {
		// The keyboard is far below the view, we have all the bounds
		return bounds;
	} else  {
		// The keyboard is covering the view partially or wholly, let's adjust the height of the bounds not covered
		bounds.size.height = MAX(CGRectGetMinY(keyboardFrame) - CGRectGetMinY(bounds), 0);
		return bounds;
	}
}

- (CGFloat)heightOfPartCoveredByKeyboardForView:(UIView *)view {
	CGRect bounds = view.bounds;
	CGRect notCoveredBounds = [self boundsNotCoveredByKeyboardForView:view];
	return CGRectGetMaxY(bounds) - CGRectGetMaxY(notCoveredBounds);
}

- (UIEdgeInsets)insetsForBoundsNotCoveredByKeyboardForView:(UIView *)view {
	return UIEdgeInsetsMake(0, 0, [self heightOfPartCoveredByKeyboardForView:view], 0);
}

#pragma mark -

- (void)keyboardWillChange:(NSNotification *)n state:(MMMKeyboardState)state {

	NSDictionary *params = [n userInfo];

	_endFrame = [params[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	NSTimeInterval duration = [params[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve curve = (UIViewAnimationCurve)[params[UIKeyboardAnimationCurveUserInfoKey] integerValue];

	_state = state;

	[_earlyObserverHub forEachObserver:^(id<MMMKeyboardObserver> observer) {
		[observer keyboard:self willChangeStateWithAnimationDuration:duration curve:curve];
	}];
	[_observerHub forEachObserver:^(id<MMMKeyboardObserver> observer) {
		[observer keyboard:self willChangeStateWithAnimationDuration:duration curve:curve];
	}];
}

- (void)keyboardWillShow:(NSNotification *)n {
	[self keyboardWillChange:n state:MMMKeyboardStateVisible];
}

- (void)keyboardWillHide:(NSNotification *)n {
	[self keyboardWillChange:n state:MMMKeyboardStateHidden];
}

#pragma mark -

- (id<MMMObserverToken>)addObserver:(id<MMMKeyboardObserver>)observer {
	return [_observerHub safeAddObserver:observer];
}

- (id<MMMObserverToken>)addEarlyObserver:(id<MMMKeyboardObserver>)observer {
	return [_earlyObserverHub safeAddObserver:observer];
}

@end

// MARK: -

#import <objc/runtime.h>

@interface MMMKeyboardLayoutHelper () <MMMKeyboardObserver>
@end

@implementation MMMKeyboardLayoutHelper {
	id<MMMObserverToken> _keyboardObserverToken;
	NSLayoutConstraint *_heightConstraint;
}

static char MMMKeyboardLayoutGuideKey[] = "MMMKayboardLayoutGuide";

+ (MMMKeyboardLayoutHelper *)instanceForView:(UIView *)view createIfNeeded:(BOOL)createIfNeeded {
	MMMKeyboardLayoutHelper *result = objc_getAssociatedObject(view, MMMKeyboardLayoutGuideKey);
	if (!result && createIfNeeded) {
		result = [[MMMKeyboardLayoutHelper alloc] initWithView:view];
	}
	return result;
}

- (id)initWithView:(UIView *)view {

	if (self = [super init]) {

		// Want to be notified earlier than potential users of our constraints.
		_keyboardObserverToken = [[MMMKeyboard shared] addEarlyObserver:self];

		_layoutGuide = [[UILayoutGuide alloc] init];
		_layoutGuide.identifier = @"MMMKeyboardLayoutGuide";

		[view addLayoutGuide:_layoutGuide];

		[NSLayoutConstraint activateConstraints:@[
			_heightConstraint = [NSLayoutConstraint
				constraintWithItem:_layoutGuide attribute:NSLayoutAttributeHeight
				relatedBy:NSLayoutRelationEqual
				toItem:nil attribute:NSLayoutAttributeNotAnAttribute
				multiplier:1 constant:0
			],
			[NSLayoutConstraint
				constraintWithItem:_layoutGuide attribute:NSLayoutAttributeBottom
				relatedBy:NSLayoutRelationEqual
				toItem:view attribute:NSLayoutAttributeBottom
				multiplier:1 constant:0
			],
			// These two are optional as nobody needs to constrain to the sides of our guide,
			// still might look nicer when debugging it.
			[NSLayoutConstraint
				constraintWithItem:_layoutGuide attribute:NSLayoutAttributeLeading
				relatedBy:NSLayoutRelationEqual
				toItem:view attribute:NSLayoutAttributeLeading
				multiplier:1 constant:0
			],
			[NSLayoutConstraint
				constraintWithItem:_layoutGuide attribute:NSLayoutAttributeTrailing
				relatedBy:NSLayoutRelationEqual
				toItem:view attribute:NSLayoutAttributeTrailing
				multiplier:1 constant:0
			]
		]];

		objc_setAssociatedObject(view, MMMKeyboardLayoutGuideKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}

	return self;
}

- (void)update {
	UIView *view = _layoutGuide.owningView;
	_heightConstraint.constant = view ? [[MMMKeyboard shared] heightOfPartCoveredByKeyboardForView:view] : 0;
}

- (void)keyboard:(MMMKeyboard *)keyboard
	willChangeStateWithAnimationDuration:(NSTimeInterval)duration
	curve:(UIViewAnimationCurve)curve
{
	[self update];
}

@end

@implementation UIView (MMMKeyboard)

- (MMMKeyboardLayoutHelper *)mmm_keyboard {
	return [MMMKeyboardLayoutHelper instanceForView:self createIfNeeded:YES];
}

@end
