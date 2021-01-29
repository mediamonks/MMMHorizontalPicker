//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

#import "MMMStylesheet.h"

#import "MMMCommonUI.h"
#import "MMMLayout.h"

NSString * const MMMSizeClassic = @"classic";
NSString * const MMMSize6 = @"6";
NSString * const MMMSize6Plus = @"6plus";
NSString * const MMMSizePad = @"pad";
NSString * const MMMSizeRest = @"rest";

//
//
//
@implementation MMMStylesheetScaleConverter {
	NSDictionary<NSString *,NSNumber *> *_scales;
}

- (id)initWithScales:(NSDictionary<NSString *,NSNumber *> *)scales {
	if (self = [super init]) {
		_scales = scales;
	}
	return self;
}

- (id)initWithTargetSizeClass:(NSString *)targetSizeClass dimensions:(NSDictionary<NSString *,NSNumber *> *)dimensions {

	NSNumber *targetDimension = dimensions[targetSizeClass];
	if (![targetDimension isKindOfClass:[NSNumber class]]) {
		NSAssert(NO, @"No dimension provided for the target size class '%@'", targetSizeClass);
		return nil;
	}

	NSMutableDictionary *scales = [[NSMutableDictionary alloc] initWithCapacity:[dimensions count]];
	for (NSString *sizeClass in [dimensions keyEnumerator]) {

		NSNumber *dimension = dimensions[sizeClass];
		if (![dimension isKindOfClass:[NSNumber class]]) {
			NSAssert(NO, @"A dimension for size class '%@' has to be a number", sizeClass);
			return nil;
		}

		scales[sizeClass] = @([targetDimension floatValue] / [dimension floatValue]);
	}

	return [self initWithScales:scales];
}

- (CGFloat)convertFloat:(CGFloat)value fromSizeClass:(NSString *)sourceSizeClass {

	NSNumber *scale = _scales[sourceSizeClass];
	if (!scale)
		scale = _scales[MMMSizeRest];

	if (!scale) {
		NSAssert(NO, @"No scale for size class %@ provided nor there is something for MMMSizeRest", sourceSizeClass);
		return value;
	}

	return roundf(value * [scale floatValue]);
}

@end

//
//
//
@implementation MMMStylesheet {

	// The screen width associated with the current size class (not the actual screen width!).
	CGFloat _screenWidth;

	// Screen widths associated with all the supported size classes.
	NSDictionary<NSString *, NSNumber *> *_widthForSizeClass;

	// Size classes in the order of preference to fallback on.
	NSArray *_nearestSizeClasses;

	// Cached result of `dictionaryWithPaddings`.
	NSDictionary *_dictionaryWithPaddings;

	MMMStylesheetScaleConverter *_widthBasedConverter;
}

- (id)init {

	if (self = [super init]) {

		// Every size class has a width associated with it. It can be used to automatically scale certain elements sometimes.
		_widthForSizeClass = @{
			MMMSizeClassic : @320,
			MMMSize6 : @375,
			MMMSize6Plus : @414,
			MMMSizePad : @768
		};

		// We want to roughly know how big the device is, i.e. what's our "size class".
		CGSize screenSize = [UIScreen mainScreen].bounds.size;
		_screenWidth = MIN(screenSize.width, screenSize.height);
		if (_screenWidth <= 320) {
			_currentSizeClass = MMMSizeClassic;
			_nearestSizeClasses = @[ MMMSize6, MMMSize6Plus, MMMSizePad ];
		} else if (_screenWidth <= 375) {
			_currentSizeClass = MMMSize6;
			_nearestSizeClasses = @[ MMMSizeClassic, MMMSize6Plus, MMMSizePad ];
		} else if (_screenWidth <= 414) {
			_currentSizeClass = MMMSize6Plus;
			_nearestSizeClasses = @[ MMMSize6, MMMSizeClassic, MMMSizePad ];
		} else {
			_currentSizeClass = MMMSizePad;
			_nearestSizeClasses = @[ MMMSize6Plus, MMMSize6, MMMSizeClassic ];
		}

		// We want the width roughly associated with the current size class, not the actual width.
		_screenWidth = [_widthForSizeClass[_currentSizeClass] floatValue];

		_widthBasedConverter = [[MMMStylesheetScaleConverter alloc]
			initWithTargetSizeClass:_currentSizeClass
			dimensions:_widthForSizeClass
		];
	}

	return self;
}

#pragma mark -

- (id)valueForCurrentSizeClass:(NSDictionary *)sizeClassToValue {

	id result = sizeClassToValue[_currentSizeClass];
	if (result)
		return result;

	result = sizeClassToValue[MMMSizeRest];
	if (result)
		return result;

	for (id sizeClass in _nearestSizeClasses) {
		result = sizeClassToValue[sizeClass];
		if (result)
			return result;
	}

	NSAssert(
		NO,
		@"No value for size class '%@' and cannot even fallback to something meaningful in %@",
		_currentSizeClass, sizeClassToValue
	);

	return nil;
}

- (CGFloat)floatForCurrentSizeClass:(NSDictionary *)sizes {
	NSNumber *result = [self valueForCurrentSizeClass:sizes];
	NSAssert([result isKindOfClass:[NSNumber class]], @"");
	return [result floatValue];
}

#pragma mark -

