//
// MMMCommonUI. Part of MMMTemple.
// Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

@import UIKit;
@import MMMCommonCore; // Technically not needed in this header but then does not have to import on the use side.

NS_ASSUME_NONNULL_BEGIN

/**
 * Returns a color from a debug palette that can be used to highlight views for diagnostics purposes.
 * For the same index the same color is returned, however the total number of different colors
 * is limited to just a few, i.e. any given index is mapped into an index of a limited palette of colors.
 */
extern UIColor *MMMDebugColor(NSInteger index);

/** 
 * Draws a rectangle lying completely inside of the specified rect taking into account line width.
 * It is possible to select which of the 4 edges of the rectangle will be drawn, 
 * and what color and line width should be used.
 */
extern void MMMDrawBorder(CGRect r, UIRectEdge edge, UIColor *color, CGFloat width);

/** 
 * Returns the size decreased by the specified insets: the width is reduced by (insets.left + insets.right)
 * and the height by (insets.top + insets.bottom).
 *
 * This is somewhat like size of the rect returned by
 * \code
 * UIEdgeInsetsInsetRect(CGRectMake(0, 0, size.width, size.height), insets)
 * \endcode
 *
 * (Except that width and height never go negative of course).
 *
 * This is handy to use in sizeThatFits: 
 */
static inline CGSize MMMDeflateSize(CGSize size, UIEdgeInsets insets) {
	return CGSizeMake(
		MAX(0, size.width - insets.left - insets.right),
		MAX(0, size.height - insets.top - insets.bottom)
	);
}

/** 
 * Inverse of MMMDeflateSize(): the insets are added to the given size instead of being subtracted.
 */
static inline CGSize MMMInflateSize(CGSize size, UIEdgeInsets insets) {
	return CGSizeMake(
		insets.left + size.width + insets.right,
		insets.top + size.height + insets.bottom
	);
}

/**
 * The smallest insets that (component-wise) are not smaller than either of the provided ones.
 */
static inline UIEdgeInsets MMMMaxUIEdgeInsets(UIEdgeInsets a, UIEdgeInsets b) {
	return UIEdgeInsetsMake(MAX(a.top, b.top), MAX(a.left, b.left), MAX(a.bottom, b.bottom), MAX(a.right, b.right));
}

/**
 * The smallest size that is not smaller than either of the provided ones.
 */
static inline CGSize MMMMaxCGSize(CGSize a, CGSize b) {
	return CGSizeMake(MAX(a.width, b.width), MAX(a.height, b.height));
}

/**
 * A sum of two insets object.
 */
static inline UIEdgeInsets MMMCombinedUIEdgeInsets(UIEdgeInsets a, UIEdgeInsets b) {
	return UIEdgeInsetsMake(a.top + b.top, a.left + b.left, a.bottom + b.bottom, a.right + b.right);
}

/** 
 * UIEdgeInsets object with all fields being equal to the given value. 
 */
static inline UIEdgeInsets MMMSymmetricalUIEdgeInsets(CGFloat value) {
	return UIEdgeInsetsMake(value, value, value, value);
}

/** 
 * A caching shortcut to [UIScreen mainScreen].scale used by MMMPixelRound().
 */
extern CGFloat MMMPixelScale(void);

/** 
 * Rounds the given value in points so the corresponding value in pixels (assuming the main screen scale)
 * is rounded to the nearest integer.
 */
static inline CGFloat MMMPixelRound(CGFloat pointValue) {
	const CGFloat scale = MMMPixelScale();
	return roundf(pointValue * scale) / scale;
}

/** 
 * Rounds the given value in points so the corresponding value in pixels (assuming the main screen scale) 
 * is rounded to the nearest larger integer.
 */
static inline CGFloat MMMPixelCeil(CGFloat pointValue) {
	const CGFloat scale = MMMPixelScale();
	return ceilf(pointValue * scale) / scale;
}

/** 
 * Rounds the given value in points so the corresponding value in pixels (assuming the main screen scale) 
 * is rounded to the nearest smaller nteger.
 */
static inline CGFloat MMMPixelFloor(CGFloat pointValue) {
	const CGFloat scale = MMMPixelScale();
	return floorf(pointValue * scale) / scale;
}

/** 
 * Size with components rounded to the closest larger integral values. Sort of missing CGSize analogue of CGIntegralRect.
 *
 * See MMMPixelIntegralSize() for pixel boundary alignment.
 */
static inline CGSize MMMIntegralSize(CGSize size) {
	return CGSizeMake(ceilf(size.width), ceilf(size.height));
}

/** 
 * A version of MMMIntegralSize() taking into account the scale of the main screen, so on 2x Retina it will round up to 0.5 points.
 */
