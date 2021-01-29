//
// MMMUtil.
// Copyright (C) 2015-2016 MediaMonks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MMMStylesheetConverter;

/** 
 * A base for app-specific stylesheets: commonly used paddings, colors, fonts, etc in a single place.
 */
@interface MMMStylesheet : NSObject

/** @{ */

/**
 * Helpers that can be used to pick paddings, font sizes, minimum sizes of UI element, etc roughly depending on the
 * physical size of the current device.
 *
 * Normally the end user of your stylesheet should not use these methods but instead have access to already prepared
 * fonts, paddings and element sizes as convenient properties which in turn use these helpers in their implementation.
 *
 * We don't use precise PPIs or actual screen sizes here, but rather broad size classes like "Classic iPhone" or "iPad".
 * See MMMSize* string constants. These size classes can be used in parallel with Apple's as the latter tell more about
 * the context the particular view is in than about the size of the device.
 */

/** The size class of the current device. See the MMSize* string constants below. */
@property (nonatomic, readonly) NSString *currentSizeClass;

/**
 * Allows to avoid code that picks values (fonts, sizes, etc) by explicitely matching `currentSizeClass`.
 * A mapping of size classes to values is passed here instead and a match is returned, falling back either to the value
 * under MMMSizeRest key, or, if it is not present, to the value under the key that seems the closest to the current
 * size class.
 */
- (id)valueForCurrentSizeClass:(NSDictionary<NSString *, id> *)sizeClassToValue;

/** A version of `valueForCurrentSizeClass:` unwrapping the result as a float, which is handy for numeric values. */
- (CGFloat)floatForCurrentSizeClass:(NSDictionary<NSString *, NSNumber *> *)sizeClassToValue;

/**
 * Deprecated.
 * Similar to `floatForCurrentSizeClass:` but instead of falling back to the value under MMMSizeRest key
 * it tries to extrapolate the requested dimension using 1 or 2 values provided for other size classes using
 * the `widthBasedConverter`.
 */
- (CGFloat)extrapolatedFloatForCurrentSizeClass:(NSDictionary<NSString *, NSNumber *> *)sizeClassToValue
	DEPRECATED_MSG_ATTRIBUTE("Try using `widthBasedConverter` instead or a custom converter if you relied on 2 dimensions");

/**
 * Deprecated.
 * Similar to `extrapolatedFloatForCurrentSizeClass:`, but allows to override values for certain size classes
 * in the `exceptions` paramater.
 */
- (CGFloat)extrapolatedFloatForCurrentSizeClass:(NSDictionary<NSString *, NSNumber *> *)sizeClassToValue
	except:(NSDictionary *)exceptions
	DEPRECATED_MSG_ATTRIBUTE("The code using this might be confusing and/or hard to support. If you need to specify values for different size classes, then list them all explicitly in a call to floatForCurrentSizeClass:");

/**
 * Converts dimensions given for one size class into dimensions suitable for the current size class
 * based on the ratio of screen widths associated with the current and source size classes.
 */
@property (nonatomic, readonly) id<MMMStylesheetConverter> widthBasedConverter;

/** @} */

/** @{ */

/** 
 * A standard set of paddings.
 * The actual stylesheet should override all these or at least the `normalPadding`.
 * They are defined here so `insetsFromRelativeInsets` can be defined here as well.
 * In case only `normalPadding` is overriden then the rest will be calculated based on it using sqrt(2) as a multiplier,
 * so every second padding is exactly 2x larger.
 */

@property (nonatomic, readonly) CGFloat extraExtraSmallPadding;
@property (nonatomic, readonly) CGFloat extraSmallPadding;
@property (nonatomic, readonly) CGFloat smallPadding;
@property (nonatomic, readonly) CGFloat normalPadding;
@property (nonatomic, readonly) CGFloat largePadding;
@property (nonatomic, readonly) CGFloat extraLargePadding;

/** @} */

/** 
 * Actual insets from relative ones.
 *
 * Each offset in relative insets is a fixed number corresponding to the actual paddings defined above:
 *
 *  - .125 - extraExtraSmallPadding
 *  - .25 — extraSmallPadding
 *  - .5 — smallPadding
 *  - 1 — normalPadding
 *  - 2 — largePadding
 *  - 4 — extraLargePadding
 *
 * Note that the large padding is not necessarily 2x larger than the normal one, etc (by default the extra large is),
 * but we intentionally use them here like this to allow more compact notation for insets which is easy to remember and
 * easy to tweak. Compare, for example:
 *
 * \code
 *		UIEdgeInsetsMake([MHStylesheet shared].normalPadding, [MHStylesheet shared].largePadding, [MHStylesheet shared].normalPadding, [MHStylesheet shared].largePadding)
 * \endcode
 *
 * and the equivalent:
 *
 * \code 
 *		[[MHStylesheet shared] insetsFromRelativeInsets:UIEdgeInsetsMake(1, 2, 1, 2)]
 * \endcode
 *
 */