- (CGFloat)extrapolatedFloatForCurrentSizeClass:(NSDictionary *)sizes {

	NSAssert(sizes.count <= 2, @"We don't support more than 2 values in the sizes array for %s", sel_getName(_cmd));
	NSAssert(sizes[MMMSizeRest] == nil, @"MMMSizeRest cannot be used with %s", sel_getName(_cmd));

	// Return asap if there is a precise value available.
	if (sizes[_currentSizeClass]) {
		return [sizes[_currentSizeClass] floatValue];
	}

	NSArray *sizeClasses = [sizes allKeys];

	if (sizes.count == 0) {

		NSAssert(NO, @"No values in the sizes array for %s", sel_getName(_cmd));
		return 0;

	} else if (sizes.count == 1) {

		id class1 = sizeClasses[0];
		return [self.widthBasedConverter convertFloat:[sizes[class1] floatValue] fromSizeClass:class1];

	} else if (sizes.count == 2) {

		// We have two values, let's scale them for the current size class individually first.
		id class1 = sizeClasses[0];
		CGFloat value1 = [self.widthBasedConverter convertFloat:[sizes[class1] floatValue] fromSizeClass:class1];

		id class2 = sizeClasses[1];
		CGFloat value2 = [self.widthBasedConverter convertFloat:[sizes[class2] floatValue] fromSizeClass:class2];

		// Then find out where the current size class is relative the other two.
		CGFloat width1 = [_widthForSizeClass[class1] floatValue];
		CGFloat width2 = [_widthForSizeClass[class2] floatValue];
		CGFloat t = (_screenWidth - width1) / (width2 - width1);

		// And now blend the individual values proportionally to their closiness to the current size class.
		return roundf(value1 * (1 - t) + value2 * t);

	} else {
		NSAssert(NO, @"");
		return 0;
	}
}

- (CGFloat)extrapolatedFloatForCurrentSizeClass:(NSDictionary *)sizes except:(NSDictionary *)exceptions {

	NSAssert(exceptions[MMMSizeRest] == nil, @"MMMSizeRest cannot be used with %s", sel_getName(_cmd));

	// If current size class in the exceptions, then use the corresponding value.
	NSNumber *exception = exceptions[_currentSizeClass];
	if (exception != nil) {
		return [exception floatValue];
	}

	// Otherwise trying to extrapolate.
	return [self extrapolatedFloatForCurrentSizeClass:sizes];
}

//
// These should be overriden in the actual stylsheet, but let's provide some defaults just in case
//

#pragma mark - Paddings

const CGFloat MMMStylesheetPaddingMultiplier = M_SQRT2;

- (CGFloat)extraExtraSmallPadding {
    return MMMPixelRound(self.normalPadding / (MMMStylesheetPaddingMultiplier * MMMStylesheetPaddingMultiplier * MMMStylesheetPaddingMultiplier));
}

- (CGFloat)extraSmallPadding {
	return MMMPixelRound(self.normalPadding / (MMMStylesheetPaddingMultiplier * MMMStylesheetPaddingMultiplier));
}

- (CGFloat)smallPadding {
	return MMMPixelRound(self.normalPadding / MMMStylesheetPaddingMultiplier);
}

- (CGFloat)normalPadding {
	// Normally 10 is only a round number in a decimal system and does not make a good padding constant,
	// but it's 1/32nd of the screen width on the classic iPhone, which makes it a great match for 32 or 16 column grids.
	return 10;
}

- (CGFloat)largePadding {
	return MMMPixelRound(self.normalPadding * MMMStylesheetPaddingMultiplier);
}

- (CGFloat)extraLargePadding {
	return MMMPixelRound(self.normalPadding * (MMMStylesheetPaddingMultiplier * MMMStylesheetPaddingMultiplier));
}

- (CGFloat)paddingFromRelativePadding:(CGFloat)padding {

	if (padding == 0) {
		return 0;
    } else if (padding <= 0.125) {
		return self.extraExtraSmallPadding;
	} else if (padding <= 0.25) {
		return self.extraSmallPadding;
	} else if (padding <= 0.5) {
		return self.smallPadding;
	} else if (padding <= 1) {
		return self.normalPadding;
	} else if (padding <= 2) {
		return self.largePadding;
	} else if (padding <= 4) {
		return self.extraLargePadding;
	} else {
		NSAssert(NO, @"Invalid value for relative padding: %.f", padding);
		return self.extraLargePadding;
	}
}

- (NSDictionary *)paddingDictionaryFromRelativeInsets:(UIEdgeInsets)insets {
	return MMMDictionaryFromUIEdgeInsets(@"padding", [self insetsFromRelativeInsets:insets]);
}

- (NSDictionary *)dictionaryFromRelativeInsets:(UIEdgeInsets)insets keyPrefix:(NSString *)keyPrefix {
	return MMMDictionaryFromUIEdgeInsets(keyPrefix, [self insetsFromRelativeInsets:insets]);
}

- (NSDictionary *)dictionaryWithPaddings {

	if (!_dictionaryWithPaddings) {
		_dictionaryWithPaddings = @{
            @"extraExtraSmallPadding" : @(self.extraExtraSmallPadding),
			@"extraSmallPadding" : @(self.extraSmallPadding),
			@"smallPadding" : @(self.smallPadding),
			@"normalPadding" : @(self.normalPadding),
			@"largePadding" : @(self.largePadding),
			@"extraLargePadding" : @(self.extraLargePadding)
		};
	}

	return _dictionaryWithPaddings;
}

- (UIEdgeInsets)insetsFromRelativeInsets:(UIEdgeInsets)insets {
	return UIEdgeInsetsMake(
		[self paddingFromRelativePadding:insets.top],
		[self paddingFromRelativePadding:insets.left],
		[self paddingFromRelativePadding:insets.bottom],
		[self paddingFromRelativePadding:insets.right]
	);
}

#pragma mark -

@end