static inline CGSize MMMPixelIntegralSize(CGSize size) {
	return CGSizeMake(MMMPixelCeil(size.width), MMMPixelCeil(size.height));
}

/** 
 * A version of CGIntegralRect() taking into account the scale of the main screen.
 */
static inline CGRect MMMPixelIntegralRect(CGRect r) {
	return CGRectMake(
		MMMPixelRound(r.origin.x), MMMPixelRound(r.origin.y),
		MMMPixelCeil(r.size.width), MMMPixelCeil(r.size.height)
	);
}

/** 
 * The length of the vector represented by the given point.
 */
static inline CGFloat MMMPointVectorLength(CGPoint p) {
	return sqrtf(p.x * p.x + p.y * p.y);
}

/** 
 * The distance between two points.
 */
static inline CGFloat MMMPointDistance(CGPoint p1, CGPoint p2) {
	CGFloat dx = p1.x - p2.x;
	CGFloat dy = p1.y - p2.y;
	return sqrtf(dx * dx + dy * dy);
}

/**
 * Translates UIViewAnimationCurve into a corresponding flag of UIViewAnimationOptions.
 * Handy when we know the curve at runtime, like in keyboard appearance handlers, and want to use 
 * the corresponding  UIViewAnimationOptions flags.
 */
static inline UIViewAnimationOptions MMMAnimationOptionsFromAnimationCurve(UIViewAnimationCurve curve) {
	// Not very clean, but will work
	return (UIViewAnimationOptions)(curve << 16);
}

/**
 * Wrapper for NSAttributedString HTML parsing functionality.
 * Can be used for simple HTML, having only paragraphs, bullets and some emphasized text.
 * The result is mutable, so you can directly adjust it.
 *
 * @param baseAttributes These attributes are applied to the whole string after the parsing.
 * @param regularAttributes Attributes applied to regular (non-bold) text.
 * @param emphasizedAttributes Attributes applied to emphasized parts of the string.
 */
extern NSMutableAttributedString *MMMParseSimpleHTML(
	NSString *text,
	NSDictionary *baseAttributes,
	NSDictionary *regularAttributes,
	NSDictionary *emphasizedAttributes
);

/** Possible values for `MMMCaseTransformAttributeName` attribute. */
typedef NSString *MMMCaseTransform NS_TYPED_EXTENSIBLE_ENUM;

/** Part of the string marked with this should not change case before being rendered. */
extern MMMCaseTransform const MMMCaseTransformOriginal;

/** Part of the string marked with this should be UPPERCASED before being rendered. */
extern MMMCaseTransform const MMMCaseTransformUppercased;

/**
 * Name of the attribute defining how the case of text should be transformed before being rendered.
 *
 * Note that this is our custom attribute, there is no support for it at the level of Core Text or our views.
 * You have to use `mmm_attributedStringApplyingCaseTransformUsingLocale:` in order to apply this attribute
 * to the strings you use.
 */
extern NSAttributedStringKey const MMMCaseTransformAttributeName NS_SWIFT_NAME(caseTransform);

@interface NSAttributedString (MMMTempleMMMCommonUI)

/**
 * Returns a string where transforms specified using `MMMCaseTransformAttributeName` are applied.
 *
 * Note that the attribute itself is not removed.
 */
- (NSAttributedString *)mmm_attributedStringApplyingCaseTransformWithLocale:(NSLocale *)locale
	NS_SWIFT_NAME(mmm_attributedStringApplyingCaseTransform(withLocale:));

@end

@interface NSDictionary (MMMTempleMMMCommonUI)

/**
 * The result of combination of attributes from this dictionary and another one.
 * The attributes from another dictionary take precedance.
 */
- (NSDictionary *)mmm_withAttributes:(NSDictionary *)attributes;

/** Attributes dictionary with the given color added under NSForegroundColorAttributeName key. */
- (NSDictionary *)mmm_withColor:(UIColor *)color;

/** Attributes dictionary with the paragraph style adjusted by the given block. */
- (NSDictionary *)mmm_withParagraphStyle:(void (^)(NSMutableParagraphStyle *ps))block;

/** Attributes dictionary with the paragraph style's alignment set to the given value. */
- (NSDictionary *)mmm_withAlignment:(NSTextAlignment)alignment;

@end

//
//
//
@interface UIColor (MMMTempleMMMCommonUI)

/** YES, if the color's alpha component is less than 1. */
- (BOOL)mmm_isTransparent;

/** 
 * A color from a CSS-like static string literal. Supports hex style only for now.
 *
 * Note that this version is designed for constant literals known at compilation time,
 * so it'll not just return nil, but assert-crash in DEBUG in case the literal cannot be parsed.
 * Use `mmm_colorWithString:error:` for dynamic strings and handle the errors properly.
 */
