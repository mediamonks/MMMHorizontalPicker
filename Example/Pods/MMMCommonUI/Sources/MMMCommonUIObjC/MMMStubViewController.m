//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMStubViewController.h"

#import "MMMStubView.h"

@import MMMLog;

/** 
 * We want the stub view controller to check if its appearance methods are called correctly, 
 * which helps with debugging of custom view controllers.
 */
typedef NS_ENUM(NSInteger, MMMStubViewControllerAppearanceState) {
	MMMStubViewControllerAppearanceStateDisappeared,
	MMMStubViewControllerAppearanceStateAppearing,
	MMMStubViewControllerAppearanceStateDisappearing,
	MMMStubViewControllerAppearanceStateAppeared
};

//
//
//
@interface MMMStubViewController ()
@end

@implementation MMMStubViewController {

	MMMStubView *__weak _view;

	NSString *_text;
	NSInteger _index;

	MMMStubViewControllerAppearanceState _appearanceState;
}

- (NSString *)mmm_instanceNameForLogging {
	return [NSString stringWithFormat:@"%ld", (long)_index];
}

- (id)initWithText:(NSString *)text index:(NSInteger)index {

	if (self = [super initWithNibName:nil bundle:nil]) {
		_text = text;
		_index = index;
		_appearanceState = MMMStubViewControllerAppearanceStateDisappeared;
	}

	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@:%p #%ld '%@'>", self.class, self, (long)_index, _text];
}

- (void)loadView {
	MMMStubView *view = [[MMMStubView alloc] initWithText:_text index:_index];
	self.view = _view = view;
}

- (void)setAppearanceState:(MMMStubViewControllerAppearanceState)state {

	if (_appearanceState == MMMStubViewControllerAppearanceStateDisappeared) {

		NSAssert(state == MMMStubViewControllerAppearanceStateAppearing, @"");

	} else if (_appearanceState == MMMStubViewControllerAppearanceStateAppearing) {

		NSAssert(
			state == MMMStubViewControllerAppearanceStateAppeared
			|| state == MMMStubViewControllerAppearanceStateDisappearing,
			@""
		);

	} else if (_appearanceState == MMMStubViewControllerAppearanceStateAppeared) {

		NSAssert(
			state == MMMStubViewControllerAppearanceStateDisappearing
			|| state == MMMStubViewControllerAppearanceStateDisappeared,
			@""
		);

	} else if (_appearanceState == MMMStubViewControllerAppearanceStateDisappearing) {

		NSAssert(
			state == MMMStubViewControllerAppearanceStateDisappeared
			|| state == MMMStubViewControllerAppearanceStateAppearing,
			@""
		);
	}

	_appearanceState = state;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	MMM_LOG_TRACE(@"%s%d", sel_getName(_cmd), animated);
	[self setAppearanceState:MMMStubViewControllerAppearanceStateAppearing];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	MMM_LOG_TRACE(@"%s%d", sel_getName(_cmd), animated);
	[self setAppearanceState:MMMStubViewControllerAppearanceStateAppeared];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	MMM_LOG_TRACE(@"%s%d", sel_getName(_cmd), animated);
	[self setAppearanceState:MMMStubViewControllerAppearanceStateDisappearing];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	MMM_LOG_TRACE(@"%s%d", sel_getName(_cmd), animated);
	[self setAppearanceState:MMMStubViewControllerAppearanceStateDisappeared];
}

@end