- (UIEdgeInsets)insetsFromRelativeInsets:(UIEdgeInsets)insets;

/** This is what `insetsFromRelativeInsets:` is using internally. Might be useful when making similar methods. */
- (CGFloat)paddingFromRelativePadding:(CGFloat)padding;

/** 
 * A metrics dictionary that can be used with Auto Layout with keys/values corresponding to all the paddings we support,
 * e.g. "extraSmallPadding", etc.
 */
- (NSDictionary<NSString *, NSNumber *> *)dictionaryWithPaddings;

/**
 * A dictionary with 4 values under keys "<keyPrefix>Top", "<keyPrefix>Bottom", "<keyPrefix>Left", "<keyPrefix>Right" 
 * corresponding to the insets obtained from the provided relative ones via `insetsFromRelativeInsets:`.
 * (A shortcut composing `insetsFromRelativeInsets` method with `MMMDictinaryFromUIEdgeInsets()`.)
 */
- (NSDictionary<NSString *, NSNumber *> *)dictionaryFromRelativeInsets:(UIEdgeInsets)insets keyPrefix:(NSString *)keyPrefix;

/**
 * A dictionary with 4 values obtained from the insets returned by `insetsFromRelativeInsets:insets`
 * under the keys "paddingTop", "paddingBottom", "paddingLeft", "paddingRight",
 * i.e. it's a shortcut for `dictionaryFromRelativeInsets:insets keyPrefix:@"padding"`.
 */
- (NSDictionary<NSString *, NSNumber *> *)paddingDictionaryFromRelativeInsets:(UIEdgeInsets)insets;

@end

/** @{ */

/**
 * Identifiers of screen size classes we normally use to pick dimensions.
 * (This is not an enum because it's easier to use them in dictionaries this way.)
 * Please don't use them to identifiy devices, think of them as of "small", "medium", and "large" instead.
 */

/** Small screen phones: iPhone 4/4s/5/5s/SE. */
extern NSString * const MMMSizeClassic;

/** Regular phones: iPhone 6/6s/7/8 and X as well. */
extern NSString * const MMMSize6;

/** Pluse-sized phones: iPhone 6/7/8 Plus. */
extern NSString * const MMMSize6Plus;

/** iPads: regular and pros. */
extern NSString * const MMMSizePad;

/** Not the actual size class, but can be used as a key `valueForCurrentSizeClass:` and related methods for a fallback value. */
extern NSString * const MMMSizeRest;

/** @} */

/**
 * Something that converts dimensions given for one size class (e.g. font sizes from the design made for iPhone 6)
 * into dimensions for another size class (e.g. font size for iPhone 5 that were not explicitely mentioned in the design).
 *
 * Different converters can be used for different kinds of values. For example, it might make sense to scale paddings
 * proportionally to screen widths, but keep font sizes the same.
 */
@protocol MMMStylesheetConverter <NSObject>

/** Converts a dimension know for certain size class according to the rules of the converter. */
- (CGFloat)convertFloat:(CGFloat)value fromSizeClass:(NSString *)sourceSizeClass;

@end

/**
 * Dimension converter that uses a table of scales.
 */
@interface MMMStylesheetScaleConverter : NSObject <MMMStylesheetConverter>

/**
 * Initializes the converter with an explicit table of scales.
 * Every value coming to `convertFloat:fromSizeClass:` will be returned multiplied by scales[sourceSizeClass].
 */
- (id)initWithScales:(NSDictionary<NSString *, NSNumber *> *)scales NS_DESIGNATED_INITIALIZER;

/**
 * Initializes the converter with a target size class and a table of dimensions associated with every size class
 * (e.g screen width).
 *
 * Every value coming to `convertFloat:fromSizeClass:` will be returned adjusted proportionally to the ratio of the
 * dimensions associated with target and source size classes, i.e. it will be multiplied by
 * scales[targetSizeClass] / scales[sourceSizeClass].
 *
 * So for a table of screen widths the converter will upscale or downscale dimensions between size classes
 * proprtionally to the ratios of screen width associated with size classes.
 */
- (id)initWithTargetSizeClass:(NSString *)targetSizeClass dimensions:(NSDictionary<NSString *, NSNumber *> *)dimensions;

- (id)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