+ (instancetype)mmm_colorWithString:(NSString *)string;

/** 
 * A color from a CSS-like string. Supports hex style only for now.
 *
 * Unlike `mmm_colorWithString:` this will never assert-crash, but will return nil and set the optional
 * error object pointer instead.
 */
+ (instancetype)mmm_colorWithString:(NSString *)s error:(NSError * __autoreleasing *)error;

@end

/**
 * The height of the top area covered by the application status bar for the given rectangle in the bounds of the 
 * specified view. It's always greater than or equal to zero.
 * It can be used to manually adjust the insets of a scroll view which is covered by the status bar.
 */
extern CGFloat MMMHeightOfAreaCoveredByStatusBar(UIView *view, CGRect rect);

//
//
//
@interface UIImage (MMMTempleMMMCommonUI)

/** 
 * Rasterized version of the given PDF image scaled to the given height and tinted with the given color.
 *
 * @param height	Height of the resulting image; pass 0 to use the actual rounded height of the PDF.
 * @param tintColor	Color to fill the non-transparent pixels with; pass `nil` to avoid tinting.
 *
 * Note that the file must be stored outside of the asset catalogue because we cannot get a raw PDF from there.
 */
+ (UIImage *)mmm_imageFromPDFNamed:(NSString *)name
	rasterizedForHeight:(CGFloat)height
	tintColor:(nullable UIColor *)tintColor;

/**
 * A shortcut for `mmm_imageFromPDFNamed:rasterizedForHeight:tintColot` without tinting
 * (passing `nil` for `tintColor`).
 */
+ (UIImage *)mmm_imageFromPDFNamed:(NSString *)name rasterizedForHeight:(CGFloat)height;

/**
 * A shortcut for `mmm_imageFromPDFNamed:rasterizedForHeight:tintColot` without scaling
 * (passing 0 for `height`).
 */
+ (UIImage *)mmm_imageFromPDFNamed:(NSString *)name tintColor:(UIColor *)tintColor;

/**
 * A non-caching version of `mmm_imageFromPDFNamed:rasterizedForHeight:tintColor:` using a concrete file path.
 */
+ (UIImage *)mmm_imageFromPDFWithPath:(NSString *)path rasterizedForHeight:(CGFloat)height tintColor:(nullable UIColor *)tintColor;

/**
 * Image of the given size in points and color, possibly transparent.
 */
+ (UIImage *)mmm_rectangleWithSize:(CGSize)size color:(UIColor *)color NS_SWIFT_NAME(mmm_rectangle(size:color:));

/** Makes a 1 by 1 point image with the given color, possibily transparent. */
+ (UIImage *)mmm_singlePixelWithColor:(UIColor *)color NS_SWIFT_NAME(mmm_singlePixel(color:));

@end

//
//
//
@interface UIViewController (MMMTempleMMMCommonUI)

/**
 * A drop-in replacement for `presentViewController:animated:completion:` helping to disable iOS 13-style interactive
 * dismissal for the view controllers we originally intended to display modally.
 *
 * Instead of setting `isModalInPresentation` on the view controller being presented to `YES` (which should have been
 * default), that we did initially, it is now setting `modalPresentationStyle` to `UIModalPresentationFullScreen`
 * to avoid interactive dismissal to mess up our layout and gestures.
 */
- (void)mmm_modallyPresentViewController:(UIViewController *)viewControllerToPresent
	animated:(BOOL)flag
	completion:(nullable void (^)(void))completion;

@end
/**
 * Calculates phase for a dashed line so that the ends of the line are cut symmetrically and at the dashed parts of the pattern.
 * `lineLength` is the total length of the line.
 * `dashLength` and `skipLength` are the length of the dashed and skipped parts of the pattern.
 */
extern CGFloat MMMPhaseForDashedPattern(CGFloat lineLength, CGFloat dashLength, CGFloat skipLength);

/**
 * Adds a path for a dashed line circle into the current graphics context and sets the given line dash pattern
 * (via CGContextSetLineDash) adjusting it a bit so the pattern will match seamlessly.
 * You need to stroke the path yourself.
 */
extern void MMMAddDashedCircle(CGPoint center, CGFloat radius, CGFloat dashLength, CGFloat skipLength);

/** YES, if running under Fastlane's Snapshot tool. */
static inline BOOL MMMIsRunningUnderFastlane() {

#if DEBUG

	static BOOL result;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		result = [[NSUserDefaults standardUserDefaults] boolForKey:@"FASTLANE_SNAPSHOT"];
	});
	return result;
	
#else
	// Always assume standalone execution for Release builds.
	return NO;
#endif
}

NS_ASSUME_NONNULL_END
